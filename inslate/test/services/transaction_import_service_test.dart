import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/library/classifiers/message_classifier.dart';
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

class _FailOnClassification implements MessageClassifier {
  @override
  ClassificationResult classify(String message) {
    throw StateError('Already-imported source ID was classified');
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory logDirectory;

  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp(
      'inslate_import_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return logDirectory.path;
        }
        throw MissingPluginException(
          'Unexpected path provider method: ${call.method}',
        );
      },
    );
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await logDirectory.delete(recursive: true);
  });

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
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
          '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final result = await importService.importMessages([message]);

    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(result.failed, 0);

    final records = await repository.getAllByReference('UFSNY9B1NP');
    final record = records.single;

    expect(record.reference, 'UFSNY9B1NP');
    expect(record.amount, 300.0);
    expect(record.balance, 3281.24);
    expect(record.transactionCost, 7.0);
    expect(record.title, 'Send Money');
    expect(record.rawMessage, message.body);
    expect(record.sourceMessageId, message.id);

    expect(record.party != null, true);
    expect(record.party!.name, 'TEST USER');
    expect(record.party!.phone, '0700000000');
  });

  test(
    'imports different subtypes with the same reference from distinct SMS IDs',
    () async {
      const reference = 'UFSNY9B1NP';
      final sendMoneyMessage = domain.RawMessage(
        id: 'SMS-SHARED-REFERENCE-SEND',
        sender: 'MPESA',
        body:
            '$reference Confirmed. Ksh300.00 sent to TEST USER '
            '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
            'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
            'transact within the day is 487,380.00. Download My OneApp on',
        receivedAt: DateTime(2026, 6, 28, 11, 47),
      );
      final fulizaMessage = domain.RawMessage(
        id: 'SMS-SHARED-REFERENCE-FULIZA',
        sender: 'MPESA',
        body:
            '$reference Confirmed. Fuliza M-PESA amount is Ksh 207.00. '
            'Access Fee charged Ksh 2.07. Total Fuliza M-PESA outstanding '
            'amount is Ksh2817.61 due on 24/08/26. To check daily charges, '
            'Dial *334#OK Select Query Charges',
        receivedAt: DateTime(2026, 6, 28, 11, 48),
      );

      final result = await importService.importMessages([
        sendMoneyMessage,
        fulizaMessage,
      ]);

      expect(result.imported, 2);
      expect(result.skipped, 0);
      expect(result.failed, 0);

      final records = await repository.getAllByReference(reference);
      expect(records, hasLength(2));

      final sendMoneyRecord = records.singleWhere(
        (record) => record.subtype.name == 'sendMoney',
      );
      final fulizaRecord = records.singleWhere(
        (record) => record.subtype.name == 'fulizaLoan',
      );

      expect(sendMoneyRecord.sourceMessageId, sendMoneyMessage.id);
      expect(sendMoneyRecord.subtype.name, 'sendMoney');
      expect(fulizaRecord.sourceMessageId, fulizaMessage.id);
      expect(fulizaRecord.subtype.name, 'fulizaLoan');
    },
  );

  test(
    'skips same-sender identical bodies with different source IDs',
    () async {
      const body =
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
          '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on';
      final firstMessage = domain.RawMessage(
        id: 'SMS-EXACT-FIRST',
        sender: 'MPESA',
        body: body,
        receivedAt: DateTime(2026, 6, 28, 11, 47),
      );
      final duplicateMessage = domain.RawMessage(
        id: 'SMS-EXACT-DUPLICATE',
        sender: 'MPESA',
        body: body,
        receivedAt: DateTime(2026, 6, 28, 11, 48),
      );

      final result = await importService.importMessages([
        firstMessage,
        duplicateMessage,
      ]);

      expect(result.imported, 1);
      expect(result.skipped, 1);
      expect(result.failed, 0);
      expect(
        (await repository.getAll()).single.sourceMessageId,
        firstMessage.id,
      );
      expect((await rawMessagesRepository.getAll()).single.id, firstMessage.id);
    },
  );

  test('imports same-sender messages with different bodies', () async {
    final firstMessage = domain.RawMessage(
      id: 'SMS-DIFFERENT-BODY-FIRST',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
          '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );
    final secondMessage = domain.RawMessage(
      id: 'SMS-DIFFERENT-BODY-SECOND',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh200.00 sent to TEST USER '
          '0700000001 on 28/6/26 at 11:49 AM. New M-PESA balance is '
          'Ksh3,074.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,180.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 49),
    );

    final result = await importService.importMessages([
      firstMessage,
      secondMessage,
    ]);

    expect(result.imported, 2);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    expect(await rawMessagesRepository.getAll(), hasLength(2));
    expect(await repository.getAllByReference('UFSNY9B1NP'), hasLength(2));
  });

  test('imports identical bodies from different senders', () async {
    const body =
        'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
        '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
        'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
        'transact within the day is 487,380.00. Download My OneApp on';
    final firstMessage = domain.RawMessage(
      id: 'SMS-DIFFERENT-SENDER-FIRST',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );
    final secondMessage = domain.RawMessage(
      id: 'SMS-DIFFERENT-SENDER-SECOND',
      sender: 'OTHER',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 11, 48),
    );

    final result = await importService.importMessages([
      firstMessage,
      secondMessage,
    ]);

    expect(result.imported, 2);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    expect(await rawMessagesRepository.getAll(), hasLength(2));
    expect(await repository.getAllByReference('UFSNY9B1NP'), hasLength(2));
  });

  test('skips exact SMS already stored with a different source ID', () async {
    const body =
        'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
        '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
        'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
        'transact within the day is 487,380.00. Download My OneApp on';
    final storedMessage = domain.RawMessage(
      id: 'SMS-STORED-EXACT',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );
    final repeatedMessage = domain.RawMessage(
      id: 'SMS-NEW-EXACT',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 11, 48),
    );

    final initialResult = await importService.importMessages([storedMessage]);
    final duplicateResult = await importService.importMessages([
      repeatedMessage,
    ]);

    expect(initialResult.imported, 1);
    expect(duplicateResult.imported, 0);
    expect(duplicateResult.skipped, 1);
    expect(duplicateResult.failed, 0);
    expect(await rawMessagesRepository.getAll(), hasLength(1));
    expect(await repository.getAll(), hasLength(1));
  });

  test('does not import the same M-PESA message twice', () async {
    final message = domain.RawMessage(
      id: 'SMS-DUPLICATE-001',
      sender: 'MPESA',
      body:
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
          '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
          'Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can '
          'transact within the day is 487,380.00. Download My OneApp on',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final firstImport = await importService.importMessages([message]);

    expect(firstImport.imported, 1);
    expect(firstImport.skipped, 0);
    expect(firstImport.failed, 0);

    final reimportService = TransactionImportService(
      classifier: _FailOnClassification(),
      financialRecordsRepository: repository,
      rawMessagesRepository: rawMessagesRepository,
    );
    final secondImport = await reimportService.importMessages([message]);

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
          'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
          '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
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
            'UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER '
            '0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is '
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

  test(
    'skips a failed KCB M-PESA withdrawal without creating a financial record',
    () async {
      final message = domain.RawMessage(
        id: 'SMS-FAILED-KCB',
        sender: 'MPESA',
        body:
            'Failed. The withdrawal from your KCB M-PESA Account cannot be '
            'completed at this time. Please contact M-PESA Customer Care.',
        receivedAt: DateTime(2026, 6, 28, 15, 0),
      );

      final result = await importService.importMessages([message]);

      expect(result.imported, 0);
      expect(result.skipped, 1);
      expect(result.failed, 0);

      final records = await repository.getAll();
      final rawMessages = await rawMessagesRepository.getAll();

      expect(records, isEmpty);
      expect(rawMessages, hasLength(1));
      expect(rawMessages.single.id, message.id);
      expect(rawMessages.single.body, message.body);
    },
  );
  test(
    'skips a failed M-Shwari withdrawal without creating a financial record',
    () async {
      final message = domain.RawMessage(
        id: 'SMS-FAILED-MSHWARI',
        sender: 'MPESA',
        body:
            'Failed. You have insufficient funds in your M-Shwari account '
            'to withdraw Ksh500.00. Your M-Shwari account available balance '
            'is Ksh0.51.',
        receivedAt: DateTime(2026, 6, 28, 11, 47),
      );

      final result = await importService.importMessages([message]);

      expect(result.imported, 0);
      expect(result.skipped, 1);
      expect(result.failed, 0);

      final records = await repository.getAll();
      final rawMessages = await rawMessagesRepository.getAll();

      expect(records, isEmpty);
      expect(rawMessages, hasLength(1));
      expect(rawMessages.single.id, message.id);
      expect(rawMessages.single.body, message.body);
    },
  );

  test('imports transactions from a TransactionSource', () async {
    final message = domain.RawMessage(
      id: 'source-test-1',
      sender: 'MPESA',
      body: '''
UFSNY9B1NP Confirmed. Ksh300.00 sent to TEST USER 0700000000 on 28/6/26 at 11:47 AM. New M-PESA balance is Ksh3,281.24. Transaction cost, Ksh7.00. Amount you can transact within the day is 487,380.00. Download My OneApp on
''',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    final source = FakeTransactionSource([message]);

    final result = await importService.importFromSource(source);

    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(result.failed, 0);

    final records = await repository.getAllByReference('UFSNY9B1NP');
    final record = records.single;

    expect(record.amount, 300);
  });
}
