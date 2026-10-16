import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_cursor.dart';
import '../models/activity_filter.dart';
import '../models/financial_records.dart';
import '../repositories/financial_records_repository.dart';
import 'activity_provider.dart';
import 'repository_providers.dart';

class ActivityTimeline {
  final List<FinancialRecord> records;
  final bool loading, hasMore, failed;
  const ActivityTimeline({
    this.records = const [],
    this.loading = true,
    this.hasMore = true,
    this.failed = false,
  });
}

class ActivityTimelineController extends StateNotifier<ActivityTimeline> {
  final FinancialRecordsRepository repository;
  final ActivityFilter filter;
  int _generation = 0;
  ActivityCursor? _cursor;
  ActivityTimelineController(this.repository, this.filter)
    : super(const ActivityTimeline()) {
    unawaited(refresh());
  }

  /// Refresh the loaded depth atomically so edits/imports do not leave old rows
  /// mixed with newly paginated results. Older in-flight requests are ignored.
  Future<void> refresh() async {
    final generation = ++_generation;
    final target = state.records.length < activityPageSize
        ? activityPageSize
        : state.records.length;
    state = ActivityTimeline(records: state.records);
    final records = <FinancialRecord>[];
    ActivityCursor? cursor;
    var hasMore = true;
    try {
      while (records.length < target && hasMore) {
        final batch = await repository.getActivity(
          filter,
          limit: activityPageSize,
          before: cursor,
        );
        if (!mounted || generation != _generation) return;
        records.addAll(batch);
        hasMore = batch.length == activityPageSize;
        if (batch.isNotEmpty) cursor = ActivityCursor.fromRecord(batch.last);
      }
      _cursor = cursor;
      state = ActivityTimeline(
        records: _unique(records),
        loading: false,
        hasMore: hasMore,
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        // Retry refresh rather than appending to a potentially outdated cursor.
        _cursor = null;
        state = ActivityTimeline(
          records: state.records,
          loading: false,
          failed: true,
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore || state.failed) return;
    final generation = _generation;
    final previous = state.records;
    state = ActivityTimeline(records: previous);
    try {
      final batch = await repository.getActivity(
        filter,
        limit: activityPageSize,
        before: _cursor,
      );
      if (!mounted || generation != _generation) return;
      if (batch.isNotEmpty) _cursor = ActivityCursor.fromRecord(batch.last);
      state = ActivityTimeline(
        records: _unique([...previous, ...batch]),
        loading: false,
        hasMore: batch.length == activityPageSize,
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        state = ActivityTimeline(
          records: previous,
          loading: false,
          failed: true,
        );
      }
    }
  }

  Future<void> retry() {
    if (_cursor == null) return refresh();
    state = ActivityTimeline(records: state.records, loading: false);
    return loadMore();
  }

  List<FinancialRecord> _unique(List<FinancialRecord> records) {
    final ids = <int>{};
    return List.unmodifiable(records.where((r) => ids.add(r.id!)));
  }
}

final activityTimelineProvider = StateNotifierProvider.autoDispose
    .family<ActivityTimelineController, ActivityTimeline, ActivityFilter>((
      ref,
      filter,
    ) {
      final controller = ActivityTimelineController(
        ref.watch(financialRecordsRepositoryProvider),
        filter,
      );
      ref.listen(
        financialDataRevisionProvider,
        (_, _) => unawaited(controller.refresh()),
      );
      ref.listen(activityRecordsRevisionProvider, (previous, next) {
        if (next.asData != null &&
            previous?.asData != null &&
            next.asData!.value != previous!.asData!.value) {
          unawaited(controller.refresh());
        }
      });
      if (filter.category != null) {
        ref.listen(activityCategoryRevisionProvider, (previous, next) {
          if (next.asData != null &&
              previous?.asData != null &&
              next.asData!.value != previous!.asData!.value) {
            unawaited(controller.refresh());
          }
        });
      }
      return controller;
    });
