import '../models/raw_message.dart';
import '../models/balance_observation.dart';

/// A wallet clause is evidence of a reported balance, never account ownership.
class MpesaWalletBalanceEvidence {
  final int amountMinor;
  final String matchedClause;
  final DateTime asOf;
  const MpesaWalletBalanceEvidence(
    this.amountMinor,
    this.matchedClause,
    this.asOf,
  );
}

class MpesaBalanceEvidenceExtractor {
  static const version = 'mpesa_wallet_v1';
  static const timeBasis = 'raw_message_received_at_proxy';

  // New/Your explicitly name the wallet. A bare M-PESA clause must start
  // a sentence, preventing KCB/Fuliza M-PESA balances from matching.
  static final _head = RegExp(
    r'(?:\b(?:New|Your)\s+M-PESA|(?:^|[.!?]\s*)M-PESA)\s+balance\s+is\b',
    caseSensitive: false,
  );
  static final _mentions = RegExp(
    r'\bM-PESA\s+balance\s+is\b',
    caseSensitive: false,
  );
  static final _amount = RegExp(
    r'^\s*(?:Ksh\s*)?((?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\.[0-9]{2})(?=$|\s|[.,](?:\s|$))',
    caseSensitive: false,
  );

  MpesaWalletBalanceEvidence? extract(RawMessage message) {
    if (message.sender.trim().toUpperCase() != 'MPESA') return null;
    final body = message.body.trim();
    // Count even unsupported/malformed second clauses conservatively.
    if (_mentions.allMatches(body).length != 1) return null;
    final clauses = _head.allMatches(body).toList();
    // Even repeated identical clauses are ambiguous; never choose one silently.
    if (clauses.length != 1) return null;
    final head = clauses.single;
    final amount = _amount.firstMatch(body.substring(head.end));
    if (amount == null) return null;
    final text = amount.group(1)!.replaceAll(',', '');
    int minor;
    try {
      minor = SnapshotMoney.parse(text, 'KES');
    } on ArgumentError {
      return null;
    }
    // RawMessage has a required receipt timestamp, but no original timestamp
    // availability flag. Label it as a proxy, not an SMS-declared as-of time.
    return MpesaWalletBalanceEvidence(
      minor,
      body
          .substring(head.start, head.end + amount.end)
          .trim()
          .replaceFirst(RegExp(r'^[.!?]\s*'), ''),
      message.receivedAt.toUtc(),
    );
  }
}
