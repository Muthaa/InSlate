import '../core/enums/record_subtype.dart';
import 'financial_records.dart';
import 'party_summary.dart';

class FinancialSummary {
  final DateTime period;
  final double currentBalance;

  final double totalIncome;
  final double totalExpenses;
  final double totalSent;
  final double totalReceived;

  final double internalTransfers;
  final double internalTransfersIn;
  final double internalTransfersOut;

  final double totalFees;
  final double netMovement;

  final int transactionCount;
  final int expenseTransactionCount;
  final int incomeTransactionCount;

  final List<FinancialRecord> recentTransactions;

  final Map<RecordSubtype, double> spendingBySubtype;
  final Map<RecordSubtype, int> transactionCountBySubtype;

  final Map<RecordSubtype, double> incomeBySubtype;
  final Map<RecordSubtype, int> incomeTransactionCountBySubtype;
  final Map<RecordSubtype, double> moneyInBySubtype;

  final List<PartySummary> topExpenses;
  final List<PartySummary> topIncome;

  final int expensePartyCount;
  final int incomePartyCount;

  const FinancialSummary({
    required this.period,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSent,
    required this.totalReceived,
    required this.internalTransfers,
    required this.internalTransfersIn,
    required this.internalTransfersOut,
    required this.totalFees,
    required this.netMovement,
    required this.transactionCount,
    required this.expenseTransactionCount,
    required this.incomeTransactionCount,
    required this.recentTransactions,
    required this.spendingBySubtype,
    required this.transactionCountBySubtype,
    required this.incomeBySubtype,
    required this.incomeTransactionCountBySubtype,
    required this.moneyInBySubtype,
    required this.topExpenses,
    required this.topIncome,
    required this.expensePartyCount,
    required this.incomePartyCount,
  });
}
