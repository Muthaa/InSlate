import 'package:flutter/foundation.dart';

import '../core/constants/mpesa_patterns.dart';
import '../models/import_progress.dart';
import '../library/classifiers/message_classifier.dart';
import '../models/raw_message.dart';
import '../parsers/parser_factory.dart';
import '../repositories/financial_records_repository.dart';
import '../repositories/raw_messages_repository.dart';
import '../sources/transaction_source.dart';
import '../models/financial_records.dart';
import 'import_logger.dart';
import '../core/enums/transaction_status.dart';

class TransactionImportService {
  final MessageClassifier classifier;
  final FinancialRecordsRepository financialRecordsRepository;
  final RawMessagesRepository rawMessagesRepository;
  final void Function(ImportProgress progress)? onProgress;

  TransactionImportService({
    required this.classifier,
    required this.financialRecordsRepository,
    required this.rawMessagesRepository,
    this.onProgress,
  });

  Future<ImportResult> importMessages(List<RawMessage> messages) async {
    var skipped = 0;
    var failed = 0;
    var imported = 0;

    final subtypeCounts = <String, int>{};
    final skippedMessages = <String, int>{};
    final failedMessages = <String, int>{};
    final sourceIdByRecord = <FinancialRecord, String>{};
    final sourceIdBySavedReference = <String, String>{};
    final recordBySavedReference = <String, FinancialRecord>{};
    final existingRecordByReference = <String, FinancialRecord?>{};

    if (messages.isEmpty) {
      await ImportLogger.write('IMPORT_START | messages=0');
      await ImportLogger.write(
        'IMPORT_SUMMARY | imported=0 | skipped=0 | failed=0 | '
        'subtypes=$subtypeCounts | skippedBySubtype=$skippedMessages | '
        'failedBySubtype=$failedMessages',
      );
      await ImportLogger.write(
        'IMPORT_COMPLETE | imported=0 | skipped=0 | failed=0',
      );

      return const ImportResult(imported: 0, skipped: 0, failed: 0);
    }

    await ImportLogger.write('IMPORT_START | messages=${messages.length}');

    onProgress?.call(
      ImportProgress(
        status: ImportStatus.loadingMessages,
        total: messages.length,
      ),
    );

    const batchSize = 2000;

    final existingSourceIds = await rawMessagesRepository.getExistingSourceIds(
      messages.map((message) => message.id).toList(),
    );

    final existingSourceIdSet = existingSourceIds.toSet();
    final alreadyImportedMessages = messages
        .where((message) => existingSourceIdSet.contains(message.id))
        .toList();
    skipped += alreadyImportedMessages.length;

    for (final message in alreadyImportedMessages) {
      await ImportLogger.write(
        'RECORD_SKIPPED | '
        'sms_id=${message.id} | '
        'reason=EXISTING_SOURCE_ID',
      );
    }

    final newMessages = messages
        .where((message) => !existingSourceIdSet.contains(message.id))
        .toList();

    final existingBodyDuplicates = await rawMessagesRepository
        .getExistingBySenderAndBodies(newMessages);
    final firstSourceIdBySenderAndBody = <String, Map<String, String>>{};
    for (final message in existingBodyDuplicates) {
      firstSourceIdBySenderAndBody
          .putIfAbsent(message.sender, () => <String, String>{})
          .putIfAbsent(message.body, () => message.id);
    }

    final seenSourceIds = <String>{};
    final firstIncomingSourceIdBySenderAndBody =
        <String, Map<String, String>>{};
    final messagesToSave = <RawMessage>[];
    final duplicateSourceIds = <String>{};

    for (final message in newMessages) {
      if (!seenSourceIds.add(message.id)) {
        continue;
      }

      final firstSourceId =
          firstSourceIdBySenderAndBody[message.sender]?[message.body] ??
          firstIncomingSourceIdBySenderAndBody[message.sender]?[message.body];

      if (firstSourceId != null && firstSourceId != message.id) {
        skipped++;
        duplicateSourceIds.add(message.id);

        final reference =
            MpesaPatterns.reference.firstMatch(message.body)?.group(1) ??
            'unavailable';
        await ImportLogger.write(
          'DUPLICATE_SMS | '
          'reference=$reference | '
          'existing_sms_id=$firstSourceId | '
          'duplicate_sms_id=${message.id} | '
          'reason=IDENTICAL_BODY | '
          'action=IGNORED',
        );

        continue;
      }

      firstIncomingSourceIdBySenderAndBody
          .putIfAbsent(message.sender, () => <String, String>{})
          .putIfAbsent(message.body, () => message.id);
      messagesToSave.add(message);
    }

    final messagesToProcess = messages
        .where(
          (message) =>
              !existingSourceIdSet.contains(message.id) &&
              !duplicateSourceIds.contains(message.id),
        )
        .toList();

    onProgress?.call(
      ImportProgress(
        status: ImportStatus.loadingMessages,
        total: messagesToSave.length,
      ),
    );

    await rawMessagesRepository.saveAll(messagesToSave);

    for (var start = 0; start < messagesToProcess.length; start += batchSize) {
      final end = (start + batchSize < messagesToProcess.length)
          ? start + batchSize
          : messagesToProcess.length;

      final batchMessages = messagesToProcess.sublist(start, end);

      onProgress?.call(
        ImportProgress(
          status: ImportStatus.processing,
          total: messagesToProcess.length,
          processed: start,
          imported: imported,
          skipped: skipped,
          failed: failed,
        ),
      );

      final parsedRecords = <FinancialRecord>[];

      for (var index = 0; index < batchMessages.length; index++) {
        final message = batchMessages[index];
        final classification = classifier.classify(message.body);

        final subtype = classification.subtype.name;

        subtypeCounts[subtype] = (subtypeCounts[subtype] ?? 0) + 1;

        if (classification.status == TransactionStatus.failed) {
          skipped++;

          skippedMessages[subtype] = (skippedMessages[subtype] ?? 0) + 1;

          await ImportLogger.write(
            'SKIPPED_FAILED_TRANSACTION | '
            'sms_id=${message.id} | '
            'subtype=$subtype | '
            'reason=TRANSACTION_FAILED',
          );
        } else if (subtype == 'unknown') {
          skipped++;

          skippedMessages[subtype] = (skippedMessages[subtype] ?? 0) + 1;

          await ImportLogger.write(
            'SKIPPED_UNKNOWN | '
            'sms_id=${message.id} | '
            'subtype=$subtype | '
            'reason=UNKNOWN_CLASSIFICATION',
          );
        } else {
          final parser = ParserFactory.getParser(classification.subtype);

          if (parser == null) {
            skipped++;

            skippedMessages[subtype] = (skippedMessages[subtype] ?? 0) + 1;

            await ImportLogger.write(
              'SKIPPED_NO_PARSER | '
              'sms_id=${message.id} | '
              'subtype=$subtype | '
              'reason=NO_PARSER',
            );
          } else {
            final result = parser.parse(message, classification);

            if (!result.success || result.record == null) {
              failed++;

              failedMessages[subtype] = (failedMessages[subtype] ?? 0) + 1;

              await ImportLogger.write(
                'PARSE_FAILED | '
                'sms_id=${message.id} | '
                'subtype=$subtype | '
                'reference=unavailable | '
                'error=${result.error} | '
                'body=${message.body}',
              );
            } else {
              final record = result.record!;

              parsedRecords.add(record);
              sourceIdByRecord[record] = message.id;
            }
          }
        }

        onProgress?.call(
          ImportProgress(
            status: ImportStatus.processing,
            total: messagesToProcess.length,
            processed: start + index + 1,
            imported: imported,
            skipped: skipped,
            failed: failed,
          ),
        );
      }

      if (parsedRecords.isEmpty) {
        continue;
      }

      final sourceMessageIds = parsedRecords
          .map((record) => record.sourceMessageId)
          .whereType<String>()
          .toList();

      final existingSourceMessageIds = await financialRecordsRepository
          .getExistingSourceMessageIds(sourceMessageIds);

      final existingSourceMessageIdSet = existingSourceMessageIds.toSet();

      final newRecords = <FinancialRecord>[];
      final seenSourceMessageIds = <String>{};

      for (final record in parsedRecords) {
        final newSourceId = sourceIdByRecord[record] ?? 'unavailable';
        final sourceMessageId = record.sourceMessageId;

        if (sourceMessageId != null &&
            existingSourceMessageIdSet.contains(sourceMessageId)) {
          skipped++;

          if (!existingRecordByReference.containsKey(record.reference)) {
            final existingRecords = await financialRecordsRepository
                .getAllByReference(record.reference);
            existingRecordByReference[record.reference] =
                existingRecords.isEmpty ? null : existingRecords.first;
          }

          final existingRecord =
              recordBySavedReference[record.reference] ??
              existingRecordByReference[record.reference];
          final existingSourceId = sourceIdBySavedReference[record.reference];
          final identicalBody = existingRecord?.rawMessage == record.rawMessage;
          final sameRecord =
              existingRecord != null &&
              existingRecord.subtype == record.subtype &&
              existingRecord.amount == record.amount &&
              identicalBody;
          final distinctSms = existingSourceId != null
              ? existingSourceId != newSourceId
              : existingRecord != null &&
                    existingRecord.receivedAt != record.receivedAt;

          if (sameRecord && distinctSms) {
            await ImportLogger.write(
              'DUPLICATE_SMS | '
              'reference=${record.reference} | '
              'existing_sms_id=${existingSourceId ?? 'unavailable'} | '
              'duplicate_sms_id=$newSourceId | '
              'reason=IDENTICAL_BODY | '
              'action=IGNORED',
            );
          } else if (!sameRecord) {
            await ImportLogger.write(
              'REFERENCE_COLLISION | '
              'reference=${record.reference} | '
              'existing_subtype=${existingRecord?.subtype.name ?? 'unavailable'} | '
              'existing_amount=${existingRecord?.amount ?? 'unavailable'} | '
              'existing_sms_id=${existingSourceId ?? 'unavailable'} | '
              'new_subtype=${record.subtype.name} | '
              'new_amount=${record.amount} | '
              'new_sms_id=$newSourceId | '
              'existing_raw_message=${existingRecord?.rawMessage ?? 'unavailable'} | '
              'new_raw_message=${record.rawMessage} | '
              'action=REVIEW_REQUIRED',
            );
          }

          await ImportLogger.write(
            'RECORD_SKIPPED | '
            'sms_id=$newSourceId | '
            'reference=${record.reference} | '
            'subtype=${record.subtype.name} | '
            'reason=EXISTING_REFERENCE',
          );

          continue;
        }

        if (sourceMessageId != null &&
            !seenSourceMessageIds.add(sourceMessageId)) {
          skipped++;

          final existingRecord = recordBySavedReference[record.reference];
          final existingSourceId = sourceIdBySavedReference[record.reference];
          final identicalBody = existingRecord?.rawMessage == record.rawMessage;

          if (identicalBody && existingSourceId != newSourceId) {
            await ImportLogger.write(
              'DUPLICATE_SMS | '
              'reference=${record.reference} | '
              'existing_sms_id=${existingSourceId ?? 'unavailable'} | '
              'duplicate_sms_id=$newSourceId | '
              'reason=IDENTICAL_BODY | '
              'action=IGNORED',
            );
          } else {
            await ImportLogger.write(
              'REFERENCE_COLLISION | '
              'reference=${record.reference} | '
              'existing_subtype=${existingRecord?.subtype.name ?? 'unavailable'} | '
              'existing_amount=${existingRecord?.amount ?? 'unavailable'} | '
              'existing_sms_id=${existingSourceId ?? 'unavailable'} | '
              'new_subtype=${record.subtype.name} | '
              'new_amount=${record.amount} | '
              'new_sms_id=$newSourceId | '
              'existing_raw_message=${existingRecord?.rawMessage ?? 'unavailable'} | '
              'new_raw_message=${record.rawMessage} | '
              'action=REVIEW_REQUIRED',
            );
          }

          await ImportLogger.write(
            'RECORD_SKIPPED | '
            'sms_id=$newSourceId | '
            'reference=${record.reference} | '
            'subtype=${record.subtype.name} | '
            'reason=DUPLICATE_REFERENCE',
          );

          continue;
        }

        newRecords.add(record);
        recordBySavedReference[record.reference] = record;
        sourceIdBySavedReference[record.reference] = newSourceId;
      }

      onProgress?.call(
        ImportProgress(
          status: ImportStatus.saving,
          total: messagesToProcess.length,
          processed: end,
          imported: imported,
          skipped: skipped,
          failed: failed,
        ),
      );

      await financialRecordsRepository.saveAll(newRecords);

      for (final record in newRecords) {
        await ImportLogger.write(
          'RECORD_SAVED | '
          'sms_id=${sourceIdBySavedReference[record.reference] ?? 'unavailable'} | '
          'reference=${record.reference} | '
          'subtype=${record.subtype.name} | '
          'amount=${record.amount} | '
          'transactionDate=${record.transactionDate} | '
          'receivedAt=${record.receivedAt}',
        );
      }

      imported += newRecords.length;

      // Give Flutter an opportunity to render between import batches.
      await Future<void>.delayed(Duration.zero);
    }

    onProgress?.call(
      ImportProgress(
        status: ImportStatus.completed,
        total: messages.length,
        processed: messages.length,
        imported: imported,
        skipped: skipped,
        failed: failed,
      ),
    );

    await ImportLogger.write(
      'IMPORT_SUMMARY | '
      'messages=${messages.length} | '
      'imported=$imported | '
      'skipped=$skipped | '
      'failed=$failed | '
      'subtypes=$subtypeCounts | '
      'skippedBySubtype=$skippedMessages | '
      'failedBySubtype=$failedMessages',
    );

    await ImportLogger.write(
      'IMPORT_COMPLETE | '
      'imported=$imported | '
      'skipped=$skipped | '
      'failed=$failed',
    );

    debugPrint('SUBTYPE COUNTS: $subtypeCounts');
    debugPrint('SKIPPED: $skippedMessages');
    debugPrint('FAILED: $failedMessages');

    debugPrint(
      'IMPORT COMPLETE '
      '$imported imported, '
      '$skipped skipped, '
      '$failed failed',
    );

    return ImportResult(imported: imported, skipped: skipped, failed: failed);
  }

  Future<ImportResult> importFromSource(TransactionSource source) async {
    final messages = await source.load();

    return importMessages(messages);
  }
}

class ImportResult {
  final int imported;
  final int skipped;
  final int failed;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
  });
}
