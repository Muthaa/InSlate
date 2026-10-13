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
  final String? sectionLabel;
  const FinancialBreakdownScreen({
    super.key,
    required this.kind,
    required this.filter,
    this.sectionLabel,
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
        title: Text(
          sectionLabel == null
              ? breakdownTitle(kind)
              : '$sectionLabel breakdown',
        ),
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
                          ? ActivityScreen(
                              preserveDrillDown: true,
                              initialFilter: group.filter,
                            )
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
                  breakdown: sectionLabel == null
                      ? breakdown
                      : FinancialBreakdown(
                          kind: breakdown.kind,
                          filter: breakdown.filter,
                          sections:
                              sectionLabel == 'Investments' ||
                                  sectionLabel == 'Savings'
                              ? [
                                  BreakdownSection(
                                    sectionLabel == 'Investments'
                                        ? 'Purchases'
                                        : 'Deposits',
                                    breakdown.sections
                                        .where(
                                          (section) =>
                                              section.label == sectionLabel,
                                        )
                                        .expand((section) => section.groups)
                                        .where(
                                          (group) =>
                                              group.filter.direction ==
                                              TransferDirection.fromCentral,
                                        ),
                                  ),
                                  BreakdownSection(
                                    sectionLabel == 'Investments'
                                        ? 'Redemptions'
                                        : 'Withdrawals',
                                    breakdown.sections
                                        .where(
                                          (section) =>
                                              section.label == sectionLabel,
                                        )
                                        .expand((section) => section.groups)
                                        .where(
                                          (group) =>
                                              group.filter.direction ==
                                              TransferDirection.intoCentral,
                                        ),
                                  ),
                                ]
                              : breakdown.sections.where(
                                  (section) => section.label == sectionLabel,
                                ),
                        ),
                  allowSectionNavigation: sectionLabel == null,
                  onSelect: (group) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityScreen(
                        preserveDrillDown: true,
                        initialFilter: group.filter,
                      ),
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
  final bool allowSectionNavigation;
  const _AccountMovementContent({
    required this.breakdown,
    required this.onSelect,
    this.allowSectionNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final internal = breakdown.kind == BreakdownKind.internalMovement;
    final loans = breakdown.kind == BreakdownKind.loans;
    final compactTotals = switch (breakdown.kind) {
      BreakdownKind.investmentPurchases ||
      BreakdownKind.investmentRedemptions ||
      BreakdownKind.savingsDeposits ||
      BreakdownKind.savingsWithdrawals => true,
      _ => false,
    };
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
                          ? 'Loan activity'
                          : breakdown.kind ==
                                BreakdownKind.investmentsAndSavings
                          ? 'Savings & investment activity'
                          : 'Total contributions & withdrawals',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (!loans &&
                  breakdown.kind != BreakdownKind.investmentsAndSavings) ...[
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatMoney(breakdown.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: compactTotals ? 20 : null,
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
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
            showTotal: breakdown.kind != BreakdownKind.investmentsAndSavings,
            totalFontSize: compactTotals ? 18 : null,
            onOpen:
                allowSectionNavigation &&
                    breakdown.kind == BreakdownKind.investmentsAndSavings &&
                    (section.label == 'Savings' ||
                        section.label == 'Investments')
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => FinancialBreakdownScreen(
                        kind: breakdown.kind,
                        filter: breakdown.filter,
                        sectionLabel: section.label,
                      ),
                    ),
                  )
                : null,
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
  final bool showTotal;
  final double? totalFontSize;
  final VoidCallback? onOpen;
  const _AccountMovementSection({
    required this.section,
    required this.onSelect,
    this.highlightMovement = false,
    this.showTotal = true,
    this.totalFontSize,
    this.onOpen,
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
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      switch (direction) {
                        TransferDirection.intoCentral =>
                          Icons.south_west_rounded,
                        TransferDirection.fromCentral =>
                          Icons.north_east_rounded,
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
                  if (onOpen != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.darkBlue,
                    ),
                ],
              ),
            ),
            if (showTotal) ...[
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(section.amount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize:
                        totalFontSize ??
                        (section.label == 'Borrowed' ||
                                section.label == 'Repaid'
                            ? 19
                            : null),
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
                  amountStyle:
                      section.label == 'Borrowed' || section.label == 'Repaid'
                      ? TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _directionColor(_groupDirection(group)),
                        )
                      : null,
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
            IconButton(
              tooltip: expense ? 'About expenses' : 'About income',
              icon: const Icon(Icons.info_outline, color: AppTheme.darkBlue),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) =>
                    _BreakdownInformationDialog(expense: expense),
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize:
                          (theme.textTheme.titleLarge?.fontSize ?? 20) - 2,
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
                      showShare:
                          !parties && breakdown.amount > 0 && group.amount >= 0,
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

class _BreakdownInformationDialog extends StatelessWidget {
  final bool expense;
  const _BreakdownInformationDialog({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = expense ? Colors.red.shade700 : Colors.green.shade700;
    final details = expense
        ? [
            (
              'What is included',
              'Ordinary expense principal, reduced by approved PayBill reversals on their reversal dates.',
            ),
            (
              'Fees stay separate',
              'Fees are excluded from expense totals and deducted once in net cash flow.',
            ),
          ]
        : [
            (
              'What is included',
              'Ordinary incoming funds for the selected period. Fees are shown separately.',
            ),
            (
              'What is excluded',
              'Loan principal, internal transfers, savings and investment movements, and returned PayBill principal.',
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
            child: Icon(
              expense ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expense ? 'About expenses' : 'About income',
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
                    Icons.insights_outlined,
                    size: 18,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Purpose-category totals are available in Insights.',
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
