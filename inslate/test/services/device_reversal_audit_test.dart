import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/paybill_reversals_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/services/paybill_reversal_parser.dart';

void main() {
  final path = Platform.environment['PHASE11R_DEVICE_AUDIT_DIR'];
  test(
    'private five-confirmation replay and optional device before/after reconciliation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inslate_reversal_host_',
      );
      final beforeFile = File('$path/before.db');
      final copy = await beforeFile.copy('${directory.path}/host.db');
      final db = AppDatabase.forTesting(NativeDatabase(copy));
      const tables = [
        'accounts',
        'raw_messages',
        'financial_records',
        'transaction_categories',
        'category_rules',
        'record_category_assignments',
        'balance_evidence',
        'budgets',
      ];
      Future<Map<String, List<Map<String, dynamic>>>> snapshot(
        AppDatabase database,
      ) async => {
        for (final table in tables)
          table: (await database.customSelect('SELECT * FROM $table').get())
              .map((r) => Map<String, dynamic>.from(r.data))
              .toList(),
      };
      try {
        final before = await snapshot(db);
        final repository = PayBillReversalsRepository(db);
        final ids = await repository.retainedConfirmationIds();
        expect(ids.length, 5);
        final originalRecords = await FinancialRecordsRepository(db).getAll();
        final totalsBefore = const FinancialSemantics().calculate(
          originalRecords,
        );
        final result = await repository.process(ids, requireAllSupported: true);
        expect(result.where((r) => r.imported), hasLength(5));
        expect(result.fold<int>(0, (n, r) => n + r.evidenceCreated), 5);
        final after = await snapshot(db);
        for (final table in tables.where(
          (t) => t != 'financial_records' && t != 'balance_evidence',
        )) {
          expect(
            jsonEncode(after[table]) == jsonEncode(before[table]),
            isTrue,
            reason: '$table preservation',
          );
        }
        expect(
          jsonEncode(
                after['financial_records']!
                    .take(originalRecords.length)
                    .toList(),
              ) ==
              jsonEncode(before['financial_records']),
          isTrue,
        );
        expect(after['financial_records']!.length, originalRecords.length + 5);
        final all = await FinancialRecordsRepository(db).getAll();
        final adjustments = all
            .where((r) => r.reversesRecordId != null)
            .toList();
        expect(adjustments, hasLength(5));
        final returned = adjustments.fold<double>(
          0,
          (sum, r) => sum + r.amount,
        );
        final totalsAfter = const FinancialSemantics().calculate(all);
        expect(
          totalsAfter.expenses,
          closeTo(totalsBefore.expenses - returned, 1e-6),
        );
        expect(
          totalsAfter.netCashFlow,
          closeTo(totalsBefore.netCashFlow + returned, 1e-6),
        );
        expect(totalsAfter.fees, totalsBefore.fees);
        expect(totalsAfter.income, totalsBefore.income);
        expect(totalsAfter.borrowed, totalsBefore.borrowed);
        expect(totalsAfter.repaid, totalsBefore.repaid);
        expect(totalsAfter.internalTransfers, totalsBefore.internalTransfers);
        final raw = await (db.select(
          db.rawMessages,
        )..where((r) => r.sourceId.isIn(ids))).get();
        for (final message in raw) {
          final claim = PayBillReversalParser().parse(
            domain.RawMessage(
              id: message.sourceId,
              sender: message.sender,
              body: message.body,
              receivedAt: message.receivedAt,
            ),
          )!;
          final adjustment = adjustments.singleWhere(
            (r) => r.sourceMessageId == message.sourceId,
          );
          expect(adjustment.transactionDate, claim.declaredAt);
          expect(adjustment.transactionCost, 0);
          final original = originalRecords.singleWhere(
            (r) => r.id == adjustment.reversesRecordId,
          );
          expect(original.amount, adjustment.amount);
          expect(
            original.transactionDate!.isBefore(adjustment.transactionDate!),
            isTrue,
          );
          final evidence = (await db.select(db.balanceEvidence).get())
              .singleWhere((e) => e.rawMessageId == message.id);
          expect(evidence.amountMinor, claim.walletMinor);
          expect(evidence.accountId, null);
          expect(evidence.timeBasis, 'sms_declared_minute');
        }
        for (final month
            in adjustments
                .map((r) => FinancialPeriod.month(r.transactionDate!))
                .toSet()) {
          final summary = await InsightsRepository(db).watch(month).first;
          final expected = const FinancialSemantics().calculate(
            all.where((r) => month.contains(r.transactionDate ?? r.receivedAt)),
          );
          expect(summary.totals.expenses, closeTo(expected.expenses, 1e-6));
          expect(summary.totals.fees, closeTo(expected.fees, 1e-6));
        }
        expect(
          (await repository.process(
            ids,
            requireAllSupported: true,
          )).every((r) => r.duplicate),
          true,
        );
        expect(jsonEncode(await snapshot(db)) == jsonEncode(after), isTrue);
        final deviceAfter = File('$path/after.db');
        if (await deviceAfter.exists()) {
          final device = AppDatabase.forTesting(
            NativeDatabase(
              await deviceAfter.copy('${directory.path}/device_after.db'),
            ),
          );
          try {
            final observed = await snapshot(device);
            for (final table in tables.where(
              (t) => t != 'financial_records' && t != 'balance_evidence',
            )) {
              expect(
                jsonEncode(observed[table]) == jsonEncode(before[table]),
                isTrue,
                reason: 'device $table preservation',
              );
            }
            expect(
              jsonEncode(
                    observed['financial_records']!
                        .take(originalRecords.length)
                        .toList(),
                  ) ==
                  jsonEncode(before['financial_records']),
              isTrue,
            );
            expect(
              observed['financial_records']!.length,
              originalRecords.length + 5,
            );
            // Creation times and newly allocated IDs can differ from a host replay.
            List<Map<String, dynamic>> stable(
              List<Map<String, dynamic>> rows,
            ) => rows
                .map(
                  (r) => Map<String, dynamic>.from(r)
                    ..remove('created_at')
                    ..remove('created_millis'),
                )
                .toList();
            expect(
              jsonEncode(
                    stable(
                      observed['financial_records']!
                          .skip(originalRecords.length)
                          .toList(),
                    ),
                  ) ==
                  jsonEncode(
                    stable(
                      after['financial_records']!
                          .skip(originalRecords.length)
                          .toList(),
                    ),
                  ),
              isTrue,
              reason: 'Device reversal content matches verified replay',
            );
            expect(
              jsonEncode(stable(observed['balance_evidence']!)) ==
                  jsonEncode(stable(after['balance_evidence']!)),
              isTrue,
              reason: 'Device wallet evidence matches verified replay',
            );
            expect(
              await device.customSelect('PRAGMA foreign_key_check').get(),
              isEmpty,
            );
            expect(
              (await device.customSelect('PRAGMA integrity_check').getSingle())
                  .read<String>('integrity_check'),
              'ok',
            );
          } finally {
            await device.close();
          }
        }
        // Aggregate report only; no bodies, references, parties or per-message amounts.
        // ignore: avoid_print
        print(
          'Phase11R: checked=5 created=5 repeat_duplicates=5 raw_unchanged=true original_records_unchanged=true expense_principal_delta=${-returned} fee_delta=0 income_delta=0 net_cash_flow_delta=$returned device_after_checked=${await deviceAfter.exists()}',
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
    skip: path == null ? 'Opt-in private device evidence required.' : false,
  );
}
