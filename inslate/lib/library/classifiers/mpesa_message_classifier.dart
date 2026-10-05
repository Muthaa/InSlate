import '/core/constants/mpesa_keywords.dart';
import '/core/enums/message_type.dart';
import '/core/enums/record_subtype.dart';
import '/core/enums/transaction_status.dart';
import 'message_classifier.dart';
import '/core/extensions/string_extensions.dart';
import '/core/constants/investment_keywords.dart';
import '/core/constants/mpesa_patterns.dart';

class MpesaMessageClassifier implements MessageClassifier {
  @override
  ClassificationResult classify(String message) {
    final text = message.toLowerCase().trim();

    // --------------------------------------------------
    // Determine transaction status
    // --------------------------------------------------

    TransactionStatus status = TransactionStatus.unknown;

    if (text.contains(MpesaKeywords.failed)) {
      status = TransactionStatus.failed;
    } else if (text.contains(MpesaKeywords.pending)) {
      status = TransactionStatus.pending;
    } else if (text.contains(MpesaKeywords.confirmed)) {
      status = TransactionStatus.successful;
    }

    // --------------------------------------------------
    // Ignore non-transaction messages
    // --------------------------------------------------

    if (status == TransactionStatus.unknown) {
      return _result(MessageType.notification, RecordSubtype.unknown, status);
    }

    // Investment Purchase
    bool containsInvestment(String text) {
      final balanceIndex = text.indexOf('new m-pesa balance');

      final transactionText = balanceIndex >= 0
          ? text.substring(0, balanceIndex)
          : text;

      return InvestmentKeywords.providers.any(transactionText.contains);
    }

    if (text.contains(MpesaKeywords.sentTo) &&
        text.contains(MpesaKeywords.forAccount) &&
        containsInvestment(text)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.investmentPurchase,
        status,
      );
    }

    // --------------------------------------------------
    // Investment Redemption
    // Must be checked before generic Receive Money
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.received) &&
        text.contains(' from ') &&
        containsInvestment(text)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.investmentRedemption,
        status,
      );
    }

    // --------------------------------------------------
    // PayBill
    // Must be checked before Send Money
    // --------------------------------------------------
    if (text.containsAll([MpesaKeywords.sentTo, MpesaKeywords.forAccount])) {
      return _result(MessageType.transaction, RecordSubtype.payBill, status);
    }

    // --------------------------------------------------
    // Buy Goods
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.paidTo)) {
      return _result(MessageType.transaction, RecordSubtype.buyGoods, status);
    }

    // --------------------------------------------------
    // Airtime Purchase
    // --------------------------------------------------

    if (text.contains('bought') && text.contains('airtime')) {
      return _result(
        MessageType.transaction,
        RecordSubtype.airtimePurchase,
        status,
      );
    }

    // --------------------------------------------------
    // Send Money
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.sentTo)) {
      return _result(MessageType.transaction, RecordSubtype.sendMoney, status);
    }

    // --------------------------------------------------
    // Receive Money
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.received)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.receiveMoney,
        status,
      );
    }

    // --------------------------------------------------
    // Agent Deposit
    // --------------------------------------------------

    if (MpesaPatterns.cashDeposit.hasMatch(message)) {
      return _result(MessageType.transaction, RecordSubtype.deposit, status);
    }

    // --------------------------------------------------
    // M-Shwari Deposit
    // --------------------------------------------------

    if (MpesaPatterns.mshwariDeposit.hasMatch(message)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.mshwariDeposit,
        status,
      );
    }

    // --------------------------------------------------
    // M-Shwari Withdrawal
    // --------------------------------------------------

    if (MpesaPatterns.mshwariWithdrawal.hasMatch(message)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.mshwariWithdrawal,
        status,
      );
    }

    // --------------------------------------------------
    // KCB Mpesa Deposit
    // --------------------------------------------------

    if (MpesaPatterns.kcbDeposit.hasMatch(message)) {
      return _result(MessageType.transaction, RecordSubtype.kcbDeposit, status);
    }

    // --------------------------------------------------
    // KCB Mpesa Withdrawal
    // --------------------------------------------------

    if (MpesaPatterns.kcbWithdrawal.hasMatch(message)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.kcbWithdrawal,
        status,
      );
    }

    // --------------------------------------------------
    // Agent Withdrawal
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.amWithdraw) ||
        text.contains(MpesaKeywords.withdraw)) {
      return _result(MessageType.transaction, RecordSubtype.withdrawal, status);
    }

    // --------------------------------------------------
    // Fuliza Loan
    // --------------------------------------------------

    if (MpesaPatterns.fulizaOutstanding.hasMatch(message)) {
      return _result(MessageType.transaction, RecordSubtype.fulizaLoan, status);
    }

    // --------------------------------------------------
    // Fuliza Repayment
    // --------------------------------------------------

    if (text.contains(MpesaKeywords.fulizaRepayment)) {
      return _result(
        MessageType.transaction,
        RecordSubtype.fulizaRepayment,
        status,
      );
    }

    // --------------------------------------------------
    // Unknown Transaction
    // --------------------------------------------------

    return _result(MessageType.transaction, RecordSubtype.unknown, status);
  }

  ClassificationResult _result(
    MessageType messageType,
    RecordSubtype subtype,
    TransactionStatus status,
  ) {
    return ClassificationResult(
      messageType: messageType,
      subtype: subtype,
      status: status,
    );
  }
}
