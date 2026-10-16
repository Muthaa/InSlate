import 'package:drift/drift.dart';
import 'transaction_categories.dart';

@DataClassName('StoredBudget')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text().customConstraint(
    "NOT NULL CHECK (scope IN ('overall', 'category'))",
  )();
  TextColumn get categoryId => text().nullable().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get amountMinor =>
      integer().customConstraint('NOT NULL CHECK (amount_minor > 0)')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    "CHECK (scope != 'overall' OR category_id IS NULL)",
  ];
}
