import '../core/enums/account_type.dart';
import 'financial_instrument.dart';

enum BalanceKind {
  reported('reported', 'Reported balance'),
  available('available', 'Available balance'),
  outstandingDebt('outstanding_debt', 'Outstanding debt');

  final String value, label;
  const BalanceKind(this.value, this.label);
}

/// Explicit supported currency scales. Never assume unknown currencies have
/// two decimals, and never convert user input through floating point.
class SnapshotMoney {
  static const scales = {
    'KES': 2,
    'USD': 2,
    'EUR': 2,
    'GBP': 2,
    'JPY': 0,
    'KWD': 3,
  };
  static String currency(String code) {
    final normalized = code.trim().toUpperCase();
    if (!scales.containsKey(normalized)) {
      throw ArgumentError('Choose a supported currency.');
    }
    return normalized;
  }

  static int parse(String text, String code) {
    final scale = scales[currency(code)]!;
    final match = RegExp(
      r'^(-?)([0-9]+)(?:\.([0-9]+))?$',
    ).firstMatch(text.trim());
    if (match == null) {
      throw ArgumentError('Enter an amount using digits and a decimal point.');
    }
    final fraction = match.group(3) ?? '';
    if (fraction.length > scale) {
      throw ArgumentError('$code allows $scale decimal places.');
    }
    final value = BigInt.parse(
      '${match.group(1)}${match.group(2)}${fraction.padRight(scale, '0')}',
    );
    final maximum = BigInt.parse('9223372036854775807');
    if (value.abs() > maximum) throw ArgumentError('Amount is too large.');
    return value.toInt();
  }

  static String decimal(int value, String code) {
    final scale = scales[currency(code)]!;
    final digits = value.abs().toString().padLeft(scale + 1, '0');
    return '${value < 0 ? '-' : ''}${scale == 0 ? digits : '${digits.substring(0, digits.length - scale)}.${digits.substring(digits.length - scale)}'}';
  }
}

class BalanceObservation {
  final String id, currency;
  final int amountMinor, revision;
  final int? accountId, rawMessageId;
  final String origin, timeBasis;
  final String? associationOrigin,
      associationName,
      matchedClause,
      extractionVersion;
  final bool associationArchived;
  final BalanceKind kind;
  final AccountType? subjectFamily;
  final DateTime asOf, createdAt;
  const BalanceObservation({
    required this.id,
    required this.currency,
    required this.amountMinor,
    required this.accountId,
    required this.revision,
    required this.kind,
    required this.subjectFamily,
    required this.asOf,
    required this.createdAt,
    this.origin = 'manual',
    this.timeBasis = 'user_supplied',
    this.rawMessageId,
    this.associationOrigin,
    this.associationName,
    this.associationArchived = false,
    this.matchedClause,
    this.extractionVersion,
  });
  bool get isManual => origin == 'manual';
  String get sourceLabel => isManual ? 'Manually recorded' : 'SMS-reported';
  String get timeBasisLabel => timeBasis == 'user_supplied'
      ? 'User-supplied as-of time'
      : timeBasis == 'raw_message_received_at_proxy'
      ? 'SMS receipt time (observation-time proxy)'
      : timeBasis == 'sms_declared_minute'
      ? 'SMS-declared time (minute precision)'
      : 'Time basis unavailable';
  String get subjectLabel => switch (subjectFamily) {
    AccountType.mpesa => 'M-PESA wallet',
    AccountType.mshwariSavings => 'M-Shwari savings',
    AccountType.kcbMpesa => 'KCB M-PESA savings',
    AccountType.mshwariLoan => 'M-Shwari loan',
    AccountType.fuliza => 'Fuliza debt',
    _ => 'Unspecified balance subject',
  };
  String get associationLabel => accountId == null
      ? 'Unattributed'
      : associationName == null
      ? 'Unavailable instrument reference'
      : '$associationName${associationArchived ? ' (Archived)' : ''}';
  String get amountText =>
      '${SnapshotMoney.decimal(amountMinor, currency)} $currency';
}

/// A presentation summary; source observations remain unchanged.
class SmsWalletBalance {
  final BalanceObservation latest;
  final int observationCount;
  const SmsWalletBalance(this.latest, this.observationCount);
  bool get isMeasuredWallet => latest.subjectFamily == AccountType.mpesa;
  String get key =>
      '${latest.subjectFamily?.name ?? 'unknown'}:${latest.currency}';
}

class BalanceHistoryPage {
  final List<BalanceObservation> entries;
  final int count, page;
  const BalanceHistoryPage(this.entries, this.count, this.page);
  int get totalPages => count == 0 ? 0 : (count - 1) ~/ 20 + 1;
}

/// Compatibility is a constraint/check, never evidence of ownership.
enum BalanceCompatibility { compatible, confirmationRequired, incompatible }

BalanceCompatibility smsBalanceCompatibility(
  BalanceObservation evidence,
  FinancialInstrument instrument,
) {
  final family = evidence.subjectFamily;
  final expectedType = switch (family) {
    AccountType.mpesa => InstrumentType.mobileWallet,
    AccountType.mshwariSavings ||
    AccountType.kcbMpesa => InstrumentType.savingsProduct,
    AccountType.mshwariLoan || AccountType.fuliza => InstrumentType.other,
    _ => null,
  };
  if (expectedType == null) return BalanceCompatibility.confirmationRequired;
  if (instrument.type != expectedType &&
      instrument.type != InstrumentType.other) {
    return BalanceCompatibility.incompatible;
  }
  final provider = instrument.provider?.trim().toUpperCase();
  // Exact aliases only; no fuzzy matching, substring matching or provider DB.
  final known = switch (provider) {
    'MPESA' || 'M-PESA' => 'mpesa',
    'M-SHWARI' => 'mshwari',
    'KCB M-PESA' => 'kcb',
    'FULIZA' || 'FULIZA M-PESA' => 'fuliza',
    _ => null,
  };
  final expectedProvider = switch (family) {
    AccountType.mpesa => 'mpesa',
    AccountType.mshwariSavings || AccountType.mshwariLoan => 'mshwari',
    AccountType.kcbMpesa => 'kcb',
    AccountType.fuliza => 'fuliza',
    _ => null,
  };
  if (known != null && known != expectedProvider) {
    return BalanceCompatibility.incompatible;
  }
  if (known == null ||
      instrument.type == InstrumentType.other ||
      instrument.storedType != instrument.type.storageValue) {
    return BalanceCompatibility.confirmationRequired;
  }
  return BalanceCompatibility.compatible;
}
