import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart' as domain;
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late InsightsRepository insights;
  late FinancialRecordsRepository records;
  late CategoriesRepository categories;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    insights = InsightsRepository(db);
    records = FinancialRecordsRepository(db);
    categories = CategoriesRepository(db);
  });
  tearDown(() => db.close());
  Future<int> save(domain.FinancialRecord r) async {
    await records.save(r);
    return (await db.select(db.financialRecords).get()).last.id;
  }

  test(
    'SQL totals reconcile with canonical semantics for every subtype and mismatched type',
    () async {
      final input = [
        for (final subtype in RecordSubtype.values.where(
          (s) => s != RecordSubtype.payBillReversal,
        ))
          record(subtype, 100.01, fee: 1.23),
        record(
          RecordSubtype.receiveMoney,
          500,
          fee: 2,
          type: FinancialRecordType.expense,
        ),
      ];
      await records.saveAll(input);
      final s = await insights.watch(period).first;
      final expected = const FinancialSemantics().calculate(input);
      expect(s.recordCount, input.length);
      expect(s.totals.income, closeTo(expected.income, 1e-8));
      expect(s.totals.expenses, closeTo(expected.expenses, 1e-8));
      expect(s.totals.fees, closeTo(expected.fees, 1e-8));
      expect(s.totals.netCashFlow, closeTo(expected.netCashFlow, 1e-8));
      expect(s.totals.borrowed, closeTo(expected.borrowed, 1e-8));
      expect(s.totals.repaid, closeTo(expected.repaid, 1e-8));
      expect(
        s.totals.transfersIntoCentral,
        closeTo(expected.transfersIntoCentral, 1e-8),
      );
      expect(
        s.totals.transfersFromCentral,
        closeTo(expected.transfersFromCentral, 1e-8),
      );
      expect(
        s.expenseCategories.fold<double>(0, (sum, c) => sum + c.amount),
        closeTo(expected.expenses, 1e-8),
      );
      expect(
        s.incomeCategories.fold<double>(0, (sum, c) => sum + c.amount),
        closeTo(expected.income, 1e-8),
      );
      expect(
        s.trends.fold<double>(0, (sum, t) => sum + t.income),
        closeTo(expected.income, 1e-8),
      );
      expect(
        s.trends.fold<double>(0, (sum, t) => sum + t.expenses),
        closeTo(expected.expenses, 1e-8),
      );
    },
  );
  test(
    'hidden categories, explicit uncategorized and missing assignments reconcile and drill down exactly',
    () async {
      final hidden = await save(record(RecordSubtype.buyGoods, 60.25, fee: 2));
      await categories.assign(
        recordId: hidden,
        categoryId: 'builtin.expense.food',
      );
      await categories.setHidden('builtin.expense.food', true);
      final cleared = await save(record(RecordSubtype.sendMoney, 20.10));
      await categories.removeAssignment(cleared);
      await save(record(RecordSubtype.payBill, 19.65));
      final incomeCategory = (await categories.getCategories(
        kind: CategoryKind.income,
      )).first;
      final income = await save(record(RecordSubtype.receiveMoney, 250));
      await categories.assign(recordId: income, categoryId: incomeCategory.id);
      await save(record(RecordSubtype.deposit, 50));
      await save(record(RecordSubtype.fulizaLoan, 999, fee: 3));
      final s = await insights.watch(period).first;
      expect(s.totals.expenses, closeTo(100, 1e-8));
      expect(s.totals.fees, 5);
      expect(s.expenseCategories.first.hidden, isTrue);
      final uncategorized = s.expenseCategories.singleWhere(
        (g) => g.id == null,
      );
      expect(uncategorized.count, 2);
      expect(uncategorized.amount, closeTo(39.75, 1e-8));
      expect(uncategorized.share(s.totals.expenses), closeTo(0.3975, 1e-8));
      for (final group in [...s.incomeCategories, ...s.expenseCategories]) {
        final population = await records.getActivity(group.filter);
        expect(await records.countActivity(group.filter), group.count);
        expect(
          population.fold<double>(0, (sum, r) => sum + r.amount),
          closeTo(group.amount, 1e-8),
        );
        expect(group.filter.period, period);
      }
      for (final scope in [ActivityScope.income, ActivityScope.expenses]) {
        final population = await records.getActivity(s.filter(scope));
        expect(
          population.fold<double>(0, (sum, r) => sum + r.amount),
          closeTo(
            scope == ActivityScope.income ? s.totals.income : s.totals.expenses,
            1e-8,
          ),
        );
      }
    },
  );
  test(
    'start inclusive end exclusive uses transaction date with receipt fallback',
    () async {
      await records.saveAll([
        record(
          RecordSubtype.receiveMoney,
          10,
          date: period.start,
          receivedAt: DateTime(2026, 10),
        ),
        record(
          RecordSubtype.receiveMoney,
          20,
          receivedAt: period.end.subtract(const Duration(seconds: 1)),
        ),
        record(RecordSubtype.receiveMoney, 40, date: period.end),
        record(
          RecordSubtype.receiveMoney,
          80,
          date: period.start.subtract(const Duration(seconds: 1)),
        ),
      ]);
      final s = await insights.watch(period).first;
      expect(s.recordCount, 2);
      expect(s.totals.income, 30);
      expect(s.previousRecordCount, 1);
      expect(s.previousTotals.income, 80);
      expect(s.trends.first.income, 10);
      expect(s.trends.last.income, 20);
    },
  );
  test(
    'daily trend buckets include genuine zeros and reproduce Activity amounts',
    () async {
      await records.saveAll([
        record(RecordSubtype.receiveMoney, 25, date: DateTime(2026, 9, 2)),
        record(RecordSubtype.buyGoods, 5, date: DateTime(2026, 9, 2)),
        record(RecordSubtype.mshwariDeposit, 500, date: DateTime(2026, 9, 3)),
      ]);
      final s = await insights.watch(period).first;
      expect(s.monthlyTrends, isFalse);
      expect(s.trends, hasLength(30));
      expect(s.trends.first.income, 0);
      expect(s.trends[1].income, 25);
      expect(s.trends[1].expenses, 5);
      expect(s.trends[2].expenses, 0);
      for (final t in s.trends) {
        for (final scope in [ActivityScope.income, ActivityScope.expenses]) {
          final population = await records.getActivity(t.filter(scope));
          expect(
            population.fold<double>(0, (sum, r) => sum + r.amount),
            scope == ActivityScope.income ? t.income : t.expenses,
          );
        }
      }
    },
  );
  test(
    'long ranges use monthly trends with clipped first and last drill-downs',
    () async {
      final range = FinancialPeriod(
        DateTime(2026, 1, 15),
        DateTime(2026, 5, 20),
      );
      await records.saveAll([
        for (final date in [
          DateTime(2026, 1, 14),
          DateTime(2026, 1, 15),
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 1),
          DateTime(2026, 5, 19),
          DateTime(2026, 5, 20),
        ])
          record(RecordSubtype.receiveMoney, 10, date: date),
      ]);
      final s = await insights.watch(range).first;
      expect(s.monthlyTrends, isTrue);
      expect(s.trends, hasLength(5));
      expect(s.totals.income, 40);
      expect(s.trends.first.income, 20);
      expect(s.trends.first.period.start, range.start);
      expect(s.trends.last.period.end, range.end);
      for (final t in s.trends) {
        final population = await records.getActivity(
          t.filter(ActivityScope.income),
        );
        expect(
          population.fold<double>(0, (sum, r) => sum + r.amount),
          t.income,
        );
      }
    },
  );
  test(
    'aggregates all matching records beyond the Activity page size',
    () async {
      await records.saveAll(
        List.generate(
          151,
          (i) => record(RecordSubtype.buyGoods, 0.10, fee: 0.01),
        ),
      );
      final s = await insights.watch(period).first;
      expect(s.recordCount, 151);
      expect(s.totals.expenses, closeTo(15.10, 1e-8));
      expect(s.totals.fees, closeTo(1.51, 1e-8));
      expect(s.expenseCategories.single.count, 151);
    },
  );
  test(
    'empty period differs from a genuine zero observation and zero shares',
    () async {
      final empty = await insights.watch(period).first;
      expect(empty.recordCount, 0);
      expect(empty.expenseCategories, isEmpty);
      await save(record(RecordSubtype.buyGoods, 0));
      final zero = await insights.watch(period).first;
      expect(zero.recordCount, 1);
      expect(zero.totals.expenses, 0);
      expect(zero.expenseCategories.single.count, 1);
      expect(zero.expenseCategories.single.share(0), isNull);
    },
  );
  test(
    'live category rename and deletion retain records and reconcile Uncategorized',
    () async {
      final custom = await categories.createCustom(
        name: 'Purpose',
        kind: CategoryKind.expense,
      );
      final id = await save(record(RecordSubtype.buyGoods, 20));
      await categories.assign(recordId: id, categoryId: custom.id);
      final iterator = StreamIterator(insights.watch(period));
      try {
        await iterator.moveNext();
        expect(iterator.current.expenseCategories.single.name, 'Purpose');
        await categories.rename(custom.id, 'Renamed');
        await iterator.moveNext();
        expect(iterator.current.expenseCategories.single.name, 'Renamed');
        await categories.deleteCustom(custom.id);
        await iterator.moveNext();
        expect(iterator.current.expenseCategories.single.id, isNull);
        expect(iterator.current.recordCount, 1);
        expect(iterator.current.totals.expenses, 20);
      } finally {
        await iterator.cancel();
      }
    },
  );
}
