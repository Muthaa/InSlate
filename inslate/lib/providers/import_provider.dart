import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../library/classifiers/mpesa_message_classifier.dart';
import '../models/import_progress.dart';
import '../services/permission_service.dart';
import '../services/transaction_import_service.dart';
import '../sources/sms_transaction_source.dart';
import 'repository_providers.dart';
import 'source_providers.dart';

final importProvider = NotifierProvider<ImportNotifier, ImportProgress>(
  ImportNotifier.new,
);

class ImportNotifier extends Notifier<ImportProgress> {
  late final TransactionImportService _importService;
  late final PermissionService _permissionService;
  late final SmsTransactionSource _smsSource;

  @override
  ImportProgress build() {
    final financialRecordsRepository = ref.watch(
      financialRecordsRepositoryProvider,
    );

    final rawMessagesRepository = ref.watch(rawMessagesRepositoryProvider);

    _permissionService = ref.watch(permissionServiceProvider);

    _smsSource = ref.watch(smsTransactionSourceProvider);

    _importService = TransactionImportService(
      classifier: MpesaMessageClassifier(),
      financialRecordsRepository: financialRecordsRepository,
      rawMessagesRepository: rawMessagesRepository,
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
}
