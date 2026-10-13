import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart' hide FinancialRecord;
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/widgets/transaction_row.dart';
import '../services/financial_summary_service_test.dart' show record;

class _SearchRepository extends FinancialRecordsRepository {
  final queries = <({ActivityFilter filter, int offset})>[];
  int counts = 0;
  _SearchRepository(super.database);
  @override
  Future<List<FinancialRecord>> getAll() =>
      throw StateError('Search must not load history');
  @override
  Future<List<FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
  }) {
    queries.add((filter: filter, offset: offset));
    return super.getActivity(filter, limit: limit, offset: offset);
  }

  @override
  Future<int> countActivity(ActivityFilter filter) {
    counts++;
    return super.countActivity(filter);
  }
}

void main() {
  late AppDatabase db;
  late _SearchRepository repository;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  const alice = Party(
    name: 'Alice',
    type: PartyType.person,
    identifier: 'Alice-ID',
    phone: '0712345678',
  );
  const bob = Party(name: 'Bob', type: PartyType.person);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = _SearchRepository(db);
  });
  tearDown(() => db.close());
  final searchField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == 'Search transactions',
  );

  Future<void> open(WidgetTester tester, [ActivityFilter? filter]) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            initialFilter: filter ?? ActivityFilter(period: period),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(searchField, text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void searchTest(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });

  searchTest(
    'debounced search filters complete dataset resets page and exact counts; clear restores',
    (tester) async {
      await repository.saveAll([
        for (var i = 0; i < 80; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), party: alice),
        for (var i = 0; i < 80; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), party: bob),
      ]);
      await open(tester);
      await tap(tester, find.byTooltip('Last page'));
      expect(find.text('4 of 4'), findsOneWidget);
      final reads = repository.queries.length;
      final counts = repository.counts;
      await tester.enterText(searchField, 'Al');
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.queries.length, reads);
      await tester.enterText(searchField, 'Alice');
      await tester.pump(const Duration(milliseconds: 299));
      expect(repository.queries.length, reads);
      expect(repository.counts, counts);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(repository.queries.length, reads + 1);
      expect(repository.queries.last.offset, 0);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('80 transactions'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      await tap(tester, find.byTooltip('Next page'));
      final beforeEquivalent = repository.queries.length;
      await search(tester, ' ALICE  ');
      expect(repository.queries.length, beforeEquivalent);
      expect(find.text('2 of 2'), findsOneWidget);
      await tap(tester, find.byTooltip('Clear search'));
      expect(find.text('1 of 4'), findsOneWidget);
      expect(find.text('160 transactions'), findsOneWidget);
      expect(repository.queries.last.filter.search, '');
      expect(tester.widget<TextField>(searchField).controller!.text, '');
    },
  );

  searchTest(
    'Dashboard filter snapshot composes with search and no-results clearing',
    (tester) async {
      await repository.saveAll([
        record(RecordSubtype.sendMoney, 1, party: alice),
        record(RecordSubtype.payBill, 2, party: alice),
        record(RecordSubtype.sendMoney, 3, party: bob),
      ]);
      final initial = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        subtype: RecordSubtype.sendMoney,
        party: PartyIdentity.fromParty(alice),
        partyPresence: PartyPresence.identified,
        resolution: SemanticResolution.resolved,
      );
      await open(tester, initial);
      await search(tester, '  0712  ');
      expect(repository.queries.last.filter, initial.withSearch('0712'));
      expect(find.text('1 transactions'), findsOneWidget);
      await search(tester, 'unmatched');
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(find.text('0 transactions · 0 pages'), findsOneWidget);
      await tap(tester, find.byTooltip('Clear search'));
      expect(repository.queries.last.filter, initial);
      expect(find.text('1 transactions'), findsOneWidget);
      expect(find.text('No matching transactions'), findsNothing);
    },
  );

  searchTest('period and scope changes preserve effective search', (
    tester,
  ) async {
    await repository.saveAll([
      record(RecordSubtype.sendMoney, 1, party: alice),
      record(RecordSubtype.sendMoney, 2, party: alice, date: DateTime(2026, 8)),
      record(RecordSubtype.receiveMoney, 3, party: bob),
    ]);
    await open(
      tester,
      ActivityFilter(period: period, scope: ActivityScope.expenses),
    );
    await search(tester, 'Alice');
    await tap(tester, find.text('September 2026'));
    await tap(tester, find.text('August 2026').last);
    expect(
      repository.queries.last.filter.period,
      FinancialPeriod.month(DateTime(2026, 8)),
    );
    expect(repository.queries.last.filter.search, 'alice');
    await tap(tester, find.widgetWithText(ChoiceChip, 'Income'));
    expect(repository.queries.last.filter.search, 'alice');
    expect(repository.queries.last.filter.scope, ActivityScope.income);
    expect(find.text('No matching transactions'), findsOneWidget);
  });

  searchTest(
    'transfer direction and account selectors retain search snapshot',
    (tester) async {
      await repository.saveAll([
        record(RecordSubtype.investmentPurchase, 1, party: alice),
        record(RecordSubtype.investmentRedemption, 2, party: alice),
      ]);
      await open(
        tester,
        ActivityFilter(period: period, scope: ActivityScope.internalTransfers),
      );
      await search(tester, 'Alice');
      await tap(tester, find.text('All directions'));
      await tap(tester, find.text('From M-PESA').last);
      expect(
        repository.queries.last.filter.direction,
        TransferDirection.fromCentral,
      );
      expect(repository.queries.last.filter.search, 'alice');
      await tap(tester, find.text('All accounts'));
      await tap(tester, find.text('Investments').last);
      expect(
        repository.queries.last.filter.endpoint,
        const AccountEndpoint(AccountType.investment),
      );
      expect(repository.queries.last.filter.search, 'alice');
      expect(find.text('1 transactions'), findsOneWidget);
    },
  );

  searchTest(
    'transaction detail return retains search page and filters without requery',
    (tester) async {
      await repository.saveAll([
        for (var i = 0; i < 70; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), party: alice),
        record(RecordSubtype.sendMoney, 999, party: bob),
      ]);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        party: PartyIdentity.fromParty(alice),
      );
      await open(tester, filter);
      await search(tester, 'Alice');
      await tap(tester, find.byTooltip('Next page'));
      final reads = repository.queries.length;
      await tap(tester, find.widgetWithText(TransactionRow, 'Alice').first);
      expect(find.text('Transaction details'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(searchField).controller!.text, 'Alice');
      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('70 transactions'), findsOneWidget);
      expect(repository.queries.last.filter, filter.withSearch('alice'));
      expect(repository.queries.length, reads);
    },
  );

  searchTest(
    'refresh retains search and typed filters and resets pagination as before',
    (tester) async {
      await repository.saveAll([
        for (var i = 0; i < 70; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), party: alice),
      ]);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        subtype: RecordSubtype.sendMoney,
      );
      await open(tester, filter.withSearch('alice'));
      expect(tester.widget<TextField>(searchField).controller!.text, 'alice');
      await tap(tester, find.byTooltip('Next page'));
      await tap(tester, find.byTooltip('Refresh activity'));
      expect(find.text('1 of 2'), findsOneWidget);
      expect(repository.queries.last.filter, filter.withSearch('alice'));
      expect(find.text('70 transactions'), findsOneWidget);
    },
  );

  searchTest(
    'clearing cancels a pending search and whitespace alone executes no query',
    (tester) async {
      await open(tester);
      final reads = repository.queries.length;
      await search(tester, '  \t ');
      expect(repository.queries.length, reads);
      expect(find.text('Nothing to show yet'), findsOneWidget);
      await tester.enterText(searchField, 'Alice');
      await tester.pump(const Duration(milliseconds: 100));
      await tap(tester, find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.queries.length, reads);
    },
  );
}
