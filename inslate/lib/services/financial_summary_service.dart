import '../core/enums/financial_record_type.dart';
import '../core/enums/record_subtype.dart';
import '../models/financial_records.dart';
import '../models/financial_summary.dart';
import '../models/party.dart';
import '../models/party_summary.dart';

class FinancialSummaryService {
  FinancialSummary calculate(
    List<FinancialRecord> records, {
    required DateTime period,
  }) {
    final periodRecords = records.where((record) {
      final date = record.transactionDate ?? record.receivedAt;

      return date.year == period.year && date.month == period.month;
    }).toList();

    double totalIncome = 0;
    double totalExpenses = 0;
    double totalSent = 0;
    double totalReceived = 0;

    double internalTransfersIn = 0;
    double internalTransfersOut = 0;

    double totalFees = 0;

    int expenseTransactionCount = 0;
    int incomeTransactionCount = 0;

    double totalLoansBorrowed = 0;
    double totalLoanRepayments = 0;

    int loanBorrowingTransactionCount = 0;
    int loanRepaymentTransactionCount = 0;

    double totalInvested = 0;
    double totalInvestmentWithdrawals = 0;

    int investmentTransactionCount = 0;
    int investmentWithdrawalTransactionCount = 0;

    final spendingBySubtype = <RecordSubtype, double>{};
    final transactionCountBySubtype = <RecordSubtype, int>{};

    final moneyInBySubtype = <RecordSubtype, double>{};

    final incomeBySubtype = <RecordSubtype, double>{};
    final incomeTransactionCountBySubtype = <RecordSubtype, int>{};

    final expenseParties = <String, _PartyAccumulator>{};
    final incomeParties = <String, _PartyAccumulator>{};

    for (final record in periodRecords) {
      totalFees += record.transactionCost;

      if (record.subtype == RecordSubtype.investmentPurchase) {
        totalInvested += record.amount;
        investmentTransactionCount++;
      } else if (record.subtype == RecordSubtype.investmentRedemption) {
        totalInvestmentWithdrawals += record.amount;
        investmentWithdrawalTransactionCount++;
      }

      switch (record.type) {
        case FinancialRecordType.income:
          incomeTransactionCount++;

          totalIncome += record.amount;
          totalReceived += record.amount;

          incomeBySubtype[record.subtype] =
              (incomeBySubtype[record.subtype] ?? 0) + record.amount;

          moneyInBySubtype[record.subtype] =
              (moneyInBySubtype[record.subtype] ?? 0) + record.amount;

          incomeTransactionCountBySubtype[record.subtype] =
              (incomeTransactionCountBySubtype[record.subtype] ?? 0) + 1;

          _addParty(incomeParties, record);

          break;

        case FinancialRecordType.expense:
          expenseTransactionCount++;

          totalExpenses += record.amount + record.transactionCost;
          totalSent += record.amount;

          spendingBySubtype[record.subtype] =
              (spendingBySubtype[record.subtype] ?? 0) +
              record.amount +
              record.transactionCost;

          transactionCountBySubtype[record.subtype] =
              (transactionCountBySubtype[record.subtype] ?? 0) + 1;

          _addParty(expenseParties, record);

          break;

        case FinancialRecordType.transfer:
          _calculateInternalTransfer(
            record,
            onIncoming: (amount) {
              internalTransfersIn += amount;
            },
            onOutgoing: (amount) {
              internalTransfersOut += amount;
            },
          );

          break;

        case FinancialRecordType.loan:
          if (record.subtype == RecordSubtype.fulizaLoan ||
              record.subtype == RecordSubtype.loanDisbursement) {
            totalLoansBorrowed += record.amount;
            loanBorrowingTransactionCount++;
          } else if (record.subtype == RecordSubtype.fulizaRepayment ||
              record.subtype == RecordSubtype.loanRepayment) {
            totalLoanRepayments += record.amount;
            loanRepaymentTransactionCount++;
          }
          break;

        case FinancialRecordType.savings:
        case FinancialRecordType.investment:
        case FinancialRecordType.repayment:
        case FinancialRecordType.fee:
        case FinancialRecordType.unknown:
          break;
      }
    }

    final internalTransfers = internalTransfersIn + internalTransfersOut;

    final recordsWithBalance =
        periodRecords.where((record) => record.balance != null).toList()
          ..sort((a, b) {
            final aDate = a.transactionDate;
            final bDate = b.transactionDate;

            if (aDate == null && bDate == null) {
              return 0;
            }

            if (aDate == null) {
              return -1;
            }

            if (bDate == null) {
              return 1;
            }

            return aDate.compareTo(bDate);
          });

    final currentBalance = recordsWithBalance.isNotEmpty
        ? recordsWithBalance.last.balance!
        : 0.0;

    final recentTransactions = [...periodRecords]
      ..sort((a, b) {
        final aDate = a.transactionDate;
        final bDate = b.transactionDate;

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

    final topExpenses = _buildTopParties(expenseParties);

    final topIncome = _buildTopParties(incomeParties);

    final expensePartyCount = expenseParties.length;

    final incomePartyCount = incomeParties.length;

    final netMovement = totalReceived - totalSent;

    return FinancialSummary(
      period: period,
      currentBalance: currentBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSent: totalSent,
      totalReceived: totalReceived,
      internalTransfers: internalTransfers,
      internalTransfersIn: internalTransfersIn,
      internalTransfersOut: internalTransfersOut,
      totalFees: totalFees,
      netMovement: netMovement,
      transactionCount: periodRecords.length,
      expenseTransactionCount: expenseTransactionCount,
      incomeTransactionCount: incomeTransactionCount,
      recentTransactions: recentTransactions.take(5).toList(),
      spendingBySubtype: spendingBySubtype,
      transactionCountBySubtype: transactionCountBySubtype,
      moneyInBySubtype: moneyInBySubtype,
      incomeBySubtype: incomeBySubtype,
      incomeTransactionCountBySubtype: incomeTransactionCountBySubtype,
      topExpenses: topExpenses,
      topIncome: topIncome,
      expensePartyCount: expensePartyCount,
      incomePartyCount: incomePartyCount,
      totalLoansBorrowed: totalLoansBorrowed,
      totalLoanRepayments: totalLoanRepayments,
      loanBorrowingTransactionCount: loanBorrowingTransactionCount,
      loanRepaymentTransactionCount: loanRepaymentTransactionCount,
      totalInvested: totalInvested,
      totalInvestmentWithdrawals: totalInvestmentWithdrawals,
      investmentTransactionCount: investmentTransactionCount,
      investmentWithdrawalTransactionCount:
          investmentWithdrawalTransactionCount,
    );
  }

  void _calculateInternalTransfer(
    FinancialRecord record, {
    required void Function(double amount) onIncoming,
    required void Function(double amount) onOutgoing,
  }) {
    switch (record.subtype) {
      // Money leaves M-PESA and moves into the
      // user's M-Shwari account.
      case RecordSubtype.mshwariDeposit:
        onOutgoing(record.amount);
        break;

      // Money leaves M-PESA and moves into the
      // user's KCB M-PESA account.
      case RecordSubtype.kcbDeposit:
        onOutgoing(record.amount);
        break;

      // Money leaves M-Shwari and comes back
      // into the user's M-PESA account.
      case RecordSubtype.mshwariWithdrawal:
        onIncoming(record.amount);
        break;

      // Money leaves KCB M-PESA and comes back
      // into the user's M-PESA account.
      case RecordSubtype.kcbWithdrawal:
        onIncoming(record.amount);
        break;

      default:
        break;
    }
  }

  void _addParty(
    Map<String, _PartyAccumulator> parties,
    FinancialRecord record,
  ) {
    final party = record.party;

    if (party == null) {
      return;
    }

    final key = _partyKey(party);

    final existing = parties[key];

    if (existing == null) {
      parties[key] = _PartyAccumulator(
        party: party,
        amount: record.amount,
        transactionCount: 1,
      );
      return;
    }

    existing.amount += record.amount;
    existing.transactionCount++;
  }

  String _partyKey(Party party) {
    final identifier = party.identifier?.trim();

    if (identifier != null && identifier.isNotEmpty) {
      return 'identifier:${identifier.toLowerCase()}';
    }

    final phone = party.phone?.trim();

    if (phone != null && phone.isNotEmpty) {
      return 'phone:$phone';
    }

    final account = party.account?.trim();

    if (account != null && account.isNotEmpty) {
      return 'account:${account.toLowerCase()}';
    }

    return 'name:${party.type.name}:${party.name.trim().toLowerCase()}';
  }

  List<PartySummary> _buildTopParties(Map<String, _PartyAccumulator> parties) {
    final results = parties.values
        .map(
          (item) => PartySummary(
            party: item.party,
            amount: item.amount,
            transactionCount: item.transactionCount,
          ),
        )
        .toList();

    results.sort((a, b) => b.amount.compareTo(a.amount));

    return results.take(5).toList();
  }
}

class _PartyAccumulator {
  final Party party;
  double amount;
  int transactionCount;

  _PartyAccumulator({
    required this.party,
    required this.amount,
    required this.transactionCount,
  });
}
