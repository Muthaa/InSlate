import 'party.dart';

class PartySummary {
  final Party party;
  final double amount;
  final int transactionCount;

  const PartySummary({
    required this.party,
    required this.amount,
    required this.transactionCount,
  });
}