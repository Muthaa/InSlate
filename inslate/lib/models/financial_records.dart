import '/core/enums/financial_record_type.dart';
import '/core/enums/record_subtype.dart';
import '/core/enums/transaction_status.dart';
import '/models/party.dart';

class FinancialRecord {
  /// Persisted row identity; absent on a newly parsed, unsaved record.
  final int? id;

  /// Explicit principal-only PayBill reversal; never an inferred association.
  final int? reversesRecordId;
  final String reference;

  final DateTime? transactionDate;

  final double amount;

  final double? balance;

  final FinancialRecordType type;

  final RecordSubtype subtype;
  final FinancialRecordType? parsedType;
  final RecordSubtype? parsedSubtype;
  final int? interpretationMappingId;

  final TransactionStatus status;

  final String title;

  final Party? party;

  final double transactionCost;

  final String rawMessage;

  final DateTime receivedAt;

  final String? sourceMessageId;

  const FinancialRecord({
    this.id,
    this.reversesRecordId,
    required this.reference,
    required this.transactionDate,
    required this.amount,
    required this.balance,
    required this.type,
    required this.subtype,
    this.parsedType,
    this.parsedSubtype,
    this.interpretationMappingId,
    required this.status,
    required this.title,
    required this.rawMessage,
    required this.receivedAt,
    this.sourceMessageId,
    this.party,
    this.transactionCost = 0,
  });
}
