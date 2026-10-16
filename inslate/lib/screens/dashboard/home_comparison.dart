import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/slate_components.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_period.dart';
import '../../models/insights.dart';
import '../../providers/insights_provider.dart';
import '../activity/activity_screen.dart';

/// Uses the existing Insights aggregation and preceding-calendar-month policy.
class HomeComparison extends ConsumerWidget {
  final FinancialPeriod period;
  const HomeComparison({super.key, required this.period});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SlateCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlateSectionHeading(
          title: 'The month in context',
          subtitle: 'Recorded income and spending · fees excluded',
        ),
        const SizedBox(height: 20),
        ref
            .watch(insightsProvider(period))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Text('Loading comparison…'),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Comparison unavailable.'),
                  TextButton(
                    onPressed: () => ref.invalidate(insightsProvider(period)),
                    child: const Text('Retry comparison'),
                  ),
                ],
              ),
              data: (data) {
                if (data.recordCount == 0 || data.previousRecordCount == 0) {
                  return const Text(
                    'A comparison needs recorded activity in both months. Missing records do not mean zero income or spending.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ComparisonRow(
                      label: 'Income',
                      change: InsightChange(
                        data.totals.income,
                        data.previousTotals.income,
                      ),
                      period: data.period,
                      previous: data.comparisonPeriod,
                      scope: ActivityScope.income,
                      tone: SlateTone.income,
                    ),
                    const Divider(),
                    _ComparisonRow(
                      label: 'Spending',
                      change: InsightChange(
                        data.totals.expenses,
                        data.previousTotals.expenses,
                      ),
                      period: data.period,
                      previous: data.comparisonPeriod,
                      scope: ActivityScope.expenses,
                      tone: SlateTone.spending,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Compared with ${periodLabel(data.comparisonPeriod)}. Current months may be incomplete; recorded history does not establish full coverage.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
      ],
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final InsightChange change;
  final FinancialPeriod period, previous;
  final ActivityScope scope;
  final SlateTone tone;
  const _ComparisonRow({
    required this.label,
    required this.change,
    required this.period,
    required this.previous,
    required this.scope,
    required this.tone,
  });
  @override
  Widget build(BuildContext context) {
    final color = slateToneColor(context, tone);
    final max = change.current > change.previous
        ? change.current
        : change.previous;
    Widget value(String name, double amount, FinancialPeriod selected) =>
        InkWell(
          key: ValueKey('home.comparison.${scope.name}.$name'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ActivityScreen(
                preserveDrillDown: true,
                initialFilter: ActivityFilter(period: selected, scope: scope),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodySmall),
                    SlateAmount(amount: amount, color: color),
                  ],
                ),
                if (max > 0 &&
                    amount >= 0 &&
                    change.current >= 0 &&
                    change.previous >= 0) ...[
                  const SizedBox(height: 8),
                  ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: (amount / max).clamp(0, 1),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                      color: name == 'Selected month'
                          ? color
                          : color.withValues(alpha: 0.45),
                      backgroundColor: SlateColors.of(context).inset,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        value('Selected month', change.current, period),
        value('Previous month', change.previous, previous),
        Text(
          change.absolute == 0
              ? 'No change in recorded ${label.toLowerCase()}'
              : '${formatMoney(change.absolute.abs())} ${change.absolute > 0 ? 'more' : 'less'} than the previous month',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
