// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransactionCategoriesTable get transactionCategories =>
      attachedDatabase.transactionCategories;
  $FinancialRecordsTable get financialRecords =>
      attachedDatabase.financialRecords;
  $CategoryRulesTable get categoryRules => attachedDatabase.categoryRules;
  $RecordCategoryAssignmentsTable get recordCategoryAssignments =>
      attachedDatabase.recordCategoryAssignments;
  CategoriesDaoManager get managers => CategoriesDaoManager(this);
}

class CategoriesDaoManager {
  final _$CategoriesDaoMixin _db;
  CategoriesDaoManager(this._db);
  $$TransactionCategoriesTableTableManager get transactionCategories =>
      $$TransactionCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.transactionCategories,
      );
  $$FinancialRecordsTableTableManager get financialRecords =>
      $$FinancialRecordsTableTableManager(
        _db.attachedDatabase,
        _db.financialRecords,
      );
  $$CategoryRulesTableTableManager get categoryRules =>
      $$CategoryRulesTableTableManager(_db.attachedDatabase, _db.categoryRules);
  $$RecordCategoryAssignmentsTableTableManager get recordCategoryAssignments =>
      $$RecordCategoryAssignmentsTableTableManager(
        _db.attachedDatabase,
        _db.recordCategoryAssignments,
      );
}
