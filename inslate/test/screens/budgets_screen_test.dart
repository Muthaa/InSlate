import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/budget.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/budgets_provider.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/budgets/budgets_screen.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> action(WidgetTester tester, String id, String label) async {
    final menu = find.byKey(ValueKey('budget.menu.$id'));
    await tester.scrollUntilVisible(menu.hitTestable(), 200);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testUi(
    'creates, edits, pauses, resumes and deletes target with exact input and no spending',
    (tester) async {
      await open(tester);
      expect(find.textContaining('No budgets.'), findsOneWidget);
      await tester.tap(find.text('New budget'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '10.01');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final rows = await tester.runAsync(() => db.select(db.budgets).get());
      final id = rows!.single.id;
      expect(rows.single.amountMinor, 1001);
      expect(find.text('Budget: KSh 10.01'), findsOneWidget);
      expect(find.text('No spending recorded this month.'), findsOneWidget);
      await action(tester, id, 'Pause');
      expect(find.text('Paused target'), findsOneWidget);
      await action(tester, id, 'Edit');
      await tester.enterText(find.byType(TextFormField), '20.02');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Budget: KSh 20.02'), findsOneWidget);
      await action(tester, id, 'Resume');
      expect(find.text('Active monthly target'), findsOneWidget);
      await action(tester, id, 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No budgets.'), findsOneWidget);
    },
  );
  testUi('invalid money and duplicate scope errors retain entered amount', (
    tester,
  ) async {
    await tester.runAsync(() => BudgetsRepository(db).create(amount: '10'));
    await open(tester);
    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive KES amount.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '1.001');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('KES allows 2 decimal places.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '12.34');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('An active budget already exists for this scope.'),
      findsOneWidget,
    );
    expect(find.text('12.34'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
  testUi(
    'hidden category and previous month drill-down reproduce expenses and preserve return period',
    (tester) async {
      final now = DateTime.now();
      final previous = FinancialPeriod.month(DateTime(now.year, now.month - 1));
      await tester.runAsync(() async {
        await FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.buyGoods, 0.10, date: previous.start),
          record(RecordSubtype.fulizaLoan, 999, date: previous.start),
        ]);
        final id = (await db.select(db.financialRecords).get()).first.id;
        await CategoriesRepository(
          db,
        ).assign(recordId: id, categoryId: 'builtin.expense.food');
        await CategoriesRepository(db).setHidden('builtin.expense.food', true);
        await BudgetsRepository(
          db,
        ).create(amount: '1', categoryId: 'builtin.expense.food');
      });
      await open(tester);
      await tester.tap(find.byType(DropdownButtonFormField<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Previous month').last);
      await tester.pumpAndSettle();
      expect(find.text('Food & groceries (hidden)'), findsOneWidget);
      expect(find.text('Spent: KSh 0.10'), findsOneWidget);
      final drill = find.text('View spending in Activity');
      await tester.scrollUntilVisible(drill.hitTestable(), 200);
      await tester.tap(drill);
      await tester.pumpAndSettle();
      final activity = tester.widget<ActivityScreen>(
        find.byType(ActivityScreen),
      );
      expect(activity.preserveDrillDown, isTrue);
      expect(activity.initialFilter!.period, previous);
      expect(activity.initialFilter!.scope, ActivityScope.expenses);
      expect(
        activity.initialFilter!.category!.categoryId,
        'builtin.expense.food',
      );
      expect(find.text('1 transactions'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Spent: KSh 0.10'), findsOneWidget);
    },
  );
  testUi(
    'zero remaining, overspending and unavailable precision are explicit',
    (tester) async {
      final month = FinancialPeriod.month(DateTime.now());
      await tester.runAsync(() async {
        await BudgetsRepository(db).create(amount: '0.30');
        await FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.buyGoods, 0.30, date: month.start));
      });
      await open(tester);
      expect(find.text('Budget fully used. Zero remaining.'), findsOneWidget);
      await tester.runAsync(
        () => FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.buyGoods, 0.01, date: month.start)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Over budget by KSh 0.01'), findsOneWidget);
      await tester.runAsync(
        () => FinancialRecordsRepository(
          db,
        ).save(record(RecordSubtype.buyGoods, 0.001, date: month.start)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Spending unavailable:'), findsOneWidget);
      expect(find.textContaining('Remaining:'), findsNothing);
    },
  );
  testUi(
    'query failures show unavailable and safe retry without fabricated spending',
    (tester) async {
      final period = FinancialPeriod.month(DateTime.now());
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetsProvider(period).overrideWith((ref) {
              calls++;
              return Stream<List<BudgetProgress>>.error(
                StateError('PRIVATE SQL'),
              );
            }),
          ],
          child: const MaterialApp(home: BudgetsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Budget data unavailable.'), findsOneWidget);
      expect(find.textContaining('PRIVATE SQL'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    },
  );
  testUi(
    'deleted category remains unavailable and requires explicit repair then resume',
    (tester) async {
      String? id;
      await tester.runAsync(() async {
        final custom = await CategoriesRepository(
          db,
        ).createCustom(name: 'Temporary', kind: CategoryKind.expense);
        id = await BudgetsRepository(
          db,
        ).create(amount: '10', categoryId: custom.id);
        await CategoriesRepository(db).deleteCustom(custom.id);
      });
      await open(tester);
      expect(find.text('Deleted category'), findsOneWidget);
      expect(find.textContaining('Category deleted.'), findsOneWidget);
      expect(find.text('View spending in Activity'), findsNothing);
      await action(tester, id!, 'Edit');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Choose an expense category or overall expenses.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & groceries').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Food & groceries'), findsOneWidget);
      expect(find.text('Paused target'), findsOneWidget);
      await action(tester, id!, 'Resume');
      expect(find.text('Active monthly target'), findsOneWidget);
    },
  );
  testUi('Budget form long names fit narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? id;
    await tester.runAsync(() async {
      final category = await CategoriesRepository(db).createCustom(
        name:
            'A very long expense category name for a narrow form and enlarged text',
        kind: CategoryKind.expense,
      );
      id = await BudgetsRepository(
        db,
      ).create(amount: '123456789.01', categoryId: category.id);
    });
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
          home: const BudgetsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await action(tester, id!, 'Edit');
    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
