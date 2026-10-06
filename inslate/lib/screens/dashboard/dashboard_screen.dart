import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'financial_breakdown_screen.dart';
import '../activity/activity_screen.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_breakdown.dart';
import '../../services/financial_breakdown_service.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../widgets/financial_group_row.dart';
import '../../widgets/transaction_row.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/financial_summary_provider.dart';
import '../../models/financial_period.dart';

import '../../core/theme/app_theme.dart';
import '../../models/financial_records.dart';

import 'widgets/month_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final period = FinancialPeriod.month(ref.watch(selectedMonthProvider));

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _DashboardStickyHeaderDelegate(
                height: _DashboardHeader.stickyExtent(context),
              ),
            ),
            summary.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => const _DashboardPeriodLoading(),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  onRetry: () => ref.invalidate(periodRecordsProvider(period)),
                ),
              ),
              data: (summary) {
                return _DashboardPendingValues(
                  pending: summary.period != period,
                  child: SliverIgnorePointer(
                    ignoring: summary.period != period,
                    sliver: _DashboardContent(summary: summary),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

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

class _DashboardPeriodLoading extends StatelessWidget {
  const _DashboardPeriodLoading();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: Center(child: Text('Loading this period…')),
  );
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final showRecent =
        summary.period.start.year == now.year &&
        summary.period.start.month == now.month;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _MoneyMovementCard(summary: summary),
          const SizedBox(height: 16),
          _OverviewCard(summary: summary),
          const SizedBox(height: 16),
          _CategorySummaryCard(
            summary: summary,
            kind: BreakdownKind.spending,
            title: 'Expense categories',
            icon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 16),
          _CategorySummaryCard(
            summary: summary,
            kind: BreakdownKind.incomeCategories,
            title: 'Income categories',
            icon: Icons.south_west_rounded,
          ),
          const SizedBox(height: 16),
          _TopPartyCard(
            title: 'Top expenses',
            subtitle: 'People and businesses you sent the most to',
            parties: summary
                .breakdown(BreakdownKind.expenseParties)
                .groups
                .take(5)
                .toList(),
            isExpense: true,
            partyCount: summary
                .breakdown(BreakdownKind.expenseParties)
                .groups
                .where((group) => group.filter.party != null)
                .length,
            transactionCount: summary
                .breakdown(BreakdownKind.expenseParties)
                .count,
            averageTransaction:
                summary.breakdown(BreakdownKind.expenseParties).count == 0
                ? 0
                : summary.breakdown(BreakdownKind.expenseParties).amount /
                      summary.breakdown(BreakdownKind.expenseParties).count,
            onOpen: () =>
                _openBreakdown(context, summary, BreakdownKind.expenseParties),
          ),
          const SizedBox(height: 16),
          _TopPartyCard(
            title: 'Top income',
            subtitle: 'People and businesses you received the most from',
            parties: summary
                .breakdown(BreakdownKind.incomeParties)
                .groups
                .take(5)
                .toList(),
            isExpense: false,
            partyCount: summary
                .breakdown(BreakdownKind.incomeParties)
                .groups
                .where((group) => group.filter.party != null)
                .length,
            transactionCount: summary
                .breakdown(BreakdownKind.incomeParties)
                .count,
            averageTransaction:
                summary.breakdown(BreakdownKind.incomeParties).count == 0
                ? 0
                : summary.breakdown(BreakdownKind.incomeParties).amount /
                      summary.breakdown(BreakdownKind.incomeParties).count,
            onOpen: () =>
                _openBreakdown(context, summary, BreakdownKind.incomeParties),
          ),
          const SizedBox(height: 16),
          _AccountActivityCard(
            summary: summary,
            kind: BreakdownKind.loans,
            title: 'Loans',
            icon: Icons.account_balance_rounded,
            action: 'View loan breakdown',
          ),
          const SizedBox(height: 16),
          _AccountActivityCard(
            summary: summary,
            kind: BreakdownKind.investmentsAndSavings,
            title: 'Investments & Savings',
            icon: Icons.savings_outlined,
            action: 'View savings & investments',
          ),
          if (showRecent) ...[
            const SizedBox(height: 16),
            _ActivityCard(
              transactions: summary.recent,
              filter: ActivityFilter(period: summary.period),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DashboardStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  _DashboardStickyHeaderDelegate({required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF4F7F8),
      child: Column(
        children: [
          const _DashboardHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: const MonthSelector(),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DashboardStickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  // Keep the top section compact, allowing its header text to wrap without
  // clipping at narrow widths or larger accessibility text sizes.
  static double stickyExtent(BuildContext context) {
    final theme = Theme.of(context);
    final textWidth = MediaQuery.sizeOf(context).width - 36 - 48 - 12 - 48;
    double textHeight(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth > 0 ? textWidth : 1);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final titleHeight = textHeight(
      'InSlate',
      theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
    final subtitleHeight = textHeight(
      'Financial intelligence',
      theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
    );
    final extraHeight = titleHeight + 2 + subtitleHeight - 48;
    return 200 +
        MediaQuery.paddingOf(context).top +
        (extraHeight > 0 ? extraHeight : 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 14,
        left: 20,
        right: 16,
        bottom: 18,
      ),
      decoration: const BoxDecoration(color: Color(0xFF0B1F3A)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'lib/assets/images/inslate_logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'InSlate',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Financial intelligence',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.insights, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MoneyMovementCard extends StatelessWidget {
  final DashboardSummary summary;

  const _MoneyMovementCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      child: _CardContents(
        children: [
          const _CardHeader(
            title: 'Money movement',
            icon: Icons.swap_vert_rounded,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _MovementMetric(
                  label: 'Received',
                  amount: summary.totals.received,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF0F9D8A),
                  amountColor: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MovementMetric(
                  label: 'Sent',
                  amount: summary.totals.sent,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFD95C5C),
                  amountColor: Colors.red.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          InkWell(
            key: const ValueKey('internal-movement-link'),
            onTap: () => _openBreakdown(
              context,
              summary,
              BreakdownKind.internalMovement,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1F3A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Internal movement',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B1F3A),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _money(summary.totals.internalTransfers, context),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: const Color.fromARGB(255, 69, 70, 71),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InternalTransferMetric(
                          label:
                              'Into ${accountLabel(summary.breakdown(BreakdownKind.internalMovement).filter.central.type)}',
                          amount: summary.totals.transfersIntoCentral,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF0F9D8A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InternalTransferMetric(
                          label:
                              'From ${accountLabel(summary.breakdown(BreakdownKind.internalMovement).filter.central.type)}',
                          amount: summary.totals.transfersFromCentral,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFD95C5C),
                        ),
                      ),
                    ],
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

class _MovementMetric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color amountColor;

  const _MovementMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(amount, context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InternalTransferMetric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _InternalTransferMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _money(amount, context),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B1F3A),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final DashboardSummary summary;

  const _OverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: _CardContents(
        children: [
          const _CardHeader(title: 'Overview', icon: Icons.insights_rounded),
          const SizedBox(height: 18),

          _OverviewRow(
            label: 'Income',
            amount: summary.totals.income,
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF0F9D8A),
            amountColor: const Color(0xFF0F9D8A),
          ),
          _OverviewRow(
            label: 'Expenses',
            amount: summary.totals.expenses,
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFFD95C5C),
            amountColor: const Color(0xFFD95C5C),
          ),
          _OverviewRow(
            label: 'Fees',
            amount: summary.totals.fees,
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF687486),
            amountColor: const Color.fromARGB(255, 69, 70, 71),
          ),
          _OverviewRow(
            label: 'Net cash flow',
            amount: summary.totals.netCashFlow,
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF0B1F3A),
            amountColor: const Color.fromARGB(255, 69, 70, 71),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color amountColor;
  final bool isLast;

  const _OverviewRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.amountColor = const Color(0xFF0B1F3A),
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              _money(amount, context),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openBreakdown(
  BuildContext context,
  DashboardSummary summary,
  BreakdownKind kind,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FinancialBreakdownScreen(
        kind: kind,
        filter: ActivityFilter(
          period: summary.period,
          scope: FinancialBreakdownService.scopeFor(kind),
        ),
      ),
    ),
  );
}

class _TopPartyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FinancialGroup> parties;
  final bool isExpense;
  final int partyCount;
  final int transactionCount;
  final double averageTransaction;
  final VoidCallback onOpen;

  const _TopPartyCard({
    required this.title,
    required this.subtitle,
    required this.parties,
    required this.isExpense,
    required this.partyCount,
    required this.transactionCount,
    required this.averageTransaction,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      child: InkWell(
        onTap: onOpen,
        child: _CardContents(
          children: [
            _CardHeader(
              title: title,
              icon: isExpense
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isExpense
                      ? Icons.storefront_outlined
                      : Icons.account_circle_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  _DashboardPendingValues.of(context)
                      ? (isExpense ? '— merchants' : '— sources')
                      : (isExpense
                            ? '$partyCount merchants'
                            : '$partyCount sources'),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Avg. transaction ${_money(averageTransaction, context)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (parties.isEmpty)
              const _PeriodDataVisibility(child: _EmptyPartyState())
            else
              ...List.generate(
                parties.length,
                (index) => Column(
                  children: [
                    _PeriodDataVisibility(
                      child: _PartyRow(
                        summary: parties[index],
                        isExpense: isExpense,
                      ),
                    ),
                    if (index < parties.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                        indent: 36,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onOpen,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 17),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _DashboardPendingValues.of(context)
                            ? (isExpense
                                  ? 'View all Expenses'
                                  : 'View all Income')
                            : isExpense
                            ? 'View all Expenses ($transactionCount)'
                            : 'View all Income ($transactionCount)',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final FinancialGroup summary;
  final bool isExpense;

  const _PartyRow({required this.summary, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = summary.label;

    return InkWell(
      key: ValueKey(summary.filter),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityScreen(initialFilter: summary.filter),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              _PartyAvatar(party: party),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF0B1F3A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.count} '
                      '${summary.count == 1 ? 'transaction' : 'transactions'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.4,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${isExpense ? '-' : '+'}${_money(summary.amount, context)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isExpense
                          ? const Color(0xFFD95C5C)
                          : const Color(0xFF0F9D8A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyAvatar extends StatelessWidget {
  final String party;

  const _PartyAvatar({required this.party});

  @override
  Widget build(BuildContext context) {
    final letter = party.trim().isEmpty ? '?' : party.trim()[0].toUpperCase();

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Color(0xFF0B1F3A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyPartyState extends StatelessWidget {
  const _EmptyPartyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'No identified people or businesses yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
      ),
    );
  }
}

class _AccountActivityCard extends StatelessWidget {
  final DashboardSummary summary;
  final BreakdownKind kind;
  final String title, action;
  final IconData icon;
  const _AccountActivityCard({
    required this.summary,
    required this.kind,
    required this.title,
    required this.action,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = kind == BreakdownKind.loans;
    final sections = summary
        .breakdown(kind)
        .sections
        .where((section) => section.includedInTotal)
        .take(2)
        .toList();
    void open() => _openBreakdown(context, summary, kind);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _CardContents(
            children: [
              _CardHeaderSurface(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.darkBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppTheme.darkBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loans
                                ? 'Loan activity this period'
                                : 'Money moved this period',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkBlue.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!loans)
                for (final pair in const [
                  [
                    (
                      BreakdownKind.investmentPurchases,
                      'Purchases',
                      Icons.trending_up_rounded,
                    ),
                    (
                      BreakdownKind.investmentRedemptions,
                      'Redemptions',
                      Icons.south_west_rounded,
                    ),
                  ],
                  [
                    (
                      BreakdownKind.savingsDeposits,
                      'Deposits',
                      Icons.savings_outlined,
                    ),
                    (
                      BreakdownKind.savingsWithdrawals,
                      'Withdrawals',
                      Icons.north_east_rounded,
                    ),
                  ],
                ])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair.first.$1 == BreakdownKind.investmentPurchases
                            ? 'Investments'
                            : 'Savings',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var index = 0; index < pair.length; index++) ...[
                            if (index > 0) const SizedBox(width: 16),
                            Expanded(
                              child: _CapitalMovementRow(
                                summary: summary,
                                kind: pair[index].$1,
                                label: pair[index].$2,
                                icon: pair[index].$3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              if (loans)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < sections.length; index++) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: loans
                              ? EdgeInsets.zero
                              : const EdgeInsets.all(12),
                          decoration: loans
                              ? null
                              : BoxDecoration(
                                  color: AppTheme.darkTeal.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sections[index].label,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _money(sections[index].amount, context),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: loans && index == 0
                                              ? theme.colorScheme.error
                                              : AppTheme.darkTeal,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _DashboardPendingValues.of(context)
                                    ? '— transactions'
                                    : '${sections[index].count} transactions',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (!loans) ...[
                                const SizedBox(height: 6),
                                Text(
                                  index == 0
                                      ? 'Deposits & withdrawals'
                                      : 'Purchases & redemptions',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: open,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    backgroundColor: AppTheme.darkTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(action, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapitalMovementRow extends StatelessWidget {
  final DashboardSummary summary;
  final BreakdownKind kind;
  final String label;
  final IconData icon;
  const _CapitalMovementRow({
    required this.summary,
    required this.kind,
    required this.label,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final breakdown = summary.breakdown(kind);
    final moneyOut =
        kind == BreakdownKind.investmentPurchases ||
        kind == BreakdownKind.savingsDeposits;
    final movementColor = moneyOut
        ? Colors.red.shade600
        : Colors.green.shade600;
    return InkWell(
      key: ValueKey(kind),
      onTap: () => _openBreakdown(context, summary, kind),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: movementColor),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              _DashboardPendingValues.of(context)
                  ? '— transactions'
                  : '${breakdown.count} transactions',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _money(breakdown.amount, context),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: movementColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final DashboardSummary summary;
  final BreakdownKind kind;
  final String title;
  final IconData icon;
  const _CategorySummaryCard({
    required this.summary,
    required this.kind,
    required this.title,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final breakdown = summary.breakdown(kind);
    final expense = kind == BreakdownKind.spending;
    return _DashboardCard(
      child: InkWell(
        onTap: () => _openBreakdown(context, summary, kind),
        borderRadius: BorderRadius.circular(12),
        child: _CardContents(
          children: [
            _CardHeaderSurface(
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.darkBlue),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.darkBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (breakdown.count == 0 && !_DashboardPendingValues.of(context))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No activity for this period.'),
              ),
            for (final group in breakdown.groups.take(4))
              _PeriodDataVisibility(
                child: FinancialGroupRow(
                  key: ValueKey(group.filter),
                  group: group,
                  compact: true,
                  showShare: true,
                  accentColor: expense
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
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
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<FinancialRecord> transactions;
  final ActivityFilter filter;
  const _ActivityCard({required this.transactions, required this.filter});
  @override
  Widget build(BuildContext context) => _DashboardCard(
    child: _CardContents(
      children: [
        const _CardHeader(title: 'Recent activity', icon: Icons.bolt_rounded),
        const SizedBox(height: 12),
        if (transactions.isEmpty && !_DashboardPendingValues.of(context))
          const Text('No activity for the current month.'),
        for (final transaction in transactions)
          _PeriodDataVisibility(
            child: TransactionRow(record: transaction, central: filter.central),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityScreen(initialFilter: filter),
              ),
            ),
            child: const Text('View all activity'),
          ),
        ),
      ],
    ),
  );
}

class _CardContents extends StatelessWidget {
  final List<Widget> children;
  const _CardContents({required this.children});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < children.length; index++)
        if (index == 0)
          children[index]
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: children[index],
          ),
    ],
  );
}

class _CardHeaderSurface extends StatelessWidget {
  final Widget child;
  const _CardHeaderSurface({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CardHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _CardHeaderSurface(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.darkBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppTheme.darkBlue),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEF0)),
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: Color(0xFF0B1F3A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load your financial summary.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _money(double amount, BuildContext context) =>
    _DashboardPendingValues.of(context) ? '—' : formatMoney(amount);
