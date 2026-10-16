import '../core/enums/account_type.dart';
import '../core/enums/record_subtype.dart';
import '../models/financial_records.dart';
import '../services/financial_semantics.dart';
import 'financial_period.dart';
import '../core/constants/instrument_catalogue.dart';
import 'party.dart';
import '../core/enums/party_type.dart';

/// A provider-qualified customer reference. Null reference means absent, not all.
class ActivityProviderFilter {
  final String providerKey;
  final String? reference;
  final bool unspecified;
  const ActivityProviderFilter(
    this.providerKey,
    this.reference, {
    this.unspecified = false,
  });
  bool matches(FinancialRecord record) =>
      record.party != null &&
      InstrumentCatalogue.providerKey(record.party!.name) == providerKey &&
      (record.party!.account == null || record.party!.account!.trim().isEmpty
              ? null
              : PartyIdentity.fromParty(
                  Party(
                    name: '',
                    type: PartyType.business,
                    account: record.party!.account!,
                  ),
                ).value) ==
          reference;
  @override
  bool operator ==(Object other) =>
      other is ActivityProviderFilter &&
      providerKey == other.providerKey &&
      reference == other.reference &&
      unspecified == other.unspecified;
  @override
  int get hashCode => Object.hash(providerKey, reference, unspecified);
}

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

/// SQLite's built-in lower() folds ASCII only. Keep Dart verification identical
/// without changing the separate, Unicode-aware party identity policy.
String activitySearchLower(String value) => String.fromCharCodes(
  value.codeUnits.map((unit) => unit >= 65 && unit <= 90 ? unit + 32 : unit),
);

String normalizeActivitySearch(String value) =>
    activitySearchLower(value.trim());

/// Null on ActivityFilter means all categories; a null ID here means
/// uncategorized, including an explicit manual-uncategorized override.
class ActivityCategoryFilter {
  final String? categoryId;
  const ActivityCategoryFilter.category(String id) : categoryId = id;
  const ActivityCategoryFilter.uncategorized() : categoryId = null;
  @override
  bool operator ==(Object other) =>
      other is ActivityCategoryFilter && categoryId == other.categoryId;
  @override
  int get hashCode => categoryId.hashCode;
}

const _unchanged = Object();

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
  final ActivityCategoryFilter? category;
  final ActivityProviderFilter? provider;
  final String _search;
  String get search => normalizeActivitySearch(_search);

  const ActivityFilter({
    required this.period,
    this.scope = ActivityScope.all,
    this.subtype,
    this.category,
    this.provider,
    this.party,
    this.partyPresence,
    this.resolution,
    this.direction,
    this.endpoint,
    this.central = const AccountEndpoint(AccountType.mpesa),
    String search = '',
  }) : _search = search;

  ActivityFilter copyWith({
    FinancialPeriod? period,
    ActivityScope? scope,
    String? search,
    Object? category = _unchanged,
    Object? subtype = _unchanged,
    Object? partyPresence = _unchanged,
    Object? resolution = _unchanged,
    Object? direction = _unchanged,
    Object? endpoint = _unchanged,
  }) => ActivityFilter(
    period: period ?? this.period,
    scope: scope ?? this.scope,
    search: search ?? this.search,
    category: identical(category, _unchanged)
        ? this.category
        : category as ActivityCategoryFilter?,
    provider: provider,
    subtype: identical(subtype, _unchanged)
        ? this.subtype
        : subtype as RecordSubtype?,
    partyPresence: identical(partyPresence, _unchanged)
        ? this.partyPresence
        : partyPresence as PartyPresence?,
    resolution: identical(resolution, _unchanged)
        ? this.resolution
        : resolution as SemanticResolution?,
    direction: identical(direction, _unchanged)
        ? this.direction
        : direction as TransferDirection?,
    endpoint: identical(endpoint, _unchanged)
        ? this.endpoint
        : endpoint as AccountEndpoint?,
    party: party,
    central: central,
  );

  ActivityFilter withPeriod(FinancialPeriod period) => copyWith(period: period);
  ActivityFilter withScope(ActivityScope scope) => copyWith(scope: scope);
  ActivityFilter withSearch(String value) => copyWith(search: value);
  ActivityFilter withCategory(ActivityCategoryFilter? value) =>
      copyWith(category: value);

  /// Used by both SQL query construction and in-memory verification.
  bool acceptsSubtype(RecordSubtype candidate) {
    if (provider?.unspecified == true &&
        candidate != RecordSubtype.instrumentPayment &&
        candidate != RecordSubtype.instrumentReceipt) {
      return false;
    }
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

  /// Category membership is resolved in SQL, not on a FinancialRecord.
  /// Callers verifying identity candidates must retain the SQL category predicate.
  bool matches(FinancialRecord record) {
    if (provider != null && !provider!.matches(record)) return false;
    if (search.isNotEmpty &&
        ![
          record.party?.name,
          record.title,
          record.reference,
          record.party?.phone,
          record.party?.account,
          record.party?.identifier,
        ].any(
          (value) =>
              value != null && activitySearchLower(value).contains(search),
        )) {
      return false;
    }
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
      central == other.central &&
      search == other.search &&
      category == other.category &&
      provider == other.provider;
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
    search,
    category,
    provider,
  );
}
