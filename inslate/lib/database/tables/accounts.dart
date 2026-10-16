import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get institution => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Only explicit registration sets this. Legacy/provider rows stay unconfirmed.
  BoolColumn get isUserRegistered =>
      boolean().withDefault(const Constant(false))();

  /// Optional descriptive identifiers, never credentials or inferred identities.
  TextColumn get identifiers => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
