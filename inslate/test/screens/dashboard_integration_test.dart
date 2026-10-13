import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:inslate/core/design/slate_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/budget.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/budgets_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import 'package:inslate/screens/dashboard/dashboard_budget_section.dart';
import 'package:inslate/screens/budgets/budgets_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  final current = FinancialPeriod.month(DateTime.now());
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

  Future<void> open(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target.hitTestable(),
      250,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testUi(
    'Dashboard preview reuses canonical spending, excludes paused targets and opens same-month budgets',
    (tester) async {
      await tester.runAsync(() async {
        await FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.receiveMoney, 200, date: current.start),
          record(RecordSubtype.buyGoods, 10, fee: 2, date: current.start),
          record(RecordSubtype.fulizaLoan, 500, fee: 3, date: current.start),
        ]);
        final repo = BudgetsRepository(db);
        await repo.create(amount: '40');
        final paused = await repo.create(
          amount: '50',
          categoryId: 'builtin.expense.food',
        );
        await repo.setActive(paused, false);
      });
      await open(tester, const DashboardScreen());
      final panel = find.byType(DashboardBudgetSection);
      await scrollTo(tester, panel);
      expect(
        find.descendant(of: panel, matching: find.text('Spent KSh 10.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('25.00% used')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Remaining KSh 30.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Food & groceries')),
        findsNothing,
      );
      final spending = find.text('Expense categories');
      await scrollTo(tester, spending);
      final categories = find.ancestor(
        of: spending,
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_CategoriesCard',
        ),
      );
      expect(
        find.descendant(
          of: categories,
          matching: find.descendant(
            of: find.byType(SlateAmount),
            matching: find.text('KSh 10.00'),
          ),
        ),
        findsOneWidget,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
      await tester.pumpAndSettle();
      final overview = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_OverviewCard',
      );
      expect(
        find.descendant(of: overview, matching: find.text('KSh 5.00')),
        findsOneWidget,
      );
      await scrollTo(tester, find.byKey(const ValueKey('dashboard.budgets')));
      await tester.tap(find.byKey(const ValueKey('dashboard.budgets')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<BudgetsScreen>(find.byType(BudgetsScreen)).previousMonth,
        isFalse,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );
  testUi(
    'preview distinguishes zero spending from unsupported precision and updates live',
    (tester) async {
      await tester.runAsync(() => BudgetsRepository(db).create(amount: '10'));
      await open(
        tester,
        Scaffold(body: DashboardBudgetSection(period: current)),
      );
      expect(find.text('Spent KSh 0.00'), findsOneWidget);
      expect(find.text('0.00% used'), findsOneWidget);
      expect(find.text('No spending recorded.'), findsOneWidget);
      await tester.runAsync(
        () => FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.buyGoods, 0.001, date: current.start)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Spending unavailable;'), findsOneWidget);
      expect(find.textContaining('Spent KSh'), findsNothing);
    },
  );
  testUi(
    'unsupported historical month does not fetch or show current progress as historical',
    (tester) async {
      final old = FinancialPeriod.month(
        DateTime(current.start.year - 1, current.start.month),
      );
      var reads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetsProvider(old).overrideWith((ref) {
              reads++;
              return Stream.value(<BudgetProgress>[]);
            }),
          ],
          child: MaterialApp(
            home: Scaffold(body: DashboardBudgetSection(period: old)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 0);
      expect(find.text('View current-month budgets'), findsOneWidget);
      expect(find.textContaining('Spent'), findsNothing);
    },
  );
  testUi('preview errors provide retry and never display fabricated zero', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetsProvider(current).overrideWith((ref) {
            reads++;
            return Stream<List<BudgetProgress>>.error(StateError('PRIVATE'));
          }),
        ],
        child: MaterialApp(
          home: Scaffold(body: DashboardBudgetSection(period: current)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budget progress unavailable.'), findsOneWidget);
    expect(find.textContaining('KSh 0.00'), findsNothing);
    await tester.tap(find.text('Retry budget progress'));
    await tester.pumpAndSettle();
    expect(reads, 2);
  });
  testUi(
    'long hidden-category targets fit a narrow screen and preview remains bounded',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final categories = CategoriesRepository(db);
        for (var i = 0; i < 5; i++) {
          final category = await categories.createCustom(
            name: 'Long category name for narrow screen testing number $i',
            kind: CategoryKind.expense,
          );
          await categories.setHidden(category.id, true);
          await BudgetsRepository(
            db,
          ).create(amount: '123456789.01', categoryId: category.id);
        }
      });
      await open(
        tester,
        SingleChildScrollView(child: DashboardBudgetSection(period: current)),
      );
      expect(find.text('2 more active targets in Budgets'), findsOneWidget);
      expect(find.text('Target KSh 123,456,789.01'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}
