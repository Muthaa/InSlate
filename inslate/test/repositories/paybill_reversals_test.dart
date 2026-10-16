import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/repositories/paybill_reversals_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/services/financial_breakdown_service.dart';
import 'package:inslate/services/paybill_reversal_parser.dart';
import 'package:inslate/services/transaction_import_service.dart';
import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';

// Synthetic, redacted fixture using the complete verified five-message wording.
domain.RawMessage confirmation({
  String id = 'reverse',
  String ref = 'REVERSAL01',
  String original = 'ORIGINAL01',
  String amount = '1,000.25',
  String date = '12/9/26',
  String time = '10:34 AM',
  DateTime? receipt,
}) => domain.RawMessage(
  id: id,
  sender: ' MPESA ',
  receivedAt: receipt ?? DateTime(2026, 10, 2),
  body:
      '$ref confirmed. Reversal of transaction $original has been successfully reversed  on $date  at $time and Ksh$amount is credited to your M-PESA account. New M-PESA account balance is Ksh0.00',
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory logs;
  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('inslate_reversal_test_logs_');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => logs.path,
    );
  });
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await logs.delete(recursive: true);
  });
  late AppDatabase db;
  late PayBillReversalsRepository reversals;
  late FinancialRecordsRepository records;
  late CategoriesRepository categories;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    reversals = PayBillReversalsRepository(db);
    records = FinancialRecordsRepository(db);
    categories = CategoriesRepository(db);
  });
  tearDown(() => db.close());
  Future<int> original({
    String reference = 'ORIGINAL01',
    double amount = 1000.25,
    String subtype = 'payBill',
    String status = 'successful',
    DateTime? date,
    double fee = 23,
  }) => db
      .into(db.financialRecords)
      .insert(
        FinancialRecordsCompanion.insert(
          reference: reference,
          transactionDate: Value(date ?? DateTime(2026, 9, 10, 9)),
          receivedAt: DateTime(2026, 9, 10, 9),
          amount: amount,
          type: 'expense',
          subtype: subtype,
          status: status,
          title: 'PayBill',
          rawMessage: 'original',
          transactionCost: Value(fee),
        ),
      );
  Future<ReversalResult> process(domain.RawMessage sms) async {
    await RawMessagesRepository(db).saveAll([sms]);
    return (await reversals.process([sms.id])).single;
  }

  for (final clock in [
    '1:05 AM',
    '12:00 AM',
    '10:34 AM',
    '12:01 PM',
    '8:12 PM',
  ]) {
    test('verified wording and minute precision: $clock', () {
      final parsed = PayBillReversalParser().parse(confirmation(time: clock));
      expect(parsed, isNotNull);
      expect(parsed!.principalMinor, 100025);
      expect(parsed.walletMinor, 0);
      expect(parsed.declaredAt.second, 0);
    });
  }
  test('malformed, partial, ambiguous and non-credit wording are rejected', () {
    final sms = confirmation();
    for (final body in [
      sms.body.replaceAll('1,000.25', '1,00.25'),
      sms.body.replaceAll('12/9/26', '31/2/26'),
      sms.body.replaceAll('10:34 AM', '13:34 AM'),
      sms.body.replaceAll('credited', 'debited'),
      '${sms.body} ${sms.body}',
      sms.body.replaceAll('ORIGINAL01', 'REVERSAL01'),
      sms.body.replaceAll('1,000.25', '0.00'),
    ]) {
      expect(
        PayBillReversalParser().parse(
          domain.RawMessage(
            id: sms.id,
            sender: sms.sender,
            body: body,
            receivedAt: sms.receivedAt,
          ),
        ),
        isNull,
      );
    }
    expect(
      PayBillReversalParser().parse(
        confirmation(receipt: DateTime(2026, 9, 11)),
      ),
      isNull,
    );
  });
  test(
    'one distinct adjustment preserves principal, original fee, date and all links',
    () async {
      final id = await original();
      final before = (await db.select(db.financialRecords).get()).single
          .toJson();
      final result = await process(confirmation());
      expect(result.imported, isTrue);
      expect(result.evidenceCreated, 1);
      final all = await records.getAll();
      expect(all, hasLength(2));
      expect(
        (await db.select(db.financialRecords).get()).first.toJson(),
        before,
      );
      final adjustment = all.last;
      expect(adjustment.reversesRecordId, id);
      expect(adjustment.transactionCost, 0);
      expect(adjustment.balance, isNull);
      expect(adjustment.transactionDate, DateTime(2026, 9, 12, 10, 34));
      final totals = const FinancialSemantics().calculate(all);
      expect(totals.expenses, 0);
      expect(totals.fees, 23);
      expect(totals.income, 0);
      expect(totals.netCashFlow, -23);
      final evidence = (await db.select(db.balanceEvidence).get()).single;
      expect(evidence.amountMinor, 0);
      expect(evidence.accountId, isNull);
      expect(evidence.timeBasis, 'sms_declared_minute');
      expect(evidence.rawMessageId, isNotNull);
      expect(evidence.financialRecordId, adjustment.id);
      expect(evidence.matchedClause, 'New M-PESA account balance is Ksh0.00');
    },
  );
  test(
    'repeat is idempotent and preserves existing evidence associations/content',
    () async {
      await original();
      await process(confirmation());
      final before = (await db.select(db.balanceEvidence).get()).single
          .toJson();
      expect((await reversals.process(['reverse'])).single.duplicate, isTrue);
      expect(await records.getAll(), hasLength(2));
      expect(
        (await db.select(db.balanceEvidence).get()).single.toJson(),
        before,
      );
      expect(
        (await process(confirmation(id: 'second', ref: 'REVERSAL02'))).outcome,
        'REVERSAL_ALREADY_REVERSED',
      );
    },
  );
  test('ambiguous originals are never guessed', () async {
    await original();
    await original();
    expect(
      (await process(confirmation())).outcome,
      'REVERSAL_ORIGINAL_NOT_UNIQUE',
    );
    expect(await records.getAll(), hasLength(2));
  });
  for (final scenario in [
    'missing',
    'failed',
    'sendMoney',
    'amount',
    'chronology',
    'reference',
  ]) {
    test(
      'rejects $scenario without a financial movement or balance mutation',
      () async {
        if (scenario != 'missing') {
          await original(
            status: scenario == 'failed' ? 'failed' : 'successful',
            subtype: scenario == 'sendMoney' ? 'sendMoney' : 'payBill',
            amount: scenario == 'amount' ? 999 : 1000.25,
            date: scenario == 'chronology'
                ? DateTime(2026, 9, 12, 10, 34)
                : null,
          );
        }
        if (scenario == 'reference') await original(reference: 'REVERSAL01');
        expect((await process(confirmation())).imported, isFalse);
        expect(await db.select(db.balanceEvidence).get(), isEmpty);
        expect(
          (await records.getAll()).where((r) => r.reversesRecordId != null),
          isEmpty,
        );
      },
    );
  }
  test(
    'bounded all-supported operation rolls back rather than partly accepting',
    () async {
      await original();
      await RawMessagesRepository(db).saveAll([
        confirmation(),
        confirmation(id: 'bad', original: 'NOTFOUND01'),
      ]);
      await expectLater(
        reversals.process(['reverse', 'bad'], requireAllSupported: true),
        throwsStateError,
      );
      expect(await records.getAll(), hasLength(1));
      expect(await db.select(db.balanceEvidence).get(), isEmpty);
    },
  );
  for (final crossMonth in [false, true]) {
    test(
      '${crossMonth ? 'cross' : 'same'} month canonical SQL/category/budget/Activity reconciliation',
      () async {
        final id = await original();
        final period = FinancialPeriod.month(
          DateTime(2026, crossMonth ? 10 : 9),
        );
        await process(confirmation(date: crossMonth ? '1/10/26' : '12/9/26'));
        await BudgetsRepository(db).create(amount: '2000');
        await BudgetsRepository(
          db,
        ).create(amount: '2000', categoryId: 'builtin.expense.food');
        for (final category in [
          'builtin.expense.food',
          'builtin.expense.transport',
          null,
        ]) {
          if (category == null) {
            await categories.removeAssignment(id);
          } else {
            await categories.assign(recordId: id, categoryId: category);
          }
          final summary = await InsightsRepository(db).watch(period).first;
          final expected = crossMonth ? -1000.25 : 0.0;
          expect(summary.totals.expenses, expected);
          expect(summary.totals.income, 0);
          expect(summary.totals.fees, crossMonth ? 0 : 23);
          expect(summary.expenseCategories.single.id, category);
          expect(summary.expenseCategories.single.amount, expected);
          final filter = summary.expenseCategories.single.filter;
          final activity = await records.getActivity(filter, limit: 50);
          expect(await records.countActivity(filter), crossMonth ? 1 : 2);
          expect(
            const FinancialSemantics().calculate(activity).expenses,
            expected,
          );
          final budget = await BudgetsRepository(db).watch(period).first;
          expect(
            budget.firstWhere((p) => p.budget.overall).spentMinor,
            BigInt.from(crossMonth ? -100025 : 0),
          );
          expect(
            budget.firstWhere((p) => !p.budget.overall).spentMinor,
            BigInt.from(
              category == 'builtin.expense.food' && crossMonth ? -100025 : 0,
            ),
          );
          final dashboard = const FinancialBreakdownService().dashboard(
            await records.getForPeriod(period),
            period,
          );
          expect(dashboard.totals.expenses, expected);
        }
        if (crossMonth) {
          expect(
            (await InsightsRepository(
                  db,
                ).watch(FinancialPeriod.month(DateTime(2026, 9))).first)
                .totals
                .expenses,
            1000.25,
          );
        }
      },
    );
  }
  test(
    'hidden/deleted categories and rule application remain dynamically inherited',
    () async {
      final id = await original();
      await (db.update(
        db.financialRecords,
      )..where((f) => f.id.equals(id))).write(
        const FinancialRecordsCompanion(
          partyName: Value('Synthetic PayBill'),
          partyIdentifier: Value('123456'),
        ),
      );
      await categories.assignSimilar(
        recordId: id,
        categoryId: 'builtin.expense.food',
      );
      await process(confirmation());
      final adjustment = (await records.getAll()).last;
      await categories.assign(recordId: id, categoryId: 'builtin.expense.food');
      await categories.applyRules();
      expect(
        (await db.select(db.recordCategoryAssignments).get()).map(
          (r) => r.financialRecordId,
        ),
        [id],
      );
      await categories.setHidden('builtin.expense.food', true);
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        scope: ActivityScope.expenses,
        category: const ActivityCategoryFilter.category('builtin.expense.food'),
      );
      expect(await records.countActivity(filter), 2);
      await expectLater(
        categories.assign(
          recordId: adjustment.id!,
          categoryId: 'builtin.expense.transport',
        ),
        throwsArgumentError,
      );
      await expectLater(
        categories.removeAssignment(adjustment.id!),
        throwsArgumentError,
      );
      await categories.applyRules();
      expect(
        (await db.select(db.recordCategoryAssignments).get()).map(
          (r) => r.financialRecordId,
        ),
        [id],
      );
    },
  );
  test('deleted custom category becomes dynamically Uncategorized', () async {
    final id = await original();
    await process(confirmation());
    final category = await categories.createCustom(
      name: 'Purpose',
      kind: CategoryKind.expense,
    );
    await categories.assign(recordId: id, categoryId: category.id);
    await categories.deleteCustom(category.id);
    final summary = await InsightsRepository(
      db,
    ).watch(FinancialPeriod.month(DateTime(2026, 9))).first;
    expect(summary.expenseCategories.single.id, isNull);
    expect(
      await records.countActivity(summary.expenseCategories.single.filter),
      2,
    );
  });
  test(
    'generic saves cannot forge an adjustment and explicit links use the returned-funds endpoint',
    () async {
      await original();
      await process(confirmation());
      final adjustment = (await records.getAll()).last;
      expect(
        InstrumentLinksRepository.supports(
          adjustment,
          InstrumentEndpoint.destination,
        ),
        isTrue,
      );
      expect(
        InstrumentLinksRepository.supports(
          adjustment,
          InstrumentEndpoint.source,
        ),
        isFalse,
      );
      await expectLater(records.save(adjustment), throwsArgumentError);
      await expectLater(records.saveAll([adjustment]), throwsArgumentError);
    },
  );
  test('foreign key and uniqueness protect original history', () async {
    final id = await original();
    await process(confirmation());
    await expectLater(
      (db.delete(db.financialRecords)..where((f) => f.id.equals(id))).go(),
      throwsA(isA<Exception>()),
    );
    final row = (await db.select(db.financialRecords).get()).last;
    await expectLater(
      db
          .into(db.financialRecords)
          .insert(
            row
                .toCompanion(false)
                .copyWith(
                  id: const Value.absent(),
                  reference: const Value('REVERSAL03'),
                ),
          ),
      throwsA(isA<Exception>()),
    );
    expect(await records.getAll(), hasLength(2));
  });
  test(
    'normal import persists reversal only after the exact original is present',
    () async {
      await original();
      final importer = TransactionImportService(
        classifier: MpesaMessageClassifier(),
        financialRecordsRepository: records,
        rawMessagesRepository: RawMessagesRepository(db),
      );
      final result = await importer.importMessages([confirmation()]);
      expect(result.imported, 1);
      expect(result.skipped, 0);
      expect(result.failed, 0);
      expect(result.evidenceCreated, 1);
      final repeat = await importer.importMessages([confirmation()]);
      expect(repeat.duplicate, 1);
      expect(await records.getAll(), hasLength(2));
    },
  );
  test(
    'original and reversal in one import batch resolve independently of input order',
    () async {
      final originalSms = domain.RawMessage(
        id: 'original-source',
        sender: 'MPESA',
        receivedAt: DateTime(2026, 9, 10, 9, 1),
        body:
            'ORIGINAL01 Confirmed. Ksh1,000.25 sent to SYNTHETIC COMPANY for account 123 on 10/9/26 at 9:00 AM New M-PESA balance is Ksh0.00. Transaction cost, Ksh23.00.',
      );
      final importer = TransactionImportService(
        classifier: MpesaMessageClassifier(),
        financialRecordsRepository: records,
        rawMessagesRepository: RawMessagesRepository(db),
      );
      final result = await importer.importMessages([
        confirmation(),
        originalSms,
      ]);
      expect(result.imported, 2);
      expect(result.failed, 0);
      expect(result.skipped, 0);
      expect(result.evidenceCreated, 2);
      expect(result.audit.map((e) => e.index), [0, 1]);
      final all = await records.getAll();
      expect(all, hasLength(2));
      final totals = const FinancialSemantics().calculate(all);
      expect(totals.expenses, 0);
      expect(totals.fees, 23);
      expect(totals.income, 0);
    },
  );
  test(
    'v9 migration preserves all old record columns and enforces numeric relationship',
    () async {
      final dir = await Directory.systemTemp.createTemp('inslate_reversal_v9_');
      final file = File('${dir.path}/db');
      var migrationDb = AppDatabase.forTesting(NativeDatabase(file));
      try {
        await migrationDb
            .into(migrationDb.financialRecords)
            .insert(
              FinancialRecordsCompanion.insert(
                reference: 'original',
                receivedAt: DateTime(2026),
                amount: 5,
                type: 'expense',
                subtype: 'payBill',
                status: 'successful',
                title: 'payment',
                rawMessage: 'private',
                transactionCost: const Value(1),
                sourceAccountId: const Value(77),
              ),
            );
        final before =
            (await migrationDb
                    .customSelect('SELECT * FROM financial_records')
                    .getSingle())
                .data
              ..remove('interpreted_type')
              ..remove('interpreted_subtype')
              ..remove('interpretation_mapping_id')
              ..remove('reverses_record_id');
        await migrationDb.customStatement(
          'DROP INDEX financial_reversal_original_idx',
        );
        await migrationDb.customStatement(
          'DROP INDEX financial_reversal_reference_idx',
        );
        await migrationDb.customStatement(
          'ALTER TABLE financial_records DROP COLUMN reverses_record_id',
        );
        await migrationDb.customStatement('DROP TABLE instrument_mappings');
        await migrationDb.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpreted_type',
        );
        await migrationDb.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpreted_subtype',
        );
        await migrationDb.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpretation_mapping_id',
        );
        await migrationDb.customStatement('PRAGMA user_version = 9');
        await migrationDb.close();
        migrationDb = AppDatabase.forTesting(NativeDatabase(file));
        final after =
            (await migrationDb
                    .customSelect('SELECT * FROM financial_records')
                    .getSingle())
                .data;
        expect(after.remove('interpreted_type'), isNull);
        expect(after.remove('interpreted_subtype'), isNull);
        expect(after.remove('interpretation_mapping_id'), isNull);
        expect(after.remove('reverses_record_id'), isNull);
        expect(after, before);
        expect(
          (await migrationDb.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          11,
        );
        expect(
          await migrationDb.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await migrationDb.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
