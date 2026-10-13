/// User-declared instrument kinds. These storage values are permanent and
/// independent of transaction AccountType, provider names and RecordSubtype.
enum InstrumentType {
  bankAccount('bank_account'),
  mobileWallet('mobile_wallet'),
  savingsProduct('savings_product'),
  investmentAccount('investment_account'),
  saccoMembership('sacco_membership'),
  insurancePolicy('insurance_policy'),
  pension('pension'),
  other('other');

  final String storageValue;
  const InstrumentType(this.storageValue);

  /// Unknown/legacy strings never change stored data or imply ownership.
  static InstrumentType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () => other,
  );
}

/// User-entered reference numbers only. No passwords, PINs or access tokens.
/// These values are descriptive metadata; they do not match/link transactions.
class InstrumentIdentifiers {
  final String? accountNumber,
      walletNumber,
      membershipNumber,
      policyNumber,
      reference;
  const InstrumentIdentifiers({
    this.accountNumber,
    this.walletNumber,
    this.membershipNumber,
    this.policyNumber,
    this.reference,
  });

  Map<String, String> toJson() => {
    'accountNumber': ?accountNumber,
    'walletNumber': ?walletNumber,
    'membershipNumber': ?membershipNumber,
    'policyNumber': ?policyNumber,
    'reference': ?reference,
  };
  factory InstrumentIdentifiers.fromJson(Map<String, dynamic> json) =>
      InstrumentIdentifiers(
        accountNumber: json['accountNumber'] as String?,
        walletNumber: json['walletNumber'] as String?,
        membershipNumber: json['membershipNumber'] as String?,
        policyNumber: json['policyNumber'] as String?,
        reference: json['reference'] as String?,
      );
}

/// Projection of an explicitly registered Accounts row, not a second account
/// store. Numeric ID and UUID stay stable through edits and archiving.
class FinancialInstrument {
  final int id;
  final String uuid, name;
  final InstrumentType type;
  final String storedType;
  final String? provider;
  final InstrumentIdentifiers? identifiers;
  final bool isActive;
  final DateTime createdAt;
  bool get isArchived => !isActive;

  const FinancialInstrument({
    required this.id,
    required this.uuid,
    required this.name,
    required this.type,
    required this.storedType,
    this.provider,
    this.identifiers,
    required this.isActive,
    required this.createdAt,
  });
}
