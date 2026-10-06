import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_breakdown.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../services/financial_semantics.dart';
import '../../core/enums/record_subtype.dart';
import '../../widgets/financial_group_row.dart';
import '../activity/activity_screen.dart';

String breakdownTitle(BreakdownKind kind) => switch (kind) {
  BreakdownKind.spending => 'Expense categories',
  BreakdownKind.incomeCategories => 'Income categories',
  BreakdownKind.expenseParties => 'Expense breakdown',
  BreakdownKind.incomeParties => 'Income breakdown',
  BreakdownKind.internalMovement => 'Internal movement',
  BreakdownKind.loans => 'Loan breakdown',
  BreakdownKind.investmentsAndSavings => 'Investments & savings',
  BreakdownKind.investmentPurchases => 'Investment purchases',
  BreakdownKind.investmentRedemptions => 'Investment redemptions',
  BreakdownKind.savingsDeposits => 'Savings deposits',
  BreakdownKind.savingsWithdrawals => 'Savings withdrawals',
};

class FinancialBreakdownScreen extends ConsumerWidget {
  final BreakdownKind kind;
  final ActivityFilter filter;
  const FinancialBreakdownScreen({
    super.key,
    required this.kind,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (kind: kind, filter: filter);
    final result = ref.watch(financialBreakdownProvider(query));
    final categories =
        kind == BreakdownKind.spending ||
        kind == BreakdownKind.incomeCategories;
    final parties =
        kind == BreakdownKind.expenseParties ||
        kind == BreakdownKind.incomeParties;
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(breakdownTitle(kind)),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load this breakdown.'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(periodRecordsProvider(filter.period)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (breakdown) => categories || parties
              ? _FinancialGroupingContent(
                  breakdown: breakdown,
                  expense:
                      kind == BreakdownKind.spending ||
                      kind == BreakdownKind.expenseParties,
                  parties: parties,
                  onSelect: (group) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => parties
                          ? ActivityScreen(initialFilter: group.filter)
                          : FinancialBreakdownScreen(
                              kind: kind == BreakdownKind.spending
                                  ? BreakdownKind.expenseParties
                                  : BreakdownKind.incomeParties,
                              filter: group.filter,
                            ),
                    ),
                  ),
                )
              : _AccountMovementContent(
                  breakdown: breakdown,
                  onSelect: (group) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ActivityScreen(initialFilter: group.filter),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AccountMovementContent extends StatelessWidget {
  final FinancialBreakdown breakdown;
  final ValueChanged<FinancialGroup> onSelect;
  const _AccountMovementContent({
    required this.breakdown,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final internal = breakdown.kind == BreakdownKind.internalMovement;
    final loans = breakdown.kind == BreakdownKind.loans;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          periodLabel(breakdown.filter.period),
          style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.darkBlue),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.darkBlue.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    loans
                        ? Icons.account_balance_outlined
                        : internal
                        ? Icons.swap_horiz_rounded
                        : Icons.savings_outlined,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      internal
                          ? 'Total internal movement'
                          : loans
                          ? 'Total loan activity'
                          : 'Total contributions & withdrawals',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(breakdown.amount),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${breakdown.count} transactions',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 28),
              Text(
                'Recorded fees · ${formatMoney(breakdown.fees)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                internal
                    ? 'Transfers between your accounts, not income or expenses. Amounts exclude fees.'
                    : loans
                    ? 'Borrowed and repaid activity; this is not an outstanding balance.'
                    : 'Contributions and withdrawals only; no account or portfolio value is inferred.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loans
              ? 'Borrowing & repayments'
              : internal
              ? 'Movement by account'
              : 'Savings & investment instruments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loans
              ? 'Choose a loan group to view its transactions.'
              : 'Choose an account group to view its transactions.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        if (breakdown.sections.every((section) => section.groups.isEmpty))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No activity found for this period.'),
          ),
        for (final section in breakdown.sections)
          _AccountMovementSection(
            section: section,
            onSelect: onSelect,
            highlightMovement: !internal && !loans,
          ),
      ],
    );
  }
}

TransferDirection? _groupDirection(FinancialGroup group) =>
    group.filter.direction ??
    switch (group.filter.subtype) {
      RecordSubtype.fulizaLoan ||
      RecordSubtype.loanDisbursement => TransferDirection.intoCentral,
      RecordSubtype.fulizaRepayment ||
      RecordSubtype.loanRepayment => TransferDirection.fromCentral,
      _ => null,
    };

Color _directionColor(TransferDirection? direction) => switch (direction) {
  TransferDirection.intoCentral => Colors.green.shade700,
  TransferDirection.fromCentral => Colors.red.shade700,
  _ => AppTheme.darkBlue,
};

class _AccountMovementSection extends StatelessWidget {
  final BreakdownSection section;
  final ValueChanged<FinancialGroup> onSelect;
  final bool highlightMovement;
  const _AccountMovementSection({
    required this.section,
    required this.onSelect,
    this.highlightMovement = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstDirection = section.groups.isEmpty
        ? null
        : _groupDirection(section.groups.first);
    final direction =
        section.groups.every(
          (group) => _groupDirection(group) == firstDirection,
        )
        ? firstDirection
        : null;
    final accent = _directionColor(direction);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    switch (direction) {
                      TransferDirection.intoCentral => Icons.south_west_rounded,
                      TransferDirection.fromCentral => Icons.north_east_rounded,
                      _ => Icons.swap_horiz_rounded,
                    },
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoney(section.amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${section.count} transactions${section.includedInTotal ? '' : ' · Excluded from total'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),
            if (section.groups.isEmpty)
              const Text('No activity for this group.'),
            for (final group in section.groups)
              if (highlightMovement)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _directionColor(
                      _groupDirection(group),
                    ).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        switch (_groupDirection(group)) {
                          TransferDirection.intoCentral =>
                            Icons.south_west_rounded,
                          TransferDirection.fromCentral =>
                            Icons.north_east_rounded,
                          _ => Icons.swap_horiz_rounded,
                        },
                        size: 18,
                        color: _directionColor(_groupDirection(group)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FinancialGroupRow(
                          group: group,
                          compact: true,
                          accentColor: _directionColor(_groupDirection(group)),
                          onTap: () => onSelect(group),
                        ),
                      ),
                    ],
                  ),
                )
              else
                FinancialGroupRow(
                  group: group,
                  compact: true,
                  accentColor: _directionColor(_groupDirection(group)),
                  onTap: () => onSelect(group),
                ),
          ],
        ),
      ),
    );
  }
}

class _FinancialGroupingContent extends StatelessWidget {
  final FinancialBreakdown breakdown;
  final bool expense;
  final bool parties;
  final ValueChanged<FinancialGroup> onSelect;
  const _FinancialGroupingContent({
    required this.breakdown,
    required this.expense,
    this.parties = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = expense ? Colors.red.shade700 : Colors.green.shade700;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppTheme.darkBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                periodLabel(breakdown.filter.period),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (parties && breakdown.filter.subtype != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subtypeLabel(breakdown.filter.subtype!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      expense
                          ? Icons.north_east_rounded
                          : Icons.south_west_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      expense ? 'Total expenses' : 'Total income',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatMoney(breakdown.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '${breakdown.count} transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  Text(
                    '${breakdown.groups.length} ${parties ? 'party groups' : 'categories'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Text(
                'Recorded fees · ${formatMoney(breakdown.fees)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                parties
                    ? 'Party amounts exclude fees.'
                    : 'Category amounts and shares exclude fees.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                parties
                    ? (expense ? 'People & businesses' : 'Income sources')
                    : 'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
            Text(
              'Largest first',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          parties
              ? 'Choose a party to view its transactions.'
              : 'Choose a category to see people and businesses.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 14),
        if (breakdown.groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 32, color: accent),
                const SizedBox(height: 12),
                const Text(
                  'No activity found for this period.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        for (final group in breakdown.groups)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: InkWell(
              onTap: () => onSelect(group),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  if (parties) ...[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: group.filter.party == null
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: accent,
                            )
                          : Text(
                              group.label.trim().isEmpty
                                  ? '?'
                                  : group.label
                                        .trim()
                                        .characters
                                        .first
                                        .toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FinancialGroupRow(
                      group: group,
                      showShare: !parties,
                      compact: true,
                      accentColor: accent,
                      onTap: () => onSelect(group),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
