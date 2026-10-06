import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/services/activity_grouping.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/activity_filter.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test('groups fallback dates by day and preserves equal-date DAO order', () {
    final groups = groupActivityByDay([
      record(RecordSubtype.sendMoney, 3, date: DateTime(2026, 9, 11, 12)),
      record(RecordSubtype.sendMoney, 2, receivedAt: DateTime(2026, 9, 11, 12)),
      record(RecordSubtype.sendMoney, 1, date: DateTime(2026, 9, 10)),
    ]);
    expect(groups.map((g) => g.date), [
      DateTime(2026, 9, 11),
      DateTime(2026, 9, 10),
    ]);
    expect(groups.first.records.map((r) => r.amount), [3, 2]);
    expect(groupActivityByDay([]), isEmpty);
  });
  test('period and query have value equality for provider family keys', () {
    final period = FinancialPeriod.month(DateTime(2026, 12));
    expect(period.end, DateTime(2027, 1));
    expect(period.contains(period.start), isTrue);
    expect(period.contains(period.end), isFalse);
    expect(
      () => FinancialPeriod(period.end, period.start),
      throwsArgumentError,
    );
    final first = ActivityFilter(period: period, scope: ActivityScope.loans);
    final same = ActivityFilter(
      period: FinancialPeriod.month(DateTime(2026, 12, 15)),
      scope: ActivityScope.loans,
    );
    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(
      first.withPeriod(FinancialPeriod.month(DateTime(2026, 11))).scope,
      ActivityScope.loans,
    );
  });
}
