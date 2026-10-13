import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/financial_period.dart';
import '../repositories/budgets_repository.dart';
import 'repository_providers.dart';
import 'activity_provider.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>(
  (ref) =>
      BudgetsRepository(ref.watch(financialRecordsRepositoryProvider).database),
);
final budgetsProvider = StreamProvider.autoDispose
    .family<List<BudgetProgress>, FinancialPeriod>((ref, period) {
      ref.watch(financialDataRevisionProvider);
      return ref.watch(budgetsRepositoryProvider).watch(period);
    });
