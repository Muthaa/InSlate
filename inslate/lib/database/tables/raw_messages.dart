import 'package:drift/drift.dart';

@TableIndex(name: 'raw_messages_sender_body_idx', columns: {#sender, #body})
class RawMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourceId => text().unique()();

  TextColumn get sender => text()();

  TextColumn get body => text()();

  DateTimeColumn get receivedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
