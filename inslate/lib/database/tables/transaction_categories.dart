import 'package:drift/drift.dart';

@DataClassName('StoredCategory')
class TransactionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().customConstraint(
    'NOT NULL CHECK (length(trim(display_name)) > 0)',
  )();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('expense', 'income'))",
  )();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}
