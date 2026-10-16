import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/enums/account_type.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_filter.dart';
import '../../models/transaction_category.dart';
import '../../providers/category_provider.dart';
import 'activity_advanced_filters.dart';
import '../../models/financial_period.dart';
import '../../providers/activity_provider.dart';
import '../../providers/activity_timeline_provider.dart';
import '../../models/financial_records.dart';
import '../../services/activity_grouping.dart';
import '../../services/financial_semantics.dart';
import '../../widgets/transaction_row.dart';
import 'transaction_detail_screen.dart';

/// The same entry point can be pushed with a typed Dashboard drill-down filter.
class ActivityScreen extends StatelessWidget {
  final ActivityFilter? initialFilter;
  final bool preserveDrillDown;
  const ActivityScreen({
    super.key,
    this.initialFilter,
    this.preserveDrillDown = false,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      backgroundColor: AppTheme.darkBlue,
      foregroundColor: Colors.white,
      title: const Row(
        children: [
          Icon(Icons.history_rounded, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Your financial timeline',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    body: ActivityContent(
      initialFilter: initialFilter,
      preserveDrillDown: preserveDrillDown,
    ),
  );
}

/// Reusable filtered explorer, independent of shell navigation and Dashboard state.
class ActivityContent extends ConsumerStatefulWidget {
  final ActivityFilter? initialFilter;
  final bool preserveDrillDown;
  const ActivityContent({
    super.key,
    this.initialFilter,
    this.preserveDrillDown = false,
  });
  @override
  ConsumerState<ActivityContent> createState() => _ActivityContentState();
}

class _ActivityContentState extends ConsumerState<ActivityContent> {
  late ActivityFilter _filter;
  late ActivityFilter _constraints;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _filter =
        widget.initialFilter ??
        ActivityFilter(period: FinancialPeriod.month(DateTime.now()));
    _constraints = widget.preserveDrillDown
        ? _filter
        : ActivityFilter(period: _filter.period, central: _filter.central);
    _searchController = TextEditingController(text: _filter.search);
    _scrollController.addListener(_loadNearBottom);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _changeFilter(ActivityFilter filter) {
    setState(() {
      _filter = filter;
    });
    _scrollToTop();
  }

  void _validateCategory(List<TransactionCategory> all) {
    final id = _filter.category?.categoryId;
    if (id == null || all.any((c) => c.id == id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _filter.category?.categoryId != id) return;
      _constraints = _constraints.withCategory(null);
      _changeFilter(_filter.withCategory(null));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Category is no longer available. Category filter cleared.',
          ),
        ),
      );
    });
  }

  void _clearUserFilters() {
    _searchDebounce?.cancel();
    _searchController.text = _constraints.search;
    _changeFilter(_constraints.withPeriod(_filter.period));
  }

  Future<void> _advancedFilters() async {
    final selected = await showModalBottomSheet<ActivityFilter>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          ActivityAdvancedFilters(filter: _filter, constraints: _constraints),
    );
    if (mounted && selected != null && selected != _filter) {
      // Preserve a search/period update that completed while the sheet was open.
      _changeFilter(
        selected.copyWith(search: _filter.search, period: _filter.period),
      );
    }
  }

  void _searchChanged(String value) {
    setState(() {}); // Only the clear affordance changes immediately.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || normalizeActivitySearch(value) == _filter.search) return;
      _changeFilter(_filter.withSearch(value));
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_filter.search.isNotEmpty) {
      _changeFilter(_filter.withSearch(''));
    } else {
      setState(() {});
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _selectRange(Set<DateTime> months) async {
    final preset = await showModalBottomSheet<_PeriodPreset>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your period',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Currently: ${periodLabel(_filter.period)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final choice in _PeriodPreset.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      choice == _PeriodPreset.custom
                          ? Icons.date_range_outlined
                          : Icons.calendar_month_outlined,
                      color: AppTheme.teal,
                    ),
                    title: Text(switch (choice) {
                      _PeriodPreset.thisMonth => 'This month',
                      _PeriodPreset.lastMonth => 'Last month',
                      _PeriodPreset.last30Days => 'Last 30 days',
                      _PeriodPreset.last60Days => 'Last 60 days',
                      _PeriodPreset.last90Days => 'Last 90 days',
                      _PeriodPreset.allTime => 'All time',
                      _PeriodPreset.custom => 'Custom date range',
                    }),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, choice),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (preset == null || !mounted) return;
    if (preset != _PeriodPreset.custom) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = switch (preset) {
        _PeriodPreset.thisMonth => FinancialPeriod.month(today),
        _PeriodPreset.lastMonth => FinancialPeriod.month(
          DateTime(now.year, now.month - 1),
        ),
        _PeriodPreset.last30Days => FinancialPeriod(
          DateTime(today.year, today.month, today.day - 29),
          DateTime(today.year, today.month, today.day + 1),
        ),
        _PeriodPreset.last60Days => FinancialPeriod(
          DateTime(today.year, today.month, today.day - 59),
          DateTime(today.year, today.month, today.day + 1),
        ),
        _PeriodPreset.last90Days => FinancialPeriod(
          DateTime(today.year, today.month, today.day - 89),
          DateTime(today.year, today.month, today.day + 1),
        ),
        _PeriodPreset.allTime => FinancialPeriod.allTime(),
        _PeriodPreset.custom => throw StateError(
          'Custom range handled separately',
        ),
      };
      _changeFilter(_filter.withPeriod(selected));
      return;
    }
    final now = DateTime.now();
    final earliest = [...months, _filter.period.start, now]..sort();
    final latest = [
      ...months.map((month) => DateTime(month.year, month.month + 1, 0)),
      _filter.period.end.subtract(const Duration(days: 1)),
      now,
    ]..sort();
    final range = await showDateRangePicker(
      context: context,
      helpText: 'Choose start and end dates',
      saveText: 'Apply range',
      fieldStartLabelText: 'Start date',
      fieldEndLabelText: 'End date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.teal,
          ).copyWith(primary: AppTheme.darkBlue, surface: Colors.white),
          scaffoldBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
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

  Widget _timeline(ActivityTimeline timeline) {
    if (timeline.records.isEmpty) {
      if (timeline.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (timeline.failed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load activity.'),
              TextButton(
                onPressed: () => ref
                    .read(activityTimelineProvider(_filter).notifier)
                    .retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return _ActivityEmptyState(
        icon: Icons.receipt_long_outlined,
        title: _filter.search.isEmpty
            ? 'Nothing to show yet'
            : 'No matching transactions',
        message: _filter.search.isEmpty
            ? 'No activity found for this period and filters.'
            : 'Try a different search or adjust the period and filters.',
      );
    }
    final items = <Object>[];
    for (final day in groupActivityByDay(timeline.records)) {
      items.add(day);
      items.addAll(day.records);
    }
    return ListView.builder(
      key: const ValueKey('activity.timeline'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          if (timeline.failed) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('Unable to load more activity.'),
                  TextButton(
                    onPressed: () => ref
                        .read(activityTimelineProvider(_filter).notifier)
                        .retry(),
                    child: const Text('Retry loading activity'),
                  ),
                ],
              ),
            );
          }
          if (timeline.loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return const SizedBox(height: 8);
        }
        final item = items[index];
        if (item is ActivityDay) {
          return Padding(
            key: ValueKey('activity.day.${item.date.toIso8601String()}'),
            padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMMEEEEd().format(item.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.records.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final record = item as FinancialRecord;
        final first = index > 0 && items[index - 1] is ActivityDay;
        final last =
            index == items.length - 1 || items[index + 1] is ActivityDay;
        return Material(
          key: ValueKey('activity.record.${record.id}'),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(first ? 18 : 0),
              bottom: Radius.circular(last ? 18 : 0),
            ),
            side: const BorderSide(color: Color(0xFFE8ECEF)),
          ),
          child: TransactionRow(
            record: record,
            central: _filter.central,
            fullWidthMetadata: true,
            onTap: record.id == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionDetailScreen(
                        recordId: record.id!,
                        central: _filter.central,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _loadNearBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 480) {
      ref.read(activityTimelineProvider(_filter).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _filter.category != null
        ? ref.watch(categoriesProvider)
        : const AsyncData<List<TransactionCategory>>([]);
    final loadedCategories = categoriesAsync.asData?.value;
    if (loadedCategories != null) _validateCategory(loadedCategories);
    final monthsAsync = ref.watch(activityMonthsProvider);
    final months = monthsAsync.valueOrNull ?? <DateTime>{};
    final periods = {
      ...months.map(FinancialPeriod.month),
      FinancialPeriod.month(DateTime.now()),
      _filter.period,
    }.toList()..sort((a, b) => b.start.compareTo(a.start));
    final timeline = ref.watch(activityTimelineProvider(_filter));
    final countAsync = ref.watch(activityCountProvider(_filter));
    final countLabel = countAsync.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (count) => '$count transactions',
      loading: () => 'Counting transactions…',
      error: (_, _) => 'Count unavailable',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !timeline.loading && !timeline.failed) _loadNearBottom();
    });
    final centralLabel = accountLabel(_filter.central.type);
    final detailedFilterSummary = [
      if (_filter.provider != null)
        'Provider: ${_filter.provider!.providerKey} · Reference: ${_filter.provider!.reference ?? 'not reported'}',
      if (_filter.category != null)
        _filter.category!.categoryId == null
            ? 'Uncategorized'
            : categoriesAsync.valueOrNull
                      ?.where((c) => c.id == _filter.category!.categoryId)
                      .map((c) => '${c.name}${c.isHidden ? ' (hidden)' : ''}')
                      .firstOrNull ??
                  'Loading category...',
      if (_filter.partyPresence == PartyPresence.identified) 'Identified party',
      if (_filter.resolution == SemanticResolution.resolved)
        'Resolved financial meaning',
      if (_filter.direction != null)
        switch (_filter.direction!) {
          TransferDirection.intoCentral => 'Into $centralLabel',
          TransferDirection.fromCentral => 'From $centralLabel',
          TransferDirection.unrelated => 'Between other accounts',
          TransferDirection.unresolved => 'Unresolved direction',
        },
      if (_filter.endpoint != null) accountLabel(_filter.endpoint!.type),
      if (_filter.subtype != null) subtypeLabel(_filter.subtype!),
      if (_filter.partyPresence == PartyPresence.unidentified)
        'Unidentified party',
      if (_filter.resolution == SemanticResolution.unresolved)
        'Unresolved financial meaning',
      if (_filter.party != null) 'Party: ${_filter.party!.value}',
      if (_filter.endpoint?.identity != null)
        'Account: ${_filter.endpoint!.identity!.value}',
    ].join(' · ');
    final hasDetailedFilter =
        _filter.provider != null ||
        _filter.partyPresence != null ||
        _filter.resolution != null ||
        _filter.subtype != null ||
        _filter.party != null ||
        _filter.endpoint != null ||
        _filter.direction != null ||
        _filter.category != null ||
        _filter.scope != _constraints.scope ||
        _filter.search != _constraints.search;

    return SafeArea(
      top: false,
      child: _ActivityLayout(
        controls: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: const Icon(Icons.search, color: AppTheme.darkBlue),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close, color: AppTheme.darkBlue),
                      ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECEF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppTheme.teal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FinancialPeriod>(
                      isExpanded: true,
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: AppTheme.darkBlue,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBlue,
                        fontWeight: FontWeight.w600,
                      ),
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
            height: 56,
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
                  showCheckmark: false,
                  selectedColor: switch (scope) {
                    ActivityScope.income => Colors.green.shade700,
                    ActivityScope.expenses => Colors.red.shade700,
                    _ => AppTheme.darkBlue,
                  },
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: scope == _filter.scope
                        ? Colors.transparent
                        : const Color(0xFFE8ECEF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.labelLarge?.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scope == _filter.scope
                        ? Colors.white
                        : AppTheme.darkBlue,
                  ),
                  onSelected: _constraints.scope != ActivityScope.all
                      ? null
                      : (_) => _changeFilter(_filter.withScope(scope)),
                );
              },
            ),
          ),
          if (_filter.scope == ActivityScope.internalTransfers ||
              _filter.scope == ActivityScope.investmentsAndSavings)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
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
                      onChanged: _constraints.direction != null
                          ? null
                          : (direction) => _changeFilter(
                              _filter.copyWith(direction: direction),
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
                      onChanged: _constraints.endpoint != null
                          ? null
                          : (type) => _changeFilter(
                              _filter.copyWith(
                                endpoint: type == null
                                    ? null
                                    : AccountEndpoint(type),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _advancedFilters,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      const Text('Filters'),
                      const Text('·'),
                      Text(countLabel),
                    ],
                  ),
                ),
                if (countAsync.hasError)
                  IconButton(
                    tooltip: 'Retry transaction count',
                    onPressed: () =>
                        ref.invalidate(activityCountProvider(_filter)),
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                if (hasDetailedFilter)
                  TextButton(
                    onPressed: _clearUserFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          if (detailedFilterSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      detailedFilterSummary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
        content: _timeline(timeline),
      ),
    );
  }
}

/// Keep timeline above navigation; let controls scroll when the keyboard or
/// landscape leaves too little height. The widget hierarchy stays stable on
/// resize, preserving search focus, query state and the transaction controller.
class _ActivityLayout extends StatelessWidget {
  final List<Widget> controls;
  final Widget content;
  const _ActivityLayout({required this.controls, required this.content});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final compact = constraints.maxHeight < 420 * scale;
      return Column(
        children: [
          Flexible(
            flex: compact ? 1 : 0,
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              key: const ValueKey('activity.controls'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: controls,
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    },
  );
}

enum _PeriodPreset {
  thisMonth,
  lastMonth,
  last30Days,
  last60Days,
  last90Days,
  allTime,
  custom,
}

class _ActivityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const _ActivityEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 32, color: AppTheme.teal),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    ),
  );
}
