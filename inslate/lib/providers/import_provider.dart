import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../library/classifiers/mpesa_message_classifier.dart';
import '../models/import_progress.dart';
import '../services/permission_service.dart';
import '../services/transaction_import_service.dart';
import '../sources/sms_transaction_source.dart';
import 'repository_providers.dart';
import 'source_providers.dart';
import 'financial_records_provider.dart';
import '../repositories/raw_messages_repository.dart';

final importProvider = NotifierProvider<ImportNotifier, ImportProgress>(
  ImportNotifier.new,
);

class ImportNotifier extends Notifier<ImportProgress> {
  late final TransactionImportService _importService;
  late final PermissionService _permissionService;
  late final SmsTransactionSource _smsSource;
  late final RawMessagesRepository _rawMessagesRepository;

  @override
  ImportProgress build() {
    final financialRecordsRepository = ref.watch(
      financialRecordsRepositoryProvider,
    );

    _rawMessagesRepository = ref.watch(rawMessagesRepositoryProvider);

    _permissionService = ref.watch(permissionServiceProvider);

    _smsSource = ref.watch(smsTransactionSourceProvider);

    _importService = TransactionImportService(
      classifier: MpesaMessageClassifier(),
      financialRecordsRepository: financialRecordsRepository,
      rawMessagesRepository: _rawMessagesRepository,
      onProgress: (progress) {
        state = progress;
      },
    );

    return const ImportProgress(status: ImportStatus.idle);
  }

  Future<void> importMessages() async {
    state = const ImportProgress(status: ImportStatus.requestingPermission);

    try {
      final granted = await _permissionService.requestSmsPermission();

      if (!granted) {
        state = const ImportProgress(
          status: ImportStatus.failed,
          error: 'SMS permission denied',
        );
        return;
      }

      state = const ImportProgress(status: ImportStatus.loadingMessages);

      final result = await _importService.importFromSource(_smsSource);

      state = ImportProgress(
        status: ImportStatus.completed,
        total: result.imported + result.skipped + result.failed,
        processed: result.imported + result.skipped + result.failed,
        imported: result.imported,
        skipped: result.skipped,
        failed: result.failed,
      );
    } catch (e) {
      state = ImportProgress(status: ImportStatus.failed, error: e.toString());
    }
  }

  Future<void> catchUpNewMessages() async {
    try {
      final latestMessage = await _rawMessagesRepository.getLatest();

      if (latestMessage == null) {
        debugPrint('SMS CATCH-UP SKIPPED: no existing raw messages');
        return;
      }

      // Small overlap protects against messages sharing the same timestamp.
      // Existing duplicate detection will safely ignore already imported SMS.
      final since = latestMessage.receivedAt.subtract(
        const Duration(minutes: 1),
      );

      final messages = await _smsSource.loadSince(since);

      if (messages.isEmpty) {
        debugPrint('SMS CATCH-UP: no new M-PESA messages');

        // A background SMS isolate may have written directly to the database
        // while the foreground Riverpod state was inactive.
        ref.invalidate(financialRecordsProvider);

        return;
      }

      final result = await _importService.importMessages(messages);

      debugPrint(
        'SMS CATCH-UP COMPLETE: '
        '${result.imported} imported, '
        '${result.skipped} skipped, '
        '${result.failed} failed',
      );

      // Always reload financial records after catch-up.
      //
      // Background SMS processing may already have persisted these messages,
      // causing catch-up to report them as skipped rather than imported.
      ref.invalidate(financialRecordsProvider);
    } catch (e) {
      debugPrint('SMS CATCH-UP ERROR: $e');
    }
  }

  void startIncomingSmsListener() {
    _smsSource.listenForIncomingMessages(
      onMessage: (message) async {
        try {
          final result = await _importService.importMessages([message]);

          if (result.imported > 0) {
            ref.invalidate(financialRecordsProvider);
          }
        } catch (e) {
          if (kDebugMode) {
            print('INCOMING SMS IMPORT ERROR: $e');
          }
        }
      },
    );
  }
}
