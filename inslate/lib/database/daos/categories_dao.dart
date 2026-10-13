import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_categories.dart';
import '../tables/record_category_assignments.dart';
import '../../models/transaction_category.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [TransactionCategories, RecordCategoryAssignments])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<void> seedBuiltIns() async {
    await batch((batch) {
      batch.insertAll(transactionCategories, [
        for (final category in builtInCategories)
          TransactionCategoriesCompanion.insert(
            id: category.id,
            displayName: category.name,
            kind: category.kind.name,
            isBuiltIn: const Value(true),
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  Future<List<StoredCategory>> getCategories() =>
      (select(transactionCategories)..orderBy([
            (row) => OrderingTerm.asc(row.kind),
            (row) => OrderingTerm.asc(row.displayName),
            (row) => OrderingTerm.asc(row.id),
          ]))
          .get();
  Future<StoredCategory?> getCategory(String id) => (select(
    transactionCategories,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  Future<StoredCategoryAssignment?> getAssignment(int recordId) => (select(
    recordCategoryAssignments,
  )..where((row) => row.financialRecordId.equals(recordId))).getSingleOrNull();
}
