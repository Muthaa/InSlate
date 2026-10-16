import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/insights.dart';

void main() {
  test(
    'calendar comparison handles different month lengths, leap years and year rollover',
    () {
      expect(
        precedingInsightPeriod(FinancialPeriod.month(DateTime(2024, 3))),
        FinancialPeriod.month(DateTime(2024, 2)),
      );
      expect(
        precedingInsightPeriod(FinancialPeriod.month(DateTime(2026, 1))),
        FinancialPeriod.month(DateTime(2025, 12)),
      );
    },
  );
  test(
    'custom comparison is immediately preceding equal calendar-date length',
    () {
      final period = FinancialPeriod(
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 17),
      );
      expect(
        precedingInsightPeriod(period),
        FinancialPeriod(DateTime(2026, 9, 3), period.start),
      );
      final day = FinancialPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 2));
      expect(
        precedingInsightPeriod(day),
        FinancialPeriod(DateTime(2025, 12, 31), day.start),
      );
    },
  );
  test(
    'comparison differences handle zero, negative and positive baselines without infinity',
    () {
      expect(const InsightChange(150, 100).absolute, 50);
      expect(const InsightChange(150, 100).percentage, 50);
      expect(const InsightChange(50, 100).percentage, -50);
      expect(const InsightChange(100, 0).percentage, isNull);
      expect(const InsightChange(0, 0).absolute, 0);
      expect(const InsightChange(0, 0).percentage, isNull);
      expect(const InsightChange(50, -100).absolute, 150);
      expect(const InsightChange(50, -100).percentage, isNull);
    },
  );
}
