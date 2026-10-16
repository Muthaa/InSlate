import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_records.dart';
import '../database/app_database.dart' show StoredCategoryRule;
import '../models/transaction_category.dart';
import 'repository_providers.dart';

// Only category tables are observed; edits do not invalidate financial history.
final categoriesProvider =
    StreamProvider.autoDispose<List<TransactionCategory>>(
      (ref) => ref.watch(categoriesRepositoryProvider).watchCategories(),
    );
final recordCategoryProvider = StreamProvider.autoDispose
    .family<CategoryAssignment?, int>(
      (ref, id) => ref.watch(categoriesRepositoryProvider).watchAssignment(id),
    );
final transactionDetailProvider = FutureProvider.autoDispose
    .family<FinancialRecord?, int>(
      (ref, id) => ref.watch(financialRecordsRepositoryProvider).getById(id),
    );

final categoryRulesProvider =
    StreamProvider.autoDispose<List<StoredCategoryRule>>(
      (ref) => ref.watch(categoriesRepositoryProvider).watchRules(),
    );

final relatedReversalProvider = StreamProvider.autoDispose.family<int?, int>((
  ref,
  id,
) {
  final database = ref.watch(financialRecordsRepositoryProvider).database;
  return database
      .customSelect(
        'SELECT CASE WHEN id = ? THEN reverses_record_id ELSE id END AS related_id FROM financial_records WHERE (id = ? AND reverses_record_id IS NOT NULL) OR reverses_record_id = ?',
        variables: [Variable(id), Variable(id), Variable(id)],
        readsFrom: {database.financialRecords},
      )
      .watchSingleOrNull()
      .map((r) => r?.readNullable<int>('related_id'));
});
