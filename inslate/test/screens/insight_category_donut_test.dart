import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/insights.dart';
import 'package:inslate/screens/insights/insight_category_donut.dart';
import '../helpers/widget_capture.dart';

void main() {
  InsightCategory group(
    String id,
    double amount, {
    bool expense = true,
    bool hidden = false,
    String? name,
  }) => InsightCategory(
    id: id,
    name: name ?? id,
    hidden: hidden,
    amount: amount,
    count: 1,
    filter: ActivityFilter(
      period: FinancialPeriod.month(DateTime(2026, 9)),
      scope: expense ? ActivityScope.expenses : ActivityScope.income,
      category: ActivityCategoryFilter.category(id),
    ),
  );
  Future<void> open(
    WidgetTester tester,
    List<InsightCategory> groups,
    double total,
    ValueChanged<ActivityFilter> onOpen, {
    bool expense = true,
    bool large = false,
    GlobalKey? boundary,
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InsightCategoryDonut(
                    groups: groups,
                    total: total,
                    expense: expense,
                    onOpen: onOpen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'category colors and icons survive amount reordering, renaming and hiding',
    (tester) async {
      const food = 'builtin.expense.food';
      const custom = 'custom-permanent-id';
      Color? color(String id) => tester
          .widget<Icon>(
            find
                .descendant(
                  of: find.byKey(ValueKey('insights.category.expenses.$id')),
                  matching: find.byType(Icon),
                )
                .first,
          )
          .color;
      IconData? icon(String id) => tester
          .widget<Icon>(
            find
                .descendant(
                  of: find.byKey(ValueKey('insights.category.expenses.$id')),
                  matching: find.byType(Icon),
                )
                .first,
          )
          .icon;
      await open(
        tester,
        [group(food, 75, name: 'Food'), group(custom, 25, name: 'Custom')],
        100,
        (_) {},
      );
      final before = {food: color(food), custom: color(custom)};
      expect(icon(food), Icons.restaurant_outlined);
      expect(before[food], isNot(before[custom]));
      await open(
        tester,
        [
          group(custom, 90, name: 'Renamed custom', hidden: true),
          group(food, 10, name: 'Groceries'),
        ],
        100,
        (_) {},
      );
      expect(color(food), before[food]);
      expect(color(custom), before[custom]);
      expect(find.text('Renamed custom (hidden)'), findsOneWidget);
    },
  );
  testWidgets(
    'donut segments and matching legend open their exact category filters',
    (tester) async {
      final a = group('Food', 75);
      final b = group('Travel', 25, hidden: true);
      final opened = <ActivityFilter>[];
      await open(tester, [a, b], 100, opened.add);
      final center = tester.getCenter(
        find.byKey(const ValueKey('insights.donut.expenses')),
      );
      await tester.tapAt(center + const Offset(96, 0));
      expect(opened, [a.filter]);
      await tester.tapAt(center + const Offset(-68, -68));
      expect(opened, [a.filter, b.filter]);
      await tester.tapAt(center);
      expect(opened, hasLength(2));
      expect(find.text('Travel (hidden)'), findsOneWidget);
      expect(find.text('1 transaction · 25.0%'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('insights.category.expenses.Travel')),
      );
      expect(opened.last, b.filter);
    },
  );
  testWidgets(
    'negative adjustments are kept signed and never converted into positive donut slices',
    (tester) async {
      final opened = <ActivityFilter>[];
      final reversal = group('Reversal', -20);
      await open(tester, [group('Food', 100), reversal], 80, opened.add);
      expect(
        find.text('Donut unavailable for negative category values.'),
        findsOneWidget,
      );
      expect(find.text(formatMoney(-20)), findsOneWidget);
      final center = tester.getCenter(
        find.byKey(const ValueKey('insights.donut.expenses')),
      );
      await tester.tapAt(center + const Offset(96, 0));
      expect(opened, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('insights.category.expenses.Reversal')),
      );
      expect(opened.single, reversal.filter);
    },
  );
  for (final total in [0.0, -20.0]) {
    testWidgets('nonpositive total $total has no fabricated distribution', (
      tester,
    ) async {
      await open(tester, [group('Net spending', total)], total, (_) {});
      expect(
        find.text(
          total == 0
              ? 'Share unavailable (zero total)'
              : 'Share unavailable (negative net total)',
        ),
        findsOneWidget,
      );
      expect(find.text('No distribution'), findsOneWidget);
      expect(find.text('1 transaction'), findsOneWidget);
    });
  }
  testWidgets('empty categories do not invent a zero-balance donut', (
    tester,
  ) async {
    await open(tester, [], 0, (_) {}, expense: false);
    expect(find.text('No ordinary income in this period.'), findsOneWidget);
    expect(find.byKey(const ValueKey('insights.donut.income')), findsNothing);
  });
  testWidgets(
    'zero category stays in legend and category-total mismatch is explicit',
    (tester) async {
      final groups = [group('Recorded', 50), group('Zero', 0)];
      await open(tester, groups, 50, (_) {});
      expect(find.text('1 transaction · 0.0%'), findsOneWidget);
      await open(tester, groups, 100, (_) {});
      expect(find.text('Category distribution unavailable.'), findsOneWidget);
    },
  );
  testWidgets(
    'large amounts and labels remain readable on narrow screens with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(
        tester,
        [
          group(
            'A long custom category name for recorded expenses',
            99999999999.99,
          ),
        ],
        99999999999.99,
        (_) {},
        large: true,
      );
      await tester.ensureVisible(
        find.byKey(
          const ValueKey(
            'insights.category.expenses.A long custom category name for recorded expenses',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final expense in [false, true]) {
    testWidgets('render ${expense ? 'expense' : 'income'} category donut', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadCaptureFonts(tester);
      final boundary = GlobalKey();
      final groups = expense
          ? [
              group('builtin.expense.food', 3500, name: 'Food & groceries'),
              group('builtin.expense.transport', 2500, name: 'Transport'),
              group('builtin.expense.shopping', 1500, name: 'Shopping'),
              group('builtin.expense.other', 2500, name: 'Other spending'),
            ]
          : [
              group(
                'builtin.income.salary',
                7500,
                expense: false,
                name: 'Salary',
              ),
              group(
                'builtin.income.freelance',
                2000,
                expense: false,
                name: 'Freelance',
              ),
              group(
                'builtin.income.other',
                500,
                expense: false,
                name: 'Other income',
              ),
            ];
      await open(
        tester,
        groups,
        10000,
        (_) {},
        expense: expense,
        boundary: boundary,
      );
      expect(
        find.byKey(
          ValueKey('insights.donut.${expense ? 'expenses' : 'income'}'),
        ),
        findsOneWidget,
      );
      await captureWidget(
        tester,
        boundary,
        expense ? 'expense-donut' : 'income-donut',
      );
    });
  }
}
