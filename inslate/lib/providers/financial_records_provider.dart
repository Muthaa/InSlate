import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_records.dart';
import 'repository_providers.dart';
import 'activity_provider.dart';

final financialRecordsProvider = FutureProvider<List<FinancialRecord>>((
  ref,
) async {
  final repository = ref.watch(financialRecordsRepositoryProvider);

  return repository.getAll();
});

final availableMonthsProvider = FutureProvider<Set<DateTime>>((ref) {
  ref.watch(financialDataRevisionProvider);
  return ref.watch(financialRecordsRepositoryProvider).getEffectiveMonths();
});

final monthRangeProvider = FutureProvider<({DateTime start, DateTime end})>((
  ref,
) async {
  ref.watch(financialDataRevisionProvider);
  final bounds = await ref
      .watch(financialRecordsRepositoryProvider)
      .getEffectiveDateBounds();
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  if (bounds.first == null) {
    return (start: currentMonth, end: DateTime(now.year, now.month + 1));
  }
  final first = bounds.first!;
  final last = bounds.last!;
  final dataEnd = DateTime(last.year, last.month + 1);
  final currentEnd = DateTime(now.year, now.month + 1);
  return (
    start: DateTime(first.year, first.month - 1),
    end: dataEnd.isAfter(currentEnd) ? dataEnd : currentEnd,
  );
});
