import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/design/slate_components.dart';
import '../../widgets/app_dialog.dart';
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
                  onPressed: () => showSlateDialog<void>(
                    context,
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [Text(periodLabel(period)), open('Manage budgets')],
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in active.take(3))
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: SlateColors.of(context).inset,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: SlateColors.of(context).line,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p.budget.label}${p.budget.categoryHidden ? ' (hidden)' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: SlateColors.of(context).ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Target ${formatKesMinor(BigInt.from(p.budget.amountMinor))}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: SlateColors.of(context).muted,
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
                                                p.overspentMinor! > BigInt.zero
                                                ? SlateColors.of(
                                                    context,
                                                  ).attention
                                                : SlateColors.of(
                                                    context,
                                                  ).income,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    LinearProgressIndicator(
                                      value: p.usedBasisPoints! < BigInt.zero
                                          ? 0
                                          : p.usedBasisPoints! >
                                                BigInt.from(10000)
                                          ? 1
                                          : p.usedBasisPoints!.toInt() / 10000,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(6),
                                      color: p.overspentMinor! > BigInt.zero
                                          ? SlateColors.of(context).attention
                                          : SlateColors.of(context).income,
                                      backgroundColor: SlateColors.of(
                                        context,
                                      ).line,
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
                                                p.overspentMinor! > BigInt.zero
                                                ? SlateColors.of(
                                                    context,
                                                  ).attention
                                                : SlateColors.of(context).muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (p.count == 0) ...[
                                      const SizedBox(height: 4),
                                      const Text('No spending recorded.'),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          if (active.length > 3)
                            Text(
                              '${active.length - 3} more active targets in Budgets',
                            ),
                        ],
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
  Widget build(BuildContext context) => AppDialog(
    icon: Icons.savings_outlined,
    title: const Text('About monthly budgets'),
    content: const Text(
      'Monthly spending uses ordinary expense principal only; fees are excluded. Budgets are targets, not balances. Overall and category targets overlap, so their spending totals are not additive.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  );
}
