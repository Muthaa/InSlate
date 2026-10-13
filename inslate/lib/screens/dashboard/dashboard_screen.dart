import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/branding/app_brand.dart';
import '../../core/design/slate_components.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_breakdown.dart';
import '../../models/financial_period.dart';
import '../../models/financial_records.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/financial_summary_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/financial_group_row.dart';
import '../../widgets/transaction_row.dart';
import '../../widgets/unspecified_movements_card.dart';
import '../activity/activity_screen.dart';
import '../activity/transaction_detail_screen.dart';
import '../insights/insights_screen.dart';
import 'dashboard_budget_section.dart';
import 'financial_breakdown_screen.dart';
import 'home_attention.dart';
import 'home_comparison.dart';
import 'widgets/month_selector.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(FinancialPeriod)? onOpenInsights;
  const DashboardScreen({super.key, this.onOpenInsights});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final period = FinancialPeriod.month(ref.watch(selectedMonthProvider));
    void insights() {
      if (onOpenInsights != null) {
        onOpenInsights!(period);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => InsightsScreen(initialPeriod: period),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: SlateColors.of(context).canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SlateSpace.pageWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(onOpenInsights: insights),
                ),
                summary.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SlateState(
                        kind: SlateStateKind.loading,
                        title: 'Loading this period…',
                        message: 'Bringing your recorded finances into focus.',
                      ),
                    ),
                  ),
                  error: (_, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SlateState(
                        kind: SlateStateKind.error,
                        title: 'Unable to load your financial summary.',
                        message:
                            'Your stored records are unchanged. Try loading this period again.',
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.invalidate(periodRecordsProvider(period)),
                      ),
                    ),
                  ),
                  data: (data) => _DashboardPendingValues(
                    pending: data.period != period,
                    child: SliverIgnorePointer(
                      ignoring: data.period != period,
                      sliver: _HomeContent(
                        summary: data,
                        onOpenInsights: insights,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep the same content tree during refresh; mask all old-period values and
// disable drill-downs until the selected period has arrived.
class _DashboardPendingValues extends InheritedWidget {
  final bool pending;
  const _DashboardPendingValues({required this.pending, required super.child});
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DashboardPendingValues>()
          ?.pending ??
      false;
  @override
  bool updateShouldNotify(_DashboardPendingValues oldWidget) =>
      pending != oldWidget.pending;
}

class _PeriodDataVisibility extends StatelessWidget {
  final Widget child;
  const _PeriodDataVisibility({required this.child});
  @override
  Widget build(BuildContext context) => Visibility(
    visible: !_DashboardPendingValues.of(context),
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    child: child,
  );
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onOpenInsights;
  const _HomeHeader({required this.onOpenInsights});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'lib/assets/images/inslate_logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  semanticLabel: 'InSlate blue and yellow logo',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppBrand.name, style: theme.textTheme.titleLarge),
                    Text(AppBrand.tagline, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('dashboard.insights'),
                tooltip: 'Open Insights for selected month',
                onPressed: onOpenInsights,
                icon: const Icon(Icons.insights_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your financial overview',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'A clearer picture of your recorded money.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          const MonthSelector(),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final DashboardSummary summary;
  final VoidCallback onOpenInsights;
  const _HomeContent({required this.summary, required this.onOpenInsights});
  @override
  Widget build(BuildContext context) {
    final empty = summary.recent.isEmpty;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (empty) ...[
            SlateCard(
              child: SlateState(
                kind: _DashboardPendingValues.of(context)
                    ? SlateStateKind.loading
                    : SlateStateKind.empty,
                title: _DashboardPendingValues.of(context)
                    ? 'Loading this period…'
                    : 'Your story starts with a record',
                message: _DashboardPendingValues.of(context)
                    ? 'Bringing your recorded finances into focus.'
                    : 'No financial records for this month. Choose a month with activity to see your income, spending and money movements.',
              ),
            ),
            const SizedBox(height: 24),
            const HomeAttention(),
            const SizedBox(height: 24),
            _PeriodDataVisibility(
              child: DashboardBudgetSection(period: summary.period),
            ),
          ] else ...[
            _OverviewCard(summary: summary),
            const SizedBox(height: 24),
            const HomeAttention(),
            const SizedBox(height: 24),
            _PeriodDataVisibility(
              child: HomeComparison(period: summary.period),
            ),
            const SizedBox(height: 32),
            const SlateSectionHeading(
              title: 'Beyond income & spending',
              subtitle:
                  'Contributions, withdrawals and principal · separate from cash flow',
            ),
            const SizedBox(height: 16),
            _CapitalCard(
              summary: summary,
              title: 'Investments',
              icon: Icons.trending_up_rounded,
              items: const [
                (BreakdownKind.investmentPurchases, 'Purchases'),
                (BreakdownKind.investmentRedemptions, 'Redemptions'),
              ],
              detail:
                  'Money invested and redeemed. These are movements, not returns or holdings.',
            ),
            const SizedBox(height: 12),
            _CapitalCard(
              summary: summary,
              title: 'Savings',
              icon: Icons.savings_outlined,
              items: const [
                (BreakdownKind.savingsDeposits, 'Deposits'),
                (BreakdownKind.savingsWithdrawals, 'Withdrawals'),
              ],
              detail:
                  'Deposits and withdrawals. Savings balances are not inferred.',
            ),
            const SizedBox(height: 12),
            _LoanCard(summary: summary),
            const SizedBox(height: 12),
            _MoneyMovementCard(summary: summary),
            const SizedBox(height: 12),
            _PeriodDataVisibility(
              child: UnspecifiedMovementsCard(period: summary.period),
            ),
            const SizedBox(height: 32),
            _ActivityCard(
              transactions: summary.recent,
              filter: ActivityFilter(period: summary.period),
            ),
            const SizedBox(height: 32),
            _PeriodDataVisibility(
              child: DashboardBudgetSection(period: summary.period),
            ),
            const SizedBox(height: 32),
            const SlateSectionHeading(
              title: 'Follow the money',
              subtitle:
                  'Explore the transaction types and people behind the totals',
            ),
            const SizedBox(height: 16),
            _CategoriesCard(
              summary: summary,
              kind: BreakdownKind.spending,
              title: 'Expense categories',
              action: 'Expense transaction types',
            ),
            const SizedBox(height: 12),
            _CategoriesCard(
              summary: summary,
              kind: BreakdownKind.incomeCategories,
              title: 'Income categories',
              action: 'Income transaction types',
            ),
            const SizedBox(height: 12),
            _PartiesCard(summary: summary, expense: true),
            const SizedBox(height: 12),
            _PartiesCard(summary: summary, expense: false),
            const SizedBox(height: 32),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onOpenInsights,
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Explore more in Insights'),
            ),
          ],
        ]),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final DashboardSummary summary;
  const _OverviewCard({required this.summary});
  @override
  Widget build(BuildContext context) {
    final p = SlateColors.of(context);
    final theme = Theme.of(context);
    final pending = _DashboardPendingValues.of(context);
    return SlateCard(
      color: p.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.waterfall_chart_rounded,
                color: SlateColors.brandBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Net cash flow',
                  style: theme.textTheme.titleMedium?.copyWith(color: p.onHero),
                ),
              ),
              IconButton(
                tooltip: 'How net cash flow is calculated',
                icon: Icon(Icons.info_outline, color: p.onHero, size: 20),
                onPressed: () => showSlateDialog<void>(
                  context,
                  builder: (_) => AppDialog(
                    title: const Text('Understanding cash flow'),
                    content: const Text(
                      'Net cash flow = income − ordinary spending − all recorded fees. It excludes savings and investment transfers, loan principal and purpose-unspecified principal. It is not an account balance, investment return or measure of complete history.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SlateAmount(
            key: const ValueKey('home.netCashFlow'),
            amount: summary.totals.netCashFlow,
            pending: pending,
            style: theme.textTheme.displaySmall,
            color: p.onHero,
          ),
          const SizedBox(height: 8),
          Text(
            'Income − spending − fees. Not your account balance.',
            style: theme.textTheme.bodySmall?.copyWith(color: p.onHero),
          ),
          const SizedBox(height: 24),
          Divider(color: p.onHero.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          _MetricLayout(
            children: [
              _Metric(
                label: 'Income',
                amount: summary.totals.income,
                icon: Icons.south_west_rounded,
                color: p.onHero,
                iconColor: const Color(0xFF70D9C2),
                onTap: () => _openBreakdown(
                  context,
                  summary,
                  BreakdownKind.incomeCategories,
                ),
              ),
              _Metric(
                label: 'Spending',
                amount: summary.totals.expenses,
                icon: Icons.north_east_rounded,
                color: p.onHero,
                iconColor: const Color(0xFFFFA4AA),
                onTap: () =>
                    _openBreakdown(context, summary, BreakdownKind.spending),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Metric(
            label: 'Fees',
            inline: true,
            amount: summary.totals.fees,
            icon: Icons.receipt_long_outlined,
            color: p.onHero,
            iconColor: SlateColors.brandYellow,
            onTap: () => showSlateSheet<void>(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SlateSectionHeading(
                    title: 'Recorded fees',
                    subtitle: 'Fees from all recorded movements in this month',
                  ),
                  const SizedBox(height: 16),
                  SlateAmount(amount: summary.totals.fees),
                  const SizedBox(height: 12),
                  const Text(
                    'Fees are separate from ordinary spending and are deducted once in net cash flow. Loan and transfer fees are included; their principal is excluded.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openActivity(
                        context,
                        ActivityFilter(period: summary.period),
                      );
                    },
                    child: const Text('Review supporting activity'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reflow at narrow widths or large text instead of shrinking accessible text.
class _MetricLayout extends StatelessWidget {
  final List<Widget> children;
  const _MetricLayout({required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final columns = largeText || constraints.maxWidth < 300
          ? 1
          : children.length;
      final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color? color, iconColor;
  final VoidCallback? onTap;
  final bool inline;
  const _Metric({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.color,
    this.iconColor,
    this.onTap,
    this.inline = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = SlateColors.of(context);
    final heading = Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? color ?? p.movement),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color ?? p.muted),
          ),
        ),
      ],
    );
    final value = SlateAmount(
      amount: amount,
      pending: _DashboardPendingValues.of(context),
      color: color ?? p.ink,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: inline
            ? Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 12),
                  Flexible(child: value),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 8), value],
              ),
      ),
    );
  }
}

class _CapitalCard extends StatelessWidget {
  final DashboardSummary summary;
  final String title, detail;
  final IconData icon;
  final List<(BreakdownKind, String)> items;
  const _CapitalCard({
    required this.summary,
    required this.title,
    required this.detail,
    required this.icon,
    required this.items,
  });
  @override
  Widget build(BuildContext context) => SlateCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MovementHeading(title: title, icon: icon),
        const SizedBox(height: 16),
        _MetricLayout(
          children: [
            for (final item in items)
              _CapitalMetric(summary: summary, kind: item.$1, label: item.$2),
          ],
        ),
        const SizedBox(height: 12),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
        if (title == 'Savings')
          TextButton(
            onPressed: () => _openBreakdown(
              context,
              summary,
              BreakdownKind.investmentsAndSavings,
            ),
            child: const Text('View savings & investments'),
          ),
      ],
    ),
  );
}

class _CapitalMetric extends StatelessWidget {
  final DashboardSummary summary;
  final BreakdownKind kind;
  final String label;
  const _CapitalMetric({
    required this.summary,
    required this.kind,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    final data = summary.breakdown(kind);
    final outgoing =
        kind == BreakdownKind.investmentPurchases ||
        kind == BreakdownKind.savingsDeposits;
    return Container(
      decoration: BoxDecoration(
        color: SlateColors.of(context).inset,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Metric(
            key: ValueKey(kind),
            label: label,
            amount: data.amount,
            icon: outgoing
                ? Icons.north_east_rounded
                : Icons.south_west_rounded,
            iconColor: SlateColors.of(context).movement,
            onTap: () => _openBreakdown(context, summary, kind),
          ),
          Text(
            _DashboardPendingValues.of(context)
                ? '— transactions'
                : '${data.count} ${data.count == 1 ? 'transaction' : 'transactions'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MovementHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  const _MovementHeading({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: SlateColors.of(context).movement, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

class _LoanCard extends StatelessWidget {
  final DashboardSummary summary;
  const _LoanCard({required this.summary});
  @override
  Widget build(BuildContext context) => SlateCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MovementHeading(
          title: 'Loans',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 16),
        _MetricLayout(
          children: [
            _Metric(
              label: 'Borrowed',
              amount: summary.totals.borrowed,
              icon: Icons.add_rounded,
            ),
            _Metric(
              label: 'Repaid',
              amount: summary.totals.repaid,
              icon: Icons.remove_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Recorded principal only. Borrowing is not income; repayments are not ordinary spending. Outstanding debt is not inferred.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () =>
              _openBreakdown(context, summary, BreakdownKind.loans),
          child: const Text('View loan breakdown'),
        ),
      ],
    ),
  );
}

class _MoneyMovementCard extends StatelessWidget {
  final DashboardSummary summary;
  const _MoneyMovementCard({required this.summary});
  @override
  Widget build(BuildContext context) => SlateCard(
    child: InkWell(
      key: const ValueKey('internal-movement-link'),
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          _openBreakdown(context, summary, BreakdownKind.internalMovement),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MovementHeading(
            title: 'Transfers',
            icon: Icons.swap_horiz_rounded,
          ),
          const SizedBox(height: 16),
          _MetricLayout(
            children: [
              _Metric(
                label:
                    'Into ${accountLabel(summary.breakdown(BreakdownKind.internalMovement).filter.central.type)}',
                amount: summary.totals.transfersIntoCentral,
                icon: Icons.south_west_rounded,
              ),
              _Metric(
                label:
                    'From ${accountLabel(summary.breakdown(BreakdownKind.internalMovement).filter.central.type)}',
                amount: summary.totals.transfersFromCentral,
                icon: Icons.north_east_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Transfers between account families. Includes savings and investment movements shown above; these totals are not additive.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Text('View internal movement breakdown'),
        ],
      ),
    ),
  );
}

class _CategoriesCard extends StatelessWidget {
  final DashboardSummary summary;
  final BreakdownKind kind;
  final String title, action;
  const _CategoriesCard({
    required this.summary,
    required this.kind,
    required this.title,
    required this.action,
  });
  @override
  Widget build(BuildContext context) {
    final data = summary.breakdown(kind);
    final expense = kind == BreakdownKind.spending;
    final color = expense
        ? SlateColors.of(context).spending
        : SlateColors.of(context).income;
    return SlateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlateSectionHeading(
            title: title,
            subtitle: 'Transaction types · principal only',
          ),
          const SizedBox(height: 12),
          SlateAmount(
            amount: expense ? summary.totals.expenses : summary.totals.income,
            pending: _DashboardPendingValues.of(context),
            color: color,
          ),
          const SizedBox(height: 16),
          if (data.count == 0 && !_DashboardPendingValues.of(context))
            const Text('No activity for this period.'),
          for (final group in data.groups.take(4))
            _PeriodDataVisibility(
              child: FinancialGroupRow(
                key: ValueKey(group.filter),
                group: group,
                accentColor: color,
                showShare: data.amount > 0 && group.amount >= 0,
                labelStyle: Theme.of(context).textTheme.bodyMedium,
                amountStyle: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: color),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => FinancialBreakdownScreen(
                      kind: expense
                          ? BreakdownKind.expenseParties
                          : BreakdownKind.incomeParties,
                      filter: group.filter,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _openBreakdown(context, summary, kind),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _PartiesCard extends StatelessWidget {
  final DashboardSummary summary;
  final bool expense;
  const _PartiesCard({required this.summary, required this.expense});
  @override
  Widget build(BuildContext context) {
    final kind = expense
        ? BreakdownKind.expenseParties
        : BreakdownKind.incomeParties;
    final data = summary.breakdown(kind);
    return SlateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlateSectionHeading(
            title: expense ? 'Top expenses' : 'Top income',
            subtitle: expense
                ? 'People and businesses you sent the most to'
                : 'People and businesses you received the most from',
          ),
          const SizedBox(height: 16),
          if (data.count == 0 && !_DashboardPendingValues.of(context))
            const Text('No activity for this period.'),
          for (final group in data.groups.take(5))
            _PeriodDataVisibility(
              child: FinancialGroupRow(
                key: ValueKey(group.filter),
                group: group,
                accentColor: expense
                    ? SlateColors.of(context).spending
                    : SlateColors.of(context).income,
                onTap: () => _openActivity(context, group.filter),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _openBreakdown(context, summary, kind),
            child: Text(
              'View all ${expense ? 'Expenses' : 'Income'}${_DashboardPendingValues.of(context) ? '' : ' (${data.count})'}',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<FinancialRecord> transactions;
  final ActivityFilter filter;
  const _ActivityCard({required this.transactions, required this.filter});
  @override
  Widget build(BuildContext context) => SlateCard(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SlateSectionHeading(
            title: 'Recent activity',
            subtitle: 'Latest records in ${periodLabel(filter.period)}',
          ),
        ),
        const SizedBox(height: 12),
        for (final record in transactions)
          _PeriodDataVisibility(
            child: TransactionRow(
              record: record,
              central: filter.central,
              fullWidthMetadata: true,
              onTap: record.id == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => TransactionDetailScreen(
                          recordId: record.id!,
                          central: filter.central,
                        ),
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: OutlinedButton(
            onPressed: () => _openActivity(context, filter),
            child: const Text('View all activity'),
          ),
        ),
      ],
    ),
  );
}

void _openActivity(BuildContext context, ActivityFilter filter) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ActivityScreen(preserveDrillDown: true, initialFilter: filter),
      ),
    );
void _openBreakdown(
  BuildContext context,
  DashboardSummary summary,
  BreakdownKind kind,
) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => FinancialBreakdownScreen(
      kind: kind,
      filter: summary.breakdown(kind).filter,
    ),
  ),
);
