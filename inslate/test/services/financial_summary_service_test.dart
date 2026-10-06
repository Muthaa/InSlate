import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/transaction_status.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/mappers/financial_record_type_mapper.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/services/financial_summary_service.dart';

FinancialRecord record(
  RecordSubtype subtype,
  double amount, {
  double fee = 0,
  DateTime? date,
  DateTime? receivedAt,
  FinancialRecordType? type,
  Party? party,
}) => FinancialRecord(
  reference: subtype.name,
  transactionDate: date,
  receivedAt: receivedAt ?? DateTime(2026, 9, 10),
  amount: amount,
  transactionCost: fee,
  balance: null,
  type: type ?? FinancialRecordTypeMapper.fromSubtype(subtype),
  subtype: subtype,
  status: TransactionStatus.successful,
  title: subtype.name,
  rawMessage: '',
  party: party,
);

void main() {
  test('characterizes fee-inclusive expenses and principal net movement', () {
    final summary = FinancialSummaryService().calculate([
      record(RecordSubtype.receiveMoney, 1000, fee: 2),
      record(RecordSubtype.sendMoney, 200, fee: 10),
      record(RecordSubtype.mshwariDeposit, 300, fee: 3),
      record(RecordSubtype.mshwariWithdrawal, 40),
      record(RecordSubtype.kcbDeposit, 50),
      record(RecordSubtype.kcbWithdrawal, 60),
      record(RecordSubtype.investmentPurchase, 70),
      record(RecordSubtype.investmentRedemption, 80),
      record(RecordSubtype.fulizaLoan, 90, fee: 4),
      record(RecordSubtype.fulizaRepayment, 20),
      record(RecordSubtype.receiveMoney, 999, date: DateTime(2026, 10)),
    ], period: DateTime(2026, 9));
    expect(summary.totalIncome, 1000);
    expect(summary.totalReceived, 1000);
    expect(summary.totalSent, 200);
    expect(summary.totalExpenses, 210);
    expect(summary.totalFees, 19);
    expect(summary.netMovement, 800);
    expect(summary.spendingBySubtype, {RecordSubtype.sendMoney: 210});
    expect(summary.moneyInBySubtype, {RecordSubtype.receiveMoney: 1000});
    expect(summary.internalTransfersIn, 100);
    expect(summary.internalTransfersOut, 350);
    expect(summary.internalTransfers, 450);
    expect(summary.totalInvested, 70);
    expect(summary.totalInvestmentWithdrawals, 80);
    expect(summary.totalLoansBorrowed, 90);
    expect(summary.totalLoanRepayments, 20);
    expect(summary.transactionCount, 10);
    expect(summary.legacyExpensesIncludingFees, 210);
    expect(summary.legacyPrincipalNetMovement, 800);
    expect(summary.financialTotals.expenses, 200);
    expect(summary.financialTotals.netCashFlow, 781);
    expect(summary.financialTotals.internalTransfers, 600);
  });

  test('characterizes stored-type membership and party principal grouping', () {
    const party = Party(
      name: 'Alice',
      type: PartyType.person,
      identifier: ' A ',
    );
    const renamed = Party(
      name: 'Other name',
      type: PartyType.person,
      identifier: 'a',
    );
    final summary = FinancialSummaryService().calculate([
      record(RecordSubtype.sendMoney, 10, fee: 2, party: party),
      record(RecordSubtype.payBill, 20, fee: 3, party: renamed),
      record(RecordSubtype.buyGoods, 40),
      record(RecordSubtype.receiveMoney, 5, type: FinancialRecordType.expense),
    ], period: DateTime(2026, 9));
    expect(summary.totalExpenses, 80);
    expect(summary.totalIncome, 0);
    expect(summary.topExpenses.single.amount, 30);
    expect(summary.topExpenses.single.transactionCount, 2);
    expect(summary.expensePartyCount, 1);
  });

  test('characterizes every mapped subtype contribution', () {
    for (final subtype in RecordSubtype.values) {
      final item = record(subtype, 10, fee: 1);
      final summary = FinancialSummaryService().calculate([
        item,
      ], period: DateTime(2026, 9));
      expect(
        summary.totalIncome,
        item.type == FinancialRecordType.income ? 10 : 0,
        reason: subtype.name,
      );
      expect(
        summary.totalExpenses,
        item.type == FinancialRecordType.expense ? 11 : 0,
        reason: subtype.name,
      );
      expect(summary.totalFees, 1, reason: subtype.name);
    }
  });
}
