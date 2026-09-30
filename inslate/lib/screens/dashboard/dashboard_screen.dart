import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/record_subtype.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_records.dart';
import '../../models/financial_summary.dart';
import '../../models/party.dart';
import '../../models/party_summary.dart';
import '../../providers/financial_summary_provider.dart';
import 'widgets/month_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: summary.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorState(
            onRetry: () {
              ref.invalidate(financialSummaryProvider);
            },
          ),
          data: (summary) {
            return _DashboardContent(summary: summary);
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final FinancialSummary summary;

  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _DashboardStickyHeaderDelegate(),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MoneyMovementCard(summary: summary),
              const SizedBox(height: 16),
              _OverviewCard(summary: summary),
              const SizedBox(height: 16),
              _TopPartyCard(
                title: 'Top expenses',
                subtitle: 'People and businesses you sent the most to',
                parties: summary.topExpenses,
                isExpense: true,
                partyCount: summary.expensePartyCount,
                transactionCount: summary.expenseTransactionCount,
                averageTransaction: summary.expenseTransactionCount == 0
                    ? 0
                    : summary.totalSent / summary.expenseTransactionCount,
              ),
              const SizedBox(height: 16),
              _TopPartyCard(
                title: 'Top income',
                subtitle: 'People and businesses you received the most from',
                parties: summary.topIncome,
                isExpense: false,
                partyCount: summary.incomePartyCount,
                transactionCount: summary.incomeTransactionCount,
                averageTransaction: summary.incomeTransactionCount == 0
                    ? 0
                    : summary.totalReceived / summary.incomeTransactionCount,
              ),
              const SizedBox(height: 16),
              _ActivityCard(transactions: summary.recentTransactions),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DashboardStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 232;

  @override
  double get maxExtent => 232;

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
    return false;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

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
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MoneyMovementCard extends StatelessWidget {
  final FinancialSummary summary;

  const _MoneyMovementCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  amount: summary.totalReceived,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF0F9D8A),
                  amountColor: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MovementMetric(
                  label: 'Sent',
                  amount: summary.totalSent,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFD95C5C),
                  amountColor: Colors.red.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
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
                    Text(
                      _money(summary.internalTransfers),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color.fromARGB(255, 69, 70, 71),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InternalTransferMetric(
                        label: 'In',
                        amount: summary.internalTransfersIn,
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFF0F9D8A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InternalTransferMetric(
                        label: 'Out',
                        amount: summary.internalTransfersOut,
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFD95C5C),
                      ),
                    ),
                  ],
                ),
              ],
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
              Text(
                _money(amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: amountColor,
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

    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          _money(amount),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color.fromARGB(255, 69, 70, 71),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final FinancialSummary summary;

  const _OverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Overview', icon: Icons.insights_rounded),
          const SizedBox(height: 18),

          _OverviewRow(
            label: 'Income',
            amount: summary.totalIncome,
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF0F9D8A),
            amountColor: const Color(0xFF0F9D8A),
          ),
          _OverviewRow(
            label: 'Expenses',
            amount: summary.totalExpenses,
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFFD95C5C),
            amountColor: const Color(0xFFD95C5C),
          ),
          _OverviewRow(
            label: 'Fees',
            amount: summary.totalFees,
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF687486),
            amountColor: const Color.fromARGB(255, 69, 70, 71),
          ),
          _OverviewRow(
            label: 'Net movement',
            amount: summary.netMovement,
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF0B1F3A),
            amountColor: const Color.fromARGB(255, 69, 70, 71),
            isLast: true,
          ),

          if (summary.spendingBySubtype.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SubsectionTitle(title: 'Expense categories'),
            const SizedBox(height: 10),
            ..._sortedCategories(summary.spendingBySubtype)
                .take(4)
                .map(
                  (entry) =>
                      _CategoryRow(subtype: entry.key, amount: entry.value),
                ),
          ],

          if (summary.moneyInBySubtype.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SubsectionTitle(title: 'Money-in categories'),
            const SizedBox(height: 10),
            ..._sortedCategories(summary.moneyInBySubtype)
                .take(4)
                .map(
                  (entry) => _CategoryRow(
                    subtype: entry.key,
                    amount: entry.value,
                    isIncome: true,
                  ),
                ),
          ],
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
          Text(
            _money(amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  final String title;

  const _SubsectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final RecordSubtype subtype;
  final double amount;
  final bool isIncome;

  const _CategoryRow({
    required this.subtype,
    required this.amount,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isIncome
                  ? const Color(0xFF0F9D8A)
                  : const Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _subtypeLabel(subtype),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _money(amount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF0B1F3A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPartyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PartySummary> parties;
  final bool isExpense;
  final int partyCount;
  final int transactionCount;
  final double averageTransaction;

  const _TopPartyCard({
    required this.title,
    required this.subtitle,
    required this.parties,
    required this.isExpense,
    required this.partyCount,
    required this.transactionCount,
    required this.averageTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                isExpense ? '$partyCount merchants' : '$partyCount sources',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Avg. transaction ${_money(averageTransaction)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (parties.isEmpty)
            const _EmptyPartyState()
          else
            ...List.generate(
              parties.length,
              (index) => Column(
                children: [
                  _PartyRow(
                    summary: parties[index],
                    rank: index + 1,
                    isExpense: isExpense,
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
            child: ElevatedButton.icon(
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
              onPressed: () {
                // Breakdown screen
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(
                isExpense
                    ? 'View all Expenses ($transactionCount)'
                    : 'View all Income ($transactionCount)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final PartySummary summary;
  final int rank;
  final bool isExpense;

  const _PartyRow({
    required this.summary,
    required this.rank,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = summary.party;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _PartyAvatar(party: party),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0B1F3A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.transactionCount} '
                  '${summary.transactionCount == 1 ? 'transaction' : 'transactions'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '-' : '+'}${_money(summary.amount)}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isExpense
                  ? const Color(0xFFD95C5C)
                  : const Color(0xFF0F9D8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyAvatar extends StatelessWidget {
  final Party party;

  const _PartyAvatar({required this.party});

  @override
  Widget build(BuildContext context) {
    final letter = party.name.trim().isEmpty
        ? '?'
        : party.name.trim()[0].toUpperCase();

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

class _ActivityCard extends StatelessWidget {
  final List<FinancialRecord> transactions;

  const _ActivityCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Recent activity', icon: Icons.bolt_rounded),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Text(
              'No transactions for this period.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            )
          else
            ...transactions.map(
              (transaction) => _ActivityRow(transaction: transaction),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final FinancialRecord transaction;

  const _ActivityRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type.name == 'income';

    final color = isIncome ? const Color(0xFF0F9D8A) : const Color(0xFF0B1F3A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1F3A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.subtype.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_money(transaction.amount)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CardHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF0B1F3A)),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1F3A),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(18),
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

List<MapEntry<RecordSubtype, double>> _sortedCategories(
  Map<RecordSubtype, double> categories,
) {
  final entries = categories.entries.toList();

  entries.sort((a, b) => b.value.compareTo(a.value));

  return entries;
}

String _subtypeLabel(RecordSubtype subtype) {
  switch (subtype) {
    case RecordSubtype.sendMoney:
      return 'Send Money';

    case RecordSubtype.receiveMoney:
      return 'Received';

    case RecordSubtype.buyGoods:
      return 'Buy Goods';

    case RecordSubtype.airtimePurchase:
      return 'Airtime';

    case RecordSubtype.payBill:
      return 'PayBill';

    case RecordSubtype.withdrawal:
      return 'Cash withdrawal';

    case RecordSubtype.deposit:
      return 'Cash deposit';

    case RecordSubtype.mshwariDeposit:
      return 'M-Shwari deposit';

    case RecordSubtype.mshwariWithdrawal:
      return 'M-Shwari withdrawal';

    case RecordSubtype.kcbDeposit:
      return 'KCB M-PESA deposit';

    case RecordSubtype.kcbWithdrawal:
      return 'KCB M-PESA withdrawal';

    case RecordSubtype.fulizaLoan:
      return 'Fuliza';

    case RecordSubtype.fulizaRepayment:
      return 'Fuliza repayment';

    case RecordSubtype.investmentPurchase:
      return 'Investment';

    case RecordSubtype.investmentRedemption:
      return 'Investment redemption';

    case RecordSubtype.unknown:
      return 'Other';
    case RecordSubtype.airtimeTopUp:
      return 'Airtime top-up';
    case RecordSubtype.loanRepayment:
      return 'Loan repayment';
    case RecordSubtype.loanDisbursement:
      return 'Loan disbursement';
    case RecordSubtype.savingsDeposit:
      return 'Savings deposit';
    case RecordSubtype.savingsWithdrawal:
      return 'Savings withdrawal';
    case RecordSubtype.billPayment:
      return 'Bill payment';
  }
}

String _money(double amount) {
  final value = amount.round();

  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  return 'KSh $formatted';
}
