/// A local financial date range: start inclusive, end exclusive.
class FinancialPeriod {
  final DateTime start;
  final DateTime end;

  FinancialPeriod(this.start, this.end) {
    if (!end.isAfter(start)) {
      throw ArgumentError('The end must follow the start.');
    }
  }

  factory FinancialPeriod.month(DateTime date) => FinancialPeriod(
    DateTime(date.year, date.month),
    DateTime(date.year, date.month + 1),
  );

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is FinancialPeriod && start == other.start && end == other.end;
  @override
  int get hashCode => Object.hash(start, end);
}
