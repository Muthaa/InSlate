import 'package:drift/drift.dart' show Variable;
import '../core/enums/transaction_status.dart';
import '../library/classifiers/message_classifier.dart';
import '../models/financial_records.dart';
import '../models/import_progress.dart';
import '../models/raw_message.dart';
import '../parsers/parser_factory.dart';
import '../repositories/balance_evidence_repository.dart';
import '../repositories/financial_records_repository.dart';
import '../repositories/raw_messages_repository.dart';
import '../sources/transaction_source.dart';
import 'import_logger.dart';
import 'paybill_reversal_parser.dart';
import '../repositories/paybill_reversals_repository.dart';

enum SmsImportOutcome { imported, skipped, duplicate, failed }

/// One outcome per source encounter, including repeated IDs in a batch.
class SmsImportAudit {
  final int index;
  final String sourceId;
  final SmsImportOutcome outcome;
  final String reason;
  const SmsImportAudit(this.index, this.sourceId, this.outcome, this.reason);
}

class TransactionImportService {
  final MessageClassifier classifier;
  final FinancialRecordsRepository financialRecordsRepository;
  final RawMessagesRepository rawMessagesRepository;
  final void Function(ImportProgress progress)? onProgress;
  Future<void> _pending = Future.value();

  TransactionImportService({
    required this.classifier,
    required this.financialRecordsRepository,
    required this.rawMessagesRepository,
    this.onProgress,
  });

  // Serialize overlapping manual, catch-up and incoming foreground calls.
  Future<ImportResult> importMessages(List<RawMessage> messages) {
    final snapshot = List<RawMessage>.unmodifiable(messages);
    final result = _pending.then((_) => _importMessages(snapshot));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<ImportResult> _importMessages(List<RawMessage> messages) async {
    final audit = <SmsImportAudit>[];
    var rawCreated = 0;
    var evidenceCreated = 0;
    final database = rawMessagesRepository.database;
    if (!identical(database, financialRecordsRepository.database)) {
      throw ArgumentError('Import repositories must share a database.');
    }
    ImportResult summary() => ImportResult.fromAudit(
      audit,
      rawCreated: rawCreated,
      evidenceCreated: evidenceCreated,
    );
    void progress(ImportStatus status) {
      final r = summary();
      onProgress?.call(
        ImportProgress(
          status: status,
          total: messages.length,
          processed: audit.length,
          imported: r.imported,
          skipped: r.skipped,
          duplicate: r.duplicate,
          failed: r.failed,
          rawCreated: rawCreated,
          evidenceCreated: evidenceCreated,
          reasons: r.reasons,
        ),
      );
    }

    await ImportLogger.write('IMPORT_START | messages=${messages.length}');
    progress(ImportStatus.loadingMessages);
    const batchSize = 500;
    for (var start = 0; start < messages.length; start += batchSize) {
      final batch = messages.skip(start).take(batchSize).toList();
      final batchAudit = <SmsImportAudit>[];
      var batchEvidence = 0;
      var batchRaw = 0;
      progress(ImportStatus.processing);
      try {
        // A failed movement save must not leave a raw identity that makes a
        // retry appear processed. Raw, evidence and movement writes roll back.
        await database.transaction(() async {
          final ids = batch.map((m) => m.id).toSet().toList();
          final stored = await (database.select(
            database.rawMessages,
          )..where((m) => m.sourceId.isIn(ids))).get();
          final storedById = {for (final m in stored) m.sourceId: m};
          final financialIds =
              (await financialRecordsRepository.getExistingSourceMessageIds(
                ids,
              )).toSet();
          final existingBodies = await rawMessagesRepository
              .getExistingBySenderAndBodies(batch);
          final bodies = <String, Set<String>>{};
          for (final m in existingBodies) {
            bodies.putIfAbsent(m.sender, () => {}).add(m.body);
          }
          final seen = <String, RawMessage>{};
          final toSave = <RawMessage>[];
          final records = <FinancialRecord>[];
          final reversalIndexes = <String, int>{};
          for (var i = 0; i < batch.length; i++) {
            final message = batch[i];
            void outcome(SmsImportOutcome kind, String reason) => batchAudit
                .add(SmsImportAudit(start + i, message.id, kind, reason));
            final existing = storedById[message.id];
            final incoming = seen[message.id];
            if (existing != null || incoming != null) {
              final same = existing != null
                  ? existing.sender == message.sender &&
                        existing.body == message.body
                  : incoming!.sender == message.sender &&
                        incoming.body == message.body;
              outcome(
                same ? SmsImportOutcome.duplicate : SmsImportOutcome.failed,
                same ? 'EXISTING_SOURCE_ID' : 'SOURCE_ID_COLLISION',
              );
              continue;
            }
            seen[message.id] = message;
            if (bodies[message.sender]?.contains(message.body) ?? false) {
              outcome(SmsImportOutcome.duplicate, 'IDENTICAL_BODY');
              continue;
            }
            bodies.putIfAbsent(message.sender, () => {}).add(message.body);
            toSave.add(message);
            if (financialIds.contains(message.id)) {
              outcome(
                SmsImportOutcome.duplicate,
                'EXISTING_FINANCIAL_SOURCE_ID',
              );
              continue;
            }
            try {
              if (PayBillReversalParser().parse(message) != null) {
                reversalIndexes[message.id] = start + i;
                continue;
              }
              final classification = classifier.classify(message.body);
              if (classification.status == TransactionStatus.failed) {
                outcome(SmsImportOutcome.skipped, 'TRANSACTION_FAILED');
              } else if (classification.subtype.name == 'unknown') {
                outcome(SmsImportOutcome.skipped, 'UNKNOWN_CLASSIFICATION');
              } else {
                final parser = ParserFactory.getParser(classification.subtype);
                if (parser == null) {
                  outcome(SmsImportOutcome.skipped, 'NO_PARSER');
                } else {
                  final parsed = parser.parse(message, classification);
                  if (!parsed.success || parsed.record == null) {
                    outcome(SmsImportOutcome.failed, 'PARSE_FAILED');
                  } else {
                    records.add(parsed.record!);
                    outcome(SmsImportOutcome.imported, 'MOVEMENT_PERSISTED');
                  }
                }
              }
            } catch (_) {
              outcome(SmsImportOutcome.failed, 'PROCESSING_EXCEPTION');
            }
          }
          await rawMessagesRepository.saveAll(toSave);
          final rawIds =
              (await (database.select(
                        database.rawMessages,
                      )..where((m) => m.sourceId.isIn(toSave.map((m) => m.id))))
                      .get())
                  .map((m) => m.id)
                  .toList();
          Future<int> evidenceCount() async =>
              (await database
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM balance_evidence WHERE raw_message_id IN (${List.filled(rawIds.length, '?').join(',')})',
                        variables: rawIds.map(Variable.withInt).toList(),
                      )
                      .getSingle())
                  .read<int>('n');
          if (rawIds.isNotEmpty) {
            final before = await evidenceCount();
            await BalanceEvidenceRepository(
              database,
            ).extractNewMpesaMessages(toSave.map((m) => m.id).toList());
            batchEvidence = await evidenceCount() - before;
          }
          await financialRecordsRepository.saveAll(records);
          final reversals = await PayBillReversalsRepository(
            database,
          ).process(reversalIndexes.keys.toList());
          for (final reversal in reversals) {
            batchAudit.add(
              SmsImportAudit(
                reversalIndexes[reversal.sourceId]!,
                reversal.sourceId,
                reversal.imported
                    ? SmsImportOutcome.imported
                    : reversal.duplicate
                    ? SmsImportOutcome.duplicate
                    : SmsImportOutcome.skipped,
                reversal.outcome,
              ),
            );
            batchEvidence += reversal.evidenceCreated;
          }
          batchAudit.sort((a, b) => a.index.compareTo(b.index));
          batchRaw = toSave.length;
        });
      } catch (_) {
        // Report no rolled-back writes as imported. A safe rerun can retry.
        batchAudit.clear();
        for (var i = 0; i < batch.length; i++) {
          batchAudit.add(
            SmsImportAudit(
              start + i,
              batch[i].id,
              SmsImportOutcome.failed,
              'PERSISTENCE_FAILED',
            ),
          );
        }
        batchRaw = 0;
        batchEvidence = 0;
      }
      audit.addAll(batchAudit);
      rawCreated += batchRaw;
      evidenceCreated += batchEvidence;
      // Traceable source identity; no SMS bodies, parties or amounts in logs.
      await ImportLogger.writeAll([
        for (final entry in batchAudit)
          'SMS_OUTCOME | index=${entry.index} | sms_id=${entry.sourceId} | outcome=${entry.outcome.name} | reason=${entry.reason}',
      ]);
      progress(ImportStatus.saving);
      await Future<void>.delayed(Duration.zero);
    }
    final result = summary();
    await ImportLogger.write(
      'IMPORT_COMPLETE | encountered=${messages.length} | imported=${result.imported} | skipped=${result.skipped} | duplicate=${result.duplicate} | failed=${result.failed} | raw_created=$rawCreated | evidence_created=$evidenceCreated',
    );
    progress(ImportStatus.completed);
    return result;
  }

  Future<ImportResult> importFromSource(TransactionSource source) async =>
      importMessages(await source.load());
}

class ImportResult {
  final int imported;
  final int skipped;
  final int duplicate;
  final int failed;
  final int rawCreated;
  final int evidenceCreated;
  final List<SmsImportAudit> audit;
  const ImportResult({
    required this.imported,
    required this.skipped,
    this.duplicate = 0,
    required this.failed,
    this.rawCreated = 0,
    this.evidenceCreated = 0,
    this.audit = const [],
  });
  factory ImportResult.fromAudit(
    List<SmsImportAudit> audit, {
    required int rawCreated,
    required int evidenceCreated,
  }) {
    int count(SmsImportOutcome kind) =>
        audit.where((a) => a.outcome == kind).length;
    return ImportResult(
      imported: count(SmsImportOutcome.imported),
      skipped: count(SmsImportOutcome.skipped),
      duplicate: count(SmsImportOutcome.duplicate),
      failed: count(SmsImportOutcome.failed),
      rawCreated: rawCreated,
      evidenceCreated: evidenceCreated,
      audit: List.unmodifiable(audit),
    );
  }
  int get total => imported + skipped + duplicate + failed;
  Map<String, int> get reasons {
    final counts = <String, int>{};
    for (final entry in audit) {
      counts.update(entry.reason, (n) => n + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }
}
