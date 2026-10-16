import 'dart:math' as math;
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/enums/account_type.dart';
import '../core/enums/record_subtype.dart';
import '../models/activity_filter.dart';
import '../models/financial_period.dart';
import '../models/insights.dart';
import '../services/financial_semantics.dart';

class InsightsRepository {
  final AppDatabase database;
  InsightsRepository(this.database);

  // Generated from the canonical exhaustive policy, never a second subtype map.
  static String get _movementSql {
    final clauses = RecordSubtype.values
        .map((subtype) {
          final policy = FinancialSemantics.forSubtype(subtype);
          if (policy.expectedType == null) return '';
          var movement = policy.movement.name;
          if (policy.movement == MovementClass.internalTransfer) {
            final direction = AccountMovement(
              source: policy.source == null
                  ? null
                  : AccountEndpoint(policy.source!),
              destination: policy.destination == null
                  ? null
                  : AccountEndpoint(policy.destination!),
            ).relativeTo(const AccountEndpoint(AccountType.mpesa));
            movement = direction == TransferDirection.intoCentral
                ? 'transferIn'
                : direction == TransferDirection.fromCentral
                ? 'transferOut'
                : 'internalTransfer';
          }
          return "WHEN ${FinancialSemantics.effectiveSubtypeSql('f')} = '${subtype.name}' AND ${FinancialSemantics.effectiveTypeSql('f')} = '${policy.expectedType!.name}' THEN '$movement'";
        })
        .join(' ');
    return "CASE $clauses ELSE 'unresolved' END";
  }

  Stream<InsightsSummary> watch(FinancialPeriod period) {
    final previous = precedingInsightPeriod(period);
    final monthly = period.end.difference(period.start).inDays > 90;
    final bucket = monthly ? '%Y-%m-01' : '%Y-%m-%d';
    // Assignments are one per record. LEFT JOIN retains hidden assignments and
    // both missing assignments and explicit manual-uncategorized overrides.
    return database
        .customSelect(
          """
      WITH selected AS (
        SELECT ${FinancialSemantics.principalSql('f')} AS amount, COALESCE(f.transaction_cost, 0) AS fee,
          $_movementSql AS movement,
          CASE WHEN COALESCE(f.transaction_date, f.received_at) >= ? THEN 1 ELSE 0 END AS current_period,
          strftime('$bucket', COALESCE(f.transaction_date, f.received_at), 'unixepoch', 'localtime') AS bucket,
          a.category_id, c.display_name, COALESCE(c.is_hidden, 0) AS hidden
        FROM financial_records f
        LEFT JOIN record_category_assignments a ON a.financial_record_id = ${FinancialSemantics.categoryRecordSql('f')}
        LEFT JOIN transaction_categories c ON c.id = a.category_id
        WHERE COALESCE(f.transaction_date, f.received_at) >= ?
          AND COALESCE(f.transaction_date, f.received_at) < ?
      )
      SELECT current_period, bucket, movement, category_id, display_name, hidden,
        COUNT(*) AS record_count, SUM(amount) AS amount, SUM(fee) AS fees
      FROM selected
      GROUP BY current_period, bucket, movement, category_id, display_name, hidden
      ORDER BY current_period, bucket, movement, category_id
    """,
          variables: [
            Variable<int>(period.start.millisecondsSinceEpoch ~/ 1000),
            Variable<int>(previous.start.millisecondsSinceEpoch ~/ 1000),
            Variable<int>(period.end.millisecondsSinceEpoch ~/ 1000),
          ],
          readsFrom: {
            database.financialRecords,
            database.recordCategoryAssignments,
            database.transactionCategories,
          },
        )
        .watch()
        .map((rows) => _summary(rows, period, previous, monthly));
  }

  InsightsSummary _summary(
    List<QueryRow> rows,
    FinancialPeriod period,
    FinancialPeriod previous,
    bool monthly,
  ) {
    final current = _Totals(), before = _Totals();
    final categories = <ActivityScope, Map<String?, _Category>>{
      ActivityScope.income: {},
      ActivityScope.expenses: {},
    };
    final trend = <String, _Totals>{};
    for (final row in rows) {
      final isCurrent = row.read<int>('current_period') == 1;
      final movement = row.read<String>('movement');
      final amount = row.read<double>('amount');
      final count = row.read<int>('record_count');
      (isCurrent ? current : before).add(
        movement,
        amount,
        row.read<double>('fees'),
        count,
      );
      if (!isCurrent) continue;
      final key = row.read<String>('bucket');
      trend.putIfAbsent(key, _Totals.new).add(movement, amount, 0, count);
      final scope = movement == 'income'
          ? ActivityScope.income
          : movement == 'expense'
          ? ActivityScope.expenses
          : null;
      if (scope == null) continue;
      final id = row.readNullable<String>('category_id');
      final category = categories[scope]!.putIfAbsent(
        id,
        () => _Category(
          id,
          row.readNullable<String>('display_name') ?? 'Uncategorized',
          row.read<int>('hidden') == 1,
        ),
      );
      category.amount += amount;
      category.count += count;
    }
    List<InsightCategory> groups(ActivityScope scope) {
      final result =
          categories[scope]!.values
              .map(
                (c) => InsightCategory(
                  id: c.id,
                  name: c.name,
                  hidden: c.hidden,
                  amount: c.amount,
                  count: c.count,
                  filter: ActivityFilter(
                    period: period,
                    scope: scope,
                    category: c.id == null
                        ? const ActivityCategoryFilter.uncategorized()
                        : ActivityCategoryFilter.category(c.id!),
                  ),
                ),
              )
              .toList()
            ..sort((a, b) {
              final order = b.amount.compareTo(a.amount);
              return order != 0 ? order : a.name.compareTo(b.name);
            });
      return result;
    }

    final trends = <InsightTrend>[];
    var date = monthly
        ? DateTime(period.start.year, period.start.month)
        : DateTime(period.start.year, period.start.month, period.start.day);
    while (date.isBefore(period.end)) {
      final end = monthly
          ? DateTime(date.year, date.month + 1)
          : DateTime(date.year, date.month, date.day + 1);
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final amounts = trend[key];
      final startMillis = math.max(
        date.millisecondsSinceEpoch,
        period.start.millisecondsSinceEpoch,
      );
      final endMillis = math.min(
        end.millisecondsSinceEpoch,
        period.end.millisecondsSinceEpoch,
      );
      trends.add(
        InsightTrend(
          FinancialPeriod(
            DateTime.fromMillisecondsSinceEpoch(startMillis),
            DateTime.fromMillisecondsSinceEpoch(endMillis),
          ),
          amounts?.income ?? 0,
          amounts?.expenses ?? 0,
        ),
      );
      date = end;
    }
    return InsightsSummary(
      period: period,
      comparisonPeriod: previous,
      totals: current.build(),
      previousTotals: before.build(),
      recordCount: current.count,
      previousRecordCount: before.count,
      incomeCategories: groups(ActivityScope.income),
      expenseCategories: groups(ActivityScope.expenses),
      trends: trends,
      monthlyTrends: monthly,
    );
  }
}

class _Category {
  final String? id;
  final String name;
  final bool hidden;
  double amount = 0;
  int count = 0;
  _Category(this.id, this.name, this.hidden);
}

class _Totals {
  double income = 0,
      expenses = 0,
      fees = 0,
      into = 0,
      from = 0,
      borrowed = 0,
      repaid = 0;
  int count = 0;
  void add(String movement, double amount, double fee, int records) {
    count += records;
    fees += fee;
    switch (movement) {
      case 'income':
        income += amount;
      case 'expense':
        expenses += amount;
      case 'transferIn':
        into += amount;
      case 'transferOut':
        from += amount;
      case 'loanBorrowing':
        borrowed += amount;
      case 'loanRepayment':
        repaid += amount;
    }
  }

  FinancialTotals build() => FinancialTotals(
    income: income,
    expenses: expenses,
    received: income,
    sent: expenses,
    fees: fees,
    transfersIntoCentral: into,
    transfersFromCentral: from,
    borrowed: borrowed,
    repaid: repaid,
  );
}
