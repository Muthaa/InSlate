import '../database/app_database.dart';
import '../core/enums/account_type.dart';
import '../core/enums/record_subtype.dart';
import '../core/enums/party_type.dart';
import '../models/activity_filter.dart';
import '../models/financial_instrument.dart';
import '../models/financial_period.dart';
import '../models/party.dart';
import '../core/constants/instrument_catalogue.dart';
import 'instrument_mappings_repository.dart';
import '../services/financial_semantics.dart';

/// Recognition from persisted movement metadata, never an ownership registry.
class DetectedProvider {
  final String name;
  final AccountEndpoint endpoint;
  final InstrumentType suggestedType;
  final int count;
  final bool unspecified;
  final RecordSubtype? reviewSubtype;
  final ActivityProviderFilter? providerReference;
  const DetectedProvider(
    this.name,
    this.endpoint,
    this.suggestedType,
    this.count, {
    this.unspecified = false,
    this.reviewSubtype,
    this.providerReference,
  });

  ActivityFilter get filter {
    return ActivityFilter(
      period: FinancialPeriod.allTime(),
      subtype: reviewSubtype,
      scope: unspecified || reviewSubtype != null
          ? ActivityScope.all
          : ActivityScope.investmentsAndSavings,
      endpoint: unspecified || reviewSubtype != null
          ? null
          : providerReference == null
          ? endpoint
          : AccountEndpoint(endpoint.type),
      provider: providerReference,
      partyPresence: providerReference == null
          ? PartyPresence.unidentified
          : null,
      party: providerReference != null && providerReference!.reference == null
          ? endpoint.identity
          : null,
    );
  }
}

class DetectedProvidersRepository {
  final AppDatabase database;
  DetectedProvidersRepository(this.database);

  Stream<List<DetectedProvider>> watch({int? page}) {
    if (page != null && page < 0) throw ArgumentError('Invalid page.');
    String quote(String name) => "'${name.replaceAll("'", "''")}'";
    final providerExpression = InstrumentMappingsRepository.providerKeySql(
      'party_name',
    );
    final fallbackSavings = InstrumentCatalogue.providerKey('M-Shwari');
    final fallbackKcb = InstrumentCatalogue.providerKey('KCB M-PESA');
    final canonical =
        "CASE WHEN (party_name IS NULL OR trim(party_name) = '') AND COALESCE(interpreted_subtype, subtype) LIKE 'mshwari%' THEN ${quote(fallbackSavings)} WHEN (party_name IS NULL OR trim(party_name) = '') AND COALESCE(interpreted_subtype, subtype) LIKE 'kcb%' THEN ${quote(fallbackKcb)} ELSE $providerExpression END";
    final existingPopulation =
        "COALESCE(interpreted_type, type) = 'transfer' AND COALESCE(interpreted_subtype, subtype) IN ('investmentPurchase', 'investmentRedemption', 'mshwariDeposit', 'mshwariWithdrawal', 'kcbDeposit', 'kcbWithdrawal', 'registeredSavingsDeposit', 'registeredSavingsWithdrawal', 'instrumentPayment', 'instrumentReceipt') AND ((party_name IS NOT NULL AND trim(party_name) != '') OR COALESCE(interpreted_subtype, subtype) LIKE 'mshwari%' OR COALESCE(interpreted_subtype, subtype) LIKE 'kcb%')";
    final catalogueKeys = InstrumentCatalogue.providers
        .map((p) => quote(p.id))
        .join(',');
    final reviewPopulation =
        "status = 'successful' AND COALESCE(interpreted_subtype, subtype) IN ('payBill', 'receiveMoney', 'loanRepayment', 'loanDisbursement', 'fulizaLoan', 'fulizaRepayment') AND $canonical IN ($catalogueKeys)";
    final population = '($existingPopulation) OR ($reviewPopulation)';
    final paging = page == null
        ? ''
        : " AND $canonical IN (SELECT $canonical FROM financial_records WHERE $population GROUP BY $canonical ORDER BY $canonical LIMIT 21 OFFSET ${page * 20})";
    return database
        .customSelect(
          '''SELECT COALESCE(interpreted_subtype, subtype) AS subtype, party_name, party_type, party_phone, party_account,
       party_identifier, COUNT(*) AS record_count
       FROM financial_records
       WHERE ($population) $paging
       GROUP BY subtype, party_name, party_type, party_phone, party_account, party_identifier
       ORDER BY party_name, subtype''',
          readsFrom: {database.financialRecords},
        )
        .watch()
        .map((rows) {
          final groups =
              <
                (
                  AccountType,
                  bool,
                  RecordSubtype?,
                  ActivityProviderFilter?,
                  PartyIdentity?,
                ),
                DetectedProvider
              >{};
          for (final row in rows) {
            final subtype = row.read<String>('subtype');
            final investment = subtype.startsWith('investment');
            final registeredSavings = subtype.startsWith('registeredSavings');
            final unspecified =
                subtype == 'instrumentPayment' ||
                subtype == 'instrumentReceipt';
            final reviewSubtype =
                !investment &&
                    !registeredSavings &&
                    !unspecified &&
                    !subtype.startsWith('mshwari') &&
                    !subtype.startsWith('kcb')
                ? RecordSubtype.values.byName(subtype)
                : null;
            final name = row.readNullable<String>('party_name')?.trim();
            // Unidentified investment movements do not establish a provider.
            if ((investment ||
                    registeredSavings ||
                    unspecified ||
                    reviewSubtype != null) &&
                (name == null || name.isEmpty)) {
              continue;
            }
            final family = investment
                ? AccountType.investment
                : registeredSavings || unspecified || reviewSubtype != null
                ? AccountType.unknown
                : subtype.startsWith('mshwari')
                ? AccountType.mshwariSavings
                : AccountType.kcbMpesa;
            final endpoint = AccountEndpoint(
              family,
              identity:
                  investment ||
                      registeredSavings ||
                      unspecified ||
                      reviewSubtype != null
                  ? PartyIdentity.fromParty(
                      Party(
                        name: name!,
                        type: PartyType.values.firstWhere(
                          (t) =>
                              t.name == row.readNullable<String>('party_type'),
                          orElse: () => PartyType.unknown,
                        ),
                        phone: row.readNullable<String>('party_phone'),
                        account: row.readNullable<String>('party_account'),
                        identifier: row.readNullable<String>(
                          'party_identifier',
                        ),
                      ),
                    )
                  : null,
            );
            final rawReference = row.readNullable<String>('party_account');
            final providerReference = name == null || name.isEmpty
                ? null
                : ActivityProviderFilter(
                    InstrumentCatalogue.providerKey(name),
                    rawReference == null || rawReference.trim().isEmpty
                        ? null
                        : InstrumentMappingsRepository.referenceKey(
                            rawReference,
                          ),
                    unspecified: unspecified,
                  );
            final key = (
              family,
              unspecified,
              reviewSubtype,
              providerReference,
              providerReference?.reference == null ? endpoint.identity : null,
            );
            final previous = groups[key];
            groups[key] = DetectedProvider(
              previous?.name ??
                  (investment ||
                          registeredSavings ||
                          unspecified ||
                          reviewSubtype != null
                      ? name!
                      : family == AccountType.mshwariSavings
                      ? 'M-Shwari'
                      : 'KCB M-PESA'),
              endpoint,
              unspecified || reviewSubtype != null
                  ? InstrumentType.other
                  : investment
                  ? InstrumentType.investmentAccount
                  : InstrumentType.savingsProduct,
              (previous?.count ?? 0) + row.read<int>('record_count'),
              unspecified: unspecified,
              reviewSubtype: reviewSubtype,
              providerReference: providerReference,
            );
          }
          return groups.values.toList()..sort((a, b) {
            final count = b.count.compareTo(a.count);
            return count != 0 ? count : a.name.compareTo(b.name);
          });
        });
  }
}
