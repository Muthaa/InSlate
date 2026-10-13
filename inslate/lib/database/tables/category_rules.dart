import 'package:drift/drift.dart';
import 'transaction_categories.dart';

@DataClassName('StoredCategoryRule')
class CategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get identityKey => text()();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('income', 'expense'))",
  )();
  TextColumn get categoryId => text().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.cascade,
  )();
  @override
  List<Set<Column>> get uniqueKeys => [
    {identityKey, kind},
  ];
}
