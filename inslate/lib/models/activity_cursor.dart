import 'financial_records.dart';

/// Exclusive boundary in the database's descending effective-date/ID order.
class ActivityCursor {
  final DateTime timestamp;
  final int id;
  const ActivityCursor(this.timestamp, this.id);
  factory ActivityCursor.fromRecord(FinancialRecord record) =>
      ActivityCursor(record.transactionDate ?? record.receivedAt, record.id!);
}
