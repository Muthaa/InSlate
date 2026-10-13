import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/models/budget.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late BudgetsRepository repo;
  late CategoriesRepository categories;
  late FinancialRecordsRepository records;
  final month = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BudgetsRepository(db);
    categories = CategoriesRepository(db);
    records = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());
  Future<BudgetProgress> progress(String id, [FinancialPeriod? period]) async =>
      (await repo.watch(period ?? month).first).singleWhere(
        (p) => p.budget.id == id,
      );
  test(
    'CRUD exact KES, IDs, pause/resume and retroactive target edits never mutate financial data',
    () async {
      await records.save(record(RecordSubtype.buyGoods, 10.10));
      final before = (await db.select(db.financialRecords).get()).single
          .toJson();
      final id = await repo.create(amount: '20.01');
      expect((await progress(id)).budget.amountMinor, 2001);
      await repo.update(id: id, amount: '30.02');
      expect((await progress(id)).budget.id, id);
      expect((await progress(id)).budget.amountMinor, 3002);
      expect(
        (await progress(
          id,
          FinancialPeriod.month(DateTime(2026, 8)),
        )).budget.amountMinor,
        3002,
      );
      await repo.setActive(id, false);
      expect((await progress(id)).budget.isActive, isFalse);
      await repo.setActive(id, true);
      expect((await progress(id)).budget.isActive, isTrue);
      await repo.delete(id);
      expect(await repo.watch(month).first, isEmpty);
      expect(
        (await db.select(db.financialRecords).get()).single.toJson(),
        before,
      );
      await expectLater(repo.delete(id), throwsArgumentError);
    },
  );
  test(
    'one active target per scope enforced on create, edit and resume; paused duplicates allowed',
    () async {
      final first = await repo.create(amount: '10');
      await expectLater(repo.create(amount: '20'), throwsArgumentError);
      await repo.setActive(first, false);
      final second = await repo.create(amount: '20');
      await expectLater(repo.setActive(first, true), throwsArgumentError);
      final category = await repo.create(
        amount: '30',
        categoryId: 'builtin.expense.food',
      );
      await expectLater(
        repo.create(amount: '40', categoryId: 'builtin.expense.food'),
        throwsArgumentError,
      );
      await expectLater(
        repo.update(id: category, amount: '99'),
        throwsArgumentError,
      );
      expect((await progress(category)).budget.amountMinor, 3000);
      await repo.setActive(second, false);
      await repo.setActive(first, true);
      expect((await progress(first)).budget.isActive, isTrue);
    },
  );
  test(
    'database index independently rejects duplicate active overall and category targets',
    () async {
      await repo.create(amount: '1');
      await expectLater(
        db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'duplicate',
                scope: 'overall',
                amountMinor: 100,
              ),
            ),
        throwsA(anything),
      );
      await repo.create(amount: '1', categoryId: 'builtin.expense.food');
      await expectLater(
        db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: 'duplicate-cat',
                scope: 'category',
                categoryId: const Value('builtin.expense.food'),
                amountMinor: 100,
              ),
            ),
        throwsA(anything),
      );
    },
  );
  test(
    'positive exact targets reject zero, negative, sub-cent, malformed and overflow amounts',
    () async {
      for (final value in [
        '0',
        '-1',
        '1.001',
        'abc',
        '1,000',
        '92233720368547758.08',
      ]) {
        await expectLater(repo.create(amount: value), throwsArgumentError);
      }
      final id = await repo.create(amount: '92233720368547758.07');
      expect((await progress(id)).budget.amountMinor, 9223372036854775807);
      expect(
        budgetMoney(BigInt.from((await progress(id)).budget.amountMinor)),
        'KSh 92,233,720,368,547,758.07',
      );
    },
  );
  test(
    'income, missing and deleted categories rejected; deleted targets retained unavailable until repaired',
    () async {
      final income = (await categories.getCategories(
        kind: CategoryKind.income,
      )).first;
      await expectLater(
        repo.create(amount: '1', categoryId: income.id),
        throwsArgumentError,
      );
      await expectLater(
        repo.create(amount: '1', categoryId: 'missing'),
        throwsArgumentError,
      );
      final custom = await categories.createCustom(
        name: 'Purpose',
        kind: CategoryKind.expense,
      );
      final id = await repo.create(amount: '10', categoryId: custom.id);
      await categories.deleteCustom(custom.id);
      final lost = await progress(id);
      expect(lost.budget.available, isFalse);
      expect(lost.budget.isActive, isFalse);
      expect(lost.spentMinor, isNull);
      expect(lost.filter, isNull);
      await expectLater(repo.setActive(id, true), throwsArgumentError);
      await expectLater(
        repo.create(amount: '1', categoryId: custom.id),
        throwsArgumentError,
      );
      await repo.update(
        id: id,
        amount: '12',
        categoryId: 'builtin.expense.food',
      );
      expect((await progress(id)).budget.isActive, isFalse);
      await repo.setActive(id, true);
      expect((await progress(id)).budget.isActive, isTrue);
    },
  );
  test(
    'ordinary principal reconciles to canonical semantics and Insights; fees and mismatches excluded',
    () async {
      final input = [
        for (final s in RecordSubtype.values.where(
          (s) => s != RecordSubtype.payBillReversal,
        ))
          record(s, 100.01, fee: 2.34),
        record(RecordSubtype.buyGoods, 999, type: FinancialRecordType.income),
      ];
      await records.saveAll(input);
      final p = await progress(await repo.create(amount: '1000'));
      final canonical = const FinancialSemantics().calculate(input);
      final insight = await InsightsRepository(db).watch(month).first;
      final expenseCount = input
          .where(
            (r) =>
                const FinancialSemantics().classify(r) == MovementClass.expense,
          )
          .length;
      expect(p.spentMinor, BigInt.from(10001) * BigInt.from(expenseCount));
      expect(canonical.expenses, closeTo(p.spentMinor!.toInt() / 100, 1e-8));
      expect(insight.totals.expenses, closeTo(canonical.expenses, 1e-8));
      expect(p.count, expenseCount);
    },
  );
  test(
    'category and overall include hidden assignments and Uncategorized and exact Activity drill-down',
    () async {
      await records.saveAll([
        record(RecordSubtype.buyGoods, 0.10),
        record(RecordSubtype.sendMoney, 0.20),
        record(RecordSubtype.payBill, 0.30),
        record(RecordSubtype.receiveMoney, 999),
      ]);
      final rows = await db.select(db.financialRecords).get();
      await categories.assign(
        recordId: rows[0].id,
        categoryId: 'builtin.expense.food',
      );
      await categories.removeAssignment(rows[1].id);
      await categories.setHidden('builtin.expense.food', true);
      final overall = await progress(await repo.create(amount: '1'));
      final food = await progress(
        await repo.create(amount: '1', categoryId: 'builtin.expense.food'),
      );
      expect(overall.spentMinor, BigInt.from(60));
      expect(food.spentMinor, BigInt.from(10));
      expect(food.budget.categoryHidden, isTrue);
      for (final p in [overall, food]) {
        expect(await records.countActivity(p.filter!), p.count);
        final population = await records.getActivity(p.filter!);
        expect(
          population.fold<double>(0, (sum, r) => sum + r.amount),
          closeTo(p.spentMinor!.toInt() / 100, 1e-8),
        );
        expect(p.filter!.period, month);
      }
    },
  );
  test(
    'calendar boundaries use transaction timestamp with receipt fallback and no full-page limit',
    () async {
      await records.saveAll([
        record(
          RecordSubtype.buyGoods,
          1,
          date: month.start,
          receivedAt: month.end,
        ),
        record(
          RecordSubtype.buyGoods,
          2,
          receivedAt: month.end.subtract(const Duration(seconds: 1)),
        ),
        record(RecordSubtype.buyGoods, 4, date: month.end),
        record(
          RecordSubtype.buyGoods,
          8,
          date: month.start.subtract(const Duration(seconds: 1)),
        ),
        ...List.generate(51, (i) => record(RecordSubtype.buyGoods, 0.10)),
      ]);
      final id = await repo.create(amount: '10');
      final p = await progress(id);
      expect(p.spentMinor, BigInt.from(810));
      expect(p.count, 53);
      expect(
        (await progress(
          id,
          FinancialPeriod.month(DateTime(2026, 8)),
        )).spentMinor,
        BigInt.from(800),
      );
    },
  );
  test(
    'no spending, exact exhaustion, overspending and unsupported precision are distinct',
    () async {
      final id = await repo.create(amount: '0.30');
      var p = await progress(id);
      expect(p.spentMinor, BigInt.zero);
      expect(p.count, 0);
      await records.save(record(RecordSubtype.buyGoods, 0.30));
      p = await progress(id);
      expect(p.remainingMinor, BigInt.zero);
      expect(p.usedPercentage, '100.00%');
      await records.save(record(RecordSubtype.buyGoods, 0.01));
      p = await progress(id);
      expect(p.overspentMinor, BigInt.one);
      expect(p.remainingMinor, -BigInt.one);
      await records.save(record(RecordSubtype.buyGoods, 0.001));
      p = await progress(id);
      expect(p.spentMinor, isNull);
      expect(p.remainingMinor, isNull);
      expect(p.usedPercentage, isNull);
      expect(p.count, 3);
    },
  );
  test(
    'decimal formatting cannot silently round legacy sub-cent or unsafe huge values',
    () async {
      final id = await repo.create(amount: '10');
      for (final value in [
        0.10000000000000002,
        123456789012.0001,
        100000000000000.1,
        1e20,
      ]) {
        await db.delete(db.financialRecords).go();
        await records.save(record(RecordSubtype.buyGoods, value));
        expect((await progress(id)).spentMinor, isNull);
      }
    },
  );
}
