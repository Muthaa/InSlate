class MpesaKeywords {
  MpesaKeywords._();

  // ===== Transaction Status =====

  static const confirmed = 'confirmed';
  static const failed = 'failed';
  static const pending = 'pending';

  // ===== Common Keywords =====

  static const sentTo = 'sent to';
  static const received = 'received';
  static const paidTo = 'paid to';
  static const forAccount = 'for account';

  // ===== Agent Transactions =====

  static const give = 'give';
  static const withdraw = 'withdraw';
  static const amWithdraw = 'amwithdraw';

  // ===== M-Shwari =====

  static const mshwari = 'm-shwari';
  static const transferredToMShwari = 'transferred to m-shwari';
  static const transferredFromMShwari = 'transferred from m-shwari';

  // ===== KCB M-PESA =====

  static const kcbMpesa = 'kcb m-pesa';
  static const transferredToKcb = 'transferred to kcb m-pesa';
  static const transferredFromKcb = 'transferred from your kcb m-pesa';

  // ===== Fuliza =====

  static const fuliza = 'fuliza';
  static const fulizaLoan = 'fuliza m-pesa amount';
  static const fulizaRepayment = 'outstanding fuliza';

  // ===== Generic Transfer =====

  static const transferredTo = 'transferred to';
  static const transferredFrom = 'transferred from';
}
