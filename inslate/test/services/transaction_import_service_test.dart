import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/services/transaction_import_service.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/sources/transaction_source.dart';

class FakeTransactionSource implements TransactionSource {
  final List<domain.RawMessage> messages;

  FakeTransactionSource(this.messages);

  @override
  Future<List<domain.RawMessage>> load() async {
    return messages;
  }
}

void main() {
  late AppDatabase database;
  late FinancialRecordsRepository repository;
  late RawMessagesRepository rawMessagesRepository;
  late TransactionImportService importService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = FinancialRecordsRepository(database);

    rawMessagesRepository = RawMessagesRepository(database);

    importService = TransactionImportService(
      classifier: MpesaMessageClassifier(),
      financialRecordsRepository: repository,
      rawMessagesRepository: rawMessagesRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('imports a real M-PESA send money message into SQLite', () async {
    final message = domain.RawMessage(
      id: 'SMS-001',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI '
          '0707855891 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final result = await importService.importMessages([message]);

    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(result.failed, 0);

    final record = await repository.getByReference('UFSNY9B1NP');

    expect(record != null, true);

    expect(record!.reference, 'UFSNY9B1NP');
    expect(record.amount, 300.0);
    expect(record.balance, 3281.24);
    expect(record.transactionCost, 7.0);
    expect(record.title, 'Send Money');
    expect(record.rawMessage, message.body);

    expect(record.party != null, true);
    expect(record.party!.name, 'VIVIAN  KARANI');
    expect(record.party!.phone, '0707855891');
  });

  test('does not import the same M-PESA message twice', () async {
    final message = domain.RawMessage(
      id: 'SMS-DUPLICATE-001',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI '
          '0707855891 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final firstImport = await importService.importMessages([message]);

    expect(firstImport.imported, 1);
    expect(firstImport.skipped, 0);
    expect(firstImport.failed, 0);

    final secondImport = await importService.importMessages([message]);

    expect(secondImport.imported, 0);
    expect(secondImport.skipped, 1);
    expect(secondImport.failed, 0);

    final records = await repository.getAll();
    final rawMessages = await rawMessagesRepository.getAll();

    expect(records.length, 1);
    expect(rawMessages.length, 1);

    expect(records.first.reference, 'UFSNY9B1NP');
    expect(rawMessages.first.id, 'SMS-DUPLICATE-001');
  });

  test('continues importing when one message fails', () async {
    final validMessage = domain.RawMessage(
      id: 'SMS-BATCH-VALID',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI '
          '0707855891 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final invalidMessage = domain.RawMessage(
      id: 'SMS-BATCH-INVALID',
      sender: 'MPESA',
      body: 'This is a malformed M-PESA message',
      receivedAt: DateTime(2026, 6, 28, 11, 48),
    );

    final result = await importService.importMessages([
      invalidMessage,
      validMessage,
    ]);

    expect(result.imported, 1);
    expect(result.skipped, 1);
    expect(result.failed, 0);

    final records = await repository.getAll();
    final rawMessages = await rawMessagesRepository.getAll();

    expect(records.length, 1);
    expect(rawMessages.length, 2);
  });

  test(
    'continues importing when a recognised transaction fails to parse',
    () async {
      final invalidMessage = domain.RawMessage(
        id: 'SMS-BATCH-PARSE-FAIL',
        sender: 'MPESA',
        body:
            'ABC123XYZ Confirmed. Ksh300.00 sent to on 28/6/26 at 11:47 AM. '
            'New M-PESA balance is Ksh3,281.24. Transaction cost, Ksh7.00.',
        receivedAt: DateTime(2026, 6, 28, 11, 47),
      );

      final validMessage = domain.RawMessage(
        id: 'SMS-BATCH-AFTER-FAIL',
        sender: 'MPESA',
        body:
            'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI '
            '0707855891 on 28/6/26 at 11:47 AM. New M-PESA balance is '
            'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
            'transact within the day is 487,380.00. Download My OneApp on',
        receivedAt: DateTime(2026, 6, 28, 11, 48),
      );

      final result = await importService.importMessages([
        invalidMessage,
        validMessage,
      ]);

      expect(result.imported, 1);
      expect(result.skipped, 0);
      expect(result.failed, 1);

      final records = await repository.getAll();
      final rawMessages = await rawMessagesRepository.getAll();

      expect(records.length, 1);
      expect(rawMessages.length, 2);

      expect(records.first.reference, 'UFSNY9B1NP');
    },
  );

  test('imports transactions from a TransactionSource', () async {
    final message = domain.RawMessage(
      id: 'source-test-1',
      sender: 'MPESA',
      body: '''
UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI 0707855891 on 28/6/26 at 11:47 AM. New M-PESA balance is Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can transact within the day is 487,380.00. Download My OneApp on
''',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final source = FakeTransactionSource([message]);

    final result = await importService.importFromSource(source);

    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(result.failed, 0);

    final record = await repository.getByReference('UFSNY9B1NP');

    expect(record, isNotNull);
    expect(record!.amount, 300);
  });
}
