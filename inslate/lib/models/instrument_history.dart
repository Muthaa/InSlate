import 'financial_records.dart';

enum InstrumentTransactionRole { incoming, outgoing, selfLinked }

class InstrumentHistoryEntry {
  final FinancialRecord record;
  final InstrumentTransactionRole role;
  const InstrumentHistoryEntry(this.record, this.role);
}

class InstrumentHistoryPage {
  static const pageSize = 50;
  final List<InstrumentHistoryEntry> entries;
  final int count;

  /// Zero-based, clamped against the current exact count.
  final int page;
  const InstrumentHistoryPage({
    required this.entries,
    required this.count,
    required this.page,
  });
  int get totalPages => count == 0 ? 0 : (count - 1) ~/ pageSize + 1;
}
