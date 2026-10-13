import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'v10 to v11 preserves records and introduces empty mapping registry',
    () async {
      final dir = await Directory.systemTemp.createTemp('inslate_mapping_');
      final file = File('${dir.path}/db');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        await FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.payBill, 123, fee: 4));
        final before = Map<String, dynamic>.from(
          (await db.customSelect('SELECT * FROM financial_records').getSingle())
              .data,
        );
        for (final column in [
          'interpreted_type',
          'interpreted_subtype',
          'interpretation_mapping_id',
        ]) {
          before.remove(column);
          await db.customStatement(
            'ALTER TABLE financial_records DROP COLUMN $column',
          );
        }
        await db.customStatement('DROP TABLE instrument_mappings');
        await db.customStatement('PRAGMA user_version = 10');
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        final after = Map<String, dynamic>.from(
          (await db.customSelect('SELECT * FROM financial_records').getSingle())
              .data,
        );
        for (final column in [
          'interpreted_type',
          'interpreted_subtype',
          'interpretation_mapping_id',
        ]) {
          expect(after.remove(column), isNull);
        }
        expect(after, before);
        expect(
          await db.customSelect('SELECT * FROM instrument_mappings').get(),
          isEmpty,
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
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
