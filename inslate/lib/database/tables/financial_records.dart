import 'package:drift/drift.dart';

class FinancialRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get reference => text().unique()();

  DateTimeColumn get transactionDate => dateTime().nullable()();

  RealColumn get amount => real()();

  RealColumn get balance => real().nullable()();

  RealColumn get transactionCost => real().nullable()();

  TextColumn get type => text()();

  TextColumn get subtype => text()();

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
