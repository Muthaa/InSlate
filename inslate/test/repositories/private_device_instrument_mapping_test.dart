import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/constants/instrument_catalogue.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/instrument_history.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/repositories/instrument_mappings_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/repositories/detected_providers_repository.dart';
import 'package:inslate/repositories/unspecified_movements_repository.dart';
import 'package:inslate/services/financial_breakdown_service.dart';
import 'package:inslate/services/financial_semantics.dart';

void main() {
  final directory = Platform.environment['INSLATE_PRIVATE_MAPPING_DIR'];
  test(
    'real private-copy account-reference mapping lifecycle and cross-screen reconciliation',
    () async {
      final folder = Directory(directory!);
      final db = AppDatabase.forTesting(
        NativeDatabase(File('${folder.path}/working.db')),
      );
      final records = FinancialRecordsRepository(db);
      final instruments = FinancialInstrumentsRepository(db);
      final mappings = InstrumentMappingsRepository(db);
      try {
        final registrations = await instruments.list();
        expect(registrations.length, 1);
        final instrument = registrations.single;
        expect(instrument.type, InstrumentType.investmentAccount);
        expect(instrument.isActive, true);
        final provider = instrument.provider!;
        await db.customStatement('ATTACH DATABASE ? AS baseline', [
          '${folder.path}/live-original.db',
        ]);
        Future<void> preserve() async {
          final columns =
              (await db
                      .customSelect('PRAGMA table_info(financial_records)')
                      .get())
                  .map((r) => r.read<String>('name'))
                  .where(
                    (c) => ![
                      'source_account_id',
                      'destination_account_id',
                      'interpreted_type',
                      'interpreted_subtype',
                      'interpretation_mapping_id',
                    ].contains(c),
                  );
          final equality = columns.map((c) => 'n."$c" IS o."$c"').join(' AND ');
          final changed = await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM baseline.financial_records o WHERE NOT EXISTS (SELECT 1 FROM main.financial_records n WHERE n.id=o.id AND $equality)',
              )
              .getSingle();
          expect(
            changed.read<int>('n'),
            0,
            reason: 'Parsed/source/date/fee/reference fields changed',
          );
          expect(
            (await db
                    .customSelect('SELECT COUNT(*) AS n FROM financial_records')
                    .getSingle())
                .read<int>('n'),
            8834,
          );
          for (final table in [
            'accounts',
            'raw_messages',
            'balance_evidence',
            'budgets',
            'transaction_categories',
            'category_rules',
            'record_category_assignments',
          ]) {
            final columns =
                (await db.customSelect('PRAGMA table_info($table)').get()).map(
                  (r) => r.read<String>('name'),
                );
            final equality = columns
                .map((c) => 'n."$c" IS o."$c"')
                .join(' AND ');
            final check = await db
                .customSelect(
                  'SELECT COUNT(*) AS n FROM baseline.$table o WHERE NOT EXISTS (SELECT 1 FROM main.$table n WHERE $equality)',
                )
                .getSingle();
            expect(check.read<int>('n'), 0, reason: '$table changed');
            final count = await db
                .customSelect(
                  'SELECT (SELECT COUNT(*) FROM main.$table) = (SELECT COUNT(*) FROM baseline.$table) AS equal',
                )
                .getSingle();
            expect(count.read<int>('equal'), 1);
          }
        }

        // Uses actual persisted references only. This sandbox does not confirm
        // which customer reference belongs to the registered product in live data.
        final candidate = await db
            .customSelect(
              '''SELECT party_account AS reference, COUNT(*) AS n, SUM(amount) AS principal
        FROM financial_records WHERE lower(trim(party_name)) = lower(trim(?))
        AND party_account IS NOT NULL AND trim(party_account) != ''
        AND subtype = 'investmentPurchase' AND status = 'successful'
        GROUP BY party_account ORDER BY n DESC, principal DESC, party_account LIMIT 1''',
              variables: [Variable(provider)],
            )
            .get();
        // Bind values through Drift rather than interpolating identifiers.
        expect(candidate, isNotEmpty);
        final reference = candidate.single.read<String>('reference');
        final filter = ActivityFilter(
          period: FinancialPeriod.allTime(),
          scope: ActivityScope.investmentsAndSavings,
          subtype: RecordSubtype.investmentPurchase,
          provider: ActivityProviderFilter(
            InstrumentCatalogue.providerKey(provider),
            InstrumentMappingsRepository.referenceKey(reference),
          ),
        );
        final matching = await records.getActivity(filter, limit: 50);
        expect(matching.length, candidate.single.read<int>('n'));
        final principal = matching.fold<double>(0, (n, r) => n + r.amount);
        final months = matching
            .map(
              (r) => FinancialPeriod.month(r.transactionDate ?? r.receivedAt),
            )
            .toSet();
        final baselineTotals = <FinancialPeriod, List<double>>{};
        final baselineBudgets = <FinancialPeriod, List<String>>{};
        Future<void> reconcile(
          FinancialPeriod period, {
          required bool initial,
        }) async {
          final rows = await records.getForPeriod(period);
          final dashboard = const FinancialBreakdownService().dashboard(
            rows,
            period,
          );
          final insights = await InsightsRepository(db).watch(period).first;
          final t = dashboard.totals;
          final values = [
            t.income,
            t.expenses,
            t.fees,
            t.netCashFlow,
            t.borrowed,
            t.repaid,
            t.transfersIntoCentral,
            t.transfersFromCentral,
          ];
          final i = insights.totals;
          expect([
            i.income,
            i.expenses,
            i.fees,
            i.netCashFlow,
            i.borrowed,
            i.repaid,
            i.transfersIntoCentral,
            i.transfersFromCentral,
          ], orderedEquals(values));
          expect(
            await records.countActivity(ActivityFilter(period: period)),
            rows.length,
          );
          for (final scope in [ActivityScope.income, ActivityScope.expenses]) {
            final items = await records.getActivity(
              ActivityFilter(period: period, scope: scope),
            );
            final total = items.fold<double>(
              0,
              (n, r) => n + FinancialSemantics.principalContribution(r),
            );
            expect(
              total,
              closeTo(
                scope == ActivityScope.income ? t.income : t.expenses,
                0.000001,
              ),
            );
          }
          final budgets = await BudgetsRepository(db).watch(period).first;
          final budgetValues = [
            for (final b in budgets)
              '${b.budget.id}:${b.spentMinor}:${b.count}',
          ];
          for (final b in budgets.where((b) => b.budget.overall)) {
            expect(
              b.spentMinor!.toDouble() / 100,
              closeTo(t.expenses, 0.000001),
            );
            expect(await records.countActivity(b.filter!), b.count);
          }
          if (initial) {
            baselineTotals[period] = values;
            baselineBudgets[period] = budgetValues;
          } else {
            expect(values, orderedEquals(baselineTotals[period]!));
            expect(budgetValues, orderedEquals(baselineBudgets[period]!));
          }
        }

        for (final month in months) {
          await reconcile(month, initial: true);
        }
        final preview = await mappings.preview(
          accountId: instrument.id,
          provider: provider,
          reference: reference,
          purpose: InstrumentPurpose.investment,
        );
        expect(preview.matching, matching.length);
        expect(preview.conflicts, 0);
        expect(await mappings.list(instrument.id), isEmpty);
        final result = await mappings.confirm(
          accountId: instrument.id,
          provider: provider,
          reference: reference,
          purpose: InstrumentPurpose.investment,
        );
        expect(result.linked, matching.length);
        expect(result.interpreted, matching.length);
        expect(result.conflicts, 0);
        final mapping = (await mappings.list(instrument.id)).single;
        Future<void> historyCheck() async {
          final history = await instruments.history(
            accountId: instrument.id,
            period: FinancialPeriod.allTime(),
          );
          expect(history.count, matching.length);
          expect(
            history.entries.map((e) => e.record.id).toSet(),
            matching.map((r) => r.id).toSet(),
          );
          expect(
            history.entries.every(
              (e) =>
                  e.role == InstrumentTransactionRole.incoming &&
                  e.record.subtype == RecordSubtype.investmentPurchase,
            ),
            true,
          );
          for (final r in matching) {
            final row = await (db.select(
              db.financialRecords,
            )..where((f) => f.id.equals(r.id!))).getSingle();
            expect(row.destinationAccountId, instrument.id);
            expect(row.sourceAccountId, isNull);
            expect(row.interpretationMappingId, isNotNull);
            expect(row.interpretedSubtype, 'investmentPurchase');
          }
        }

        await historyCheck();
        await preserve();
        for (final month in months) {
          await reconcile(month, initial: false);
        }
        final detected = await DetectedProvidersRepository(db).watch().first;
        final group = detected.singleWhere(
          (p) =>
              p.providerReference?.providerKey ==
                  InstrumentCatalogue.providerKey(provider) &&
              p.providerReference?.reference ==
                  InstrumentMappingsRepository.referenceKey(reference),
        );
        expect(group.count, matching.length);
        expect(await records.countActivity(group.filter), group.count);
        final duplicates = await mappings.preview(
          accountId: instrument.id,
          provider: provider,
          reference: reference,
          purpose: InstrumentPurpose.investment,
        );
        expect(duplicates.conflicts, matching.length);
        await expectLater(
          mappings.confirm(
            accountId: instrument.id,
            provider: provider,
            reference: reference,
            purpose: InstrumentPurpose.investment,
          ),
          throwsStateError,
        );
        await expectLater(
          InstrumentLinksRepository(db).setLink(
            recordId: matching.first.id!,
            endpoint: InstrumentEndpoint.destination,
            instrumentId: null,
            expectedCurrentId: null,
          ),
          throwsStateError,
        );
        await historyCheck();
        await mappings.remove(mapping.id, instrument.id);
        expect(await mappings.list(instrument.id), isEmpty);
        expect(
          (await db
                  .customSelect(
                    'SELECT COUNT(*) AS n FROM financial_records WHERE interpreted_type IS NOT NULL OR interpreted_subtype IS NOT NULL OR interpretation_mapping_id IS NOT NULL',
                  )
                  .getSingle())
              .read<int>('n'),
          0,
        );
        expect(
          (await instruments.history(
            accountId: instrument.id,
            period: FinancialPeriod.allTime(),
          )).count,
          matching.length,
        );
        final reapplied = await mappings.confirm(
          accountId: instrument.id,
          provider: provider,
          reference: reference,
          purpose: InstrumentPurpose.investment,
        );
        expect(reapplied.linked, 0);
        expect(reapplied.interpreted, matching.length);
        expect(reapplied.conflicts, 0);
        await historyCheck();
        await preserve();
        for (final month in months) {
          await reconcile(month, initial: false);
        }
        final unspecified = await UnspecifiedMovementsRepository(
          db,
        ).watch(FinancialPeriod.allTime()).first;
        expect(unspecified.incomingCount + unspecified.outgoingCount, 0);
        final unmatchedIncoming = await db
            .customSelect(
              "SELECT COUNT(*) AS n FROM financial_records WHERE lower(trim(party_name))=lower(trim(?)) AND subtype='investmentRedemption' AND party_account IS NULL AND source_account_id IS NULL",
              variables: [Variable(provider)],
            )
            .getSingle();
        expect(unmatchedIncoming.read<int>('n'), 49);
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
        debugPrint(
          'PRIVATE_MAPPING_RESULT ${jsonEncode({'matchedPurchases': matching.length, 'principal': principal, 'historicalLinks': result.linked, 'effectiveInterpretations': result.interpreted, 'monthPeriodsReconciled': months.length, 'incomingWithoutReferences': 49, 'duplicatePreviewConflicts': duplicates.conflicts, 'duplicateConfirmationRejected': true, 'staleUnlinkRejected': true, 'removalRetainsLinks': true, 'reapplicationNewLinks': reapplied.linked, 'parsedAndOtherTablesPreserved': true, 'integrity': 'ok'})}',
        );
      } finally {
        await db.close();
      }
    },
    skip: directory == null
        ? 'Opt-in private live-device copy required'
        : false,
  );
}
