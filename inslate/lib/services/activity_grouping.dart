import '../models/financial_records.dart';

class ActivityDay {
  final DateTime date;
  final List<FinancialRecord> records;
  ActivityDay(this.date, Iterable<FinancialRecord> records)
    : records = List.unmodifiable(records);
}

/// Preserve DAO order, including its stable ID tie-break, without re-sorting
/// domain records that omit the database ID.
List<ActivityDay> groupActivityByDay(Iterable<FinancialRecord> records) {
  final days = <DateTime, List<FinancialRecord>>{};
  for (final record in records) {
    final effectiveDate = record.transactionDate ?? record.receivedAt;
    final day = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    days.putIfAbsent(day, () => []).add(record);
  }
  return List.unmodifiable(
    days.entries.map((day) => ActivityDay(day.key, day.value)),
  );
}
