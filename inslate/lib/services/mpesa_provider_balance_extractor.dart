import '../core/enums/account_type.dart';
import '../models/balance_observation.dart';
import '../models/raw_message.dart';

class ProviderBalanceEvidence {
  final String subjectKey, matchedClause;
  final AccountType subjectFamily;
  final BalanceKind kind;
  final int amountMinor;
  const ProviderBalanceEvidence({
    required this.subjectKey,
    required this.subjectFamily,
    required this.kind,
    required this.amountMinor,
    required this.matchedClause,
  });
}

/// Restricted to provider clauses evidenced by the parser fixtures. No amounts
/// are inferred from movements, repayment wording, limits or instrument links.
class MpesaProviderBalanceExtractor {
  static const version = 'mpesa_products_v1';
  static RegExp _pattern(String pattern) =>
      RegExp(pattern, caseSensitive: false);
  static final _mshwari = _pattern(
    r'\b(?:(?:New|Your)\s+)?M-Shwari\s+(?:(?:saving\s+account|account\s+available)\s+)?balance\s+is\b',
  );
  static final _kcb = _pattern(
    r'\b(?:New\s+)?KCB\s+M-PESA\s+(?:Saving\s+account|Account)\s+balance\s+is\b',
  );
  static final _fulizaMentions = _pattern(
    r'\b(?:Total\s+)?Fuliza\s+M-PESA\s+outstanding\s+(?:amount|balance)\s+is\b',
  );
  static final _fuliza = _pattern(
    r'\bTotal\s+Fuliza\s+M-PESA\s+outstanding\s+amount\s+is\b',
  );
  static final _loan = _pattern(r'\bLoan\s+balance\s+is\b');
  static final _repayment = _pattern(
    r'\bLoan\s+of\s+Ksh[0-9,]+\.[0-9]{2}\s+repaid\s+from\s+M-Shwari\s+on\b',
  );
  static final _precedingSavings = _pattern(
    r'\b(?:New\s+)?M-Shwari\s+balance\s+is\s+Ksh[0-9,]+\.[0-9]{2}\s*\.\s*$',
  );
  static final _money = _pattern(
    r'^\s*Ksh\s*((?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\.[0-9]{2})(?=\s*$|\s*[.,](?=[A-Za-z]|\s|$)|\s+due\s+on\b)',
  );

  List<ProviderBalanceEvidence> extract(RawMessage message) {
    if (message.sender.trim().toUpperCase() != 'MPESA') return const [];
    final body = message.body;
    final result = <ProviderBalanceEvidence>[];
    void add(RegExp heads, String key, AccountType family, BalanceKind kind) {
      final matches = heads.allMatches(body).toList();
      // Ambiguity is per subject, including duplicate identical or malformed
      // clauses. Other independently identified subjects remain eligible.
      if (matches.length != 1) return;
      final head = matches.single;
      // Bare provider headings must begin a clause. In particular, do not
      // reinterpret "outstanding M-Shwari balance" as a savings balance.
      final explicitPrefix = RegExp(
        r'^(?:New|Your)\b',
        caseSensitive: false,
      ).hasMatch(head.group(0)!);
      if (!explicitPrefix &&
          head.start != 0 &&
          !RegExp(r'[.!?,]\s*$').hasMatch(body.substring(0, head.start))) {
        return;
      }
      final money = _money.firstMatch(body.substring(head.end));
      if (money == null) return;
      int minor;
      try {
        minor = SnapshotMoney.parse(money.group(1)!.replaceAll(',', ''), 'KES');
      } on ArgumentError {
        return;
      }
      result.add(
        ProviderBalanceEvidence(
          subjectKey: key,
          subjectFamily: family,
          kind: kind,
          amountMinor: minor,
          matchedClause: body.substring(head.start, head.end + money.end),
        ),
      );
    }

    final savings = _mshwari.allMatches(body).toList();
    add(
      _mshwari,
      'mshwari-savings',
      AccountType.mshwariSavings,
      savings.length == 1 &&
              savings.single.group(0)!.toLowerCase().contains('available')
          ? BalanceKind.available
          : BalanceKind.reported,
    );
    add(_kcb, 'kcb-mpesa-savings', AccountType.kcbMpesa, BalanceKind.reported);
    final loans = _loan.allMatches(body).toList();
    if (loans.length == 1 &&
        _repayment.hasMatch(body.substring(0, loans.single.start)) &&
        _precedingSavings.hasMatch(body.substring(0, loans.single.start))) {
      add(
        _loan,
        'mshwari-loan',
        AccountType.mshwariLoan,
        BalanceKind.outstandingDebt,
      );
    }
    if (_fulizaMentions.allMatches(body).length == 1) {
      add(
        _fuliza,
        'fuliza-debt',
        AccountType.fuliza,
        BalanceKind.outstandingDebt,
      );
    }
    return result;
  }
}
