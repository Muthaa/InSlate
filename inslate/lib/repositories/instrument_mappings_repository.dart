import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/constants/instrument_catalogue.dart';
import '../core/enums/record_subtype.dart';
import '../core/enums/financial_record_type.dart';
import '../core/enums/party_type.dart';
import '../models/party.dart';
import '../services/financial_semantics.dart';

enum InstrumentPurpose { investment, savings, loan, unknown }

class InstrumentMapping {
  final int id, accountId;
  final String provider, reference;
  final InstrumentPurpose purpose;
  const InstrumentMapping(
    this.id,
    this.accountId,
    this.provider,
    this.reference,
    this.purpose,
  );
}

class DetectedReferenceReview {
  final String provider, reference;
  final int detected, eligible, conflicts;
  final int? mappedAccountId;
  const DetectedReferenceReview(
    this.provider,
    this.reference,
    this.detected,
    this.eligible,
    this.conflicts,
    this.mappedAccountId,
  );
}

class MappingPreviewTransaction {
  final int id;
  final double amount;
  final DateTime asOf;
  final bool incoming;
  final String treatment;
  const MappingPreviewTransaction(
    this.id,
    this.amount,
    this.asOf,
    this.incoming,
    this.treatment,
  );
}

class MappingResult {
  final int matching, linked, interpreted, conflicts, protected;
  const MappingResult(
    this.matching,
    this.linked,
    this.interpreted,
    this.conflicts,
    this.protected,
  );
}

/// Exact user-confirmed provider + customer-reference mappings. No fuzzy ownership.
class InstrumentMappingsRepository {
  final AppDatabase database;
  InstrumentMappingsRepository(this.database);

  static String referenceKey(String reference) => PartyIdentity.fromParty(
    Party(name: '', type: PartyType.business, account: reference),
  ).value;

  Future<List<InstrumentMapping>> list(int accountId) async {
    final rows = await database
        .customSelect(
          'SELECT * FROM instrument_mappings WHERE account_id = ? ORDER BY id',
          variables: [Variable(accountId)],
        )
        .get();
    return rows.map(_mapping).toList();
  }

  InstrumentMapping _mapping(QueryRow r) => InstrumentMapping(
    r.read<int>('id'),
    r.read<int>('account_id'),
    r.read<String>('provider_key'),
    r.read<String>('account_reference'),
    InstrumentPurpose.values.byName(r.read<String>('purpose')),
  );

  /// SQL aggregation only; no message bodies or full history loaded.
  Future<List<({String provider, String reference, int count})>>
  detectedReferences({int limit = 50, int offset = 0, String? provider}) async {
    if (limit < 1 || limit > 100 || offset < 0) {
      throw ArgumentError('Invalid page.');
    }
    final providerExpression = providerKeySql('party_name');
    final condition = provider == null ? '' : ' AND $providerExpression = ?';
    final rows = await database
        .customSelect(
          """SELECT MIN(party_name) AS party_name, MIN(party_account) AS party_account, COUNT(*) AS n FROM financial_records
      WHERE party_name IS NOT NULL AND party_account IS NOT NULL AND trim(party_account) != '' AND status = 'successful' $condition
      GROUP BY $providerExpression, lower(trim(party_account))
      ORDER BY n DESC, party_name, party_account LIMIT ? OFFSET ?""",
          variables: [
            if (provider != null)
              Variable(InstrumentCatalogue.providerKey(provider)),
            Variable(limit),
            Variable(offset),
          ],
        )
        .get();
    return rows
        .map(
          (r) => (
            provider: r.read<String>('party_name'),
            reference: r.read<String>('party_account'),
            count: r.read<int>('n'),
          ),
        )
        .toList();
  }

  /// Evaluate a bounded discovery page in one traversal, not one query per reference.
  Future<List<DetectedReferenceReview>> referenceReviewPage({
    required int accountId,
    String? provider,
    int offset = 0,
  }) async {
    final references = await detectedReferences(
      provider: provider,
      offset: offset,
    );
    if (references.isEmpty) return [];
    final providers = references
        .map((r) => InstrumentCatalogue.providerKey(r.provider))
        .toSet()
        .toList();
    final keys = references
        .map((r) => referenceKey(r.reference))
        .toSet()
        .toList();
    final saved =
        (await database
                .customSelect(
                  'SELECT * FROM instrument_mappings WHERE provider_key IN (${List.filled(providers.length, '?').join(',')}) AND account_reference IN (${List.filled(keys.length, '?').join(',')})',
                  variables: [
                    ...providers.map(Variable.new),
                    ...keys.map(Variable.new),
                  ],
                )
                .get())
            .map(_mapping)
            .toList();
    final existing = {for (final m in saved) (m.provider, m.reference): m};
    final candidates = {
      for (final r in references)
        (
          InstrumentCatalogue.providerKey(r.provider),
          referenceKey(r.reference),
        ),
    };
    final counts = <(String, String), int>{},
        conflicts = <(String, String), int>{};
    await _apply(
      [
        for (final key in candidates)
          InstrumentMapping(
            existing[key]?.accountId == accountId ? existing[key]!.id : -1,
            accountId,
            key.$1,
            key.$2,
            InstrumentPurpose.unknown,
          ),
      ],
      persist: false,
      onDecision: (mapping, eligible) {
        final key = (mapping.provider, mapping.reference);
        final target = eligible ? counts : conflicts;
        target[key] = (target[key] ?? 0) + 1;
      },
    );
    return [
      for (final r in references)
        DetectedReferenceReview(
          r.provider,
          r.reference,
          r.count,
          counts[(
                InstrumentCatalogue.providerKey(r.provider),
                referenceKey(r.reference),
              )] ??
              0,
          conflicts[(
                InstrumentCatalogue.providerKey(r.provider),
                referenceKey(r.reference),
              )] ??
              0,
          existing[(
                InstrumentCatalogue.providerKey(r.provider),
                referenceKey(r.reference),
              )]
              ?.accountId,
        ),
    ];
  }

  static String normalizedNameSql(String column) {
    var expression = "lower(trim($column))";
    for (var i = 0; i < 8; i++) {
      expression = "replace($expression, '  ', ' ')";
    }
    return expression;
  }

  /// Discovery grouping only; the mapping engine still verifies shared Dart identity.
  static String providerKeySql(String column) {
    final normalized = normalizedNameSql(column);
    String quote(String value) => "'${value.replaceAll("'", "''")}'";
    final cases = InstrumentCatalogue.providers
        .map(
          (provider) =>
              'WHEN $normalized IN (${[provider.name, ...provider.aliases].map((name) => quote(InstrumentCatalogue.normalizeName(name))).join(',')}) THEN ${quote(provider.id)}',
        )
        .join(' ');
    return 'CASE $cases ELSE $normalized END';
  }

  /// One consistent, read-only traversal for counts and bounded preview rows.
  Future<
    ({MappingResult summary, List<MappingPreviewTransaction> transactions})
  >
  previewPage({
    required int accountId,
    required String provider,
    required String reference,
    required InstrumentPurpose purpose,
    int offset = 0,
    int limit = 20,
  }) => database.transaction(() async {
    if (offset < 0 || limit < 1 || limit > 50) {
      throw ArgumentError('Invalid page.');
    }
    await _validate(accountId, provider, reference);
    final transactions = <MappingPreviewTransaction>[];
    var seen = 0;
    final summary = await _apply(
      [
        InstrumentMapping(
          -1,
          accountId,
          InstrumentCatalogue.providerKey(provider),
          referenceKey(reference),
          purpose,
        ),
      ],
      persist: false,
      onPreview: (row) {
        if (seen++ >= offset && transactions.length < limit) {
          transactions.add(row);
        }
      },
    );
    return (summary: summary, transactions: transactions);
  });

  Future<List<MappingPreviewTransaction>> previewTransactions({
    required int accountId,
    required String provider,
    required String reference,
    required InstrumentPurpose purpose,
    int offset = 0,
    int limit = 20,
  }) async => (await previewPage(
    accountId: accountId,
    provider: provider,
    reference: reference,
    purpose: purpose,
    offset: offset,
    limit: limit,
  )).transactions;

  Future<MappingResult> preview({
    required int accountId,
    required String provider,
    required String reference,
    required InstrumentPurpose purpose,
  }) async {
    await _validate(accountId, provider, reference);
    return _apply([
      InstrumentMapping(
        -1,
        accountId,
        InstrumentCatalogue.providerKey(provider),
        referenceKey(reference),
        purpose,
      ),
    ], persist: false);
  }

  Future<MappingResult> confirm({
    required int accountId,
    required String provider,
    required String reference,
    required InstrumentPurpose purpose,
  }) => database.transaction(() async {
    await _validate(accountId, provider, reference);
    final key = InstrumentCatalogue.providerKey(provider),
        ref = referenceKey(reference);
    final existing = await database
        .customSelect(
          'SELECT id FROM instrument_mappings WHERE provider_key = ? AND account_reference = ?',
          variables: [Variable(key), Variable(ref)],
        )
        .get();
    if (existing.isNotEmpty) {
      throw StateError(
        'This reference already has a mapping. Remove it explicitly before replacing it.',
      );
    }
    await database.customStatement(
      'INSERT INTO instrument_mappings(account_id,provider_key,account_reference,purpose,created_at) VALUES(?,?,?,?,?)',
      [
        accountId,
        key,
        ref,
        purpose.name,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    final id =
        (await database
                .customSelect('SELECT last_insert_rowid() AS id')
                .getSingle())
            .read<int>('id');
    return _apply([
      InstrumentMapping(id, accountId, key, ref, purpose),
    ], persist: true);
  });

  Future<void> _validate(
    int accountId,
    String provider,
    String reference,
  ) async {
    if (provider.trim().isEmpty ||
        reference.trim().isEmpty ||
        provider.length > 200 ||
        reference.length > 100) {
      throw ArgumentError(
        'Enter a provider and an exact customer account reference.',
      );
    }
    final account = await (database.select(
      database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();
    if (account == null || !account.isUserRegistered || !account.isActive) {
      throw ArgumentError('Choose an active registered instrument.');
    }
  }

  Future<void> remove(
    int id,
    int expectedAccountId,
  ) => database.transaction(() async {
    final rows = await database
        .customSelect(
          'SELECT account_id FROM instrument_mappings WHERE id = ?',
          variables: [Variable(id)],
        )
        .get();
    if (rows.isEmpty ||
        rows.single.read<int>('account_id') != expectedAccountId) {
      throw StateError('Mapping changed. Refresh and try again.');
    }
    await (database.update(
      database.financialRecords,
    )..where((r) => r.interpretationMappingId.equals(id))).write(
      const FinancialRecordsCompanion(
        interpretedType: Value(null),
        interpretedSubtype: Value(null),
        interpretationMappingId: Value(null),
      ),
    );
    await database.customStatement(
      'DELETE FROM instrument_mappings WHERE id = ?',
      [id],
    );
    // Historical numeric links remain; unlinking is an explicit independent action.
  });

  /// Run after normalized records persist, within the caller's transaction.
  Future<MappingResult> applyNew({
    required int afterId,
  }) => database.transaction(() async {
    final rows = await database
        .customSelect(
          'SELECT m.* FROM instrument_mappings m JOIN accounts a ON a.id = m.account_id WHERE a.is_user_registered = 1 AND a.is_active = 1',
        )
        .get();
    return _apply(
      rows.map(_mapping).toList(),
      persist: true,
      afterId: afterId,
      recognize: true,
    );
  });

  static bool? incoming(String subtype) =>
      switch (RecordSubtype.values.byName(subtype)) {
        RecordSubtype.payBill ||
        RecordSubtype.investmentPurchase ||
        RecordSubtype.mshwariDeposit ||
        RecordSubtype.kcbDeposit ||
        RecordSubtype.savingsDeposit ||
        RecordSubtype.loanRepayment ||
        RecordSubtype.fulizaRepayment => false,
        RecordSubtype.receiveMoney ||
        RecordSubtype.investmentRedemption ||
        RecordSubtype.mshwariWithdrawal ||
        RecordSubtype.kcbWithdrawal ||
        RecordSubtype.savingsWithdrawal ||
        RecordSubtype.loanDisbursement ||
        RecordSubtype.fulizaLoan ||
        RecordSubtype.payBillReversal => true,
        _ => null,
      };

  Future<MappingResult> _apply(
    List<InstrumentMapping> mappings, {
    required bool persist,
    int afterId = 0,
    bool recognize = false,
    void Function(MappingPreviewTransaction)? onPreview,
    void Function(InstrumentMapping, bool)? onDecision,
  }) async {
    if (mappings.isEmpty && !recognize) {
      return const MappingResult(0, 0, 0, 0, 0);
    }
    var cursor = afterId,
        matching = 0,
        linked = 0,
        interpreted = 0,
        conflicts = 0,
        protected = 0;
    while (true) {
      final batch =
          await (database.select(database.financialRecords)
                ..where(
                  (r) =>
                      r.id.isBiggerThanValue(cursor) & r.partyName.isNotNull(),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.id)])
                ..limit(100))
              .get();
      if (batch.isEmpty) break;
      final reversals = await (database.select(
        database.financialRecords,
      )..where((r) => r.reversesRecordId.isIn(batch.map((r) => r.id)))).get();
      final reversed = reversals.map((r) => r.reversesRecordId).toSet();
      for (final row in batch) {
        cursor = row.id;
        if (row.status != 'successful') continue;
        final direction = incoming(row.subtype);
        if (direction == null) continue;
        final candidates = mappings
            .where(
              (m) =>
                  m.provider ==
                      InstrumentCatalogue.providerKey(row.partyName!) &&
                  row.partyAccount != null &&
                  m.reference == referenceKey(row.partyAccount!),
            )
            .toList();
        final providerKey = InstrumentCatalogue.providerKey(row.partyName!);
        final recognized =
            recognize &&
            candidates.isEmpty &&
            (row.subtype == 'payBill' || row.subtype == 'receiveMoney') &&
            InstrumentCatalogue.providers.any((p) => p.id == providerKey);
        if (candidates.length != 1 && !recognized) continue;
        final mapping = recognized
            ? InstrumentMapping(
                -1,
                0,
                providerKey,
                '',
                InstrumentPurpose.unknown,
              )
            : candidates.single;
        matching++;
        final current = direction
            ? row.sourceAccountId
            : row.destinationAccountId;
        if ((current != null && current != mapping.accountId) ||
            (row.interpretationMappingId != null &&
                row.interpretationMappingId != mapping.id)) {
          conflicts++;
          onDecision?.call(mapping, false);
          onPreview?.call(
            MappingPreviewTransaction(
              row.id,
              row.amount,
              row.transactionDate ?? row.receivedAt,
              direction,
              'Conflict - review individually; unchanged',
            ),
          );
          continue;
        }
        final explicitLoan =
            FinancialSemantics.forSubtype(
                  RecordSubtype.values.byName(row.subtype),
                ).movement ==
                MovementClass.loanRepayment ||
            FinancialSemantics.forSubtype(
                  RecordSubtype.values.byName(row.subtype),
                ).movement ==
                MovementClass.loanBorrowing;
        final protect =
            row.reversesRecordId != null ||
            reversed.contains(row.id) ||
            explicitLoan;
        if (protect) protected++;
        final subtype = switch (mapping.purpose) {
          InstrumentPurpose.investment =>
            direction
                ? RecordSubtype.investmentRedemption
                : RecordSubtype.investmentPurchase,
          InstrumentPurpose.savings =>
            direction
                ? RecordSubtype.registeredSavingsWithdrawal
                : RecordSubtype.registeredSavingsDeposit,
          InstrumentPurpose.loan =>
            direction
                ? RecordSubtype.loanDisbursement
                : RecordSubtype.loanRepayment,
          InstrumentPurpose.unknown =>
            direction
                ? RecordSubtype.instrumentReceipt
                : RecordSubtype.instrumentPayment,
        };
        onDecision?.call(mapping, true);
        onPreview?.call(
          MappingPreviewTransaction(
            row.id,
            row.amount,
            row.transactionDate ?? row.receivedAt,
            direction,
            protect
                ? 'Protected - original treatment retained'
                : switch (mapping.purpose) {
                    InstrumentPurpose.investment =>
                      direction
                          ? 'Investment redemption'
                          : 'Investment purchase',
                    InstrumentPurpose.savings =>
                      direction ? 'Savings withdrawal' : 'Savings deposit',
                    InstrumentPurpose.loan =>
                      direction ? 'Loan received' : 'Loan repayment',
                    InstrumentPurpose.unknown =>
                      direction
                          ? 'Payment in - purpose not sure'
                          : 'Payment out - purpose not sure',
                  },
          ),
        );
        if (current == null && !recognized) linked++;
        final interpretedType = mapping.purpose == InstrumentPurpose.loan
            ? FinancialRecordType.loan.name
            : FinancialRecordType.transfer.name;
        final changed =
            !protect &&
            (row.interpretedType != interpretedType ||
                row.interpretedSubtype != subtype.name ||
                (!recognized && row.interpretationMappingId != mapping.id));
        if (changed) interpreted++;
        if (persist && ((current == null && !recognized) || changed)) {
          await (database.update(
            database.financialRecords,
          )..where((r) => r.id.equals(row.id))).write(
            FinancialRecordsCompanion(
              sourceAccountId: direction && current == null && !recognized
                  ? Value(mapping.accountId)
                  : const Value.absent(),
              destinationAccountId: !direction && current == null && !recognized
                  ? Value(mapping.accountId)
                  : const Value.absent(),
              interpretedType: !protect
                  ? Value(
                      mapping.purpose == InstrumentPurpose.loan
                          ? FinancialRecordType.loan.name
                          : FinancialRecordType.transfer.name,
                    )
                  : const Value.absent(),
              interpretedSubtype: !protect
                  ? Value(subtype.name)
                  : const Value.absent(),
              interpretationMappingId: !protect && !recognized
                  ? Value(mapping.id)
                  : const Value.absent(),
            ),
          );
        }
      }
    }
    return MappingResult(matching, linked, interpreted, conflicts, protected);
  }
}
