import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../core/enums/account_type.dart';
import '../models/balance_observation.dart';
import '../models/historical_balance_extraction.dart';
import '../models/raw_message.dart' as domain;
import 'financial_instruments_repository.dart';
import '../services/mpesa_balance_evidence_extractor.dart';
import '../services/mpesa_provider_balance_extractor.dart';

class BalanceEvidenceRepository {
  final AppDatabase database;
  BalanceEvidenceRepository(this.database);

  /// Only the caller's newly accepted source IDs are examined: no history scan.
  /// The source namespace intentionally excludes extractor version, so a future
  /// version cannot silently create a second observation for the same SMS and subject.
  Future<void> extractNewMpesaMessages(List<String> sourceIds) =>
      database.transaction(() async {
        final ids = sourceIds.toSet().toList();
        for (var start = 0; start < ids.length; start += 500) {
          final rows = await (database.select(
            database.rawMessages,
          )..where((m) => m.sourceId.isIn(ids.skip(start).take(500)))).get();
          await database.batch((batch) {
            for (final row in rows) {
              for (final observation in _observations(row)) {
                batch.insert(
                  database.balanceEvidence,
                  observation,
                  mode: InsertMode.insertOrIgnore,
                );
              }
            }
          });
        }
      });

  List<BalanceEvidenceCompanion> _observations(RawMessage row) {
    final message = domain.RawMessage(
      id: row.sourceId,
      sender: row.sender,
      body: row.body,
      receivedAt: row.receivedAt,
    );
    final evidence = MpesaBalanceEvidenceExtractor().extract(message);
    final observations = <BalanceEvidenceCompanion>[];
    if (evidence != null) {
      observations.add(
        BalanceEvidenceCompanion.insert(
          id: 'sms:mpesa-wallet:${row.sourceId}',
          amountMinor: evidence.amountMinor,
          currency: 'KES',
          kind: BalanceKind.reported.value,
          subjectFamily: const Value('mpesa'),
          origin: 'sms_reported',
          asOfMillis: evidence.asOf.millisecondsSinceEpoch,
          timeBasis: MpesaBalanceEvidenceExtractor.timeBasis,
          createdMillis: DateTime.now().millisecondsSinceEpoch,
          rawMessageId: Value(row.id),
          matchedClause: Value(evidence.matchedClause),
          extractionVersion: const Value(MpesaBalanceEvidenceExtractor.version),
        ),
      );
    }
    for (final product in MpesaProviderBalanceExtractor().extract(message)) {
      observations.add(
        BalanceEvidenceCompanion.insert(
          id: 'sms:${product.subjectKey}:${row.sourceId}',
          amountMinor: product.amountMinor,
          currency: 'KES',
          kind: product.kind.value,
          subjectFamily: Value(product.subjectFamily.name),
          origin: 'sms_reported',
          asOfMillis: row.receivedAt.millisecondsSinceEpoch,
          timeBasis: MpesaBalanceEvidenceExtractor.timeBasis,
          createdMillis: DateTime.now().millisecondsSinceEpoch,
          rawMessageId: Value(row.id),
          matchedClause: Value(product.matchedClause),
          extractionVersion: const Value(MpesaProviderBalanceExtractor.version),
        ),
      );
    }
    return observations;
  }

  Future<HistoricalBalanceCheckpoint> beginHistoricalExtraction() async {
    final t = database.rawMessages;
    final maximum = t.id.max();
    final through =
        (await (database.selectOnly(
          t,
        )..addColumns([maximum])).getSingle()).read(maximum) ??
        0;
    return HistoricalBalanceCheckpoint(
      throughId: through,
      complete: through == 0,
    );
  }

  /// One atomic page: no financial-record import, OFFSET or complete history read.
  Future<HistoricalBalanceCheckpoint> historicalExtractionBatch(
    HistoricalBalanceCheckpoint checkpoint,
  ) => database.transaction(() async {
    if (checkpoint.afterId < 0 || checkpoint.afterId > checkpoint.throughId) {
      throw ArgumentError('Invalid historical extraction checkpoint.');
    }
    if (checkpoint.complete) return checkpoint;
    final rows =
        await (database.select(database.rawMessages)
              ..where(
                (m) =>
                    m.id.isBiggerThanValue(checkpoint.afterId) &
                    m.id.isSmallerOrEqualValue(checkpoint.throughId),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.id)])
              ..limit(200))
            .get();
    final observations = <BalanceEvidenceCompanion>[];
    var unsupported = 0;
    for (final row in rows) {
      final extracted = _observations(row);
      if (extracted.isEmpty) unsupported++;
      observations.addAll(extracted);
    }
    final candidateIds = observations.map((e) => e.id.value).toList();
    Future<int> countCandidates() async {
      var count = 0;
      final t = database.balanceEvidence;
      final countExpr = t.id.count();
      for (var start = 0; start < candidateIds.length; start += 400) {
        count +=
            (await (database.selectOnly(t)
                      ..addColumns([countExpr])
                      ..where(t.id.isIn(candidateIds.skip(start).take(400))))
                    .getSingle())
                .read(countExpr)!;
      }
      return count;
    }

    final before = await countCandidates();
    await database.batch((batch) {
      for (final observation in observations) {
        batch.insert(
          database.balanceEvidence,
          observation,
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    final after = await countCandidates();
    final complete = rows.length < 200 || rows.last.id == checkpoint.throughId;
    return HistoricalBalanceCheckpoint(
      throughId: checkpoint.throughId,
      afterId: complete ? checkpoint.throughId : rows.last.id,
      scanned: checkpoint.scanned + rows.length,
      created: checkpoint.created + after - before,
      existing: checkpoint.existing + before,
      unsupported: checkpoint.unsupported + unsupported,
      complete: complete,
    );
  });

  Future<void> associateSms({
    required String id,
    required int? expectedAccountId,
    required int expectedRevision,
    required int? accountId,
    bool confirmReplacement = false,
    bool confirmUncertainCompatibility = false,
  }) => database.transaction(() async {
    final row = await _row(id);
    if (row == null || row.origin != 'sms_reported') {
      throw ArgumentError('SMS observation no longer exists.');
    }
    if (row.accountId != expectedAccountId ||
        row.revision != expectedRevision) {
      throw StateError(
        'Association changed. Reload the observation and try again.',
      );
    }
    if (row.accountId == accountId) return;
    if (accountId != null) {
      if (row.accountId != null && !confirmReplacement) {
        throw ArgumentError('Confirm replacement of the existing association.');
      }
      final instrument = await FinancialInstrumentsRepository(
        database,
      ).getById(accountId);
      if (instrument == null || !instrument.isActive) {
        throw ArgumentError('Select an active registered instrument.');
      }
      final compatibility = smsBalanceCompatibility(_map(row), instrument);
      if (compatibility == BalanceCompatibility.incompatible) {
        throw ArgumentError(
          'The instrument type or provider conflicts with this balance subject.',
        );
      }
      if (compatibility == BalanceCompatibility.confirmationRequired &&
          !confirmUncertainCompatibility) {
        throw ArgumentError(
          'Confirm compatibility because instrument metadata is incomplete or unrecognized.',
        );
      }
    }
    await (database.update(
      database.balanceEvidence,
    )..where((e) => e.id.equals(id))).write(
      BalanceEvidenceCompanion(
        accountId: Value(accountId),
        associationOrigin: Value(accountId == null ? null : 'explicit_user'),
        associatedMillis: Value(
          accountId == null ? null : DateTime.now().millisecondsSinceEpoch,
        ),
        revision: Value(row.revision + 1),
      ),
    );
  });

  Future<BalanceHistoryPage> smsHistory({
    bool unattributedOnly = true,
    int page = 0,
  }) => database.transaction(() async {
    if (page < 0) throw ArgumentError('Invalid evidence page.');
    final t = database.balanceEvidence;
    final predicate =
        t.origin.equals('sms_reported') &
        (unattributedOnly ? t.accountId.isNull() : const Constant(true));
    final countExpr = t.id.count();
    final count =
        (await (database.selectOnly(t)
                  ..addColumns([countExpr])
                  ..where(predicate))
                .getSingle())
            .read(countExpr)!;
    final last = count == 0 ? 0 : (count - 1) ~/ 20;
    final actual = page > last ? last : page;
    final a = database.accounts;
    final rows =
        await (database.select(t).join([
                leftOuterJoin(
                  a,
                  a.id.equalsExp(t.accountId) & a.isUserRegistered.equals(true),
                ),
              ])
              ..where(predicate)
              ..orderBy([
                OrderingTerm.desc(t.asOfMillis),
                OrderingTerm.desc(t.createdMillis),
                OrderingTerm.desc(t.id),
              ])
              ..limit(20, offset: actual * 20))
            .get();
    return BalanceHistoryPage(
      [
        for (final row in rows)
          _map(
            row.readTable(t),
            associationName: row.readTableOrNull(a)?.name,
            associationArchived: row.readTableOrNull(a)?.isActive == false,
          ),
      ],
      count,
      actual,
    );
  });

  Future<void> _registered(int id) async {
    if (await database.accountsDao.getRegisteredById(id) == null) {
      throw ArgumentError('Registered instrument no longer exists.');
    }
  }

  void _validate(int minor, BalanceKind kind, DateTime asOf) {
    if (kind == BalanceKind.outstandingDebt && minor < 0) {
      throw ArgumentError('Outstanding debt cannot be negative.');
    }
    if (asOf.isAfter(DateTime.now())) {
      throw ArgumentError('Observation time cannot be in the future.');
    }
  }

  Future<BalanceObservation> createManual({
    required int accountId,
    required String amount,
    required String currency,
    required BalanceKind kind,
    required DateTime asOf,
    AccountType? subjectFamily,
  }) => database.transaction(() async {
    await _registered(accountId);
    final code = SnapshotMoney.currency(currency);
    final minor = SnapshotMoney.parse(amount, code);
    _validate(minor, kind, asOf);
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database
        .into(database.balanceEvidence)
        .insert(
          BalanceEvidenceCompanion.insert(
            id: id,
            amountMinor: minor,
            currency: code,
            kind: kind.value,
            subjectFamily: Value(subjectFamily?.name),
            origin: 'manual',
            asOfMillis: asOf.millisecondsSinceEpoch,
            timeBasis: 'user_supplied',
            createdMillis: now,
            accountId: Value(accountId),
            associationOrigin: const Value('explicit_user'),
            associatedMillis: Value(now),
          ),
        );
    return _map((await _row(id))!);
  });
  Future<StoredBalanceEvidence?> _row(String id) => (database.select(
    database.balanceEvidence,
  )..where((e) => e.id.equals(id))).getSingleOrNull();
  Future<StoredBalanceEvidence> _editable(
    String id,
    int accountId,
    int expectedRevision,
  ) async {
    await _registered(accountId);
    final row = await _row(id);
    if (row == null || row.accountId != accountId) {
      throw ArgumentError('Balance observation no longer exists.');
    }
    if (row.origin != 'manual' || row.associationOrigin != 'explicit_user') {
      throw ArgumentError('Only manual observations can be changed here.');
    }
    if (row.revision != expectedRevision) {
      throw StateError('This observation changed. Reopen it and try again.');
    }
    return row;
  }

  Future<void> correctManual({
    required String id,
    required int accountId,
    required int expectedRevision,
    required String amount,
    required String currency,
    required BalanceKind kind,
    required DateTime asOf,
    AccountType? subjectFamily,
  }) => database.transaction(() async {
    await _editable(id, accountId, expectedRevision);
    final code = SnapshotMoney.currency(currency);
    final minor = SnapshotMoney.parse(amount, code);
    _validate(minor, kind, asOf);
    await (database.update(
      database.balanceEvidence,
    )..where((e) => e.id.equals(id))).write(
      BalanceEvidenceCompanion(
        amountMinor: Value(minor),
        currency: Value(code),
        kind: Value(kind.value),
        asOfMillis: Value(asOf.millisecondsSinceEpoch),
        subjectFamily: Value(subjectFamily?.name),
        revision: Value(expectedRevision + 1),
      ),
    );
  });
  Future<void> deleteManual({
    required String id,
    required int accountId,
    required int expectedRevision,
  }) => database.transaction(() async {
    await _editable(id, accountId, expectedRevision);
    await (database.delete(
      database.balanceEvidence,
    )..where((e) => e.id.equals(id))).go();
  });
  SimpleSelectStatement<$BalanceEvidenceTable, StoredBalanceEvidence> _query(
    int accountId,
  ) => database.select(database.balanceEvidence)
    ..where(
      (e) =>
          e.accountId.equals(accountId) &
          e.origin.isIn(['manual', 'sms_reported']),
    )
    ..orderBy([
      (e) => OrderingTerm.desc(e.asOfMillis),
      (e) => OrderingTerm.desc(e.createdMillis),
      (e) => OrderingTerm.desc(e.id),
    ]);
  Future<BalanceObservation?> latest(int accountId) async {
    await _registered(accountId);
    final row = await (_query(accountId)..limit(1)).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<BalanceHistoryPage> history(int accountId, {int page = 0}) =>
      database.transaction(() async {
        if (page < 0) throw ArgumentError('Invalid balance history page.');
        await _registered(accountId);
        final t = database.balanceEvidence;
        final countExpr = t.id.count();
        final count =
            (await (database.selectOnly(t)
                      ..addColumns([countExpr])
                      ..where(
                        t.accountId.equals(accountId) &
                            t.origin.isIn(['manual', 'sms_reported']),
                      ))
                    .getSingle())
                .read(countExpr)!;
        final last = count == 0 ? 0 : (count - 1) ~/ 20;
        final actual = page > last ? last : page;
        final rows = await (_query(
          accountId,
        )..limit(20, offset: actual * 20)).get();
        return BalanceHistoryPage(rows.map(_map).toList(), count, actual);
      });
  Stream<int> changes() async* {
    var revision = 0;
    yield revision;
    await for (final _ in database.tableUpdates(
      TableUpdateQuery.onAllTables([
        database.balanceEvidence,
        database.accounts,
      ]),
    )) {
      yield ++revision;
    }
  }

  BalanceObservation _map(
    StoredBalanceEvidence row, {
    String? associationName,
    bool associationArchived = false,
  }) => BalanceObservation(
    id: row.id,
    currency: row.currency,
    amountMinor: row.amountMinor,
    accountId: row.accountId,
    origin: row.origin,
    timeBasis: row.timeBasis,
    associationName: associationName,
    associationArchived: associationArchived,
    associationOrigin: row.associationOrigin,
    rawMessageId: row.rawMessageId,
    matchedClause: row.matchedClause,
    extractionVersion: row.extractionVersion,
    revision: row.revision,
    kind: BalanceKind.values.firstWhere((k) => k.value == row.kind),
    subjectFamily: row.subjectFamily == null
        ? null
        : AccountType.values.firstWhere(
            (f) => f.name == row.subjectFamily,
            orElse: () => AccountType.unknown,
          ),
    asOf: DateTime.fromMillisecondsSinceEpoch(row.asOfMillis, isUtc: true),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdMillis,
      isUtc: true,
    ),
  );
}
