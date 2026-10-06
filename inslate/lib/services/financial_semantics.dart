import '../core/enums/account_type.dart';
import '../core/enums/financial_record_type.dart';
import '../core/enums/party_type.dart';
import '../core/enums/record_subtype.dart';
import '../models/financial_records.dart';
import '../models/party.dart';

enum MovementClass {
  income,
  expense,
  internalTransfer,
  loanBorrowing,
  loanRepayment,
  unresolved,
}

enum TransferDirection { intoCentral, fromCentral, unrelated, unresolved }

enum PartyIdentityKind { identifier, phone, account, name }

/// Identity precedence is shared with the existing summary service.
class PartyIdentity {
  final PartyIdentityKind kind;
  final String value;
  final PartyType? type;
  const PartyIdentity(this.kind, this.value, {this.type});

  factory PartyIdentity.fromParty(Party party) {
    for (final entry in [
      (PartyIdentityKind.identifier, party.identifier),
      (PartyIdentityKind.phone, party.phone),
      (PartyIdentityKind.account, party.account),
    ]) {
      final value = entry.$2?.trim();
      if (value != null && value.isNotEmpty) {
        return PartyIdentity(
          entry.$1,
          entry.$1 == PartyIdentityKind.phone ? value : value.toLowerCase(),
        );
      }
    }
    return PartyIdentity(
      PartyIdentityKind.name,
      party.name.trim().toLowerCase(),
      type: party.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PartyIdentity &&
      kind == other.kind &&
      value == other.value &&
      type == other.type;
  @override
  int get hashCode => Object.hash(kind, value, type);
}

/// A recognized account family, optionally qualified by stored party identity.
/// It is not an invented database account or ownership identifier.
class AccountEndpoint {
  final AccountType type;
  final PartyIdentity? identity;
  const AccountEndpoint(this.type, {this.identity});
  @override
  bool operator ==(Object other) =>
      other is AccountEndpoint &&
      type == other.type &&
      identity == other.identity;
  @override
  int get hashCode => Object.hash(type, identity);
}

class AccountMovement {
  final AccountEndpoint? source;
  final AccountEndpoint? destination;
  const AccountMovement({this.source, this.destination});

  TransferDirection relativeTo(AccountEndpoint central) {
    if (source == null || destination == null) {
      return TransferDirection.unresolved;
    }
    if (central.identity != null &&
        [source!, destination!].any(
          (endpoint) =>
              endpoint.type == central.type && endpoint.identity == null,
        )) {
      return TransferDirection.unresolved;
    }
    bool matches(AccountEndpoint endpoint) =>
        endpoint.type == central.type &&
        (central.identity == null || endpoint.identity == central.identity);
    if (matches(source!) && !matches(destination!)) {
      return TransferDirection.fromCentral;
    }
    if (matches(destination!) && !matches(source!)) {
      return TransferDirection.intoCentral;
    }
    return TransferDirection.unrelated;
  }
}

class SubtypeSemantics {
  final MovementClass movement;
  final FinancialRecordType? expectedType;
  final AccountType? source;
  final AccountType? destination;
  const SubtypeSemantics(
    this.movement,
    this.expectedType, {
    this.source,
    this.destination,
  });
  bool get isSavingsOrInvestment =>
      movement == MovementClass.internalTransfer &&
      [source, destination].any(
        (type) =>
            type == AccountType.mshwariSavings ||
            type == AccountType.kcbMpesa ||
            type == AccountType.investment,
      );
}

/// Presentation/accounting policy; does not change parser or classifier output.
class FinancialSemantics {
  const FinancialSemantics();

  // Exhaustive: new subtypes require a deliberate accounting decision.
  static SubtypeSemantics forSubtype(
    RecordSubtype subtype,
  ) => switch (subtype) {
    RecordSubtype.receiveMoney || RecordSubtype.deposit =>
      const SubtypeSemantics(MovementClass.income, FinancialRecordType.income),
    RecordSubtype.sendMoney ||
    RecordSubtype.buyGoods ||
    RecordSubtype.payBill ||
    RecordSubtype.airtimePurchase ||
    RecordSubtype.airtimeTopUp ||
    RecordSubtype.withdrawal => const SubtypeSemantics(
      MovementClass.expense,
      FinancialRecordType.expense,
    ),
    RecordSubtype.fulizaLoan ||
    RecordSubtype.loanDisbursement => const SubtypeSemantics(
      MovementClass.loanBorrowing,
      FinancialRecordType.loan,
    ),
    RecordSubtype.fulizaRepayment ||
    RecordSubtype.loanRepayment => const SubtypeSemantics(
      MovementClass.loanRepayment,
      FinancialRecordType.loan,
    ),
    RecordSubtype.mshwariDeposit => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.mpesa,
      destination: AccountType.mshwariSavings,
    ),
    RecordSubtype.mshwariWithdrawal => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.mshwariSavings,
      destination: AccountType.mpesa,
    ),
    RecordSubtype.kcbDeposit => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.mpesa,
      destination: AccountType.kcbMpesa,
    ),
    RecordSubtype.kcbWithdrawal => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.kcbMpesa,
      destination: AccountType.mpesa,
    ),
    RecordSubtype.investmentPurchase => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.mpesa,
      destination: AccountType.investment,
    ),
    RecordSubtype.investmentRedemption => const SubtypeSemantics(
      MovementClass.internalTransfer,
      FinancialRecordType.transfer,
      source: AccountType.investment,
      destination: AccountType.mpesa,
    ),
    // Generic savings have no known account endpoint; billPayment has no
    // established mapping. Keep principal visible without guessing its meaning.
    RecordSubtype.savingsDeposit ||
    RecordSubtype.savingsWithdrawal ||
    RecordSubtype.billPayment ||
    RecordSubtype.unknown => const SubtypeSemantics(
      MovementClass.unresolved,
      null,
    ),
  };

  MovementClass classify(FinancialRecord record) {
    final policy = forSubtype(record.subtype);
    return policy.expectedType == record.type
        ? policy.movement
        : MovementClass.unresolved;
  }

  AccountMovement movement(FinancialRecord record) {
    if (classify(record) != MovementClass.internalTransfer) {
      return const AccountMovement();
    }
    final policy = forSubtype(record.subtype);
    final identity = record.party == null
        ? null
        : PartyIdentity.fromParty(record.party!);
    AccountEndpoint? endpoint(AccountType? type) => type == null
        ? null
        : AccountEndpoint(
            type,
            identity: type == AccountType.investment ? identity : null,
          );
    return AccountMovement(
      source: endpoint(policy.source),
      destination: endpoint(policy.destination),
    );
  }

  FinancialTotals calculate(
    Iterable<FinancialRecord> records, {
    AccountEndpoint central = const AccountEndpoint(AccountType.mpesa),
  }) {
    double income = 0,
        expenses = 0,
        received = 0,
        sent = 0,
        fees = 0,
        into = 0,
        from = 0,
        borrowed = 0,
        repaid = 0;
    for (final record in records) {
      fees += record.transactionCost;
      switch (classify(record)) {
        case MovementClass.income:
          income += record.amount;
          received += record.amount;
        case MovementClass.expense:
          expenses += record.amount;
          sent += record.amount;
        case MovementClass.loanBorrowing:
          borrowed += record.amount;
        case MovementClass.loanRepayment:
          repaid += record.amount;
        case MovementClass.internalTransfer:
          switch (movement(record).relativeTo(central)) {
            case TransferDirection.intoCentral:
              into += record.amount;
            case TransferDirection.fromCentral:
              from += record.amount;
            case TransferDirection.unrelated || TransferDirection.unresolved:
              break;
          }
        case MovementClass.unresolved:
          break;
      }
    }
    return FinancialTotals(
      income: income,
      expenses: expenses,
      received: received,
      sent: sent,
      fees: fees,
      transfersIntoCentral: into,
      transfersFromCentral: from,
      borrowed: borrowed,
      repaid: repaid,
    );
  }
}

class FinancialTotals {
  final double income,
      expenses,
      fees,
      transfersIntoCentral,
      transfersFromCentral,
      borrowed,
      repaid;
  final double received, sent;
  const FinancialTotals({
    required this.income,
    required this.expenses,
    required this.fees,
    required this.transfersIntoCentral,
    required this.transfersFromCentral,
    required this.borrowed,
    required this.repaid,
    required this.received,
    required this.sent,
  });
  double get netCashFlow => income - expenses - fees;
  double get internalTransfers => transfersIntoCentral + transfersFromCentral;
}
