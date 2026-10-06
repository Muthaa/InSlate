import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase database;
  late FinancialRecordsRepository repository;
  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinancialRecordsRepository(database);
  });
  tearDown(() => database.close());

  test(
    'Activity counts reconcile with paginated filters including identity batches',
    () async {
      final period = FinancialPeriod.month(DateTime(2026, 9));
      const alice = Party(
        name: 'ALICE',
        type: PartyType.person,
        identifier: ' Alice-ID ',
      );
      await repository.saveAll([
        for (var i = 0; i < 205; i++)
          record(
            RecordSubtype.sendMoney,
            i.toDouble(),
            party: i.isEven
                ? alice
                : const Party(name: 'Bob', type: PartyType.person),
          ),
        record(RecordSubtype.receiveMoney, 12, party: alice),
        record(RecordSubtype.mshwariDeposit, 50),
        record(RecordSubtype.fulizaLoan, 100),
        record(RecordSubtype.sendMoney, 999, party: alice, date: period.end),
      ]);
      for (final filter in [
        ActivityFilter(period: period),
        ActivityFilter(period: period, scope: ActivityScope.expenses),
        ActivityFilter(period: period, scope: ActivityScope.loans),
        ActivityFilter(period: period, party: PartyIdentity.fromParty(alice)),
        ActivityFilter(
          period: period,
          scope: ActivityScope.expenses,
          party: PartyIdentity.fromParty(alice),
        ),
        ActivityFilter(
          period: period,
          direction: TransferDirection.fromCentral,
          scope: ActivityScope.internalTransfers,
        ),
        ActivityFilter(period: FinancialPeriod.month(DateTime(2025, 1))),
      ]) {
        final all = await repository.getActivity(filter);
        expect(await repository.countActivity(filter), all.length);
        if (all.isNotEmpty) {
          final lastOffset = ((all.length - 1) ~/ 50) * 50;
          expect(
            await repository.getActivity(filter, offset: lastOffset, limit: 50),
            hasLength(all.length - lastOffset),
          );
        }
      }
      expect(
        await repository.countActivity(
          ActivityFilter(period: period, party: PartyIdentity.fromParty(alice)),
        ),
        104,
      );
    },
  );

  test(
    'period uses transaction date or fallback and excludes next month',
    () async {
      final period = FinancialPeriod.month(DateTime(2026, 12));
      await repository.saveAll([
        record(
          RecordSubtype.receiveMoney,
          1,
          date: period.start,
          receivedAt: DateTime(2027, 1),
        ),
        record(
          RecordSubtype.receiveMoney,
          2,
          receivedAt: period.end.subtract(const Duration(seconds: 1)),
        ),
        record(RecordSubtype.receiveMoney, 3, date: period.end),
        record(
          RecordSubtype.receiveMoney,
          4,
          receivedAt: period.start.subtract(const Duration(seconds: 1)),
        ),
        record(
          RecordSubtype.receiveMoney,
          5,
          date: DateTime(2026, 11),
          receivedAt: period.start,
        ),
      ]);
      expect((await repository.getForPeriod(period)).map((r) => r.amount), [
        2,
        1,
      ]);
      expect(await repository.getAll(), hasLength(5));
      expect(await repository.getEffectiveMonths(), {
        DateTime(2026, 11),
        DateTime(2026, 12),
        DateTime(2027, 1),
      });
      final bounds = await repository.getEffectiveDateBounds();
      expect(bounds.first, DateTime(2026, 11));
      expect(bounds.last, DateTime(2027, 1));
    },
  );

  test(
    'SQL and domain agree for every scope, subtype and transfer filter',
    () async {
      final records = RecordSubtype.values
          .map((s) => record(s, s.index + 1.0))
          .toList();
      records.add(
        record(
          RecordSubtype.investmentPurchase,
          999,
          type: FinancialRecordType.expense,
        ),
      );
      await repository.saveAll(records);
      final period = FinancialPeriod.month(DateTime(2026, 9));
      final filters = [
        for (final scope in ActivityScope.values)
          ActivityFilter(period: period, scope: scope),
        for (final resolution in SemanticResolution.values)
          ActivityFilter(period: period, resolution: resolution),
        for (final presence in PartyPresence.values)
          ActivityFilter(period: period, partyPresence: presence),
        for (final subtype in RecordSubtype.values)
          ActivityFilter(period: period, subtype: subtype),
        for (final direction in TransferDirection.values)
          ActivityFilter(period: period, direction: direction),
        ActivityFilter(
          period: period,
          endpoint: const AccountEndpoint(AccountType.mshwariSavings),
        ),
        ActivityFilter(
          period: period,
          endpoint: const AccountEndpoint(AccountType.investment),
        ),
        ActivityFilter(
          period: period,
          direction: TransferDirection.intoCentral,
          central: const AccountEndpoint(AccountType.kcbMpesa),
        ),
      ];
      for (final filter in filters) {
        final expected = records
            .where(filter.matches)
            .map((r) => r.amount)
            .toSet();
        expect(
          (await repository.getActivity(filter)).map((r) => r.amount).toSet(),
          expected,
          reason: '${filter.scope} ${filter.subtype} ${filter.direction}',
        );
      }
    },
  );

  test(
    'party identities do not merge names and retain identifier precedence',
    () async {
      const alice = Party(
        name: 'Same name',
        type: PartyType.person,
        identifier: ' ID-A ',
      );
      const other = Party(
        name: 'Same name',
        type: PartyType.person,
        identifier: 'id-b',
      );
      const renamed = Party(
        name: 'Renamed',
        type: PartyType.business,
        identifier: 'id-a',
      );
      const phone = Party(
        name: 'Same name',
        type: PartyType.person,
        phone: ' 123 ',
      );
      const account = Party(
        name: 'Same name',
        type: PartyType.person,
        account: ' AB ',
      );
      const named = Party(name: ' Same name ', type: PartyType.person);
      final parties = [alice, other, renamed, phone, account, named];
      final records = [
        for (var i = 0; i < parties.length; i++)
          record(RecordSubtype.sendMoney, i + 1.0, party: parties[i]),
      ];
      await repository.saveAll(records);
      final period = FinancialPeriod.month(DateTime(2026, 9));
      for (final party in parties) {
        final filter = ActivityFilter(
          period: period,
          party: PartyIdentity.fromParty(party),
        );
        expect(
          (await repository.getActivity(filter)).map((r) => r.amount).toSet(),
          records.where(filter.matches).map((r) => r.amount).toSet(),
        );
      }
      await repository.save(
        record(RecordSubtype.investmentPurchase, 10, party: alice),
      );
      final investment = ActivityFilter(
        period: period,
        endpoint: AccountEndpoint(
          AccountType.investment,
          identity: PartyIdentity.fromParty(alice),
        ),
      );
      expect((await repository.getActivity(investment)).single.amount, 10);
    },
  );

  test(
    'filtering happens before deterministic pagination, including same references',
    () async {
      await repository.saveAll([
        for (var i = 0; i < 8; i++)
          record(
            i.isEven ? RecordSubtype.sendMoney : RecordSubtype.receiveMoney,
            i.toDouble(),
          ),
      ]);
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        scope: ActivityScope.expenses,
      );
      expect(
        (await repository.getActivity(filter, limit: 2)).map((r) => r.amount),
        [6, 4],
      );
      expect(
        (await repository.getActivity(
          filter,
          limit: 2,
          offset: 2,
        )).map((r) => r.amount),
        [2, 0],
      );
      expect(
        await repository.getActivity(filter, limit: 2, offset: 4),
        isEmpty,
      );
      expect(
        (await repository.getActivity(filter, offset: 2)).map((r) => r.amount),
        [2, 0],
      );
    },
  );

  test('empty metadata has null bounds and no months', () async {
    expect(await repository.getEffectiveMonths(), isEmpty);
    expect(await repository.getEffectiveDateBounds(), (
      first: null,
      last: null,
    ));
  });

  test(
    'Unicode party normalization and pagination agree with shared identity',
    () async {
      const original = Party(
        name: '\u00a0ÉLODIE\u00a0',
        type: PartyType.person,
      );
      const normalized = Party(name: 'élodie', type: PartyType.person);
      await repository.saveAll([
        for (var i = 0; i < 205; i++)
          record(
            RecordSubtype.sendMoney,
            i.toDouble(),
            party: i.isEven ? original : null,
          ),
      ]);
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        party: PartyIdentity.fromParty(normalized),
      );
      final page = await repository.getActivity(filter, offset: 49, limit: 3);
      expect(page.map((record) => record.amount), [106, 104, 102]);
      expect(await repository.getActivity(filter), hasLength(103));
    },
  );
}
