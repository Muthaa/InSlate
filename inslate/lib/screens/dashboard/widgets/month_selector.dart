import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/financial_summary_provider.dart';
import '../../../providers/financial_records_provider.dart';

class MonthSelector extends ConsumerStatefulWidget {
  const MonthSelector({super.key});

  @override
  ConsumerState<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends ConsumerState<MonthSelector> {
  late final ScrollController _scrollController;
  bool _initialScrollScheduled = false;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedMonth();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedMonth() {
    if (!mounted || !_scrollController.hasClients) return;

    final selectedMonth = ref.read(selectedMonthProvider);

    final index = selectedMonth.month - 1;

    const itemWidth = 72.0;

    final targetOffset =
        (index * itemWidth) -
        (MediaQuery.sizeOf(context).width / 2) +
        (itemWidth / 2);

    _scrollController.jumpTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
    );
  }

  bool _isMonthAvailable(DateTime month, Set<DateTime> availableMonths) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    // Future month.
    if (month.isAfter(currentMonth)) {
      return false;
    }

    // Current month is always available.
    if (month == currentMonth) {
      return true;
    }

    return availableMonths.contains(month);
  }

  void _selectMonth(DateTime month, Set<DateTime> availableMonths) {
    if (!_isMonthAvailable(month, availableMonths)) {
      return;
    }

    ref.read(selectedMonthProvider.notifier).state = DateTime(
      month.year,
      month.month,
    );

    _scrollToSelectedMonth();
  }

  void _changeYear(
    int offset,
    DateTime selectedMonth,
    DateTime start,
    DateTime end,
  ) {
    final targetYear = selectedMonth.year + offset;

    final minYear = start.year;
    final maxYear = end.year;

    if (targetYear < minYear || targetYear > maxYear) {
      return;
    }

    final now = DateTime.now();

    if (targetYear > now.year) {
      return;
    }

    var targetMonth = selectedMonth.month;

    // If moving into the current year, don't allow
    // the selected month to become a future month.
    if (targetYear == now.year && targetMonth > now.month) {
      targetMonth = now.month;
    }

    final newMonth = DateTime(targetYear, targetMonth);

    ref.read(selectedMonthProvider.notifier).state = newMonth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);

    final availableMonths =
        ref.watch(availableMonthsProvider).valueOrNull ?? {};

    final range = ref.watch(monthRangeProvider).valueOrNull;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (range == null) {
      return const SizedBox(
        height: 82,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_initialScrollScheduled) {
      _initialScrollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToSelectedMonth();
      });
    }

    final selectedYear = selectedMonth.year;

    final minYear = range.start.year;
    final maxYear = range.end.year;

    final now = DateTime.now();

    final canGoPrevious = selectedYear > minYear;

    final canGoNext = selectedYear < maxYear && selectedYear < now.year;

    return Container(
      color: AppTheme.appBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: canGoPrevious
                    ? () =>
                          _changeYear(-1, selectedMonth, range.start, range.end)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '$selectedYear',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
                ),
              ),
              IconButton(
                onPressed: canGoNext
                    ? () =>
                          _changeYear(1, selectedMonth, range.start, range.end)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 46,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;

                final month = DateTime(selectedMonth.year, monthNumber);

                final isWithinRange =
                    !month.isBefore(range.start) && month.isBefore(range.end);

                final isAvailable =
                    isWithinRange && _isMonthAvailable(month, availableMonths);

                final isSelected = selectedMonth.month == monthNumber;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: isAvailable
                        ? () => _selectMonth(month, availableMonths)
                        : null,
                    child: Container(
                      width: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.darkTeal
                            : isAvailable
                            ? Colors.white
                            : const Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.darkTeal
                              : const Color(0xFFE7EEF2),
                          width: isSelected ? 0 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.darkBlue.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _months[index],
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                              ? AppTheme.darkTeal
                              : AppTheme.darkTeal.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
