import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/financial_summary_provider.dart';
import '/core/enums/record_subtype.dart';
import '/models/financial_records.dart';
import '/providers/financial_records_provider.dart';
// import '/providers/app_preferences_provider.dart';
import 'party_transactions_screen.dart';

class CategoryTransactionsScreen extends ConsumerWidget {
  final RecordSubtype subtype;
  final bool isIncome;

  const CategoryTransactionsScreen({
    super.key,
    required this.subtype,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);

    final recordsAsync = ref.watch(financialRecordsProvider);

    final accentColor = isIncome
        ? const Color(0xFF1E8E5A)
        : const Color(0xFFCC4A4A);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            isIncome ? 'INCOME' : 'EXPENSE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: accentColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFEC1C24)),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Unable to load transactions.')),
          data: (records) {
            final filtered = records.where((record) {
              final date = record.transactionDate ?? record.receivedAt;

              return date.year == selectedMonth.year &&
                  date.month == selectedMonth.month &&
                  record.subtype == subtype;
            }).toList();

            filtered.sort((a, b) {
              final aDate = a.transactionDate ?? a.receivedAt;
              final bDate = b.transactionDate ?? b.receivedAt;

              return bDate.compareTo(aDate);
            });

            final grouped = <String, List<FinancialRecord>>{};

            for (final record in filtered) {
              final partyName = record.party?.name.trim().isNotEmpty == true
                  ? record.party!.name.trim()
                  : record.title;

              grouped.putIfAbsent(partyName, () => []).add(record);
            }

            return _CategoryContent(
              groups: grouped,
              subtype: subtype,
              isIncome: isIncome,
              category: _subtypeLabel(subtype),
              periodLabel:
                  '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
            );
          },
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HeaderStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0B1F3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryContent extends StatelessWidget {
  final Map<String, List<FinancialRecord>> groups;
  final RecordSubtype subtype;
  final bool isIncome;
  final String category;
  final String periodLabel;

  const _CategoryContent({
    required this.groups,
    required this.subtype,
    required this.isIncome,
    required this.category,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: Text('No transactions found for this period.'),
      );
    }

    final totalAmount = groups.values
        .expand((transactions) => transactions)
        .fold<double>(0, (sum, record) => sum + record.amount);

    final totalFees = groups.values
        .expand((transactions) => transactions)
        .fold<double>(0, (sum, record) => sum + record.transactionCost);

    final sortedGroups = groups.entries.toList()
      ..sort((first, second) {
        final firstTotal = first.value.fold<double>(
          0,
          (sum, record) => sum + record.amount + record.transactionCost,
        );
        final secondTotal = second.value.fold<double>(
          0,
          (sum, record) => sum + record.amount + record.transactionCost,
        );

        return secondTotal.compareTo(firstTotal);
      });

    final header = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(label: 'Source', value: '${groups.length}'),
              ),
              Expanded(
                child: _HeaderStat(
                  label: 'Total',
                  value: _money(totalAmount),
                  valueColor: isIncome
                      ? const Color(0xFF1E8E5A)
                      : const Color(0xFFCC4A4A),
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  label: 'Fees',
                  value: _money(totalFees),
                  valueColor: const Color(0xFF687486),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(header: header, height: 96),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = sortedGroups[index];
              final transactions = entry.value;

              final total = transactions.fold<double>(
                0,
                (sum, record) => sum + record.amount + record.transactionCost,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartyTransactionsScreen(
                            subtype: subtype,
                            partyName: entry.key,
                            isIncome: isIncome,
                          ),
                        ),
                      );
                    },
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _money(total),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isIncome
                                ? const Color(0xFF0F9D8A)
                                : const Color(0xFFD95C5C),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: sortedGroups.length),
          ),
        ),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget header;
  final double height;

  const _CategoryHeaderDelegate({required this.header, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: header,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.header != header || oldDelegate.height != height;
  }
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}

String _subtypeLabel(RecordSubtype subtype) {
  switch (subtype) {
    case RecordSubtype.sendMoney:
      return 'Send Money';
    case RecordSubtype.receiveMoney:
      return 'Received';
    case RecordSubtype.buyGoods:
      return 'Buy Goods';
    case RecordSubtype.payBill:
      return 'PayBill';
    case RecordSubtype.airtimePurchase:
      return 'Airtime';
    case RecordSubtype.deposit:
      return 'Cash deposit';
    case RecordSubtype.withdrawal:
      return 'Cash withdrawal';
    default:
      return subtype.name;
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
