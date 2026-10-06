import 'activity_filter.dart';
import 'financial_period.dart';
import 'financial_records.dart';
import '../services/financial_semantics.dart';

enum BreakdownKind {
  spending,
  incomeCategories,
  expenseParties,
  incomeParties,
  internalMovement,
  loans,
  investmentsAndSavings,
  investmentPurchases,
  investmentRedemptions,
  savingsDeposits,
  savingsWithdrawals,
}

class FinancialGroup {
  final String label;
  final String? detail;
  final double amount, fees, share;
  final int count;
  final ActivityFilter filter;
  const FinancialGroup({
    required this.label,
    required this.amount,
    required this.fees,
    required this.count,
    required this.filter,
    this.detail,
    this.share = 0,
  });
}

class BreakdownSection {
  final String label;
  final List<FinancialGroup> groups;
  final bool includedInTotal;
  late final double amount;
  late final int count;
  BreakdownSection(
    this.label,
    Iterable<FinancialGroup> groups, {
    this.includedInTotal = true,
  }) : groups = List.unmodifiable(groups) {
    amount = this.groups.fold(0, (sum, group) => sum + group.amount);
    count = this.groups.fold(0, (sum, group) => sum + group.count);
  }
}

class FinancialBreakdown {
  final BreakdownKind kind;
  final ActivityFilter filter;
  final List<BreakdownSection> sections;
  late final double amount, fees;
  late final int count;
  late final List<FinancialGroup> groups;
  FinancialBreakdown({
    required this.kind,
    required this.filter,
    required Iterable<BreakdownSection> sections,
  }) : sections = List.unmodifiable(sections) {
    groups = List.unmodifiable(
      this.sections
          .where((section) => section.includedInTotal)
          .expand((section) => section.groups),
    );
    amount = groups.fold(0, (sum, group) => sum + group.amount);
    count = groups.fold(0, (sum, group) => sum + group.count);
    fees = groups.fold(0, (sum, group) => sum + group.fees);
  }
}

typedef BreakdownQuery = ({BreakdownKind kind, ActivityFilter filter});

class DashboardSummary {
  final FinancialPeriod period;
  final FinancialTotals totals;
  final Map<BreakdownKind, FinancialBreakdown> breakdowns;
  final List<FinancialRecord> recent;
  DashboardSummary({
    required this.period,
    required this.totals,
    required Map<BreakdownKind, FinancialBreakdown> breakdowns,
    required Iterable<FinancialRecord> recent,
  }) : breakdowns = Map.unmodifiable(breakdowns),
       recent = List.unmodifiable(recent);
  FinancialBreakdown breakdown(BreakdownKind kind) => breakdowns[kind]!;
}
