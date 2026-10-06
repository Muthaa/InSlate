import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/record_subtype.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_breakdown.dart';
import '../../models/financial_period.dart';
import '../../providers/financial_summary_provider.dart';
import 'financial_breakdown_screen.dart';

/// Compatibility entry point: category parties now share financial breakdowns.
class CategoryTransactionsScreen extends ConsumerStatefulWidget {
  final RecordSubtype subtype;
  final bool isIncome;
  final FinancialPeriod? period;
  const CategoryTransactionsScreen({
    super.key,
    required this.subtype,
    required this.isIncome,
    this.period,
  });
  @override
  ConsumerState<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends ConsumerState<CategoryTransactionsScreen> {
  late final ActivityFilter _filter;
  @override
  void initState() {
    super.initState();
    _filter = ActivityFilter(
      period:
          widget.period ??
          FinancialPeriod.month(ref.read(selectedMonthProvider)),
      scope: widget.isIncome ? ActivityScope.income : ActivityScope.expenses,
      subtype: widget.subtype,
    );
  }

  @override
  Widget build(BuildContext context) => FinancialBreakdownScreen(
    kind: widget.isIncome
        ? BreakdownKind.incomeParties
        : BreakdownKind.expenseParties,
    filter: _filter,
  );
}
