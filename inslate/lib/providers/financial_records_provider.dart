import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_records.dart';
import 'repository_providers.dart';

final financialRecordsProvider = FutureProvider<List<FinancialRecord>>((
  ref,
) async {
  final repository = ref.watch(financialRecordsRepositoryProvider);

  return repository.getAll();
});

final availableMonthsProvider = FutureProvider<Set<DateTime>>((ref) async {
  final records = await ref.watch(financialRecordsProvider.future);

  final months = <DateTime>{};

  for (final record in records) {
    final date = record.transactionDate;

    if (date == null) continue;

    months.add(DateTime(date.year, date.month));
  }

  return months;
});

final monthRangeProvider = FutureProvider<({DateTime start, DateTime end})>((
  ref,
) async {
  final records = await ref.watch(financialRecordsProvider.future);

  final datedRecords = records
      .where((record) => record.transactionDate != null)
      .toList();

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);

  // No historical data yet.
  if (datedRecords.isEmpty) {
    return (
      start: currentMonth,
      end: DateTime(currentMonth.year, currentMonth.month + 1),
    );
  }

  datedRecords.sort((a, b) => a.transactionDate!.compareTo(b.transactionDate!));

  final firstDate = datedRecords.first.transactionDate!;
  final lastDate = datedRecords.last.transactionDate!;

  final firstMonth = DateTime(firstDate.year, firstDate.month);

  final lastMonth = DateTime(lastDate.year, lastDate.month);

  // One month before the earliest data.
  final start = DateTime(firstMonth.year, firstMonth.month - 1);

  // Never allow the selector to extend beyond one month
  // after the current month, and never beyond the latest
  // month for which data exists plus one month.
  final dataEnd = DateTime(lastMonth.year, lastMonth.month + 1);

  final currentEnd = DateTime(currentMonth.year, currentMonth.month + 1);

  final end = dataEnd.isAfter(currentEnd) ? dataEnd : currentEnd;

  return (start: start, end: end);
});
