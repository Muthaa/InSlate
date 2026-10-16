import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import '../models/activity_filter.dart';
import '../models/financial_records.dart';
import 'repository_providers.dart';
import '../services/activity_grouping.dart';

/// Import/resume only needs to increment this read-side refresh dependency.
final financialDataRevisionProvider = StateProvider<int>((ref) => 0);
const activityPageSize = 50;
typedef ActivityPageQuery = ({ActivityFilter filter, int page});

class ActivityPage {
  final List<ActivityDay> days;
  final int count;
  final bool hasMore;
  ActivityPage(List<FinancialRecord> records)
    : days = groupActivityByDay(records.take(activityPageSize)),
      count = records.length > activityPageSize
          ? activityPageSize
          : records.length,
      hasMore = records.length > activityPageSize;
}

final activityPageProvider = FutureProvider.autoDispose
    .family<ActivityPage, ActivityPageQuery>((ref, query) async {
      ref.watch(financialDataRevisionProvider);
      if (query.filter.category != null) {
        ref.watch(
          activityCategoryRevisionProvider.select((v) => v.valueOrNull ?? 0),
        );
      }
      final records = await ref
          .watch(financialRecordsRepositoryProvider)
          .getActivity(
            query.filter,
            limit: activityPageSize + 1,
            offset: query.page * activityPageSize,
          );
      return ActivityPage(records);
    });

final activityMonthsProvider = FutureProvider.autoDispose<Set<DateTime>>((ref) {
  ref.watch(financialDataRevisionProvider);
  return ref.watch(financialRecordsRepositoryProvider).getEffectiveMonths();
});

final activityCountProvider = FutureProvider.autoDispose
    .family<int, ActivityFilter>((ref, filter) {
      ref.watch(financialDataRevisionProvider);
      if (filter.category != null) {
        ref.watch(
          activityCategoryRevisionProvider.select((v) => v.valueOrNull ?? 0),
        );
      }
      return ref
          .watch(financialRecordsRepositoryProvider)
          .countActivity(filter);
    });

// Observe table invalidations, without selecting every assignment or reloading
// financial history. Only category-filtered queries depend on this revision.
final activityCategoryRevisionProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final db = ref.watch(financialRecordsRepositoryProvider).database;
  var revision = 0;
  yield revision;
  await for (final _ in db.tableUpdates(
    TableUpdateQuery.onTable(db.recordCategoryAssignments),
  )) {
    yield ++revision;
  }
});
