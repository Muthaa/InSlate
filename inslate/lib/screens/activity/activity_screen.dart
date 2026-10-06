import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/enums/account_type.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_period.dart';
import '../../providers/activity_provider.dart';
import '../../services/financial_semantics.dart';
import '../../widgets/transaction_row.dart';

/// The same entry point can be pushed with a typed Dashboard drill-down filter.
class ActivityScreen extends StatelessWidget {
  final ActivityFilter? initialFilter;
  const ActivityScreen({super.key, this.initialFilter});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(title: const Text('Activity')),
    body: ActivityContent(initialFilter: initialFilter),
  );
}

/// Reusable filtered explorer, independent of shell navigation and Dashboard state.
class ActivityContent extends ConsumerStatefulWidget {
  final ActivityFilter? initialFilter;
  const ActivityContent({super.key, this.initialFilter});
  @override
  ConsumerState<ActivityContent> createState() => _ActivityContentState();
}

class _ActivityContentState extends ConsumerState<ActivityContent> {
  late ActivityFilter _filter;
  int _page = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filter =
        widget.initialFilter ??
        ActivityFilter(period: FinancialPeriod.month(DateTime.now()));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeFilter(ActivityFilter filter) {
    setState(() {
      _filter = filter;
      _page = 0;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _selectRange(Set<DateTime> months) async {
    final now = DateTime.now();
    final earliest = [...months, _filter.period.start, now]..sort();
    final latest = [
      ...months.map((month) => DateTime(month.year, month.month + 1, 0)),
      _filter.period.end.subtract(const Duration(days: 1)),
      now,
    ]..sort();
    final range = await showDateRangePicker(
      context: context,
      firstDate: earliest.first,
      lastDate: latest.last,
      initialDateRange: DateTimeRange(
        start: _filter.period.start,
        end: _filter.period.end.subtract(const Duration(microseconds: 1)),
      ),
    );
    if (range != null && mounted) {
      _changeFilter(
        _filter.withPeriod(
          FinancialPeriod(
            range.start,
            DateTime(range.end.year, range.end.month, range.end.day + 1),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(financialDataRevisionProvider, (_, next) {
      if (_page != 0) {
        setState(() => _page = 0);
        _scrollToTop();
      }
    });
    final monthsAsync = ref.watch(activityMonthsProvider);
    final months = monthsAsync.valueOrNull ?? <DateTime>{};
    final periods = {
      ...months.map(FinancialPeriod.month),
      FinancialPeriod.month(DateTime.now()),
      _filter.period,
    }.toList()..sort((a, b) => b.start.compareTo(a.start));
    final query = (filter: _filter, page: _page);
    final pageAsync = ref.watch(activityPageProvider(query));
    final centralLabel = accountLabel(_filter.central.type);
    final hasDetailedFilter =
        _filter.partyPresence != null ||
        _filter.resolution != null ||
        _filter.subtype != null ||
        _filter.party != null ||
        _filter.endpoint != null ||
        _filter.direction != null;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FinancialPeriod>(
                      isExpanded: true,
                      value: _filter.period,
                      items: periods
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Text(
                                periodLabel(period),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (period) {
                        if (period != null) {
                          _changeFilter(_filter.withPeriod(period));
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Choose date range',
                  onPressed: () => _selectRange(months),
                  icon: const Icon(Icons.date_range_outlined),
                ),
                IconButton(
                  tooltip: 'Refresh activity',
                  onPressed: () {
                    ref.read(financialDataRevisionProvider.notifier).state++;
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          if (monthsAsync.hasError)
            TextButton(
              onPressed: () => ref.invalidate(activityMonthsProvider),
              child: const Text('Unable to load available months. Retry'),
            ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: ActivityScope.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final scope = ActivityScope.values[index];
                return ChoiceChip(
                  label: Text(scopeLabel(scope)),
                  selected: scope == _filter.scope,
                  onSelected: (_) => _changeFilter(_filter.withScope(scope)),
                );
              },
            ),
          ),
          if (_filter.scope == ActivityScope.internalTransfers ||
              _filter.scope == ActivityScope.investmentsAndSavings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<TransferDirection>(
                      isExpanded: true,
                      value: _filter.direction,
                      hint: const Text('All directions'),
                      items: [
                        const DropdownMenuItem<TransferDirection>(
                          value: null,
                          child: Text('All directions'),
                        ),
                        DropdownMenuItem(
                          value: TransferDirection.intoCentral,
                          child: Text('Into $centralLabel'),
                        ),
                        DropdownMenuItem(
                          value: TransferDirection.fromCentral,
                          child: Text('From $centralLabel'),
                        ),
                        if (_filter.direction == TransferDirection.unrelated)
                          const DropdownMenuItem(
                            value: TransferDirection.unrelated,
                            child: Text('Between other accounts'),
                          ),
                        if (_filter.direction == TransferDirection.unresolved)
                          const DropdownMenuItem(
                            value: TransferDirection.unresolved,
                            child: Text('Unresolved direction'),
                          ),
                      ],
                      onChanged: (direction) => _changeFilter(
                        ActivityFilter(
                          period: _filter.period,
                          scope: _filter.scope,
                          subtype: _filter.subtype,
                          party: _filter.party,
                          partyPresence: _filter.partyPresence,
                          resolution: _filter.resolution,
                          direction: direction,
                          endpoint: _filter.endpoint,
                          central: _filter.central,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<AccountType>(
                      isExpanded: true,
                      value: _filter.endpoint?.type,
                      hint: const Text('All accounts'),
                      items: [
                        const DropdownMenuItem<AccountType>(
                          value: null,
                          child: Text('All accounts'),
                        ),
                        for (final type in [
                          AccountType.mshwariSavings,
                          AccountType.kcbMpesa,
                          AccountType.investment,
                        ])
                          DropdownMenuItem(
                            value: type,
                            child: Text(accountLabel(type)),
                          ),
                        if (_filter.endpoint != null &&
                            ![
                              AccountType.mshwariSavings,
                              AccountType.kcbMpesa,
                              AccountType.investment,
                            ].contains(_filter.endpoint!.type))
                          DropdownMenuItem(
                            value: _filter.endpoint!.type,
                            child: Text(accountLabel(_filter.endpoint!.type)),
                          ),
                      ],
                      onChanged: (type) => _changeFilter(
                        ActivityFilter(
                          period: _filter.period,
                          scope: _filter.scope,
                          subtype: _filter.subtype,
                          party: _filter.party,
                          partyPresence: _filter.partyPresence,
                          resolution: _filter.resolution,
                          direction: _filter.direction,
                          endpoint: type == null ? null : AccountEndpoint(type),
                          central: _filter.central,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasDetailedFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (_filter.subtype != null)
                          subtypeLabel(_filter.subtype!),
                        if (_filter.partyPresence == PartyPresence.unidentified)
                          'Unidentified party',
                        if (_filter.resolution == SemanticResolution.unresolved)
                          'Unresolved financial meaning',
                        if (_filter.party != null)
                          'Party: ${_filter.party!.value}',
                        if (_filter.endpoint?.identity != null)
                          'Account: ${_filter.endpoint!.identity!.value}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _changeFilter(
                      ActivityFilter(
                        period: _filter.period,
                        central: _filter.central,
                      ),
                    ),
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: pageAsync.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load activity.'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(activityPageProvider(query)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (page) {
                if (page.count == 0) {
                  return const Center(
                    child: Text(
                      'No activity found for this period and filters.',
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: page.days.length,
                  itemBuilder: (context, index) {
                    final day = page.days[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            DateFormat.yMMMMEEEEd().format(day.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0B1F3A),
                            ),
                          ),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < day.records.length; i++) ...[
                                TransactionRow(
                                  record: day.records[i],
                                  central: _filter.central,
                                ),
                                if (i < day.records.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: _page == 0 || pageAsync.isLoading
                      ? null
                      : () {
                          setState(() => _page--);
                          _scrollToTop();
                        },
                  child: const Text('Previous'),
                ),
                Expanded(
                  child: Text('Page ${_page + 1}', textAlign: TextAlign.center),
                ),
                TextButton(
                  onPressed:
                      pageAsync.isLoading ||
                          !(pageAsync.valueOrNull?.hasMore ?? false)
                      ? null
                      : () {
                          setState(() => _page++);
                          _scrollToTop();
                        },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
