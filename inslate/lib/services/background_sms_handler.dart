import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';
import 'sms_source_id.dart';
import '../database/app_database.dart';
import '../library/classifiers/mpesa_message_classifier.dart';
import '../models/raw_message.dart' as domain;
import '../repositories/financial_records_repository.dart';
import '../repositories/raw_messages_repository.dart';
import 'transaction_import_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage sms) async {
  WidgetsFlutterBinding.ensureInitialized();

  final sender = sms.address?.trim().toUpperCase();

  if (sender != 'MPESA') {
    return;
  }

  final body = sms.body;

  if (body == null || body.isEmpty) {
    return;
  }

  final database = AppDatabase();

  try {
    final rawMessagesRepository = RawMessagesRepository(database);

    final financialRecordsRepository = FinancialRecordsRepository(database);

    final importService = TransactionImportService(
      classifier: MpesaMessageClassifier(),
      financialRecordsRepository: financialRecordsRepository,
      rawMessagesRepository: rawMessagesRepository,
    );

    final senderAddress = sms.address ?? '';
    final receivedAtMilliseconds =
        sms.date ?? DateTime.now().millisecondsSinceEpoch;

    final message = domain.RawMessage(
      id: smsSourceId(
        smsId: sms.id,
        sender: senderAddress,
        body: body,
        receivedAtMilliseconds: receivedAtMilliseconds,
      ),
      sender: senderAddress,
      body: body,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMilliseconds),
    );

    final result = await importService.importMessages([message]);

    debugPrint(
      'BACKGROUND SMS IMPORT: '
      '${result.imported} imported, '
      '${result.skipped} skipped, '
      '${result.failed} failed',
    );
  } catch (e) {
    debugPrint('BACKGROUND SMS IMPORT ERROR: $e');
  } finally {
    await database.close();
  }
}
