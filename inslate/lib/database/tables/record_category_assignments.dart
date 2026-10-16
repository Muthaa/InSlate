import 'package:drift/drift.dart';
import 'financial_records.dart';
import 'transaction_categories.dart';
import 'category_rules.dart';

@DataClassName('StoredCategoryAssignment')
@TableIndex(name: 'record_category_category_idx', columns: {#categoryId})
class RecordCategoryAssignments extends Table {
  IntColumn get financialRecordId => integer().references(
    FinancialRecords,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get categoryId => text().nullable().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get origin => text().customConstraint(
    "NOT NULL CHECK (origin IN ('manual', 'ruleDerived', 'manualUncategorized'))",
  )();
  IntColumn get ruleId => integer().nullable().references(
    CategoryRules,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {financialRecordId};

  @override
  List<String> get customConstraints => [
    "CHECK ((origin = 'manualUncategorized' AND category_id IS NULL AND rule_id IS NULL) OR (origin IN ('manual', 'ruleDerived') AND category_id IS NOT NULL))",
    "CHECK (origin = 'ruleDerived' OR rule_id IS NULL)",
  ];

  @override
  bool get withoutRowId => true;
}
