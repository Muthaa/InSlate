import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/accounts.dart';
import 'tables/budgets.dart';
import 'tables/balance_evidence.dart';
import 'tables/financial_records.dart';
import 'tables/raw_messages.dart';
import 'daos/accounts_dao.dart';
import 'daos/financial_records_dao.dart';
import 'daos/raw_messages_dao.dart';
import 'tables/transaction_categories.dart';
import 'tables/category_rules.dart';
import 'tables/record_category_assignments.dart';
import 'daos/categories_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Budgets,
    BalanceEvidence,
    FinancialRecords,
    RawMessages,
    TransactionCategories,
    RecordCategoryAssignments,
    CategoryRules,
  ],
  daos: [AccountsDao, FinancialRecordsDao, RawMessagesDao, CategoriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  Future<void> _createInstrumentMappings() => customStatement('''
    CREATE TABLE instrument_mappings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
      provider_key TEXT NOT NULL,
      account_reference TEXT NOT NULL,
      purpose TEXT NOT NULL CHECK(purpose IN ('investment', 'savings', 'loan', 'unknown')),
      created_at INTEGER NOT NULL,
      UNIQUE(provider_key, account_reference)
    )
  ''');

  Future<void> _createBudgetIndexes() async {
    await customStatement(
      "CREATE UNIQUE INDEX budgets_active_overall_idx ON budgets(scope) WHERE scope = 'overall' AND is_active = 1",
    );
    await customStatement(
      "CREATE UNIQUE INDEX budgets_active_category_idx ON budgets(category_id) WHERE scope = 'category' AND is_active = 1 AND category_id IS NOT NULL",
    );
  }

  Future<void> _createReversalIndexes() async {
    await customStatement(
      "CREATE UNIQUE INDEX financial_reversal_original_idx ON financial_records(reverses_record_id) WHERE reverses_record_id IS NOT NULL",
    );
    await customStatement(
      "CREATE UNIQUE INDEX financial_reversal_reference_idx ON financial_records(reference) WHERE subtype = 'payBillReversal'",
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await categoriesDao.seedBuiltIns();
      await _createBudgetIndexes();
      await _createReversalIndexes();
      await _createInstrumentMappings();
    },
    onUpgrade: (m, from, to) async {
      if (from < 11) {
        await m.addColumn(financialRecords, financialRecords.interpretedType);
        await m.addColumn(
          financialRecords,
          financialRecords.interpretedSubtype,
        );
        await m.addColumn(
          financialRecords,
          financialRecords.interpretationMappingId,
        );
        await _createInstrumentMappings();
      }
      if (from >= 3 && from < 10) {
        await m.addColumn(financialRecords, financialRecords.reversesRecordId);
      }
      if (from < 9) {
        await m.createTable(budgets);
        await _createBudgetIndexes();
      }
      if (from < 2) {
        await m.addColumn(financialRecords, financialRecords.sourceMessageId);
      }
      if (from < 3) {
        await m.alterTable(
          TableMigration(
            financialRecords,
            newColumns: [financialRecords.reversesRecordId],
          ),
        );
      }
      if (from < 4) {
        await m.alterTable(TableMigration(rawMessages));
      }
      if (from < 5) {
        await m.createTable(transactionCategories);
        await m.createTable(categoryRules);
        await m.createTable(recordCategoryAssignments);
        await categoriesDao.seedBuiltIns();
      } else if (from < 6) {
        await m.createTable(categoryRules);
        await m.alterTable(
          TableMigration(
            recordCategoryAssignments,
            newColumns: [recordCategoryAssignments.ruleId],
          ),
        );
      }
      if (from < 8) {
        await m.createTable(balanceEvidence);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS balance_evidence_account_asof_idx ON balance_evidence(account_id, as_of_millis)',
        );
      }
      if (from < 7) {
        await m.addColumn(accounts, accounts.isUserRegistered);
        await m.addColumn(accounts, accounts.identifiers);
      }
      if (from < 10) await _createReversalIndexes();
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
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
