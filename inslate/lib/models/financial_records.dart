import '/core/enums/financial_record_type.dart';
import '/core/enums/record_subtype.dart';
import '/core/enums/transaction_status.dart';
import '/models/party.dart';

class FinancialRecord {
  final String reference;

  final DateTime? transactionDate;

  final double amount;

  final double? balance;

  final FinancialRecordType type;

  final RecordSubtype subtype;

  final TransactionStatus status;

  final String title;

  final Party? party;

  final double transactionCost;

  final String rawMessage;

  const FinancialRecord({
    required this.reference,
    required this.transactionDate,
    required this.amount,
    required this.balance,
    required this.type,
    required this.subtype,
    required this.status,
    required this.title,
    required this.rawMessage,
    this.party,
    this.transactionCost = 0,
  });
}
