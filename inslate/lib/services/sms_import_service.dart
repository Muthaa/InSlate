import '../sources/transaction_source.dart';
import 'permission_service.dart';
import 'transaction_import_service.dart';

class SmsImportService {
  final PermissionService permissionService;
  final TransactionImportService transactionImportService;
  final TransactionSource source;

  SmsImportService({
    required this.permissionService,
    required this.transactionImportService,
    required this.source,
  });

  Future<ImportResult> importSms() async {
    final granted = await permissionService.requestSmsPermission();

    if (!granted) {
      return const ImportResult(imported: 0, skipped: 0, failed: 0);
    }

    return transactionImportService.importFromSource(source);
  }
}
