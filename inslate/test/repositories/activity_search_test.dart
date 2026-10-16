import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart' hide FinancialRecord;
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialRecordsRepository repository;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());

  FinancialRecord fixture({
    String title = 'Normal title',
    String reference = 'NORMAL',
    String raw = '',
    Party? party,
  }) => FinancialRecord(
    reference: reference,
    transactionDate: period.start,
    amount: 10,
    balance: null,
    type: FinancialRecordType.expense,
    subtype: RecordSubtype.sendMoney,
    status: record(RecordSubtype.sendMoney, 10).status,
    title: title,
    rawMessage: raw,
    receivedAt: period.start,
    party: party,
  );

  for (final field in [
    'name',
    'title',
    'reference',
    'phone',
    'account',
    'identifier',
  ]) {
    test(
      'search matches stored $field case-insensitively before count',
      () async {
        final hit = fixture(
          title: field == 'title' ? 'Before NeEdLe After' : 'Normal title',
          reference: field == 'reference' ? 'NeEdLe123' : 'NORMAL',
          party: Party(
            name: field == 'name' ? 'NeEdLe Business' : 'Ordinary party',
            type: PartyType.person,
            phone: field == 'phone' ? '+NeEdLe123' : null,
            account: field == 'account' ? 'AccNeEdLe' : null,
            identifier: field == 'identifier' ? 'NeEdLe-ID' : null,
          ),
        );
        await repository.saveAll([hit, fixture()]);
        final filter = ActivityFilter(period: period, search: '  NEEDLE  ');
        expect((await repository.getActivity(filter, limit: 50)).length, 1);
        expect(await repository.countActivity(filter), 1);
        expect(filter.matches(hit), isTrue);
      },
    );
  }

  test(
    'normalization defines provider identity and copies preserve search',
    () {
      final filter = ActivityFilter(period: period, search: '  AbC \n');
      expect(filter, ActivityFilter(period: period, search: 'abc'));
      expect(
        filter.hashCode,
        ActivityFilter(period: period, search: 'abc').hashCode,
      );
      expect(
        filter.withPeriod(FinancialPeriod.month(DateTime(2026, 8))).search,
        'abc',
      );
      expect(filter.withScope(ActivityScope.expenses).search, 'abc');
      expect(filter.withSearch(' \t '), ActivityFilter(period: period));
      expect(filter.withSearch('xyz'), isNot(filter));
    },
  );

  test(
    'whitespace is unfiltered and raw SMS and category names are excluded',
    () async {
      await repository.saveAll([fixture(raw: 'secret-sms'), fixture()]);
      final id = (await repository.getActivity(
        ActivityFilter(period: period),
      )).first.id!;
      await CategoriesRepository(
        db,
      ).assign(recordId: id, categoryId: 'builtin.expense.food');
      expect(
        await repository.countActivity(
          ActivityFilter(period: period, search: ' \n '),
        ),
        2,
      );
      expect(
        await repository.getActivity(
          ActivityFilter(period: period, search: 'secret-sms'),
        ),
        isEmpty,
      );
      expect(
        await repository.countActivity(
          ActivityFilter(period: period, search: 'Food & groceries'),
        ),
        0,
      );
    },
  );

  test(
    'substring punctuation is literal rather than SQL wildcard or injection',
    () async {
      await repository.saveAll([
        fixture(title: "Shop 50%_off 'sale'"),
        fixture(title: 'Shop 500 off sale'),
      ]);
      for (final term in ['%', '_', "'sale'"]) {
        expect(
          await repository.countActivity(
            ActivityFilter(period: period, search: term),
          ),
          1,
        );
      }
      expect(
        await repository.countActivity(
          ActivityFilter(period: period, search: "' OR 1=1 --"),
        ),
        0,
      );
    },
  );

  test(
    'count and pagination search beyond first 50 and stay period bounded',
    () async {
      const alice = Party(name: 'Alice', type: PartyType.person);
      await repository.saveAll([
        for (var i = 0; i < 123; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), party: alice),
        for (var i = 0; i < 80; i++)
          record(RecordSubtype.sendMoney, 900 + i.toDouble()),
        record(RecordSubtype.sendMoney, 2000, party: alice, date: period.end),
      ]);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        search: 'alice',
      );
      expect(await repository.countActivity(filter), 123);
      final ids = <int>[];
      for (final offset in [0, 50, 100]) {
        final page = await repository.getActivity(
          filter,
          limit: 50,
          offset: offset,
        );
        expect(page, hasLength(offset == 100 ? 23 : 50));
        ids.addAll(page.map((r) => r.id!));
      }
      expect(ids.toSet(), hasLength(123));
      // Inspect the existing schema's representative search query without adding
      // an index speculatively. Includes the same period and six search columns.
      final fields = [
        'party_name',
        'title',
        'reference',
        'party_phone',
        'party_account',
        'party_identifier',
      ];
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT id FROM financial_records WHERE COALESCE(transaction_date, received_at) >= ? AND COALESCE(transaction_date, received_at) < ? AND (${fields.map((c) => 'instr(lower($c), ?) > 0').join(' OR ')}) ORDER BY COALESCE(transaction_date, received_at) DESC, id DESC LIMIT 51',
            variables: [
              Variable<int>(period.start.millisecondsSinceEpoch ~/ 1000),
              Variable<int>(period.end.millisecondsSinceEpoch ~/ 1000),
              for (final _ in fields) const Variable<String>('alice'),
            ],
          )
          .get();
      // ignore: avoid_print
      print(
        'Activity search query plan: ${plan.map((row) => row.read<String>('detail')).join('; ')}',
      );
    },
  );

  test(
    'search composes with scope subtype identity presence and resolution',
    () async {
      const alice = Party(
        name: 'Alice',
        type: PartyType.person,
        identifier: ' Alice-ID ',
      );
      await repository.saveAll([
        record(RecordSubtype.sendMoney, 1, party: alice),
        record(RecordSubtype.receiveMoney, 2, party: alice),
        record(
          RecordSubtype.sendMoney,
          3,
          party: alice,
          type: FinancialRecordType.loan,
        ),
        record(RecordSubtype.sendMoney, 4),
        record(RecordSubtype.payBill, 5, party: alice),
      ]);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        subtype: RecordSubtype.sendMoney,
        party: PartyIdentity.fromParty(alice),
        partyPresence: PartyPresence.identified,
        resolution: SemanticResolution.resolved,
        search: 'ALICE',
      );
      expect((await repository.getActivity(filter)).map((r) => r.amount), [1]);
      expect(await repository.countActivity(filter), 1);
      expect(
        await repository.countActivity(
          ActivityFilter(
            period: period,
            resolution: SemanticResolution.unresolved,
            search: 'alice',
          ),
        ),
        1,
      );
      expect(
        await repository.countActivity(
          ActivityFilter(
            period: period,
            partyPresence: PartyPresence.unidentified,
            search: 'sendmoney',
          ),
        ),
        1,
      );
    },
  );

  test(
    'identity batching preserves Unicode policy alongside database search',
    () async {
      const same = Party(
        name: 'MATCH',
        type: PartyType.person,
        identifier: '\u00a0İD\u00a0',
      );
      const different = Party(
        name: 'MATCH',
        type: PartyType.person,
        identifier: 'else',
      );
      await repository.saveAll([
        for (var i = 0; i < 205; i++)
          record(
            RecordSubtype.sendMoney,
            i.toDouble(),
            party: i.isEven ? same : different,
          ),
      ]);
      final filter = ActivityFilter(
        period: period,
        party: PartyIdentity.fromParty(same),
        search: 'match',
      );
      expect(await repository.countActivity(filter), 103);
      expect(
        await repository.getActivity(filter, limit: 50, offset: 100),
        hasLength(3),
      );
      expect(await repository.getActivity(filter.withSearch('else')), isEmpty);
    },
  );

  test(
    'search retains transfer direction account family and instrument identity',
    () async {
      const fund = Party(
        name: 'Fund Alpha',
        type: PartyType.business,
        identifier: ' Fund-A ',
      );
      await repository.saveAll([
        record(RecordSubtype.investmentPurchase, 1, party: fund),
        record(RecordSubtype.investmentRedemption, 2, party: fund),
        record(RecordSubtype.mshwariDeposit, 3, party: fund),
        record(
          RecordSubtype.investmentPurchase,
          4,
          party: fund,
          type: FinancialRecordType.income,
        ),
      ]);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.investmentsAndSavings,
        direction: TransferDirection.fromCentral,
        endpoint: AccountEndpoint(
          AccountType.investment,
          identity: PartyIdentity.fromParty(fund),
        ),
        search: 'fund',
      );
      expect((await repository.getActivity(filter)).map((r) => r.amount), [1]);
      expect(await repository.countActivity(filter), 1);
      expect(await repository.countActivity(filter.withSearch('missing')), 0);
    },
  );

  test(
    'SQLite ASCII case folding agrees with Dart search verification',
    () async {
      final hit = fixture(title: 'ÉCOLE');
      await repository.save(hit);
      for (final query in ['École', 'école']) {
        final filter = ActivityFilter(period: period, search: query);
        expect(
          await repository.countActivity(filter),
          filter.matches(hit) ? 1 : 0,
        );
      }
    },
  );
}
