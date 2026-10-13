import 'package:drift/drift.dart';

@TableIndex(name: 'financial_records_reference_idx', columns: {#reference})
class FinancialRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get reversesRecordId => integer().nullable().references(
    FinancialRecords,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get reference => text()();

  TextColumn get sourceMessageId => text().nullable()();

  DateTimeColumn get transactionDate => dateTime().nullable()();

  DateTimeColumn get receivedAt => dateTime()();

  RealColumn get amount => real()();

  RealColumn get balance => real().nullable()();

  RealColumn get transactionCost => real().nullable()();

  TextColumn get type => text()();

  TextColumn get subtype => text()();

  /// User-confirmed interpretation; parsed type/subtype remain unchanged.
  TextColumn get interpretedType => text().nullable()();
  TextColumn get interpretedSubtype => text().nullable()();
  IntColumn get interpretationMappingId => integer().nullable()();

  TextColumn get status => text()();

  TextColumn get title => text()();

  TextColumn get rawMessage => text()();

  IntColumn get sourceAccountId => integer().nullable()();

  IntColumn get destinationAccountId => integer().nullable()();

  TextColumn get partyName => text().nullable()();

  TextColumn get partyType => text().nullable()();

  TextColumn get partyPhone => text().nullable()();

  TextColumn get partyAccount => text().nullable()();

  TextColumn get partyIdentifier => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
