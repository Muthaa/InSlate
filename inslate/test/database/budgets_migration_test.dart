import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'v8 to v9 preserves every existing table and adds empty budgets with uniqueness indexes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inslate_budget_v8_',
      );
      final file = File('${directory.path}/migration.db');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final account = await FinancialInstrumentsRepository(
          db,
        ).create(name: 'Wallet', type: InstrumentType.mobileWallet);
        await FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.buyGoods, 12.34));
        final financial = (await db.select(db.financialRecords).get()).single;
        await CategoriesRepository(
          db,
        ).assign(recordId: financial.id, categoryId: 'builtin.expense.food');
        await BalanceEvidenceRepository(db).createManual(
          accountId: account.id,
          amount: '0',
          currency: 'KES',
          kind: BalanceKind.reported,
          asOf: DateTime(2026),
        );
        await db.rawMessagesDao.insertMessage(
          RawMessagesCompanion.insert(
            sourceId: 'source',
            sender: 'MPESA',
            body: 'Original SMS',
            receivedAt: DateTime(2026),
          ),
        );
        const tables = [
          'accounts',
          'financial_records',
          'raw_messages',
          'transaction_categories',
          'record_category_assignments',
          'category_rules',
          'balance_evidence',
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
        await db.customStatement('PRAGMA user_version = 8');
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        expect(await snapshot(), before);
        expect(await db.select(db.budgets).get(), isEmpty);
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
        await BudgetsRepository(db).create(amount: '1.01');
        await expectLater(
          BudgetsRepository(db).create(amount: '2'),
          throwsArgumentError,
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
