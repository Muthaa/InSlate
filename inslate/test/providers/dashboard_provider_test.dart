import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/providers/dashboard_provider.dart';
import 'package:inslate/providers/activity_provider.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/providers/financial_records_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import '../helpers/activity_test_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'Dashboard and selector never load complete history; snapshot survives month change',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = ActivityTestRepository(database, [
        record(RecordSubtype.receiveMoney, 100, receivedAt: DateTime(2026, 9)),
        record(RecordSubtype.receiveMoney, 200, receivedAt: DateTime(2026, 8)),
      ]);
      final container = ProviderContainer(
        overrides: [
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      container.read(selectedMonthProvider.notifier).state = DateTime(2026, 9);
      final subscription = container.listen(
        dashboardSummaryProvider,
        (_, _) {},
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await database.close();
      });
      expect(
        (await container.read(dashboardSummaryProvider.future)).totals.income,
        100,
      );
      expect(await container.read(availableMonthsProvider.future), {
        DateTime(2026, 8),
        DateTime(2026, 9),
      });
      expect(
        (await container.read(monthRangeProvider.future)).start,
        DateTime(2026, 7),
      );
      final query = (
        kind: BreakdownKind.incomeParties,
        filter: ActivityFilter(
          period: FinancialPeriod.month(DateTime(2026, 9)),
          scope: ActivityScope.income,
        ),
      );
      final snapshot = container.listen(
        financialBreakdownProvider(query),
        (_, _) {},
      );
      addTearDown(snapshot.close);
      expect(
        (await container.read(financialBreakdownProvider(query).future)).amount,
        100,
      );
      container.read(selectedMonthProvider.notifier).state = DateTime(2026, 8);
      expect(
        (await container.read(dashboardSummaryProvider.future)).totals.income,
        200,
      );
      expect(
        (await container.read(financialBreakdownProvider(query).future)).amount,
        100,
      );
      repository.records.add(
        record(RecordSubtype.receiveMoney, 50, receivedAt: DateTime(2026, 8)),
      );
      container.read(financialDataRevisionProvider.notifier).state++;
      expect(
        (await container.read(dashboardSummaryProvider.future)).totals.income,
        250,
      );
      expect(
        repository.requestedPeriods.every(
          (period) =>
              period == FinancialPeriod.month(DateTime(2026, 8)) ||
              period == FinancialPeriod.month(DateTime(2026, 9)),
        ),
        isTrue,
      );
    },
  );
}
