import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_period.dart';
import '../../models/instrument_history.dart';
import '../../providers/instrument_history_provider.dart';
import '../../widgets/transaction_row.dart';
import '../activity/transaction_detail_screen.dart';

class InstrumentActivitySection extends ConsumerStatefulWidget {
  final int accountId;
  const InstrumentActivitySection({super.key, required this.accountId});
  @override
  ConsumerState<InstrumentActivitySection> createState() =>
      _InstrumentActivitySectionState();
}

class _InstrumentActivitySectionState
    extends ConsumerState<InstrumentActivitySection>
    with AutomaticKeepAliveClientMixin {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _page = 0;
  @override
  bool get wantKeepAlive => true;
  InstrumentHistoryQuery get _query => (
    accountId: widget.accountId,
    period: FinancialPeriod.month(_month),
    page: _page,
  );

  Future<void> _open(int recordId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(recordId: recordId),
      ),
    );
    if (!mounted) return;
    // Refresh only this instrument's bounded query and month keys. Activity and
    // Dashboard dependencies are deliberately untouched.
    ref.invalidate(instrumentHistoryProvider(_query));
    ref.invalidate(instrumentHistoryMonthsProvider(widget.accountId));
  }

  String _role(InstrumentTransactionRole role) => switch (role) {
    InstrumentTransactionRole.incoming => 'Incoming (destination)',
    InstrumentTransactionRole.outgoing => 'Outgoing (source)',
    InstrumentTransactionRole.selfLinked =>
      'Self-linked (source and destination)',
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(instrumentHistoryProvider(_query), (_, next) {
      final actualPage = next.asData?.value.page;
      if (actualPage != null && actualPage != _page) {
        setState(() => _page = actualPage);
      }
    });
    final months = ref.watch(instrumentHistoryMonthsProvider(widget.accountId));
    final options = {
      ...?months.valueOrNull,
      _month,
      DateTime(DateTime.now().year, DateTime.now().month),
    }.toList()..sort((a, b) => b.compareTo(a));
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DateTime>(
                    key: const ValueKey('instrument.history.period'),
                    initialValue: _month,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final month in options)
                        DropdownMenuItem(
                          value: month,
                          child: Text(DateFormat.yMMMM().format(month)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _month = value;
                          _page = 0;
                        });
                      }
                    },
                  ),
                  if (months.hasError)
                    TextButton(
                      onPressed: () => ref.invalidate(
                        instrumentHistoryMonthsProvider(widget.accountId),
                      ),
                      child: const Text('Unable to load periods. Retry'),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Directions refer to this instrument. Transaction classifications retain their recorded meaning.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ref
                .watch(instrumentHistoryProvider(_query))
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => TextButton(
                    onPressed: () =>
                        ref.invalidate(instrumentHistoryProvider(_query)),
                    child: const Text(
                      'Unable to load linked transactions. Retry',
                    ),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${data.count} linked transactions',
                          key: const ValueKey('instrument.history.count'),
                        ),
                      ),
                      if (data.entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No linked transactions in this period.'),
                        ),
                      for (final entry in data.entries)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Text(
                                '${DateFormat.yMMMd().format(entry.record.transactionDate ?? entry.record.receivedAt)} - ${_role(entry.role)}',
                                key: ValueKey(
                                  'instrument.history.role.${entry.record.id}',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                            ),
                            TransactionRow(
                              key: ValueKey(
                                'instrument.history.record.${entry.record.id}',
                              ),
                              record: entry.record,
                              onTap: () => _open(entry.record.id!),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                      if (data.count > 0)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                'Page ${data.page + 1} of ${data.totalPages}',
                                key: const ValueKey('instrument.history.page'),
                              ),
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: data.page == 0
                                        ? null
                                        : () => setState(() => _page = 0),
                                    child: const Text('First'),
                                  ),
                                  TextButton(
                                    onPressed: data.page == 0
                                        ? null
                                        : () => setState(
                                            () => _page = data.page - 1,
                                          ),
                                    child: const Text('Previous'),
                                  ),
                                  TextButton(
                                    onPressed: data.page + 1 >= data.totalPages
                                        ? null
                                        : () => setState(
                                            () => _page = data.page + 1,
                                          ),
                                    child: const Text('Next'),
                                  ),
                                  TextButton(
                                    onPressed: data.page + 1 >= data.totalPages
                                        ? null
                                        : () => setState(
                                            () => _page = data.totalPages - 1,
                                          ),
                                    child: const Text('Last'),
                                  ),
                                ],
                              ),
                            ],
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
