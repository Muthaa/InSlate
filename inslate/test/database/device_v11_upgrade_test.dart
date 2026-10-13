import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';

void main() {
  final directory = Platform.environment['INSLATE_V11_UPGRADE_DIR'];
  test(
    'private device-copy v10 to v11 preserves every existing table and row',
    () async {
      final expected =
          jsonDecode(await File('$directory/expected.json').readAsString())
              as Map<String, dynamic>;
      final manifest =
          jsonDecode(await File('$directory/manifest.json').readAsString())
              as Map<String, dynamic>;
      final db = AppDatabase.forTesting(
        NativeDatabase(File('$directory/validation.db')),
      );
      try {
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          11,
        );
        for (final entry in expected.entries) {
          final order = (manifest['columns'][entry.key] as List)
              .map((c) => '"$c"')
              .join(', ');
          final rows = await db
              .customSelect('SELECT * FROM "${entry.key}" ORDER BY $order')
              .get();
          final after = rows
              .map((row) => Map<String, dynamic>.from(row.data))
              .toList();
          if (entry.key == 'financial_records') {
            for (final row in after) {
              for (final column in [
                'interpreted_type',
                'interpreted_subtype',
                'interpretation_mapping_id',
              ]) {
                expect(
                  row.containsKey(column) && row.remove(column) == null,
                  true,
                  reason: 'New interpretation must remain absent',
                );
              }
            }
          }
          // A boolean comparison prevents private row contents appearing on failure.
          expect(
            jsonEncode(after) == jsonEncode(entry.value),
            true,
            reason: '${entry.key}: existing contents changed',
          );
        }
        expect(
          await db.customSelect('SELECT * FROM instrument_mappings').get(),
          isEmpty,
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        expect(
          (await db.customSelect('PRAGMA integrity_check').getSingle())
              .data
              .values
              .single,
          'ok',
        );
      } finally {
        await db.close();
      }
    },
    skip: directory == null ? 'Opt-in private device capture required' : false,
  );
}
