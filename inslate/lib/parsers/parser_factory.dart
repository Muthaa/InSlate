import '/core/enums/record_subtype.dart';
import '/parsers/mpesa/send_money_parser.dart';
import '/parsers/parser.dart';
import '/parsers/mpesa/receive_money_parser.dart';
import '/parsers/mpesa/buy_goods_parser.dart';
import '/parsers/mpesa/paybill_parser.dart';
import '/parsers/mpesa/cash_transaction_parser.dart';
import '/parsers/mpesa/account_transfer_parser.dart';
import '/parsers/mpesa/fuliza_parser.dart';
import '/parsers/mpesa/investment_parser.dart';

class ParserFactory {
  ParserFactory._();

  static Parser? getParser(RecordSubtype subtype) {
    switch (subtype) {
      case RecordSubtype.sendMoney:
        return SendMoneyParser();

      case RecordSubtype.receiveMoney:
        return ReceiveMoneyParser();

      case RecordSubtype.buyGoods:
        return BuyGoodsParser();

      case RecordSubtype.payBill:
        return PayBillParser();

      case RecordSubtype.deposit:
      case RecordSubtype.withdrawal:
        return CashTransactionParser();

      case RecordSubtype.mshwariDeposit:
      case RecordSubtype.mshwariWithdrawal:
      case RecordSubtype.kcbDeposit:
      case RecordSubtype.kcbWithdrawal:
        return AccountTransferParser();

      case RecordSubtype.fulizaLoan:
      case RecordSubtype.fulizaRepayment:
        return FulizaParser();

      case RecordSubtype.investmentPurchase:
      case RecordSubtype.investmentRedemption:
        return InvestmentParser();

      default:
        return null;
    }
  }
}
