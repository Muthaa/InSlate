import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/raw_message.dart' as domain;
import '../models/balance_observation.dart';
import '../services/paybill_reversal_parser.dart';

class ReversalResult {
  final String sourceId, outcome;
  final int? recordId;
  final int evidenceCreated;
  const ReversalResult(
    this.sourceId,
    this.outcome, {
    this.recordId,
    this.evidenceCreated = 0,
  });
  bool get imported => outcome == 'REVERSAL_PERSISTED';
  bool get duplicate => outcome == 'EXISTING_REVERSAL';
}

/// Only explicit credit confirmations and exact, unique successful PayBills.
/// Every read/write is in the same transaction as RawMessage persistence.
class PayBillReversalsRepository {
  final AppDatabase database;
  PayBillReversalsRepository(this.database);

  /// Bounded review; never a financial-record reimport or an unbounded history read.
  Future<List<String>> retainedConfirmationIds({int limit = 6}) async {
    if (limit < 1 || limit > 100) throw ArgumentError('Invalid review bound.');
    final rows = await database
        .customSelect(
          "SELECT source_id FROM raw_messages WHERE upper(trim(sender)) = 'MPESA' AND lower(body) LIKE '%reversal of transaction%' ORDER BY id LIMIT ?",
          variables: [Variable(limit)],
          readsFrom: {database.rawMessages},
        )
        .get();
    return rows.map((r) => r.read<String>('source_id')).toList();
  }

  /// A caller must supply the reviewed source identities; no implicit backfill.
  Future<List<ReversalResult>> process(
    List<String> sourceIds, {
    bool requireAllSupported = false,
  }) => database.transaction(() async {
    final ids = sourceIds.toSet().toList();
    if (ids.length > 500) {
      throw ArgumentError('At most 500 sources per operation.');
    }
    if (ids.isEmpty) return [];
    final raw = await (database.select(
      database.rawMessages,
    )..where((r) => r.sourceId.isIn(ids))).get();
    if (raw.length != ids.length) {
      throw ArgumentError('Source message no longer exists.');
    }
    final parser = PayBillReversalParser();
    final claims = {
      for (final r in raw)
        r.sourceId: parser.parse(
          domain.RawMessage(
            id: r.sourceId,
            sender: r.sender,
            body: r.body,
            receivedAt: r.receivedAt,
          ),
        ),
    };
    final references = claims.values
        .whereType<PayBillReversalClaim>()
        .expand((c) => [c.originalReference, c.reference])
        .toSet();
    final originals = await (database.select(
      database.financialRecords,
    )..where((f) => f.reference.isIn(references))).get();
    final reversals =
        await (database.select(database.financialRecords)..where(
              (f) =>
                  f.reversesRecordId.isIn(originals.map((f) => f.id)) |
                  f.sourceMessageId.isIn(ids),
            ))
            .get();
    final results = <ReversalResult>[];
    final usedOriginals = reversals
        .where((r) => r.reversesRecordId != null)
        .map((r) => r.reversesRecordId)
        .toSet();
    final usedReferences = <String>{};
    for (final r in raw) {
      final claim = claims[r.sourceId];
      String? rejection;
      final matches = claim == null
          ? <FinancialRecord>[]
          : originals
                .where(
                  (f) =>
                      f.reference == claim.originalReference &&
                      f.type == 'expense' &&
                      f.subtype == 'payBill' &&
                      f.status == 'successful',
                )
                .toList();
      final existing = reversals
          .where((f) => f.sourceMessageId == r.sourceId)
          .toList();
      if (claim == null) {
        rejection = 'UNSUPPORTED_REVERSAL';
      } else if (existing.isNotEmpty) {
        final valid =
            existing.length == 1 &&
            matches.length == 1 &&
            existing.single.type == 'reversal' &&
            existing.single.subtype == 'payBillReversal' &&
            existing.single.reversesRecordId == matches.single.id &&
            existing.single.reference == claim.reference &&
            existing.single.amount == claim.principalMinor / 100 &&
            existing.single.transactionCost == 0 &&
            existing.single.transactionDate == claim.declaredAt &&
            existing.single.rawMessage == r.body;
        rejection = valid ? 'EXISTING_REVERSAL' : 'REVERSAL_SOURCE_CONFLICT';
      } else if (matches.length != 1) {
        rejection = 'REVERSAL_ORIGINAL_NOT_UNIQUE';
      } else {
        final original = matches.single;
        int? originalMinor;
        try {
          originalMinor = SnapshotMoney.parse(
            original.amount.toString(),
            'KES',
          );
        } on ArgumentError {
          /* exact cents unavailable */
        }
        if (originalMinor != claim.principalMinor) {
          rejection = 'REVERSAL_PRINCIPAL_MISMATCH';
        } else if (original.transactionDate == null ||
            !claim.declaredAt.isAfter(original.transactionDate!)) {
          rejection = 'REVERSAL_INVALID_CHRONOLOGY';
        } else if (usedOriginals.contains(original.id)) {
          rejection = 'REVERSAL_ALREADY_REVERSED';
        } else if (originals.any((f) => f.reference == claim.reference) ||
            usedReferences.contains(claim.reference)) {
          rejection = 'REVERSAL_REFERENCE_CONFLICT';
        }
      }
      if (rejection != null) {
        if (requireAllSupported && rejection != 'EXISTING_REVERSAL') {
          throw StateError(rejection);
        }
        results.add(
          ReversalResult(
            r.sourceId,
            rejection,
            recordId: existing.length == 1 ? existing.single.id : null,
          ),
        );
        continue;
      }
      final original = matches.single;
      // A newly verified reversal protects its original from mapped interpretation.
      await (database.update(
        database.financialRecords,
      )..where((f) => f.id.equals(original.id))).write(
        const FinancialRecordsCompanion(
          interpretedType: Value(null),
          interpretedSubtype: Value(null),
          interpretationMappingId: Value(null),
        ),
      );
      final c = claim!;
      final recordId = await database
          .into(database.financialRecords)
          .insert(
            FinancialRecordsCompanion.insert(
              reference: c.reference,
              sourceMessageId: Value(r.sourceId),
              reversesRecordId: Value(original.id),
              transactionDate: Value(c.declaredAt),
              receivedAt: r.receivedAt,
              amount: c.principalMinor / 100,
              type: 'reversal',
              subtype: 'payBillReversal',
              status: 'successful',
              title: 'PayBill reversal',
              rawMessage: r.body,
              transactionCost: const Value(0),
              // Balance evidence is separate; neither instrument links nor ownership are copied.
              partyName: Value(original.partyName),
              partyType: Value(original.partyType),
              partyPhone: Value(original.partyPhone),
              partyAccount: Value(original.partyAccount),
              partyIdentifier: Value(original.partyIdentifier),
            ),
          );
      await database
          .into(database.balanceEvidence)
          .insert(
            BalanceEvidenceCompanion.insert(
              id: 'sms:mpesa-wallet:${r.sourceId}',
              amountMinor: c.walletMinor,
              currency: 'KES',
              kind: 'reported',
              subjectFamily: const Value('mpesa'),
              origin: 'sms_reported',
              asOfMillis: c.declaredAt.millisecondsSinceEpoch,
              timeBasis: 'sms_declared_minute',
              createdMillis: DateTime.now().millisecondsSinceEpoch,
              rawMessageId: Value(r.id),
              financialRecordId: Value(recordId),
              matchedClause: Value(c.walletClause),
              extractionVersion: const Value(PayBillReversalParser.version),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // SQLite insertOrIgnore's rowid is not a reliable creation counter.
      final changes = await database
          .customSelect('SELECT changes() AS n')
          .getSingle();
      usedOriginals.add(original.id);
      usedReferences.add(c.reference);
      results.add(
        ReversalResult(
          r.sourceId,
          'REVERSAL_PERSISTED',
          recordId: recordId,
          evidenceCreated: changes.read<int>('n'),
        ),
      );
    }
    return results;
  });
}
