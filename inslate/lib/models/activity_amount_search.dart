/// A complete whole amount with optional partial fractional digits. Numeric
/// bounds avoid matching 500 against 1500/5000 or an unrelated fee/balance.
/// Existing text fields are still searched literally alongside this range.
class ActivityAmountSearch {
  final double lower, upper;
  final bool exact;
  const ActivityAmountSearch(this.lower, this.upper, this.exact);

  static ActivityAmountSearch? parse(String search) {
    final value = search.trim().toLowerCase().replaceFirst(
      RegExp(r'^ksh\s*'),
      '',
    );
    if (!RegExp(
      r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{0,2})?$',
    ).hasMatch(value)) {
      return null;
    }
    final normalized = value.replaceAll(',', '');
    final amount = double.tryParse(normalized);
    if (amount == null || !amount.isFinite) return null;
    final fraction = normalized.contains('.')
        ? normalized.split('.').last.length
        : 0;
    final upper =
        amount +
        (fraction == 0
            ? 1
            : fraction == 1
            ? 0.1
            : 0);
    return ActivityAmountSearch(
      amount,
      upper,
      fraction == 2 || upper == amount,
    );
  }

  bool matches(double amount) =>
      exact ? amount == lower : amount >= lower && amount < upper;
}
