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
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/sources/transaction_source.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import '../fixtures/mshwari_loan_messages.dart';

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

  test(
    'imports production M-Shwari loan and queries Loans Activity without duplicates',
    () async {
      final message = domain.RawMessage(
        id: 'SMS-MSHWARI-LOAN',
        sender: 'MPESA',
        body: mshwariApprovedLoan,
        receivedAt: DateTime(2026, 10, 3, 0, 42),
      );
      expect((await importService.importMessages([message])).imported, 1);
      final record = (await repository.getAllByReference('UJ3NY8KRG4')).single;
      expect(record.subtype, RecordSubtype.loanDisbursement);
      expect(record.party!.name, 'M-Shwari');
      expect(record.amount, 3940);
      final loanActivity = await repository.getActivity(
        ActivityFilter(
          period: FinancialPeriod.month(DateTime(2026, 10)),
          scope: ActivityScope.loans,
        ),
      );
      expect(loanActivity.single.reference, 'UJ3NY8KRG4');
      expect((await importService.importMessages([message])).imported, 0);
      expect(await repository.getAllByReference('UJ3NY8KRG4'), hasLength(1));
    },
  );

  test(
    'stored but unparsed M-Shwari loan is duplicate without historical reimport',
    () async {
      final message = domain.RawMessage(
        id: 'SMS-SKIPPED-MSHWARI',
        sender: 'MPESA',
        body: mshwariApprovedLoan,
        receivedAt: DateTime(2026, 10, 3),
      );
      await rawMessagesRepository.save(message);
      final result = await importService.importMessages([message]);
      expect(result.skipped, 0);
      expect(result.duplicate, 1);
      expect(result.imported, 0);
      expect(await repository.getAllByReference('UJ3NY8KRG4'), isEmpty);
    },
  );

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
      expect(result.skipped, 0);
      expect(result.duplicate, 1);
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
    expect(duplicateResult.skipped, 0);
    expect(duplicateResult.duplicate, 1);
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
    expect(secondImport.skipped, 0);
    expect(secondImport.duplicate, 1);
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
  domain.RawMessage balanceSms(String id, String body) => domain.RawMessage(
    id: id,
    sender: 'MPESA',
    body: body,
    receivedAt: DateTime.utc(2026, 6, 28, 8, 47, 12, 456),
  );
  test(
    'repeated source encounters are each accounted once, including unknown SMS',
    () async {
      final sms = balanceSms('same-source', 'Your M-PESA balance is Ksh0.00.');
      final updates = <int>[];
      final service = TransactionImportService(
        classifier: MpesaMessageClassifier(),
        financialRecordsRepository: repository,
        rawMessagesRepository: rawMessagesRepository,
        onProgress: (p) {
          expect(p.total, 3);
          expect(p.imported + p.skipped + p.duplicate + p.failed, p.processed);
          updates.add(p.processed);
        },
      );
      final result = await service.importMessages([sms, sms, sms]);
      expect(
        [result.imported, result.skipped, result.duplicate, result.failed],
        [0, 1, 2, 0],
      );
      expect(result.total, 3);
      expect(result.audit.map((a) => a.index), [0, 1, 2]);
      expect(result.rawCreated, 1);
      expect(result.evidenceCreated, 1);
      expect(updates.last, 3);
      expect(await repository.getAll(), isEmpty);
    },
  );
  test(
    'conflicting content for a source ID fails without overwriting persisted content',
    () async {
      final sms = balanceSms('collision', 'Your M-PESA balance is Ksh1.00.');
      final other = balanceSms('collision', 'Your M-PESA balance is Ksh2.00.');
      final first = await importService.importMessages([sms, other]);
      expect([first.skipped, first.failed], [1, 1]);
      expect(first.reasons['SOURCE_ID_COLLISION'], 1);
      final repeat = await importService.importMessages([other]);
      expect(repeat.failed, 1);
      expect(
        (await rawMessagesRepository.getBySourceId('collision'))!.body,
        sms.body,
      );
      expect(
        (await database.select(database.balanceEvidence).get())
            .single
            .amountMinor,
        100,
      );
    },
  );
  test(
    'classification exceptions retain raw SMS and yield an auditable failure',
    () async {
      final service = TransactionImportService(
        classifier: _FailOnClassification(),
        financialRecordsRepository: repository,
        rawMessagesRepository: rawMessagesRepository,
      );
      final sms = balanceSms(
        'classification-error',
        'Your M-PESA balance is Ksh1.00.',
      );
      final result = await service.importMessages([sms]);
      expect(result.failed, 1);
      expect(result.reasons, {'PROCESSING_EXCEPTION': 1});
      expect(result.rawCreated, 1);
      expect(result.evidenceCreated, 1);
      expect(await repository.getAll(), isEmpty);
    },
  );
  test(
    'financial persistence failure rolls back raw and evidence and allows retry',
    () async {
      await database.customStatement(
        "CREATE TRIGGER reject_financial BEFORE INSERT ON financial_records BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final sms = balanceSms(
        'financial-retry',
        File('test/fixtures/send_money.txt').readAsStringSync(),
      );
      final failed = await importService.importMessages([sms]);
      expect(failed.reasons, {'PERSISTENCE_FAILED': 1});
      expect(failed.imported, 0);
      expect(failed.rawCreated, 0);
      expect(failed.evidenceCreated, 0);
      expect(await rawMessagesRepository.getAll(), isEmpty);
      expect(await database.select(database.balanceEvidence).get(), isEmpty);
      expect(await repository.getAll(), isEmpty);
      await database.customStatement('DROP TRIGGER reject_financial');
      final retry = await importService.importMessages([sms]);
      expect(retry.imported, 1);
      expect(retry.failed, 0);
      expect(retry.rawCreated, 1);
      expect(retry.evidenceCreated, 1);
    },
  );
  test(
    'overlapping import calls serialize without losing or duplicating movements',
    () async {
      final sms = balanceSms(
        'overlap',
        File('test/fixtures/send_money.txt').readAsStringSync(),
      );
      final results = await Future.wait([
        importService.importMessages([sms]),
        importService.importMessages([sms]),
      ]);
      expect(results.map((r) => r.imported), [1, 0]);
      expect(results.map((r) => r.duplicate), [0, 1]);
      expect(await repository.getAll(), hasLength(1));
      expect(await rawMessagesRepository.getAll(), hasLength(1));
    },
  );
  test(
    'deduplication and progress remain exact across bounded import batches',
    () async {
      final messages = List.generate(
        501,
        (i) => balanceSms('bounded-$i', 'Your M-PESA balance is Ksh$i.00.'),
      );
      final result = await importService.importMessages([
        ...messages,
        messages.first,
      ]);
      expect(
        [result.total, result.skipped, result.duplicate, result.failed],
        [502, 501, 1, 0],
      );
      expect(result.rawCreated, 501);
      expect(result.evidenceCreated, 501);
      final repeated = await importService.importMessages(messages);
      expect(repeated.duplicate, 501);
      expect(repeated.rawCreated, 0);
      expect(repeated.evidenceCreated, 0);
    },
  );
  test(
    'balance-only SMS persists traceable unassociated evidence without movement',
    () async {
      final instrument = await FinancialInstrumentsRepository(database).create(
        name: 'M-PESA',
        type: InstrumentType.mobileWallet,
        provider: 'M-PESA',
      );
      final sms = balanceSms('balance-only', 'Your M-PESA balance is Ksh0.00.');
      final result = await importService.importMessages([sms]);
      expect(result.imported, 0);
      expect(await repository.getAll(), isEmpty);
      final row =
          (await database.select(database.balanceEvidence).get()).single;
      final raw = (await database.rawMessagesDao.getAllMessages()).single;
      expect(raw.body, sms.body);
      expect(row.id, 'sms:mpesa-wallet:balance-only');
      expect(row.amountMinor, 0);
      expect(row.currency, 'KES');
      expect(row.kind, 'reported');
      expect(row.subjectFamily, 'mpesa');
      expect(row.origin, 'sms_reported');
      expect(row.rawMessageId, raw.id);
      expect(row.matchedClause, 'Your M-PESA balance is Ksh0.00');
      expect(row.extractionVersion, 'mpesa_wallet_v1');
      expect(row.timeBasis, 'raw_message_received_at_proxy');
      expect(row.asOfMillis, raw.receivedAt.millisecondsSinceEpoch);
      expect(row.createdMillis, greaterThan(0));
      expect(row.accountId, isNull);
      expect(row.associationOrigin, isNull);
      expect(row.associatedMillis, isNull);
      expect(row.financialRecordId, isNull);
      expect(
        await BalanceEvidenceRepository(database).latest(instrument.id),
        isNull,
      );
    },
  );
  test(
    'failed movement with valid wallet balance creates evidence only',
    () async {
      final result = await importService.importMessages([
        balanceSms(
          'failed-wallet',
          'Failed. You have insufficient funds in your M-Shwari account to withdraw Ksh500.00. Your M-Shwari account available balance is Ksh0.24. New M-PESA balance is Ksh0.51.',
        ),
      ]);
      expect(result.imported, 0);
      expect(await repository.getAll(), isEmpty);
      final evidence = await database.select(database.balanceEvidence).get();
      expect(evidence, hasLength(2));
      expect(
        evidence.singleWhere((e) => e.subjectFamily == 'mpesa').amountMinor,
        51,
      );
      expect(
        evidence
            .singleWhere((e) => e.subjectFamily == 'mshwariSavings')
            .amountMinor,
        24,
      );
    },
  );
  test(
    'duplicate source imports and repeated extraction are idempotent',
    () async {
      final sms = balanceSms('repeat', 'New M-PESA balance is Ksh2.29.');
      await importService.importMessages([sms, sms]);
      final before = (await database.select(database.balanceEvidence).get())
          .single
          .toJson();
      await importService.importMessages([sms]);
      final balances = BalanceEvidenceRepository(database);
      await Future.wait([
        balances.extractNewMpesaMessages(['repeat', 'repeat']),
        balances.extractNewMpesaMessages(['repeat']),
      ]);
      expect(
        (await database.select(database.balanceEvidence).get()).single.toJson(),
        before,
      );
      expect(await repository.getAll(), isEmpty);
    },
  );
  test(
    'existing body duplicate policy avoids broadcast/inbox evidence duplicates',
    () async {
      const body = 'New M-PESA balance is Ksh2.29.';
      await importService.importMessages([balanceSms('broadcast:one', body)]);
      await importService.importMessages([balanceSms('inbox-one', body)]);
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(1),
      );
      expect(await database.rawMessagesDao.getAllMessages(), hasLength(1));
    },
  );
  test('already stored messages are not backfilled', () async {
    final sms = balanceSms('old', 'New M-PESA balance is Ksh2.29.');
    await rawMessagesRepository.save(sms);
    await importService.importMessages([sms]);
    expect(await database.select(database.balanceEvidence).get(), isEmpty);
  });
  test(
    'ambiguous wallet evidence does not alter successful financial parsing',
    () async {
      final body = File('test/fixtures/send_money.txt').readAsStringSync();
      await importService.importMessages([
        balanceSms('ambiguous', '$body Your M-PESA balance is Ksh5.00.'),
      ]);
      expect(await database.select(database.balanceEvidence).get(), isEmpty);
      final record = (await repository.getAll()).single;
      expect(record.amount, 300);
      expect(record.balance, 3281.24);
    },
  );
  test(
    'evidence adds no records or semantic totals and leaves parser balance untouched',
    () async {
      final body = File('test/fixtures/send_money.txt').readAsStringSync();
      await importService.importMessages([balanceSms('movement', body)]);
      final before = (await database.financialRecordsDao.getAllRecords()).single
          .toJson();
      final totals = const FinancialSemantics().calculate(
        await repository.getAll(),
      );
      expect((await repository.getAll()).single.balance, 3281.24);
      await importService.importMessages([
        balanceSms('observation', 'Your M-PESA balance is Ksh999999.99.'),
      ]);
      expect(
        (await database.financialRecordsDao.getAllRecords()).single.toJson(),
        before,
      );
      final after = const FinancialSemantics().calculate(
        await repository.getAll(),
      );
      expect(
        [
          after.income,
          after.expenses,
          after.fees,
          after.internalTransfers,
          after.borrowed,
          after.repaid,
        ],
        [
          totals.income,
          totals.expenses,
          totals.fees,
          totals.internalTransfers,
          totals.borrowed,
          totals.repaid,
        ],
      );
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(2),
      );
    },
  );
  test(
    'raw save and evidence insertion roll back together and can retry',
    () async {
      await database.customStatement(
        "CREATE TRIGGER reject_evidence BEFORE INSERT ON balance_evidence BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final sms = balanceSms('retry', 'New M-PESA balance is Ksh1.00.');
      expect((await importService.importMessages([sms])).failed, 1);
      expect(await rawMessagesRepository.exists('retry'), isFalse);
      expect(await database.select(database.balanceEvidence).get(), isEmpty);
      await database.customStatement('DROP TRIGGER reject_evidence');
      await importService.importMessages([sms]);
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(1),
      );
    },
  );
  test(
    'bounded source batches persist more than 500 observations without history scan',
    () async {
      final messages = List.generate(
        501,
        (i) => balanceSms('batch-$i', 'New M-PESA balance is Ksh$i.00.'),
      );
      await rawMessagesRepository.saveAll(messages);
      final balances = BalanceEvidenceRepository(database);
      await balances.extractNewMpesaMessages(
        messages.map((m) => m.id).toList(),
      );
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(501),
      );
      await balances.extractNewMpesaMessages(['missing', messages.last.id]);
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(501),
      );
      expect(await repository.getAll(), isEmpty);
    },
  );
  final providerImports = {
    'mshwari_deposit': ('mshwari-savings', 200024, 2, 1),
    'mshwari_withdrawal': ('mshwari-savings', 24, 2, 1),
    'kcb_deposit': ('kcb-mpesa-savings', 200053, 2, 1),
    'kcb_withdrawal': ('kcb-mpesa-savings', 100053, 2, 1),
    'fuliza_loan': ('fuliza-debt', 88936, 1, 1),
    'failed_transaction': ('mshwari-savings', 50024, 1, 0),
  };
  for (final entry in providerImports.entries) {
    test(
      'provider import ${entry.key} preserves movement count and provenance',
      () async {
        final body = File('test/fixtures/${entry.key}.txt').readAsStringSync();
        final sms = balanceSms('products-${entry.key}', body);
        final result = await importService.importMessages([sms]);
        expect(result.imported, entry.value.$4);
        final beforeRecords =
            (await database.financialRecordsDao.getAllRecords())
                .map((r) => r.toJson())
                .toList();
        expect(beforeRecords, hasLength(entry.value.$4));
        final evidence = await database.select(database.balanceEvidence).get();
        expect(evidence, hasLength(entry.value.$3));
        final product = evidence.singleWhere(
          (e) => e.id == 'sms:${entry.value.$1}:${sms.id}',
        );
        expect(product.amountMinor, entry.value.$2);
        expect(product.origin, 'sms_reported');
        expect(product.extractionVersion, 'mpesa_products_v1');
        expect(product.currency, 'KES');
        expect(product.timeBasis, 'raw_message_received_at_proxy');
        final raw = (await database.rawMessagesDao.getAllMessages()).single;
        expect(raw.body, body);
        expect(product.rawMessageId, raw.id);
        expect(product.asOfMillis, raw.receivedAt.millisecondsSinceEpoch);
        expect(body, contains(product.matchedClause));
        for (final e in evidence) {
          expect(e.accountId, isNull);
          expect(e.associationOrigin, isNull);
          expect(e.associatedMillis, isNull);
          expect(e.financialRecordId, isNull);
        }
        final beforeEvidence = evidence.map((e) => e.toJson()).toList();
        await importService.importMessages([sms]);
        await BalanceEvidenceRepository(
          database,
        ).extractNewMpesaMessages([sms.id]);
        expect(
          (await database.select(database.balanceEvidence).get())
              .map((e) => e.toJson())
              .toList(),
          beforeEvidence,
        );
        expect(
          (await database.financialRecordsDao.getAllRecords())
              .map((r) => r.toJson())
              .toList(),
          beforeRecords,
        );
      },
    );
  }
  test(
    'M-Shwari zero debt and savings persist independently of repayment amount',
    () async {
      await importService.importMessages([
        balanceSms('repaid-product', mshwariRepaidLoan),
      ]);
      final entries = await database.select(database.balanceEvidence).get();
      expect(entries, hasLength(2));
      expect(
        entries
            .singleWhere((e) => e.id == 'sms:mshwari-loan:repaid-product')
            .amountMinor,
        0,
      );
      expect(
        entries.singleWhere((e) => e.subjectFamily == 'mshwariLoan').kind,
        'outstanding_debt',
      );
      expect(
        entries
            .singleWhere((e) => e.subjectFamily == 'mshwariSavings')
            .amountMinor,
        10734,
      );
      final movement = (await repository.getAll()).single;
      expect(movement.amount, 4300);
      expect(movement.balance, isNull);
      final before = (await database.financialRecordsDao.getAllRecords()).single
          .toJson();
      final totals = const FinancialSemantics().calculate(
        await repository.getAll(),
      );
      await importService.importMessages([
        balanceSms(
          'debt-only',
          'Total Fuliza M-PESA outstanding amount is Ksh0.00 due on 26/07/26.',
        ),
      ]);
      expect(
        (await database.financialRecordsDao.getAllRecords()).single.toJson(),
        before,
      );
      final after = const FinancialSemantics().calculate(
        await repository.getAll(),
      );
      expect(
        [
          after.income,
          after.expenses,
          after.fees,
          after.internalTransfers,
          after.borrowed,
          after.repaid,
        ],
        [
          totals.income,
          totals.expenses,
          totals.fees,
          totals.internalTransfers,
          totals.borrowed,
          totals.repaid,
        ],
      );
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(3),
      );
    },
  );
  test('provider balance-only SMS do not manufacture movements', () async {
    await importService.importMessages([
      balanceSms(
        'savings-only',
        'New M-Shwari saving account balance is Ksh0.00. KCB M-PESA Account balance is Ksh100.25.',
      ),
    ]);
    expect(await repository.getAll(), isEmpty);
    expect(await database.select(database.balanceEvidence).get(), hasLength(2));
  });
  test(
    'provider insertion failure rolls back raw message and wallet evidence together',
    () async {
      await database.customStatement(
        "CREATE TRIGGER reject_product BEFORE INSERT ON balance_evidence WHEN NEW.subject_family = 'kcbMpesa' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final sms = balanceSms(
        'atomic-products',
        File('test/fixtures/kcb_deposit.txt').readAsStringSync(),
      );
      expect((await importService.importMessages([sms])).failed, 1);
      expect(await rawMessagesRepository.exists(sms.id), isFalse);
      expect(await database.select(database.balanceEvidence).get(), isEmpty);
      expect(await repository.getAll(), isEmpty);
      await database.customStatement('DROP TRIGGER reject_product');
      await importService.importMessages([sms]);
      expect(
        await database.select(database.balanceEvidence).get(),
        hasLength(2),
      );
      expect(await repository.getAll(), hasLength(1));
    },
  );
}
