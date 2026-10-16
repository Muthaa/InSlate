import 'package:flutter/material.dart';
import '../helpers/widget_capture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/models/budget.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/providers/budgets_provider.dart';
import 'package:inslate/screens/dashboard/dashboard_budget_section.dart';

void main() {
  for (final large in [false, true]) {
    testWidgets(
      'all active Home budgets scroll horizontally, large text $large',
      (tester) async {
        tester.view.physicalSize = const Size(360, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await loadCaptureFonts(tester);
        final boundary = GlobalKey();
        final period = FinancialPeriod.month(DateTime.now());
        final rows = [
          for (var i = 0; i < 6; i++)
            BudgetProgress(
              Budget(
                id: '$i',
                categoryId: 'category-$i',
                label: i == 5 ? 'Paused target' : 'Target $i',
                amountMinor: 1000,
                overall: false,
                isActive: i != 5,
                categoryHidden: false,
              ),
              period,
              BigInt.from(1500),
              1,
            ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              budgetsProvider(period).overrideWith((ref) => Stream.value(rows)),
            ],
            child: RepaintBoundary(
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
                    child: DashboardBudgetSection(period: period),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!large) await captureWidget(tester, boundary, 'home-budgets');
        final scroller = find.byKey(
          const ValueKey('dashboard.budget.scroller'),
        );
        expect(
          tester.widget<SingleChildScrollView>(scroller).scrollDirection,
          Axis.horizontal,
        );
        final first = tester.getRect(
          find.byKey(const ValueKey('dashboard.budget.0')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('dashboard.budget.1')),
        );
        expect(first.top, second.top);
        expect(first.right, lessThanOrEqualTo(second.left));
        expect(find.text('Paused target'), findsNothing);
        expect(find.text('Over budget by KSh 5.00'), findsNWidgets(5));
        expect(find.text('Target 4').hitTestable(), findsNothing);
        await tester.drag(scroller, const Offset(-1800, 0));
        await tester.pumpAndSettle();
        expect(find.text('Target 4').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
