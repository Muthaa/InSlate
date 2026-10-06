import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/record_subtype.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_breakdown.dart';
import '../../models/financial_period.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/financial_summary_provider.dart';
import '../../services/financial_semantics.dart';
import '../../widgets/financial_group_row.dart';
import '../activity/activity_screen.dart';

/// Legacy callers supply a display name; resolve matching identity groups
/// without merging them. New callers can supply the exact PartyIdentity.
class PartyTransactionsScreen extends ConsumerStatefulWidget {
  final RecordSubtype subtype;
  final String partyName;
  final bool isIncome;
  final PartyIdentity? party;
  final FinancialPeriod? period;
  const PartyTransactionsScreen({
    super.key,
    required this.subtype,
    required this.partyName,
    required this.isIncome,
    this.party,
    this.period,
  });
  @override
  ConsumerState<PartyTransactionsScreen> createState() =>
      _PartyTransactionsScreenState();
}

class _PartyTransactionsScreenState
    extends ConsumerState<PartyTransactionsScreen> {
  late final ActivityFilter _filter;
  @override
  void initState() {
    super.initState();
    _filter = ActivityFilter(
      period:
          widget.period ??
          FinancialPeriod.month(ref.read(selectedMonthProvider)),
      scope: widget.isIncome ? ActivityScope.income : ActivityScope.expenses,
      subtype: widget.subtype,
      party: widget.party,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.party != null) return ActivityScreen(initialFilter: _filter);
    final query = (
      kind: widget.isIncome
          ? BreakdownKind.incomeParties
          : BreakdownKind.expenseParties,
      filter: _filter,
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.partyName)),
      body: ref
          .watch(financialBreakdownProvider(query))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(periodRecordsProvider(_filter.period)),
                child: const Text('Retry'),
              ),
            ),
            data: (breakdown) {
              final groups = breakdown.groups
                  .where((group) => group.label == widget.partyName.trim())
                  .toList();
              if (groups.isEmpty) {
                return const Center(
                  child: Text(
                    'No identified party matches this name for the period.',
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Choose a party to view its transactions.'),
                  for (final group in groups)
                    FinancialGroupRow(
                      group: group,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActivityScreen(initialFilter: group.filter),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}
