extension StringExtensions on String {
  double toMoney() {
    return double.parse(replaceAll(',', ''));
  }

  bool containsAll(List<String> values) {
    return values.every(contains);
  }

  bool containsAny(List<String> values) {
    return values.any(contains);
  }
}
