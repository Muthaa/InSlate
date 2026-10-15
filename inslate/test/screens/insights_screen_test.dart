import 'package:drift/native.dart';
import 'package:inslate/core/theme/app_theme.dart';
import '../helpers/widget_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/insights.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/insights_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/screens/insights/insights_screen.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  void testUi(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => db.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  Future<void> open(
    WidgetTester tester, {
    FinancialPeriod? initial,
    bool large = false,
    GlobalKey? boundary,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(large ? 1.6 : 1)),
              child: child!,
            ),
            home: InsightsScreen(initialPeriod: initial ?? period),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final large in [false, true]) {
    testUi('overview combines current totals and comparisons, large $large', (
      tester,
    ) async {
      tester.view.physicalSize = Size(large ? 320 : 430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadCaptureFonts(tester);
      await tester.runAsync(
        () => FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.receiveMoney, 200, date: DateTime(2026, 9, 10)),
          record(
            RecordSubtype.buyGoods,
            80,
            fee: 4,
            date: DateTime(2026, 9, 10),
          ),
          record(RecordSubtype.receiveMoney, 100, date: DateTime(2026, 8, 10)),
          record(
            RecordSubtype.buyGoods,
            60,
            fee: 3,
            date: DateTime(2026, 8, 10),
          ),
        ]),
      );
      final boundary = GlobalKey();
      await open(tester, large: large, boundary: boundary);
      final income = find.byKey(const ValueKey('insights.comparison.income'));
      final expense = find.byKey(
        const ValueKey('insights.comparison.spending'),
      );
      await tester.scrollUntilVisible(income, 250);
      final incomeRect = tester.getRect(income);
      final expenseRect = tester.getRect(expense);
      if (large) {
        expect(expenseRect.top, greaterThan(incomeRect.bottom));
      } else {
        expect(expenseRect.top, incomeRect.top);
        expect(expenseRect.left, greaterThan(incomeRect.right));
      }
      for (final value in {
        'income': ('+KSh 100.00', '100.0% more'),
        'spending': ('+KSh 20.00', '33.3% more'),
        'fees': ('+KSh 1.00', '33.3% more'),
        'net cash flow': ('+KSh 79.00', '213.5% more'),
      }.entries) {
        final metric = find.byKey(ValueKey('insights.comparison.${value.key}'));
        expect(
          find.descendant(of: metric, matching: find.text(value.value.$1)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: metric, matching: find.text(value.value.$2)),
          findsOneWidget,
        );
      }
      expect(find.text('2 records in comparison period'), findsOneWidget);
      expect(find.text('Selected period: September 2026'), findsOneWidget);
      expect(find.text('Comparison period: August 2026'), findsOneWidget);
      final overview = find.ancestor(
        of: find.text('Overview'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: overview,
          matching: find.text('Compared with preceding period'),
        ),
        findsOneWidget,
      );
      expect(find.text('Compared with preceding period'), findsOneWidget);
      for (final amount in [200, 80, 4, 116]) {
        expect(
          find.descendant(
            of: overview,
            matching: find.text(formatMoney(amount.toDouble())),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: overview,
          matching: find.byIcon(Icons.arrow_upward_rounded),
        ),
        findsNWidgets(4),
      );
      if (!large) {
        await tester.ensureVisible(find.text('Overview'));
        await tester.pumpAndSettle();
        await captureWidget(tester, boundary, 'insights-overview-comparison');
      }
      await tester.scrollUntilVisible(
        find.text('Expense purpose categories'),
        250,
      );
      await tester.ensureVisible(find.text('Expense purpose categories'));
      await tester.pumpAndSettle();
      if (!large) await captureWidget(tester, boundary, 'insights-categories');
      final expensesCard = find
          .ancestor(
            of: find.text('Expense purpose categories'),
            matching: find.byType(Card),
          )
          .first;
      final incomeCard = find
          .ancestor(
            of: find.text('Income purpose categories'),
            matching: find.byType(Card),
          )
          .first;
      final purpose = find.text('Purpose unspecified');
      expect(
        tester.getRect(purpose).top,
        greaterThan(tester.getRect(incomeCard).bottom),
      );
      // Amounts remain in category rows, with no duplicate total in headings.
      final expenseHeader = find
          .descendant(of: expensesCard, matching: find.byType(Row))
          .first;
      final incomeHeader = find
          .descendant(of: incomeCard, matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: expenseHeader, matching: find.text('KSh 80.00')),
        findsNothing,
      );
      expect(
        find.descendant(of: incomeHeader, matching: find.text('KSh 200.00')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testUi('overview handles decreases, unchanged and nonpositive baselines', (
    tester,
  ) async {
    await tester.runAsync(
      () => FinancialRecordsRepository(db).saveAll([
        record(RecordSubtype.receiveMoney, 50, date: DateTime(2026, 9, 10)),
        record(
          RecordSubtype.buyGoods,
          100,
          fee: 0,
          date: DateTime(2026, 9, 10),
        ),
        record(RecordSubtype.receiveMoney, 100, date: DateTime(2026, 8, 10)),
        record(
          RecordSubtype.buyGoods,
          150,
          fee: 0,
          date: DateTime(2026, 8, 10),
        ),
      ]),
    );
    await open(tester);
    final income = find.byKey(const ValueKey('insights.comparison.income'));
    expect(
      find.descendant(of: income, matching: find.text('-KSh 50.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: income, matching: find.text('50.0% less')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: income,
        matching: find.byIcon(Icons.arrow_downward_rounded),
      ),
      findsOneWidget,
    );
    final fees = find.byKey(const ValueKey('insights.comparison.fees'));
    final net = find.byKey(const ValueKey('insights.comparison.net cash flow'));
    for (final metric in [fees, net]) {
      expect(
        find.descendant(
          of: metric,
          matching: find.text(
            'Percentage unavailable (zero or negative baseline)',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metric,
          matching: find.byIcon(Icons.horizontal_rule),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testUi('overview does not invent changes without a preceding population', (
    tester,
  ) async {
    await tester.runAsync(
      () => FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.receiveMoney, 50)),
    );
    await open(tester);
    expect(find.text('0 records in comparison period'), findsOneWidget);
    expect(
      find.text(
        'No records in comparison period; differences are unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.text('Comparison unavailable'), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('insights.comparison.income')),
      findsNothing,
    );
    expect(find.text('100.0% more'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testUi(
    'overview retains canonical fees and hidden category drill-down preserves constraints and return state',
    (tester) async {
      await tester.runAsync(
        () => FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.buyGoods, 100, fee: 2),
          record(RecordSubtype.receiveMoney, 200),
          record(RecordSubtype.fulizaLoan, 1000, fee: 3),
          record(RecordSubtype.mshwariDeposit, 500, fee: 4),
        ]),
      );
      final id = (await tester.runAsync(
        () => db.select(db.financialRecords).get(),
      ))!.first.id;
      await tester.runAsync(() async {
        final repo = CategoriesRepository(db);
        await repo.assign(recordId: id, categoryId: 'builtin.expense.food');
        await repo.setHidden('builtin.expense.food', true);
      });
      await open(tester);
      expect(find.text('4 financial records in this period'), findsOneWidget);
      expect(find.text(formatMoney(9)), findsOneWidget);
      expect(find.text(formatMoney(91)), findsOneWidget);
      final category = find.byKey(
        const ValueKey('insights.category.expenses.builtin.expense.food'),
      );
      await tester.scrollUntilVisible(category.hitTestable(), 300);
      expect(find.text('Food & groceries (hidden)'), findsOneWidget);
      await tester.tap(category);
      await tester.pumpAndSettle();
      final activity = tester.widget<ActivityScreen>(
        find.byType(ActivityScreen),
      );
      expect(activity.preserveDrillDown, isTrue);
      expect(activity.initialFilter!.period, period);
      expect(activity.initialFilter!.scope, ActivityScope.expenses);
      expect(
        activity.initialFilter!.category!.categoryId,
        'builtin.expense.food',
      );
      expect(find.text('1 transactions'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(category.hitTestable(), findsOneWidget);
      expect(find.byType(InsightsScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text('September 2026'), -300);
      expect(find.text('September 2026'), findsOneWidget);
      final trend = find.byKey(
        ValueKey(
          'insights.trend.expenses.${DateTime(2026, 9, 10).millisecondsSinceEpoch}',
        ),
      );
      await tester.scrollUntilVisible(trend.hitTestable(), 500);
      await tester.tap(trend);
      await tester.pumpAndSettle();
      final trendFilter = tester
          .widget<ActivityScreen>(find.byType(ActivityScreen))
          .initialFilter!;
      expect(
        trendFilter.period,
        FinancialPeriod(DateTime(2026, 9, 10), DateTime(2026, 9, 11)),
      );
      expect(trendFilter.scope, ActivityScope.expenses);
      expect(trendFilter.category, isNull);
      expect(find.text('1 transactions'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    },
  );
  testUi(
    'current and previous month selection changes actual query population',
    (tester) async {
      final now = DateTime.now();
      final current = FinancialPeriod.month(now);
      final previous = FinancialPeriod.month(DateTime(now.year, now.month - 1));
      await tester.runAsync(
        () => FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.receiveMoney, 12, date: current.start),
          record(RecordSubtype.receiveMoney, 7, date: previous.start),
        ]),
      );
      await open(tester, initial: current);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Income'),
            matching: find.byType(ListTile),
          ),
          matching: find.text(formatMoney(12)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Net cash flow'),
            matching: find.byType(ListTile),
          ),
          matching: find.text(formatMoney(12)),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byType(DropdownButtonFormField<InsightPeriodChoice>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Previous month').last);
      await tester.pumpAndSettle();
      expect(find.text(periodLabel(previous)), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Income'),
            matching: find.byType(ListTile),
          ),
          matching: find.text(formatMoney(7)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Net cash flow'),
            matching: find.byType(ListTile),
          ),
          matching: find.text(formatMoney(7)),
        ),
        findsOneWidget,
      );
      expect(find.text('Monthly budgets'), findsNothing);
      expect(find.text(periodLabel(previous)), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text(periodLabel(previous)), findsOneWidget);
      await tester.tap(
        find.byType(DropdownButtonFormField<InsightPeriodChoice>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Current month').last);
      await tester.pumpAndSettle();
      expect(find.text(periodLabel(current)), findsOneWidget);
    },
  );
  testUi(
    'custom date range includes its end date and overview drill-down uses the exact range',
    (tester) async {
      await tester.runAsync(
        () => FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.receiveMoney, 10, date: DateTime(2026, 9, 10)),
          record(RecordSubtype.receiveMoney, 20, date: DateTime(2026, 9, 11)),
          record(RecordSubtype.receiveMoney, 40, date: DateTime(2026, 9, 12)),
        ]),
      );
      await open(tester);
      await tester.tap(find.byTooltip('Change date range'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '09/10/2026');
      await tester.enterText(fields.at(1), '09/11/2026');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('2 financial records in this period'), findsOneWidget);
      expect(find.text(formatMoney(30)), findsWidgets);
      await tester.tap(find.widgetWithText(ListTile, 'Income').first);
      await tester.pumpAndSettle();
      final filter = tester
          .widget<ActivityScreen>(find.byType(ActivityScreen))
          .initialFilter!;
      expect(
        filter.period,
        FinancialPeriod(DateTime(2026, 9, 10), DateTime(2026, 9, 12)),
      );
      expect(find.text('2 transactions'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('2 financial records in this period'), findsOneWidget);
    },
  );
  testUi('no records is distinct from zero-valued financial records', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('No records in this period'), findsOneWidget);
    await tester.runAsync(
      () => FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.buyGoods, 0)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No records in this period'), findsNothing);
    expect(find.text('1 financial records in this period'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Share unavailable'),
      300,
    );
    expect(
      find.textContaining('Share unavailable (zero total)'),
      findsOneWidget,
    );
  });
  testUi(
    'loading and errors stay explicit and retry does not expose exception content',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insightsProvider(period).overrideWith((ref) {
              calls++;
              return Stream<InsightsSummary>.error(
                StateError('PRIVATE SQL DETAILS'),
              );
            }),
          ],
          child: MaterialApp(home: InsightsScreen(initialPeriod: period)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load insights.'), findsOneWidget);
      expect(find.textContaining('PRIVATE SQL DETAILS'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('loading'),
          overrides: [
            insightsProvider(
              period,
            ).overrideWith((ref) => const Stream<InsightsSummary>.empty()),
          ],
          child: MaterialApp(home: InsightsScreen(initialPeriod: period)),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No records in this period'), findsNothing);
    },
  );
  testUi('Insights large amounts fit narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.receiveMoney, 99999999999.99)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: InsightsScreen(initialPeriod: period),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
