import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/accounts.dart';
import 'tables/financial_records.dart';
import 'tables/raw_messages.dart';
import 'daos/accounts_dao.dart';
import 'daos/financial_records_dao.dart';
import 'daos/raw_messages_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, FinancialRecords, RawMessages],
  daos: [AccountsDao, FinancialRecordsDao, RawMessagesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(financialRecords, financialRecords.sourceMessageId);
      }
      if (from < 3) {
        await m.alterTable(TableMigration(financialRecords));
      }
      if (from < 4) {
        await m.alterTable(TableMigration(rawMessages));
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(p.join(dir.path, 'InSlate.db'));

    return NativeDatabase(file);
  });
}
