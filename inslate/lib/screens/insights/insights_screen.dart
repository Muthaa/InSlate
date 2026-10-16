import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design/design_tokens.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_period.dart';
import '../../models/insights.dart';
import '../../providers/insights_provider.dart';
import '../../providers/repository_providers.dart';
import '../activity/activity_screen.dart';
import 'insight_trend_chart.dart';
import 'insight_category_donut.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/unspecified_movements_card.dart';

enum InsightPeriodChoice {
  currentMonth,
  previousMonth,
  last3Months,
  last6Months,
  thisYear,
  custom,
}

class InsightsScreen extends ConsumerStatefulWidget {
  final FinancialPeriod? initialPeriod;
  final int navigationRevision;
  const InsightsScreen({
    super.key,
    this.initialPeriod,
    this.navigationRevision = 0,
  });
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late FinancialPeriod _period =
      widget.initialPeriod ?? FinancialPeriod.month(DateTime.now());
  late InsightPeriodChoice _choice = widget.initialPeriod == null
      ? InsightPeriodChoice.currentMonth
      : InsightPeriodChoice.custom;

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPeriod != null &&
        (widget.initialPeriod != oldWidget.initialPeriod ||
            widget.navigationRevision != oldWidget.navigationRevision)) {
      _period = widget.initialPeriod!;
      final now = DateTime.now();
      _choice = _period == FinancialPeriod.month(now)
          ? InsightPeriodChoice.currentMonth
          : _period == FinancialPeriod.month(DateTime(now.year, now.month - 1))
          ? InsightPeriodChoice.previousMonth
          : InsightPeriodChoice.custom;
    }
  }

  Future<void> _select(InsightPeriodChoice choice) async {
    final now = DateTime.now();
    if (choice != InsightPeriodChoice.custom) {
      setState(() {
        _choice = choice;
        _period = switch (choice) {
          InsightPeriodChoice.currentMonth => FinancialPeriod.month(now),
          InsightPeriodChoice.previousMonth => FinancialPeriod.month(
            DateTime(now.year, now.month - 1),
          ),
          InsightPeriodChoice.last3Months => FinancialPeriod(
            DateTime(now.year, now.month - 2),
            DateTime(now.year, now.month, now.day + 1),
          ),
          InsightPeriodChoice.last6Months => FinancialPeriod(
            DateTime(now.year, now.month - 5),
            DateTime(now.year, now.month, now.day + 1),
          ),
          InsightPeriodChoice.thisYear => FinancialPeriod(
            DateTime(now.year),
            DateTime(now.year, now.month, now.day + 1),
          ),
          InsightPeriodChoice.custom => _period,
        };
      });
      return;
    }
    try {
      final bounds = await ref
          .read(financialRecordsRepositoryProvider)
          .getEffectiveDateBounds();
      if (!mounted) return;
      final starts = [
        _period.start,
        now,
        if (bounds.first != null) bounds.first!.toLocal(),
      ]..sort();
      final ends = [
        _period.end.subtract(const Duration(microseconds: 1)),
        now,
        if (bounds.last != null) bounds.last!.toLocal(),
      ]..sort();
      final range = await showDateRangePicker(
        context: context,
        helpText: 'Choose start and end dates',
        saveText: 'Apply range',
        fieldStartLabelText: 'Start date',
        fieldEndLabelText: 'End date',
        firstDate: starts.first,
        lastDate: ends.last,
        initialDateRange: DateTimeRange(
          start: _period.start,
          end: _period.end.subtract(const Duration(microseconds: 1)),
        ),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.teal,
            ).copyWith(primary: AppTheme.darkBlue, surface: Colors.white),
          ),
          child: child!,
        ),
      );
      if (range != null && mounted) {
        setState(() {
          _choice = choice;
          _period = FinancialPeriod(
            range.start,
            DateTime(range.end.year, range.end.month, range.end.day + 1),
          );
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load date range. Please try again.'),
          ),
        );
      }
    }
  }

  void _open(ActivityFilter filter) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          ActivityScreen(initialFilter: filter, preserveDrillDown: true),
    ),
  );

  Widget _section(
    String title,
    List<Widget> children, {
    IconData? icon,
    Color? accent,
    Widget? action,
    String? subtitle,
    bool compact = false,
  }) => Card(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: compact ? 19 : 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _metric(
    String label,
    double value,
    double previous, {
    required bool comparisonAvailable,
    ActivityFilter? filter,
  }) {
    final accent = switch (label) {
      'Income' => AppTheme.teal,
      'Expenses' => Colors.red.shade700,
      'Fees' => Colors.amber.shade800,
      _ => Colors.blue.shade700,
    };
    final icon = switch (label) {
      'Income' => Icons.add_circle_outline,
      'Expenses' => Icons.remove_circle_outline,
      'Fees' => Icons.receipt_outlined,
      _ => Icons.swap_vert,
    };
    final subject = switch (label) {
      'Income' => 'income',
      'Expenses' => 'spending',
      'Fees' => 'fees',
      _ => 'net cash flow',
    };
    final change = InsightChange(value, previous);
    final percentageLabel = change.percentage == null
        ? 'Percentage unavailable (zero or negative baseline)'
        : change.percentage == 0
        ? 'No change in $subject'
        : '${change.percentage!.abs().toStringAsFixed(1)}% ${change.percentage! < 0 ? 'less' : 'more'}';
    final direction = change.absolute == 0
        ? Icons.horizontal_rule
        : change.absolute > 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final palette = SlateColors.of(context);
    final changeColor = palette.muted;
    final lowerIsFavorable = label == 'Expenses' || label == 'Fees';
    final favorable = lowerIsFavorable
        ? change.absolute < 0
        : change.absolute > 0;
    final percentageColor =
        !comparisonAvailable ||
            change.percentage == null ||
            change.absolute == 0
        ? palette.muted
        : favorable
        ? palette.income
        : palette.spending;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        dense: true,
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (filter != null)
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoney(value),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (comparisonAvailable)
              Column(
                key: ValueKey('insights.comparison.$subject'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${change.absolute > 0 ? '+' : ''}${formatMoney(change.absolute)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(direction, size: 16, color: percentageColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          percentageLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: percentageColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(
                'Comparison unavailable',
                style: TextStyle(fontSize: 12, color: changeColor),
              ),
          ],
        ),
        onTap: filter == null ? null : () => _open(filter),
      ),
    );
  }

  Widget _purposeCategories(
    List<InsightCategory> groups,
    double total, {
    bool expense = false,
  }) {
    final accent = expense ? Colors.red.shade700 : AppTheme.teal;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _section(
        expense ? 'Expense purpose categories' : 'Income purpose categories',
        [
          InsightCategoryDonut(
            groups: groups,
            total: total,
            expense: expense,
            onOpen: _open,
          ),
        ],
        compact: true,
        icon: expense ? Icons.remove_circle_outline : Icons.add_circle_outline,
        accent: accent,
      ),
    );
  }

  Widget _comparisonPair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 280 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 8), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _trends(InsightsSummary s) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.monthlyTrends
                          ? 'Monthly income and expense trends'
                          : 'Daily income and expense trends',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'About income and expense trends',
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AppDialog(
                        title: const Text('About trends'),
                        icon: Icons.insights_outlined,
                        content: const Text(
                          'Ordinary principal amounts; fees are shown separately in the overview. Expense adjustments may appear below zero. Select a date, then tap Income or Expenses to view its records.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InsightTrendChart(
              trends: s.trends,
              monthly: s.monthlyTrends,
              onOpen: _open,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(insightsProvider(_period));
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.insights_outlined, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insights'),
                  Text(
                    'Understand your income and spending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<InsightPeriodChoice>(
            isExpanded: true,
            initialValue: _choice,
            key: ValueKey(_choice),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(
              Icons.expand_more_rounded,
              color: AppTheme.darkBlue,
            ),
            decoration: InputDecoration(
              labelText: 'Viewing period',
              prefixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: AppTheme.teal,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.teal),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: InsightPeriodChoice.currentMonth,
                child: Text(
                  'Current month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: InsightPeriodChoice.previousMonth,
                child: Text(
                  'Previous month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: InsightPeriodChoice.last3Months,
                child: Text('Last 3 months'),
              ),
              DropdownMenuItem(
                value: InsightPeriodChoice.last6Months,
                child: Text('Last 6 months'),
              ),
              DropdownMenuItem(
                value: InsightPeriodChoice.thisYear,
                child: Text('This year'),
              ),
              DropdownMenuItem(
                value: InsightPeriodChoice.custom,
                child: Text(
                  'Custom date range',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (choice) {
              if (choice != null) _select(choice);
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    periodLabel(_period),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                if (_choice == InsightPeriodChoice.custom)
                  IconButton(
                    tooltip: 'Change date range',
                    onPressed: () => _select(_choice),
                    icon: const Icon(
                      Icons.edit_calendar_outlined,
                      size: 20,
                      color: AppTheme.teal,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          result.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              children: [
                const Text('Unable to load insights.'),
                TextButton(
                  onPressed: () => ref.invalidate(insightsProvider(_period)),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (s) => Column(
              children: [
                if (s.recordCount == 0)
                  _section('No records in this period', [
                    const Text(
                      'No financial records are stored for these dates. Displayed zero totals do not establish an account balance.',
                    ),
                  ]),
                _section(
                  'Overview',
                  [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBlue.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected period: ${periodLabel(s.period)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comparison period: ${periodLabel(s.comparisonPeriod)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.previousRecordCount} records in comparison period',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (s.recordCount == 0 || s.previousRecordCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          s.recordCount == 0
                              ? 'No records in selected period; differences are unavailable.'
                              : 'No records in comparison period; differences are unavailable.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _comparisonPair(
                      _metric(
                        'Income',
                        s.totals.income,
                        s.previousTotals.income,
                        comparisonAvailable:
                            s.recordCount > 0 && s.previousRecordCount > 0,
                        filter: s.filter(ActivityScope.income),
                      ),
                      _metric(
                        'Expenses',
                        s.totals.expenses,
                        s.previousTotals.expenses,
                        comparisonAvailable:
                            s.recordCount > 0 && s.previousRecordCount > 0,
                        filter: s.filter(ActivityScope.expenses),
                      ),
                    ),
                    const Divider(height: 24),
                    _comparisonPair(
                      _metric(
                        'Fees',
                        s.totals.fees,
                        s.previousTotals.fees,
                        comparisonAvailable:
                            s.recordCount > 0 && s.previousRecordCount > 0,
                      ),
                      _metric(
                        'Net cash flow',
                        s.totals.netCashFlow,
                        s.previousTotals.netCashFlow,
                        comparisonAvailable:
                            s.recordCount > 0 && s.previousRecordCount > 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${s.recordCount} financial records in selected period',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  subtitle: 'Compared with preceding period',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: AppTheme.darkBlue,
                  action: IconButton(
                    tooltip: 'About overview',
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AppDialog(
                        title: const Text('About overview'),
                        icon: Icons.account_balance_wallet_outlined,
                        content: const Text(
                          'Tap ordinary income or expenses to explore their records. Expenses are net principal amounts, including approved PayBill reversal adjustments on their reversal dates. Fees include charges on all recorded movements and are deducted once in net cash flow. Loans, internal transfers, savings, investments and unresolved principal are excluded from ordinary income and expenses.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (s.recordCount > 0) _trends(s),
                _purposeCategories(
                  s.expenseCategories,
                  s.totals.expenses,
                  expense: true,
                ),
                _purposeCategories(s.incomeCategories, s.totals.income),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: UnspecifiedMovementsCard(period: s.period),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
