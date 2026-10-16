import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'v7 to v9 adds empty evidence table and preserves all legacy data and links',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inslate_balance_v7_',
      );
      final file = File('${directory.path}/migration.db');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final instruments = FinancialInstrumentsRepository(db);
        final registered = await instruments.create(
          name: 'Wallet',
          type: InstrumentType.mobileWallet,
        );
        await instruments.setArchived(registered.uuid, true);
        await db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            uuid: 'legacy',
            name: 'Legacy',
            type: 'free-text',
          ),
        );
        await FinancialRecordsRepository(db).save(
          record(
            RecordSubtype.sendMoney,
            11,
            party: const Party(
              name: 'Shop',
              type: PartyType.business,
              identifier: 'shop',
            ),
          ),
        );
        final row = (await db.financialRecordsDao.getAllRecords()).single;
        await (db.update(db.financialRecords)).write(
          FinancialRecordsCompanion(
            sourceAccountId: Value(registered.id),
            balance: const Value(42.25),
          ),
        );
        await CategoriesRepository(
          db,
        ).assignSimilar(recordId: row.id, categoryId: 'builtin.expense.food');
        await db.rawMessagesDao.insertMessage(
          RawMessagesCompanion.insert(
            sourceId: 'raw',
            sender: 'MPESA',
            body: 'Original SMS',
            receivedAt: DateTime(2025),
          ),
        );
        const tables = [
          'accounts',
          'financial_records',
          'raw_messages',
          'transaction_categories',
          'category_rules',
          'record_category_assignments',
        ];
        Future<Map<String, List<Map<String, dynamic>>>> snapshot() async => {
          for (final table in tables)
            table: (await db.customSelect('SELECT * FROM $table').get())
                .map(
                  (r) => Map<String, dynamic>.from(r.data)
                    ..remove('interpreted_type')
                    ..remove('interpreted_subtype')
                    ..remove('interpretation_mapping_id')
                    ..remove('reverses_record_id'),
                )
                .toList(),
        };
        final before = await snapshot();
        await db.customStatement('DROP TABLE budgets');
        await db.customStatement('DROP TABLE balance_evidence');
        await db.customStatement('DROP INDEX financial_reversal_original_idx');
        await db.customStatement('DROP INDEX financial_reversal_reference_idx');
        await db.customStatement(
          'ALTER TABLE financial_records DROP COLUMN reverses_record_id',
        );
        await db.customStatement('DROP TABLE instrument_mappings');
        await db.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpreted_type',
        );
        await db.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpreted_subtype',
        );
        await db.customStatement(
          'ALTER TABLE financial_records DROP COLUMN interpretation_mapping_id',
        );
        await db.customStatement('PRAGMA user_version = 7');
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        expect(await snapshot(), before);
        expect(await db.select(db.balanceEvidence).get(), isEmpty);
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          11,
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        expect(
          await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='index' AND name='balance_evidence_account_asof_idx'",
              )
              .get(),
          hasLength(1),
        );
        final evidence = await BalanceEvidenceRepository(db).createManual(
          accountId: registered.id,
          amount: '0.29',
          currency: 'KES',
          kind: BalanceKind.available,
          asOf: DateTime.utc(2025, 1, 2, 3, 4, 5, 678),
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        final restored = (await BalanceEvidenceRepository(
          db,
        ).latest(registered.id))!;
        expect(restored.id, evidence.id);
        expect(restored.amountMinor, 29);
        expect(restored.asOf, evidence.asOf);
        expect(restored.createdAt, evidence.createdAt);
        expect(await snapshot(), before);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
