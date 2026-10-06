import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_breakdown.dart';
import '../models/financial_period.dart';
import '../models/financial_records.dart';
import '../services/financial_breakdown_service.dart';
import 'activity_provider.dart';
import 'financial_summary_provider.dart';
import 'repository_providers.dart';

final periodRecordsProvider = FutureProvider.autoDispose
    .family<List<FinancialRecord>, FinancialPeriod>((ref, period) {
      ref.watch(financialDataRevisionProvider);
      return ref.watch(financialRecordsRepositoryProvider).getForPeriod(period);
    });

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final period = FinancialPeriod.month(ref.watch(selectedMonthProvider));
  final records = await ref.watch(periodRecordsProvider(period).future);
  return const FinancialBreakdownService().dashboard(records, period);
});

final financialBreakdownProvider = FutureProvider.autoDispose
    .family<FinancialBreakdown, BreakdownQuery>((ref, query) async {
      final records = await ref.watch(
        periodRecordsProvider(query.filter.period).future,
      );
      return const FinancialBreakdownService().calculate(records, query);
    });
