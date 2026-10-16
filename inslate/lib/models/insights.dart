import 'activity_filter.dart';
import 'financial_period.dart';
import '../services/financial_semantics.dart';

/// Calendar months compare with the preceding month. Other date ranges compare
/// with the immediately preceding interval of the same number of local dates.
FinancialPeriod precedingInsightPeriod(FinancialPeriod period) {
  if (period == FinancialPeriod.month(period.start)) {
    return FinancialPeriod.month(
      DateTime(period.start.year, period.start.month - 1),
    );
  }
  final days = DateTime.utc(period.end.year, period.end.month, period.end.day)
      .difference(
        DateTime.utc(period.start.year, period.start.month, period.start.day),
      )
      .inDays;
  if (days > 0 && period.start.hour == 0 && period.end.hour == 0) {
    return FinancialPeriod(
      DateTime(period.start.year, period.start.month, period.start.day - days),
      period.start,
    );
  }
  return FinancialPeriod(
    period.start.subtract(period.end.difference(period.start)),
    period.start,
  );
}

class InsightChange {
  final double current, previous;
  const InsightChange(this.current, this.previous);
  double get absolute => current - previous;

  /// Zero and negative baselines do not define a useful percentage increase.
  double? get percentage => previous > 0 ? absolute / previous * 100 : null;
}

class InsightCategory {
  final String? id;
  final String name;
  final bool hidden;
  final double amount;
  final int count;
  final ActivityFilter filter;
  const InsightCategory({
    required this.id,
    required this.name,
    required this.hidden,
    required this.amount,
    required this.count,
    required this.filter,
  });
  double? share(double total) => total > 0 ? amount / total : null;
}

class InsightTrend {
  final FinancialPeriod period;
  final double income, expenses;
  const InsightTrend(this.period, this.income, this.expenses);
  ActivityFilter filter(ActivityScope scope) =>
      ActivityFilter(period: period, scope: scope);
}

class InsightsSummary {
  final FinancialPeriod period, comparisonPeriod;
  final FinancialTotals totals, previousTotals;
  final int recordCount, previousRecordCount;
  final List<InsightCategory> incomeCategories, expenseCategories;
  final List<InsightTrend> trends;
  final bool monthlyTrends;
  const InsightsSummary({
    required this.period,
    required this.comparisonPeriod,
    required this.totals,
    required this.previousTotals,
    required this.recordCount,
    required this.previousRecordCount,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.trends,
    required this.monthlyTrends,
  });
  ActivityFilter filter(ActivityScope scope) =>
      ActivityFilter(period: period, scope: scope);
}
