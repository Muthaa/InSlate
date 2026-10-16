import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart' hide FinancialRecord;
import 'package:inslate/models/activity_cursor.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/providers/activity_timeline_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

class _Repository extends FinancialRecordsRepository {
  final requests =
      <({ActivityCursor? before, Completer<List<FinancialRecord>> result})>[];
  _Repository(super.database);
  @override
  Future<List<FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
    ActivityCursor? before,
  }) {
    expect(limit, 50);
    expect(offset, 0);
    final result = Completer<List<FinancialRecord>>();
    requests.add((before: before, result: result));
    return result.future;
  }
}

List<FinancialRecord> batch(int highest, int count) =>
    List.generate(count, (i) {
      final r = record(RecordSubtype.sendMoney, highest - i.toDouble());
      return FinancialRecord(
        id: highest - i,
        reference: r.reference,
        transactionDate: r.transactionDate,
        amount: r.amount,
        balance: r.balance,
        type: r.type,
        subtype: r.subtype,
        status: r.status,
        title: r.title,
        rawMessage: r.rawMessage,
        receivedAt: r.receivedAt,
      );
    });
Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  late AppDatabase db;
  late _Repository repository;
  final filter = ActivityFilter(
    period: FinancialPeriod.month(DateTime(2026, 9)),
  );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = _Repository(db);
  });
  tearDown(() => db.close());
  test(
    'one in-flight append, exclusive boundary, exact 50 boundary terminates',
    () async {
      final controller = ActivityTimelineController(repository, filter);
      addTearDown(controller.dispose);
      repository.requests[0].result.complete(batch(100, 50));
      await flush();
      final first = controller.loadMore();
      final concurrent = controller.loadMore();
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.before!.id, 51);
      repository.requests.last.result.complete([]);
      await first;
      await concurrent;
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.records, hasLength(50));
      await controller.loadMore();
      expect(repository.requests, hasLength(2));
    },
  );
  test(
    'refresh ignores stale append and replaces complete loaded range',
    () async {
      final controller = ActivityTimelineController(repository, filter);
      addTearDown(controller.dispose);
      repository.requests[0].result.complete(batch(100, 50));
      await flush();
      final append = controller.loadMore();
      final refresh = controller.refresh();
      repository.requests[2].result.complete(batch(101, 50));
      await refresh;
      repository.requests[1].result.complete(batch(50, 50));
      await append;
      expect(
        controller.state.records.map((r) => r.id),
        orderedEquals(List.generate(50, (i) => 101 - i)),
      );
    },
  );
  test('append failure preserves data and retries the same cursor', () async {
    final controller = ActivityTimelineController(repository, filter);
    addTearDown(controller.dispose);
    repository.requests[0].result.complete(batch(100, 50));
    await flush();
    final append = controller.loadMore();
    repository.requests[1].result.completeError(StateError('private'));
    await append;
    expect(controller.state.failed, isTrue);
    expect(controller.state.records, hasLength(50));
    final retry = controller.retry();
    expect(repository.requests[2].before!.id, 51);
    repository.requests[2].result.complete(batch(50, 20));
    await retry;
    expect(controller.state.records, hasLength(70));
    expect(controller.state.failed, isFalse);
    expect(controller.state.hasMore, isFalse);
  });
  test(
    'disposed filter results cannot overwrite a new filtered timeline',
    () async {
      final old = ActivityTimelineController(repository, filter);
      old.dispose();
      final current = ActivityTimelineController(
        repository,
        filter.withSearch('1500'),
      );
      addTearDown(current.dispose);
      repository.requests[1].result.complete(batch(200, 1));
      await flush();
      repository.requests[0].result.complete(batch(100, 50));
      await flush();
      expect(current.state.records.single.id, 200);
    },
  );
}
