import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/enums/record_subtype.dart';
import '/models/financial_records.dart';
import '/providers/financial_records_provider.dart';
import '/providers/financial_summary_provider.dart';

class PartyTransactionsScreen extends ConsumerWidget {
  final RecordSubtype subtype;
  final String partyName;
  final bool isIncome;

  const PartyTransactionsScreen({
    super.key,
    required this.subtype,
    required this.partyName,
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
        title: Text(
          partyName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B1F3A),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              const Center(child: Text('Unable to load transactions.')),
          data: (records) {
            final filtered = records.where((record) {
              final date = record.transactionDate ?? record.receivedAt;

              final recordParty = record.party?.name.trim().isNotEmpty == true
                  ? record.party!.name.trim()
                  : record.title;

              return date.year == selectedMonth.year &&
                  date.month == selectedMonth.month &&
                  record.subtype == subtype &&
                  recordParty == partyName;
            }).toList();

            filtered.sort((a, b) {
              final aDate = a.transactionDate ?? a.receivedAt;
              final bDate = b.transactionDate ?? b.receivedAt;

              return bDate.compareTo(aDate);
            });

            return _PartyTransactionsContent(
              records: filtered,
              accentColor: accentColor,
              periodLabel:
                  '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
            );
          },
        ),
      ),
    );
  }
}

class _PartyTransactionsContent extends StatelessWidget {
  final List<FinancialRecord> records;
  final Color accentColor;
  final String periodLabel;

  const _PartyTransactionsContent({
    required this.records,
    required this.accentColor,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No transactions found for this period.'),
      );
    }

    final total = records.fold<double>(0, (sum, record) => sum + record.amount);

    final fees = records.fold<double>(
      0,
      (sum, record) => sum + record.transactionCost,
    );

    final grouped = <String, List<FinancialRecord>>{};
    for (final record in records) {
      final date = record.transactionDate ?? record.receivedAt;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final header = Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              periodLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Transactions', value: '${records.length}'),
              ),
              Expanded(
                child: _Stat(
                  label: 'Total',
                  value: _money(total),
                  color: accentColor,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Fees',
                  value: _money(fees),
                  color: const Color(0xFF687486),
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
          delegate: _PartyHeaderDelegate(header: header, height: 100),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = grouped.entries.elementAt(index);
              final date =
                  entry.value.first.transactionDate ??
                  entry.value.first.receivedAt;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0B1F3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (
                            int transactionIndex = 0;
                            transactionIndex < entry.value.length;
                            transactionIndex++
                          ) ...[
                            _TransactionRow(
                              record: entry.value[transactionIndex],
                              accentColor: accentColor,
                            ),
                            if (transactionIndex < entry.value.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: grouped.length),
          ),
        ),
      ],
    );
  }
}

class _PartyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget header;
  final double height;

  const _PartyHeaderDelegate({required this.header, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: header);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PartyHeaderDelegate oldDelegate) {
    return oldDelegate.header != header || oldDelegate.height != height;
  }
}

class _TransactionRow extends StatelessWidget {
  final FinancialRecord record;
  final Color accentColor;

  const _TransactionRow({required this.record, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final date = record.transactionDate ?? record.receivedAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              _formatTime(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.reference,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
                if (record.transactionCost > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Fee ${_money(record.transactionCost)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(record.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color ?? const Color(0xFF0B1F3A),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
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

String _money(double amount) {
  final value = amount.round();

  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  return 'KSh $formatted';
}
