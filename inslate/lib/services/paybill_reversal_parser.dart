import '../models/balance_observation.dart';
import '../models/raw_message.dart';

/// The five audited confirmations share this complete, explicit credit wording.
/// Other reversal notices are not a supported financial movement.
class PayBillReversalClaim {
  final String reference, originalReference, walletClause;
  final int principalMinor, walletMinor;
  final DateTime declaredAt;
  const PayBillReversalClaim(
    this.reference,
    this.originalReference,
    this.principalMinor,
    this.walletMinor,
    this.declaredAt,
    this.walletClause,
  );
}

class PayBillReversalParser {
  static const version = 'paybill_principal_reversal_v1';
  static const _money = r'((?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\.[0-9]{2})';
  static final _pattern = RegExp(
    r'^([A-Z0-9]{10})\s+confirmed\.\s+Reversal of transaction\s+([A-Z0-9]{10})\s+has been successfully reversed\s+on\s+(\d{1,2})/(\d{1,2})/(\d{2})\s+at\s+(\d{1,2}):(\d{2})\s+(AM|PM)\s+and\s+Ksh' +
        _money +
        r'\s+is credited to your M-PESA account\.\s+(New M-PESA account balance is Ksh' +
        _money +
        r')\.?$',
    caseSensitive: false,
  );

  PayBillReversalClaim? parse(RawMessage message) {
    if (message.sender.trim().toUpperCase() != 'MPESA') return null;
    final m = _pattern.firstMatch(message.body.trim());
    if (m == null) return null;
    final reference = m[1]!;
    final original = m[2]!;
    // References are exact, not case-folded identities.
    if (reference != reference.toUpperCase() ||
        original != original.toUpperCase() ||
        reference == original) {
      return null;
    }
    final day = int.parse(m[3]!),
        month = int.parse(m[4]!),
        year = 2000 + int.parse(m[5]!);
    final hour = int.parse(m[6]!), minute = int.parse(m[7]!);
    if (hour < 1 || hour > 12 || minute > 59) return null;
    // Match the app's existing local M-PESA transaction timestamp convention.
    // Seconds=0 is the start of the declared minute, not claimed second precision.
    final date = DateTime(
      year,
      month,
      day,
      hour % 12 + (m[8]!.toUpperCase() == 'PM' ? 12 : 0),
      minute,
    );
    if (date.year != year ||
        date.month != month ||
        date.day != day ||
        date.isAfter(message.receivedAt)) {
      return null;
    }
    try {
      final amount = SnapshotMoney.parse(m[9]!.replaceAll(',', ''), 'KES');
      final balance = SnapshotMoney.parse(m[11]!.replaceAll(',', ''), 'KES');
      if (amount <= 0 || amount > 99999999999999) return null;
      return PayBillReversalClaim(
        reference,
        original,
        amount,
        balance,
        date,
        m[10]!,
      );
    } on ArgumentError {
      return null;
    }
  }
}
