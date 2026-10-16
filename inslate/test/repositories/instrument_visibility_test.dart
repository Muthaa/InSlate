import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/instrument_mappings_repository.dart';
import 'package:inslate/repositories/unspecified_movements_repository.dart';
import 'package:inslate/repositories/detected_providers_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialRecordsRepository records;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    records = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());
  test(
    'named and unnamed savings groups and distinct movement families reconcile independently',
    () async {
      const party = Party(
        name: 'Fund',
        type: PartyType.business,
        account: 'A1',
      );
      await records.saveAll([
        record(RecordSubtype.mshwariDeposit, 10),
        record(RecordSubtype.mshwariWithdrawal, 20, party: party),
        record(RecordSubtype.investmentPurchase, 30, party: party),
        record(RecordSubtype.registeredSavingsDeposit, 40, party: party),
      ]);
      final providers = await DetectedProvidersRepository(db).watch().first;
      expect(providers.length, 4);
      for (final provider in providers) {
        expect(await records.countActivity(provider.filter), provider.count);
        expect(
          (await records.getActivity(provider.filter, limit: 50)).length,
          provider.count,
        );
      }
    },
  );

  test(
    'effective unspecified principal, counts and drill-down reconcile at period boundaries without changing fees or income',
    () async {
      await records.saveAll([
        record(RecordSubtype.payBill, 100, fee: 3, date: period.start),
        record(
          RecordSubtype.receiveMoney,
          40,
          fee: 2,
          date: period.end.subtract(const Duration(seconds: 1)),
        ),
        record(RecordSubtype.receiveMoney, 999, date: period.end),
        record(
          RecordSubtype.payBill,
          999,
          date: period.start.subtract(const Duration(seconds: 1)),
        ),
        record(RecordSubtype.buyGoods, 10, fee: 1, date: period.start),
      ]);
      await db.customStatement(
        "UPDATE financial_records SET interpreted_subtype = CASE WHEN subtype = 'payBill' THEN 'instrumentPayment' ELSE 'instrumentReceipt' END, interpreted_type = 'transfer' WHERE subtype IN ('payBill', 'receiveMoney')",
      );
      final summary = await UnspecifiedMovementsRepository(
        db,
      ).watch(period).first;
      expect(summary.outgoing, 100);
      expect(summary.incoming, 40);
      expect(summary.outgoingCount, 1);
      expect(summary.incomingCount, 1);
      for (final incoming in [false, true]) {
        final filter = UnspecifiedMovements.filter(period, incoming: incoming);
        expect(await records.countActivity(filter), 1);
        final rows = await records.getActivity(filter, limit: 50);
        expect(
          rows.single.amount,
          incoming ? summary.incoming : summary.outgoing,
        );
      }
      final insights = await InsightsRepository(db).watch(period).first;
      expect(insights.totals.income, 0);
      expect(insights.totals.expenses, 10);
      expect(insights.totals.fees, 6);
      expect(insights.totals.netCashFlow, -16);
      final next = await UnspecifiedMovementsRepository(
        db,
      ).watch(FinancialPeriod.month(DateTime(2026, 10))).first;
      expect(next.incoming, 999);
      expect(next.outgoingCount, 0);
    },
  );

  test(
    'provider plus reference isolates collisions, aliases, missing references and pagination',
    () async {
      for (final (name, account, n) in [
        ('Fund A', 'SHARED', 55),
        ('Fund B', 'SHARED', 2),
        ('Fund A', 'OTHER', 3),
        (' fund a ', ' shared ', 1),
      ]) {
        await records.saveAll([
          for (var i = 0; i < n; i++)
            record(
              RecordSubtype.investmentPurchase,
              1,
              party: Party(
                name: name,
                type: PartyType.business,
                account: account,
                identifier: 'same-identifier',
              ),
            ),
        ]);
      }
      await records.save(
        record(
          RecordSubtype.investmentRedemption,
          1,
          party: const Party(
            name: 'Fund A',
            type: PartyType.business,
            identifier: 'same-identifier',
          ),
        ),
      );
      final providers = await DetectedProvidersRepository(db).watch().first;
      expect(providers.length, 4);
      for (final provider in providers) {
        expect(await records.countActivity(provider.filter), provider.count);
        final first = await records.getActivity(provider.filter, limit: 50);
        final second = await records.getActivity(
          provider.filter,
          limit: 50,
          offset: 50,
        );
        expect(first.length + second.length, provider.count);
        expect(
          first
              .map((r) => r.id)
              .toSet()
              .intersection(second.map((r) => r.id).toSet()),
          isEmpty,
        );
      }
      final a = providers.singleWhere(
        (p) =>
            p.providerReference?.providerKey == 'fund a' &&
            p.providerReference?.reference == 'shared',
      );
      expect(a.count, 56);
      expect(a.filter.withSearch('fund').provider, a.providerReference);
    },
  );

  test(
    'detected counts and eligible preview counts differ for unsupported shapes without mutation',
    () async {
      final instruments = FinancialInstrumentsRepository(db);
      final instrument = await instruments.create(
        name: 'Product',
        type: InstrumentType.other,
      );
      const party = Party(
        name: 'Provider',
        type: PartyType.business,
        account: 'A-1',
      );
      await records.saveAll([
        record(RecordSubtype.payBill, 10, party: party),
        record(RecordSubtype.buyGoods, 20, party: party),
      ]);
      final mappings = InstrumentMappingsRepository(db);
      expect((await mappings.detectedReferences()).single.count, 2);
      final preview = await mappings.preview(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'A-1',
        purpose: InstrumentPurpose.unknown,
      );
      expect(preview.matching, 1);
      expect(await mappings.list(instrument.id), isEmpty);
      expect(
        (await db.select(db.financialRecords).get()).every(
          (r) => r.interpretedSubtype == null,
        ),
        isTrue,
      );
    },
  );
}
