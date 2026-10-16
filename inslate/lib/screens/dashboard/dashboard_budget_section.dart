import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_period.dart';
import '../../providers/budgets_provider.dart';
import '../budgets/budgets_screen.dart';

class DashboardBudgetSection extends ConsumerWidget {
  final FinancialPeriod period;
  const DashboardBudgetSection({super.key, required this.period});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final previous = FinancialPeriod.month(DateTime(now.year, now.month - 1));
    final supported =
        period == FinancialPeriod.month(now) || period == previous;
    Widget open(String label) => TextButton.icon(
      key: const ValueKey('dashboard.budgets'),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.savings_outlined),
      label: Text(label),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              BudgetsScreen(previousMonth: supported && period == previous),
        ),
      ),
    );
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'Monthly budgets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'About monthly budgets',
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => const _BudgetInformationDialog(),
                  ),
                ),
              ],
            ),
            if (!supported) ...[
              const Text(
                'Budget management supports current and previous months.',
              ),
              open('View current-month budgets'),
            ] else ...[
              MediaQuery.textScalerOf(context).scale(14) > 14
                  ? Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(periodLabel(period)),
                        open('Manage budgets'),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: Text(periodLabel(period))),
                        open('Manage budgets'),
                      ],
                    ),
              ref
                  .watch(budgetsProvider(period))
                  .when(
                    skipLoadingOnReload: false,
                    skipLoadingOnRefresh: false,
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Loading budget progress...'),
                    ),
                    error: (_, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget progress unavailable.'),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(budgetsProvider(period)),
                          child: const Text('Retry budget progress'),
                        ),
                      ],
                    ),
                    data: (rows) {
                      final active = rows
                          .where((p) => p.budget.isActive)
                          .toList();
                      if (active.isEmpty) {
                        return const Text(
                          'No active budgets. Create or resume a monthly target.',
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth < 360
                              ? constraints.maxWidth * 0.88
                              : 320.0;
                          return SingleChildScrollView(
                            key: const ValueKey('dashboard.budget.scroller'),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(top: 12),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final p in active)
                                    Container(
                                      key: ValueKey(
                                        'dashboard.budget.${p.budget.id}',
                                      ),
                                      width: cardWidth,
                                      margin: const EdgeInsetsDirectional.only(
                                        end: 12,
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.appBackground,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${p.budget.label}${p.budget.categoryHidden ? ' (hidden)' : ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.darkBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Target ${formatKesMinor(BigInt.from(p.budget.amountMinor))}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          if (p.spentMinor == null)
                                            const Text(
                                              'Spending unavailable; recorded precision is unsupported.',
                                            )
                                          else ...[
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  'Spent ${formatKesMinor(p.spentMinor!)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${p.usedPercentage} used',
                                                  style: TextStyle(
                                                    color:
                                                        p.overspentMinor! >
                                                            BigInt.zero
                                                        ? Colors.deepOrange
                                                        : AppTheme.teal,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            LinearProgressIndicator(
                                              value:
                                                  p.usedBasisPoints! <
                                                      BigInt.zero
                                                  ? 0
                                                  : p.usedBasisPoints! >
                                                        BigInt.from(10000)
                                                  ? 1
                                                  : p.usedBasisPoints!.toInt() /
                                                        10000,
                                              minHeight: 6,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color:
                                                  p.overspentMinor! >
                                                      BigInt.zero
                                                  ? Colors.deepOrange
                                                  : AppTheme.teal,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              p.overspentMinor! > BigInt.zero
                                                  ? 'Over budget by ${formatKesMinor(p.overspentMinor!)}'
                                                  : 'Remaining ${formatKesMinor(p.remainingMinor!)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        p.overspentMinor! >
                                                            BigInt.zero
                                                        ? Colors.deepOrange
                                                        : Colors.grey.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (p.count == 0) ...[
                                              const SizedBox(height: 4),
                                              const Text(
                                                'No spending recorded.',
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetInformationDialog extends StatelessWidget {
  const _BudgetInformationDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppTheme.teal;
    const details = [
      (
        'What is included',
        'Monthly spending uses ordinary expense principal only. Fees are excluded.',
      ),
      (
        'Targets, not balances',
        'Budgets are spending targets, not account balances.',
      ),
    ];
    return AlertDialog(
      backgroundColor: const Color(0xFFF4F7F8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'About monthly budgets',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppTheme.darkBlue),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final detail in details) ...[
              Text(
                detail.$1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.$2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Overall and category targets overlap; their spending totals are not additive.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
