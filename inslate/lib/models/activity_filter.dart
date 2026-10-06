import '../core/enums/account_type.dart';
import '../core/enums/record_subtype.dart';
import '../models/financial_records.dart';
import '../services/financial_semantics.dart';
import 'financial_period.dart';

enum ActivityScope {
  all,
  income,
  expenses,
  internalTransfers,
  loans,
  investmentsAndSavings,
}

enum PartyPresence { identified, unidentified }

enum SemanticResolution { resolved, unresolved }

/// Immutable query shared by the explorer and future drill-down entry points.
class ActivityFilter {
  final FinancialPeriod period;
  final ActivityScope scope;
  final RecordSubtype? subtype;
  final PartyIdentity? party;
  final PartyPresence? partyPresence;
  final SemanticResolution? resolution;
  final TransferDirection? direction;
  final AccountEndpoint? endpoint;
  final AccountEndpoint central;

  const ActivityFilter({
    required this.period,
    this.scope = ActivityScope.all,
    this.subtype,
    this.party,
    this.partyPresence,
    this.resolution,
    this.direction,
    this.endpoint,
    this.central = const AccountEndpoint(AccountType.mpesa),
  });

  ActivityFilter withPeriod(FinancialPeriod period) => ActivityFilter(
    period: period,
    scope: scope,
    subtype: subtype,
    party: party,
    partyPresence: partyPresence,
    resolution: resolution,
    direction: direction,
    endpoint: endpoint,
    central: central,
  );
  ActivityFilter withScope(ActivityScope scope) => ActivityFilter(
    period: period,
    scope: scope,
    subtype: subtype,
    party: party,
    partyPresence: partyPresence,
    resolution: resolution,
    direction: direction,
    endpoint: endpoint,
    central: central,
  );

  /// Used by both SQL query construction and in-memory verification.
  bool acceptsSubtype(RecordSubtype candidate) {
    if (subtype != null && subtype != candidate) return false;
    final policy = FinancialSemantics.forSubtype(candidate);
    final accepted = switch (scope) {
      ActivityScope.all => true,
      ActivityScope.income => policy.movement == MovementClass.income,
      ActivityScope.expenses => policy.movement == MovementClass.expense,
      ActivityScope.internalTransfers =>
        policy.movement == MovementClass.internalTransfer,
      ActivityScope.loans =>
        policy.movement == MovementClass.loanBorrowing ||
            policy.movement == MovementClass.loanRepayment,
      ActivityScope.investmentsAndSavings => policy.isSavingsOrInvestment,
    };
    if (!accepted) return false;
    if (endpoint != null &&
        policy.source != endpoint!.type &&
        policy.destination != endpoint!.type) {
      return false;
    }
    if (direction != null) {
      final movement = AccountMovement(
        source: policy.source == null ? null : AccountEndpoint(policy.source!),
        destination: policy.destination == null
            ? null
            : AccountEndpoint(policy.destination!),
      );
      // Account families can be selected here; identity-qualified central
      // accounts cannot be resolved by today's records.
      if (movement.relativeTo(central) != direction) return false;
    }
    return true;
  }

  bool get requiresResolvedSemantics =>
      scope != ActivityScope.all || endpoint != null || direction != null;

  bool matches(FinancialRecord record) {
    if (!period.contains(record.transactionDate ?? record.receivedAt) ||
        !acceptsSubtype(record.subtype)) {
      return false;
    }
    if (partyPresence == PartyPresence.unidentified && record.party != null) {
      return false;
    }
    if (partyPresence == PartyPresence.identified && record.party == null) {
      return false;
    }
    final unresolved =
        const FinancialSemantics().classify(record) == MovementClass.unresolved;
    if (resolution == SemanticResolution.unresolved && !unresolved) {
      return false;
    }
    if (resolution == SemanticResolution.resolved && unresolved) return false;
    if (requiresResolvedSemantics &&
        const FinancialSemantics().classify(record) ==
            MovementClass.unresolved) {
      return false;
    }
    if (party != null &&
        (record.party == null ||
            PartyIdentity.fromParty(record.party!) != party)) {
      return false;
    }
    if (endpoint?.identity != null &&
        (record.party == null ||
            PartyIdentity.fromParty(record.party!) != endpoint!.identity)) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter &&
      period == other.period &&
      scope == other.scope &&
      subtype == other.subtype &&
      party == other.party &&
      partyPresence == other.partyPresence &&
      resolution == other.resolution &&
      direction == other.direction &&
      endpoint == other.endpoint &&
      central == other.central;
  @override
  int get hashCode => Object.hash(
    period,
    scope,
    subtype,
    party,
    partyPresence,
    resolution,
    direction,
    endpoint,
    central,
  );
}
