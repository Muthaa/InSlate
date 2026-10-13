import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_period.dart';
import '../models/insights.dart';
import '../repositories/insights_repository.dart';
import 'activity_provider.dart';
import 'repository_providers.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(
    ref.watch(financialRecordsRepositoryProvider).database,
  ),
);
final insightsProvider = StreamProvider.autoDispose
    .family<InsightsSummary, FinancialPeriod>((ref, period) {
      ref.watch(financialDataRevisionProvider);
      return ref.watch(insightsRepositoryProvider).watch(period);
    });
