import 'financial_records.dart';

class ParseResult {
  final bool success;

  final FinancialRecord? record;

  final String? error;

  const ParseResult.success(this.record) : success = true, error = null;

  const ParseResult.failure(this.error) : success = false, record = null;
}
