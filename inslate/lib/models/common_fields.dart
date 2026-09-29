class CommonFields {
  final String reference;
  final double amount;
  final DateTime? transactionDate;
  final double? balance;
  final double transactionCost;

  const CommonFields({
    required this.reference,
    required this.amount,
    required this.transactionDate,
    required this.balance,
    required this.transactionCost,
  });
}
