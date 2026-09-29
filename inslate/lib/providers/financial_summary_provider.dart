import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_summary.dart';
import '../services/financial_summary_service.dart';
import 'financial_records_provider.dart';

final financialSummaryServiceProvider = Provider<FinancialSummaryService>((
  ref,
) {
  return FinancialSummaryService();
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();

  return DateTime(now.year, now.month);
});

final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) async {
  final records = await ref.watch(financialRecordsProvider.future);

  final service = ref.watch(financialSummaryServiceProvider);

  final period = ref.watch(selectedMonthProvider);

  return service.calculate(records, period: period);
});
