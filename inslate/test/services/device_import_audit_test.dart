// Opt-in, private host replay. No test writes to an Android device.
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/parsers/parser_factory.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/services/transaction_import_service.dart';

void main() {
  const capture = String.fromEnvironment('PHASE11_DEVICE_AUDIT_DIR');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'private device snapshot: migration preservation, reconciliation and semantic SQL agreement',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'inslate_phase11_replay_',
      );
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => temp.path,
      );
      final file = await File(
        '$capture/device.db',
      ).copy('${temp.path}/replay.db');
      final original = <String, List<Map<String, Object?>>>{};
      final columns = <String, List<String>>{};
      final db = AppDatabase.forTesting(
        NativeDatabase(
          file,
          setup: (native) {
            for (final table in [
              'accounts',
              'financial_records',
              'raw_messages',
            ]) {
              final result = native.select('SELECT * FROM $table ORDER BY id');
              columns[table] = result.columnNames;
              original[table] = result
                  .map((r) => Map<String, Object?>.from(r))
                  .toList();
            }
          },
        ),
      );
      try {
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          10,
        );
        for (final table in original.keys) {
          final rows = await db
              .customSelect(
                'SELECT ${columns[table]!.join(',')} FROM $table ORDER BY id',
              )
              .get();
          // Never print private row contents on an assertion failure.
          expect(
            jsonEncode(rows.map((r) => r.data).toList()) ==
                jsonEncode(original[table]),
            isTrue,
            reason: 'Migration changed existing $table data',
          );
        }
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
        final raw = RawMessagesRepository(db);
        final records = FinancialRecordsRepository(db);
        final classifier = MpesaMessageClassifier();
        final messages =
            (jsonDecode(await File('$capture/messages.json').readAsString())
                    as List)
                .map(
                  (m) => domain.RawMessage(
                    id: m['id'] as String,
                    sender: m['sender'] as String,
                    body: m['body'] as String,
                    receivedAt: DateTime.fromMillisecondsSinceEpoch(
                      m['receivedMillis'] as int,
                    ),
                  ),
                )
                .toList();
        final storedSources = (await records.getAll())
            .map((r) => r.sourceMessageId)
            .toSet();
        final missingMovement = <String, int>{};
        for (final message in await raw.getAll()) {
          if (storedSources.contains(message.id)) continue;
          final c = classifier.classify(message.body);
          final parser = ParserFactory.getParser(c.subtype);
          final parsed = parser?.parse(message, c);
          final key = c.status.name == 'failed'
              ? 'recognized_failed_attempt'
              : parsed?.success == true
              ? 'now_parseable_without_stored_movement'
              : c.subtype.name == 'unknown'
              ? 'unsupported_or_notification'
              : 'recognized_parse_failure';
          missingMovement.update(key, (n) => n + 1, ifAbsent: () => 1);
        }
        final service = TransactionImportService(
          classifier: classifier,
          financialRecordsRepository: records,
          rawMessagesRepository: raw,
        );
        final result = await service.importMessages(messages);
        expect(result.total, messages.length);
        expect(result.audit.length, messages.length);
        expect(
          result.audit.map((a) => a.index).toSet().length,
          messages.length,
        );
        final repeat = await service.importMessages(messages);
        expect(repeat.imported, 0);
        expect(repeat.rawCreated, 0);
        expect(repeat.evidenceCreated, 0);
        expect(repeat.total, messages.length);
        final freshDb = AppDatabase.forTesting(NativeDatabase.memory());
        late ImportResult freshResult;
        final fieldDifferences = <String, int>{};
        try {
          freshResult = await TransactionImportService(
            classifier: classifier,
            financialRecordsRepository: FinancialRecordsRepository(freshDb),
            rawMessagesRepository: RawMessagesRepository(freshDb),
          ).importMessages(messages);
          expect(freshResult.total, messages.length);
          final legacy = {
            for (final r in original['financial_records']!)
              r['source_message_id']: r,
          };
          for (final r
              in await freshDb
                  .customSelect('SELECT * FROM financial_records')
                  .get()) {
            final before = legacy[r.data['source_message_id']];
            if (before == null) continue;
            for (final field in [
              'type',
              'subtype',
              'status',
              'amount',
              'balance',
              'transaction_cost',
              'transaction_date',
              'party_name',
              'party_type',
              'party_phone',
              'party_account',
              'party_identifier',
            ]) {
              if (before[field] != r.data[field]) {
                fieldDifferences.update(field, (n) => n + 1, ifAbsent: () => 1);
              }
            }
          }
        } finally {
          await freshDb.close();
        }
        // Existing financial rows and raw content remain byte-for-byte equivalent
        // across import as well as migration. Only newly accepted rows are added.
        for (final table in ['financial_records', 'raw_messages']) {
          final ids = original[table]!.map((r) => r['id'] as int).toList();
          final rows = await db
              .customSelect(
                'SELECT ${columns[table]!.join(',')} FROM $table WHERE id <= ${ids.reduce((a, b) => a > b ? a : b)} ORDER BY id',
              )
              .get();
          expect(
            jsonEncode(rows.map((r) => r.data).toList()) ==
                jsonEncode(original[table]),
            isTrue,
            reason: 'Import changed existing $table data',
          );
        }
        final bounds = await records.getEffectiveDateBounds();
        final period = FinancialPeriod.month(bounds.last!);
        final selected = await records.getForPeriod(period);
        final canonical = const FinancialSemantics().calculate(selected);
        final insights = await InsightsRepository(db).watch(period).first;
        expect(insights.recordCount, selected.length);
        for (final amounts in [
          (insights.totals.income, canonical.income),
          (insights.totals.expenses, canonical.expenses),
          (insights.totals.fees, canonical.fees),
          (insights.totals.netCashFlow, canonical.netCashFlow),
        ]) {
          expect(amounts.$1, closeTo(amounts.$2, 0.00001));
        }
        expect(
          await records.countActivity(ActivityFilter(period: period)),
          selected.length,
        );
        expect(
          await records.getActivity(ActivityFilter(period: period), limit: 50),
          hasLength(selected.length > 50 ? 50 : selected.length),
        );
        final budget = BudgetsRepository(db);
        await budget.create(amount: '1000000');
        final spending = (await budget.watch(period).first).single;
        expect(
          spending.spentMinor!.toDouble() / 100,
          closeTo(canonical.expenses, 0.00001),
        );
        final storage = <String, int>{};
        for (final table in [
          'raw_messages',
          'financial_records',
          'balance_evidence',
        ]) {
          storage[table] =
              (await db
                      .customSelect('SELECT COUNT(*) AS n FROM $table')
                      .getSingle())
                  .read<int>('n');
        }
        // Aggregate output only: no message bodies, names, phones or identifiers.
        debugPrint(
          'DEVICE_AUDIT ${jsonEncode({
            'eligible': messages.length,
            'imported': result.imported,
            'skipped': result.skipped,
            'duplicate': result.duplicate,
            'failed': result.failed,
            'new_raw': result.rawCreated,
            'new_evidence': result.evidenceCreated,
            'reasons': result.reasons,
            'repeat': {'imported': repeat.imported, 'skipped': repeat.skipped, 'duplicate': repeat.duplicate, 'failed': repeat.failed},
            'storage': storage,
            'legacy_raw_without_movement': missingMovement,
            'fresh_replay': {'imported': freshResult.imported, 'skipped': freshResult.skipped, 'duplicate': freshResult.duplicate, 'failed': freshResult.failed, 'new_raw': freshResult.rawCreated, 'new_evidence': freshResult.evidenceCreated, 'reasons': freshResult.reasons},
            'legacy_vs_current_parser_differences': fieldDifferences,
            'latest_month_records': selected.length,
            'migration_preserved': true,
          })}',
        );
      } finally {
        await db.close();
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        await temp.delete(recursive: true);
      }
    },
    skip: capture.isEmpty,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
