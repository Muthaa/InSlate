import '/core/enums/financial_record_type.dart';
import '/core/enums/record_subtype.dart';

class FinancialRecordTypeMapper {
  FinancialRecordTypeMapper._();

  static FinancialRecordType fromSubtype(RecordSubtype subtype) {
    switch (subtype) {
      // Expense subtypes
      case RecordSubtype.sendMoney:
      case RecordSubtype.buyGoods:
      case RecordSubtype.payBill:
      case RecordSubtype.airtimePurchase:
      case RecordSubtype.airtimeTopUp:
      case RecordSubtype.withdrawal:
        return FinancialRecordType.expense;

      // Income subtypes
      case RecordSubtype.receiveMoney:
      case RecordSubtype.deposit:
        return FinancialRecordType.income;

      // Internal transfer subtypes
      case RecordSubtype.mshwariDeposit:
      case RecordSubtype.mshwariWithdrawal:
      case RecordSubtype.kcbDeposit:
      case RecordSubtype.kcbWithdrawal:
      case RecordSubtype.investmentPurchase:
      case RecordSubtype.investmentRedemption:
        return FinancialRecordType.transfer;

      // Loan subtypes
      case RecordSubtype.fulizaLoan:
      case RecordSubtype.fulizaRepayment:
        return FinancialRecordType.loan;

      default:
        return FinancialRecordType.transfer;
    }
  }
}
