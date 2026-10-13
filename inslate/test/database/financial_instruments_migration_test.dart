import 'dart:io';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'v6 to v9 preserves legacy Accounts and every existing financial table without confirmation or linking',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inslate_instruments_v6_',
      );
      final file = File('${directory.path}/migration.db');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        await db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            id: const Value(37),
            uuid: 'legacy-wallet',
            name: 'Legacy Wallet',
            type: 'wallet',
            institution: const Value('Provider'),
          ),
        );
        await db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            id: const Value(45),
            uuid: 'legacy-custom',
            name: 'Legacy Custom',
            type: 'free-text-v6',
            institution: const Value('Provider'),
            isActive: const Value(false),
          ),
        );
        final records = FinancialRecordsRepository(db);
        final categories = CategoriesRepository(db);
        const party = Party(
          name: 'Shop',
          type: PartyType.business,
          identifier: 'shop',
        );
        await records.saveAll([
          record(RecordSubtype.sendMoney, 10, party: party),
          record(RecordSubtype.sendMoney, 20, party: party),
          record(RecordSubtype.receiveMoney, 30),
        ]);
        final rows = await db.financialRecordsDao.getAllRecords();
        await categories.assignSimilar(
          recordId: rows.first.id,
          categoryId: 'builtin.expense.food',
        );
        await categories.removeAssignment(rows.last.id);
        await (db.update(
          db.financialRecords,
        )..where((r) => r.id.equals(rows.first.id))).write(
          const FinancialRecordsCompanion(
            sourceAccountId: Value(37),
            destinationAccountId: Value(45),
          ),
        );
        await db.rawMessagesDao.insertMessage(
          RawMessagesCompanion.insert(
            sourceId: 'existing-message',
            sender: 'MPESA',
            body: 'Original SMS',
            receivedAt: DateTime(2026, 9),
          ),
        );
        Future<List<Map<String, dynamic>>> snapshot(String table) async =>
            (await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
                .map(
                  (r) => Map<String, dynamic>.from(r.data)
                    ..remove('interpreted_type')
                    ..remove('interpreted_subtype')
                    ..remove('interpretation_mapping_id')
                    ..remove('reverses_record_id'),
                )
                .toList();
        final financial = await snapshot('financial_records');
        final raw = await snapshot('raw_messages');
        final categoriesBefore = await snapshot('transaction_categories');
        final rules = await snapshot('category_rules');
        // Assignments use WITHOUT ROWID.
        final assignments =
            (await db
                    .customSelect(
                      'SELECT * FROM record_category_assignments ORDER BY financial_record_id',
                    )
                    .get())
                .map(
                  (r) => Map<String, dynamic>.from(r.data)
                    ..remove('interpreted_type')
                    ..remove('interpreted_subtype')
                    ..remove('interpretation_mapping_id')
                    ..remove('reverses_record_id'),
                )
                .toList();
        final accounts =
            (await db
                    .customSelect(
                      'SELECT id, uuid, name, type, institution, is_active, created_at FROM accounts ORDER BY id',
                    )
                    .get())
                .map(
                  (r) => Map<String, dynamic>.from(r.data)
                    ..remove('interpreted_type')
                    ..remove('interpreted_subtype')
                    ..remove('interpretation_mapping_id')
                    ..remove('reverses_record_id'),
                )
                .toList();
        // Construct the exact prior Accounts schema, leaving all v6 data intact.
        await db.customStatement(
          'ALTER TABLE accounts DROP COLUMN is_user_registered',
        );
        await db.customStatement(
          'ALTER TABLE accounts DROP COLUMN identifiers',
        );
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
        await db.customStatement('PRAGMA user_version = 6');
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        final instruments = FinancialInstrumentsRepository(db);
        expect(await instruments.list(includeArchived: true), isEmpty);
        expect(await instruments.getById(37), isNull);
        final migrated = await db.accountsDao.getAllAccounts();
        expect(migrated.map((a) => a.isUserRegistered), everyElement(isFalse));
        expect(migrated.map((a) => a.identifiers), everyElement(isNull));
        expect(
          (await db
                  .customSelect(
                    'SELECT id, uuid, name, type, institution, is_active, created_at FROM accounts ORDER BY id',
                  )
                  .get())
              .map(
                (r) => Map<String, dynamic>.from(r.data)
                  ..remove('interpreted_type')
                  ..remove('interpreted_subtype')
                  ..remove('interpretation_mapping_id')
                  ..remove('reverses_record_id'),
              )
              .toList(),
          accounts,
        );
        final preservedLinks = (await InstrumentLinksRepository(
          db,
        ).watch(rows.first.id).first)!;
        expect(preservedLinks.sourceId, 37);
        expect(preservedLinks.destinationId, 45);
        expect(await snapshot('financial_records'), financial);
        expect(await snapshot('raw_messages'), raw);
        expect(await snapshot('transaction_categories'), categoriesBefore);
        expect(await snapshot('category_rules'), rules);
        expect(
          (await db
                  .customSelect(
                    'SELECT * FROM record_category_assignments ORDER BY financial_record_id',
                  )
                  .get())
              .map(
                (r) => Map<String, dynamic>.from(r.data)
                  ..remove('interpreted_type')
                  ..remove('interpreted_subtype')
                  ..remove('interpretation_mapping_id')
                  ..remove('reverses_record_id'),
              )
              .toList(),
          assignments,
        );
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
        final created = await instruments.create(
          name: 'Confirmed',
          type: InstrumentType.insurancePolicy,
          identifiers: const InstrumentIdentifiers(policyNumber: 'POL-01'),
        );
        expect(created.id, greaterThan(45));
        final uuid = created.uuid;
        await instruments.setArchived(uuid, true);
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        final reopened = (await FinancialInstrumentsRepository(
          db,
        ).getByUuid(uuid))!;
        expect(reopened.id, created.id);
        expect(reopened.isArchived, isTrue);
        expect(reopened.identifiers!.policyNumber, 'POL-01');
        expect(await FinancialInstrumentsRepository(db).list(), isEmpty);
        expect(
          await FinancialInstrumentsRepository(db).list(includeArchived: true),
          hasLength(1),
        );
        expect(await snapshot('financial_records'), financial);
        expect(
          (await db.accountsDao.getAccountByUuid(
            'legacy-wallet',
          ))!.isUserRegistered,
          isFalse,
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
