import 'package:intl/intl.dart';
import '../../core/enums/account_type.dart';
import '../../core/enums/record_subtype.dart';
import '../../models/activity_filter.dart';
import '../../models/financial_records.dart';
import '../../models/financial_period.dart';
import '../../services/financial_semantics.dart';

String formatMoney(double amount) =>
    NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2).format(amount);
String periodLabel(FinancialPeriod period) {
  if (period == FinancialPeriod.month(period.start)) {
    return DateFormat.yMMMM().format(period.start);
  }
  return '${DateFormat.yMMMd().format(period.start)} – ${DateFormat.yMMMd().format(period.end.subtract(const Duration(microseconds: 1)))}';
}

String scopeLabel(ActivityScope scope) => switch (scope) {
  ActivityScope.all => 'All activity',
  ActivityScope.income => 'Income',
  ActivityScope.expenses => 'Expenses',
  ActivityScope.internalTransfers => 'Internal transfers',
  ActivityScope.loans => 'Loans',
  ActivityScope.investmentsAndSavings => 'Investments & savings',
};

String accountLabel(AccountType type) => switch (type) {
  AccountType.mpesa => 'M-PESA',
  AccountType.mshwariSavings => 'M-Shwari',
  AccountType.kcbMpesa => 'KCB M-PESA',
  AccountType.investment => 'Investments',
  AccountType.bank => 'Bank',
  AccountType.cash => 'Cash',
  AccountType.mshwariLoan => 'M-Shwari loan',
  AccountType.fuliza => 'Fuliza',
  AccountType.creditCard => 'Credit card',
  AccountType.unknown => 'Unresolved account',
};

String subtypeLabel(RecordSubtype subtype) => switch (subtype) {
  RecordSubtype.sendMoney => 'Send money',
  RecordSubtype.receiveMoney => 'Receive money',
  RecordSubtype.withdrawal => 'Cash withdrawal',
  RecordSubtype.deposit => 'Cash deposit',
  RecordSubtype.buyGoods => 'Buy goods',
  RecordSubtype.payBill => 'PayBill',
  RecordSubtype.mshwariDeposit => 'M-Shwari deposit',
  RecordSubtype.mshwariWithdrawal => 'M-Shwari withdrawal',
  RecordSubtype.kcbDeposit => 'KCB M-PESA deposit',
  RecordSubtype.kcbWithdrawal => 'KCB M-PESA withdrawal',
  RecordSubtype.fulizaLoan => 'Fuliza borrowing',
  RecordSubtype.fulizaRepayment => 'Fuliza repayment',
  RecordSubtype.investmentPurchase => 'Investment purchase',
  RecordSubtype.investmentRedemption => 'Investment redemption',
  RecordSubtype.airtimePurchase => 'Airtime purchase',
  RecordSubtype.airtimeTopUp => 'Airtime top-up',
  RecordSubtype.loanRepayment => 'Loan repayment',
  RecordSubtype.loanDisbursement => 'Loan disbursement',
  RecordSubtype.savingsDeposit => 'Savings deposit',
  RecordSubtype.savingsWithdrawal => 'Savings withdrawal',
  RecordSubtype.billPayment => 'Bill payment',
  RecordSubtype.unknown => 'Unrecognized activity',
};

/// Signs describe known movement only. Borrowing is not assumed to deposit cash.
class TransactionPresentation {
  final String directionLabel;
  final String amountPrefix;
  final MovementClass movement;
  const TransactionPresentation(
    this.directionLabel,
    this.amountPrefix,
    this.movement,
  );

  factory TransactionPresentation.forRecord(
    FinancialRecord record, {
    AccountEndpoint central = const AccountEndpoint(AccountType.mpesa),
  }) {
    const semantics = FinancialSemantics();
    final kind = semantics.classify(record);
    switch (kind) {
      case MovementClass.income:
        return TransactionPresentation('Income · received', '+', kind);
      case MovementClass.expense:
        return TransactionPresentation('Expense · sent', '−', kind);
      case MovementClass.loanBorrowing:
        return TransactionPresentation('Borrowed · loan principal', '', kind);
      case MovementClass.loanRepayment:
        return TransactionPresentation('Repaid · loan principal', '', kind);
      case MovementClass.unresolved:
        return TransactionPresentation(
          'Unresolved financial meaning',
          '',
          kind,
        );
      case MovementClass.internalTransfer:
        final movement = semantics.movement(record);
        final centralLabel = accountLabel(central.type);
        final source = movement.source == null
            ? 'Unresolved account'
            : accountLabel(movement.source!.type);
        final destination = movement.destination == null
            ? 'Unresolved account'
            : accountLabel(movement.destination!.type);
        return switch (movement.relativeTo(central)) {
          TransferDirection.intoCentral => TransactionPresentation(
            'Into $centralLabel · from $source',
            '+',
            kind,
          ),
          TransferDirection.fromCentral => TransactionPresentation(
            'From $centralLabel · to $destination',
            '−',
            kind,
          ),
          TransferDirection.unrelated => TransactionPresentation(
            '$source → $destination',
            '',
            kind,
          ),
          TransferDirection.unresolved => TransactionPresentation(
            'Internal transfer · unresolved direction',
            '',
            kind,
          ),
        };
    }
  }
}
