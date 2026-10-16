import 'package:drift/native.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart' hide FinancialRecord;
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/widgets/transaction_row.dart';
import '../services/financial_summary_service_test.dart' show record;

class _Repository extends FinancialRecordsRepository {
  int reads = 0, months = 0;
  ActivityFilter? last;
  _Repository(super.database);
  @override
  Future<List<FinancialRecord>> getAll() =>
      throw StateError('Do not load history');
  @override
  Future<List<FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
  }) {
    reads++;
    last = filter;
    return super.getActivity(filter, limit: limit, offset: offset);
  }

  @override
  Future<Set<DateTime>> getEffectiveMonths() {
    months++;
    return super.getEffectiveMonths();
  }
}

void main() {
  late AppDatabase db;
  late _Repository records;
  late CategoriesRepository categories;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  const food = ActivityCategoryFilter.category('builtin.expense.food');
  const alice = Party(name: 'Alice', type: PartyType.person, identifier: 'id');
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    records = _Repository(db);
    categories = CategoriesRepository(db);
  });
  tearDown(() => db.close());
  Future<void> seed([int n = 61]) async {
    await records.saveAll(
      List.generate(
        n + 2,
        (_) => record(RecordSubtype.sendMoney, 10, party: alice),
      ),
    );
    final rows = await db.financialRecordsDao.getAllRecords();
    await db.batch(
      (b) => b.insertAll(db.recordCategoryAssignments, [
        for (final r in rows.take(n))
          RecordCategoryAssignmentsCompanion.insert(
            financialRecordId: r.id,
            categoryId: Value(food.categoryId),
            origin: 'manual',
          ),
      ]),
    );
  }

  Future<void> open(
    WidgetTester tester, {
    ActivityFilter? filter,
    bool drillDown = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          financialRecordsRepositoryProvider.overrideWithValue(records),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            initialFilter: filter ?? ActivityFilter(period: period),
            preserveDrillDown: drillDown,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await tap(tester, find.text('Filters'));
    await tap(
      tester,
      find.byType(DropdownButtonFormField<ActivityCategoryFilter>),
    );
    await tap(tester, find.text(label).last);
    await tap(tester, find.text('Apply filters'));
  }

  final search = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == 'Search transactions',
  );
  void screenTest(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });

  screenTest(
    'category selection resets page and composes with search, exact count and pagination',
    (tester) async {
      await seed();
      await open(tester);
      await tap(tester, find.text('Next'));
      expect(find.text('Page 2'), findsOneWidget);
      await tester.enterText(search, 'Alice');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await choose(tester, 'Food & groceries (expense)');
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('61 transactions'), findsOneWidget);
      expect(records.last!.search, 'alice');
      expect(records.last!.category, food);
      await tap(tester, find.text('Next'));
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(11));
      await choose(tester, 'Uncategorized');
      expect(find.text('2 transactions'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
    },
  );
  screenTest(
    'hidden categories are selectable and scope incompatibility is an empty intersection',
    (tester) async {
      await seed(1);
      await categories.setHidden(food.categoryId!, true);
      await open(tester);
      await choose(tester, 'Food & groceries (expense) (hidden)');
      expect(find.text('Food & groceries (hidden)'), findsOneWidget);
      expect(find.text('1 transactions'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Income'));
      expect(find.textContaining('0 transactions'), findsOneWidget);
      expect(records.last!.category, food);
    },
  );
  screenTest('Dashboard constraints survive adding and clearing user filters', (
    tester,
  ) async {
    await seed(1);
    final initial = ActivityFilter(
      period: period,
      scope: ActivityScope.expenses,
      subtype: RecordSubtype.sendMoney,
      party: PartyIdentity.fromParty(alice),
      partyPresence: PartyPresence.identified,
      resolution: SemanticResolution.resolved,
    );
    await open(tester, filter: initial, drillDown: true);
    await choose(tester, 'Food & groceries (expense)');
    await tester.enterText(search, 'absent');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Clear filters'));
    expect(records.last, initial);
    expect(find.text('3 transactions'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Income'))
          .onSelected,
      isNull,
    );
  });
  screenTest(
    'detail category edits refresh filtered page/count while retaining valid page and search',
    (tester) async {
      await seed();
      await open(
        tester,
        filter: ActivityFilter(period: period, search: 'alice', category: food),
      );
      await tap(tester, find.text('Next'));
      final monthReads = records.months;
      await tap(tester, find.byType(TransactionRow).first);
      await tap(tester, find.text('Clear category'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('60 transactions'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(10));
      expect(records.last!.category, food);
      expect(records.last!.search, 'alice');
      expect(records.last!.period, period);
      expect(records.months, monthReads);
    },
  );
  screenTest(
    'edits clamp a vanished last page and unfiltered views avoid assignment refresh',
    (tester) async {
      await seed(51);
      await open(
        tester,
        filter: ActivityFilter(period: period, category: food),
      );
      await tap(tester, find.text('Next'));
      final id = tester
          .widget<TransactionRow>(find.byType(TransactionRow).first)
          .record
          .id!;
      await categories.removeAssignment(id);
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('50 transactions'), findsOneWidget);
      await tap(tester, find.text('Clear filters'));
      final reads = records.reads;
      await categories.assign(recordId: id, categoryId: food.categoryId!);
      await tester.pumpAndSettle();
      expect(records.reads, reads);
    },
  );
  screenTest(
    'deleted and invalid category selections clear safely while retaining drill-down constraints',
    (tester) async {
      await seed(1);
      final custom = await categories.createCustom(
        name: 'Custom',
        kind: CategoryKind.expense,
      );
      final id = (await db.financialRecordsDao.getAllRecords()).first.id;
      await categories.assign(recordId: id, categoryId: custom.id);
      final f = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        subtype: RecordSubtype.sendMoney,
        category: ActivityCategoryFilter.category(custom.id),
      );
      await open(tester, filter: f, drillDown: true);
      await categories.deleteCustom(custom.id);
      await tester.pumpAndSettle();
      expect(records.last!.category, isNull);
      expect(records.last!.subtype, f.subtype);
      expect(records.last!.scope, f.scope);
      expect(find.text('3 transactions'), findsOneWidget);
      expect(
        find.text('Category is no longer available. Category filter cleared.'),
        findsOneWidget,
      );
    },
  );
  screenTest(
    'uncategorized refresh includes explicit overrides after category edits',
    (tester) async {
      await seed(1);
      final rows = await db.financialRecordsDao.getAllRecords();
      await open(
        tester,
        filter: ActivityFilter(
          period: period,
          category: const ActivityCategoryFilter.uncategorized(),
        ),
      );
      expect(find.text('2 transactions'), findsOneWidget);
      await categories.assign(
        recordId: rows.last.id,
        categoryId: food.categoryId!,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 transactions'), findsOneWidget);
      await categories.removeAssignment(rows.first.id);
      await tester.pumpAndSettle();
      expect(find.text('2 transactions'), findsOneWidget);
    },
  );

  screenTest(
    'initial invalid category is cleared without retaining an invalid dropdown value',
    (tester) async {
      await seed(1);
      await open(
        tester,
        filter: ActivityFilter(
          period: period,
          category: const ActivityCategoryFilter.category('deleted'),
        ),
      );
      expect(records.last!.category, isNull);
      await choose(tester, 'Uncategorized');
      expect(find.text('2 transactions'), findsOneWidget);
    },
  );
  screenTest(
    'instrument association preserves Activity page, search, category and Dashboard constraints without reloading',
    (tester) async {
      await seed();
      final instrument = await FinancialInstrumentsRepository(
        db,
      ).create(name: 'My wallet', type: InstrumentType.mobileWallet);
      final filter = ActivityFilter(
        period: period,
        scope: ActivityScope.expenses,
        subtype: RecordSubtype.sendMoney,
        category: food,
        search: 'Alice',
      );
      await open(tester, filter: filter, drillDown: true);
      await tap(tester, find.text('Next'));
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('61 transactions'), findsOneWidget);
      final reads = records.reads;
      final months = records.months;
      final snapshot = records.last;
      await tap(tester, find.byType(TransactionRow).first);
      final chooseSource = find.byKey(const ValueKey('link.source.choose'));
      if (chooseSource.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          chooseSource,
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tap(tester, chooseSource);
      await tap(tester, find.byKey(ValueKey('link.choose.${instrument.id}')));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('61 transactions'), findsOneWidget);
      expect(tester.widget<TextField>(search).controller!.text, 'alice');
      expect(records.last, snapshot);
      expect(records.last!.period, period);
      expect(records.last!.category, food);
      expect(records.last!.subtype, RecordSubtype.sendMoney);
      expect(records.reads, reads);
      expect(records.months, months);
    },
  );
}
