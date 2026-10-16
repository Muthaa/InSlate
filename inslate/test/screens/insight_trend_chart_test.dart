import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/insights.dart';
import 'package:inslate/screens/insights/insight_trend_chart.dart';

void main() {
  testWidgets(
    'selects a date and drills down with exact negative expense population',
    (tester) async {
      ActivityFilter? opened;
      final trends = [
        InsightTrend(
          FinancialPeriod(DateTime(2026, 9, 1), DateTime(2026, 9, 2)),
          100,
          50,
        ),
        InsightTrend(
          FinancialPeriod(DateTime(2026, 9, 2), DateTime(2026, 9, 3)),
          0,
          -25,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: InsightTrendChart(
                trends: trends,
                monthly: false,
                onOpen: (value) => opened = value,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('insights.trend.chart')),
        findsOneWidget,
      );
      final chart = tester.getRect(
        find.byKey(const ValueKey('insights.trend.chart')),
      );
      await tester.tapAt(Offset(chart.right - 10, chart.center.dy));
      await tester.pump();
      await tester.tap(
        find.byKey(
          ValueKey(
            'insights.trend.expenses.${DateTime(2026, 9, 2).millisecondsSinceEpoch}',
          ),
        ),
      );
      expect(opened!.scope, ActivityScope.expenses);
      expect(opened!.period, trends.last.period);
      expect(opened!.category, isNull);
      await tester.tap(find.byTooltip('Close chart tooltip'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('insights.trend.tooltip')),
        findsNothing,
      );
      expect(opened!.period, trends.last.period);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single zero observation and empty period render safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: InsightTrendChart(
              trends: [
                InsightTrend(FinancialPeriod.month(DateTime(2026, 9)), 0, 0),
              ],
              monthly: true,
              onOpen: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Sep 2026'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightTrendChart(
            trends: const [],
            monthly: false,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('No trend data for this period.'), findsOneWidget);
  });
}
