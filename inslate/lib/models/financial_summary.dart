import '../core/enums/record_subtype.dart';
import 'financial_records.dart';
import 'party_summary.dart';
import '../services/financial_semantics.dart';

class FinancialSummary {
  /// Target accounting semantics. The older fields below remain a legacy
  /// Dashboard contract until that UI is migrated in a later phase.
  final FinancialTotals financialTotals;
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

  /// Explicit compatibility values for consumers not yet using financialTotals.
  double get legacyExpensesIncludingFees => totalExpenses;
  double get legacyPrincipalNetMovement => netMovement;
  Map<RecordSubtype, double> get legacySpendingIncludingFees =>
      spendingBySubtype;

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

  final double? totalLoansBorrowed;
  final double? totalLoanRepayments;
  final int? loanBorrowingTransactionCount;
  final int? loanRepaymentTransactionCount;

  final double totalInvested;
  final double totalInvestmentWithdrawals;
  final int investmentTransactionCount;
  final int investmentWithdrawalTransactionCount;

  const FinancialSummary({
    required this.financialTotals,
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
    this.totalLoansBorrowed = 0,
    this.totalLoanRepayments = 0,
    this.loanBorrowingTransactionCount = 0,
    this.loanRepaymentTransactionCount = 0,

    this.totalInvested = 0,
    this.totalInvestmentWithdrawals = 0,
    this.investmentTransactionCount = 0,
    this.investmentWithdrawalTransactionCount = 0,
  });
}
