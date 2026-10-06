import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/providers/activity_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../helpers/activity_test_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'refresh reloads active period pages and month metadata without getAll',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = ActivityTestRepository(database, [
        record(RecordSubtype.sendMoney, 1),
      ]);
      final container = ProviderContainer(
        overrides: [
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final query = (
        filter: ActivityFilter(
          period: FinancialPeriod.month(DateTime(2026, 9)),
        ),
        page: 0,
      );
      final subscription = container.listen(
        activityPageProvider(query),
        (_, _) {},
      );
      final monthsSubscription = container.listen(
        activityMonthsProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        monthsSubscription.close();
        container.dispose();
        await database.close();
      });
      expect(
        (await container.read(activityPageProvider(query).future)).count,
        1,
      );
      expect(await container.read(activityMonthsProvider.future), {
        DateTime(2026, 9),
      });
      repository.records.add(
        record(RecordSubtype.receiveMoney, 2, receivedAt: DateTime(2026, 10)),
      );
      repository.records.add(record(RecordSubtype.receiveMoney, 3));
      container.read(financialDataRevisionProvider.notifier).state++;
      expect(
        (await container.read(activityPageProvider(query).future)).count,
        2,
      );
      expect(await container.read(activityMonthsProvider.future), {
        DateTime(2026, 9),
        DateTime(2026, 10),
      });
      expect(repository.activityReads, 2);
      expect(repository.monthReads, 2);
    },
  );

  test('pagination hides the sentinel and groups the visible page only', () {
    final page = ActivityPage([
      for (var i = 0; i < activityPageSize + 1; i++)
        record(RecordSubtype.sendMoney, i.toDouble()),
    ]);
    expect(page.count, activityPageSize);
    expect(page.hasMore, isTrue);
    expect(page.days.single.records, hasLength(activityPageSize));
  });
}
