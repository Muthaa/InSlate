import 'package:drift/drift.dart';

class RawMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceId => text().unique()();

  TextColumn get sender => text()();

  TextColumn get body => text()();

  DateTimeColumn get receivedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
