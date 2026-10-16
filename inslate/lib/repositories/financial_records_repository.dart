import '../models/activity_cursor.dart';
import 'package:drift/drift.dart';
import 'categories_repository.dart';
import 'instrument_mappings_repository.dart';

import '../core/enums/financial_record_type.dart';
import '../core/enums/party_type.dart';
import '../core/enums/record_subtype.dart';
import '../core/enums/transaction_status.dart';
import '../database/app_database.dart';
import '../models/financial_records.dart' as domain;
import '../models/party.dart';
import '../models/financial_period.dart';
import '../models/activity_filter.dart';
import '../services/financial_semantics.dart';

class FinancialRecordsRepository {
  final AppDatabase database;

  FinancialRecordsRepository(this.database);

  Future<void> save(domain.FinancialRecord record) async {
    _ordinarySave(record);
    await database.transaction(() async {
      final id = await database.financialRecordsDao.insertRecord(
        FinancialRecordsCompanion.insert(
          reference: record.reference,
          transactionDate: Value(record.transactionDate),
          receivedAt: record.receivedAt,
          amount: record.amount,
          balance: Value(record.balance),
          transactionCost: Value(record.transactionCost),
          type: record.type.name,
          subtype: record.subtype.name,
          status: record.status.name,
          title: record.title,
          rawMessage: record.rawMessage,
          sourceMessageId: Value(record.sourceMessageId),
          partyName: Value(record.party?.name),
          partyType: Value(record.party?.type.name),
          partyPhone: Value(record.party?.phone),
          partyAccount: Value(record.party?.account),
          partyIdentifier: Value(record.party?.identifier),
        ),
      );
      await InstrumentMappingsRepository(database).applyNew(afterId: id - 1);
      await CategoriesRepository(
        database,
      ).applyRules(afterId: id - 1, throughId: id);
    });
  }

  void _ordinarySave(domain.FinancialRecord record) {
    if (record.type == FinancialRecordType.reversal ||
        record.subtype == RecordSubtype.payBillReversal ||
        record.reversesRecordId != null) {
      throw ArgumentError('Use the validated PayBill reversal repository.');
    }
  }

  Future<List<String>> getExistingReferences(List<String> references) {
    return database.financialRecordsDao.getExistingReferences(references);
  }

  Future<List<String>> getExistingSourceMessageIds(
    List<String> sourceMessageIds,
  ) {
    return database.financialRecordsDao.getExistingSourceMessageIds(
      sourceMessageIds,
    );
  }

  Future<void> saveAll(List<domain.FinancialRecord> records) async {
    if (records.isEmpty) {
      return;
    }

    for (final record in records) {
      _ordinarySave(record);
    }
    await database.transaction(() async {
      final last =
          await (database.select(database.financialRecords)
                ..orderBy([(r) => OrderingTerm.desc(r.id)])
                ..limit(1))
              .getSingleOrNull();
      await database.financialRecordsDao.insertRecords(
        records
            .map(
              (record) => FinancialRecordsCompanion.insert(
                reference: record.reference,
                transactionDate: Value(record.transactionDate),
                receivedAt: record.receivedAt,
                amount: record.amount,
                balance: Value(record.balance),
                transactionCost: Value(record.transactionCost),
                type: record.type.name,
                subtype: record.subtype.name,
                status: record.status.name,
                title: record.title,
                rawMessage: record.rawMessage,
                sourceMessageId: Value(record.sourceMessageId),
                partyName: Value(record.party?.name),
                partyType: Value(record.party?.type.name),
                partyPhone: Value(record.party?.phone),
                partyAccount: Value(record.party?.account),
                partyIdentifier: Value(record.party?.identifier),
              ),
            )
            .toList(),
      );
      await InstrumentMappingsRepository(
        database,
      ).applyNew(afterId: last?.id ?? 0);
      await CategoriesRepository(database).applyRules(afterId: last?.id ?? 0);
    });
  }

  Future<List<domain.FinancialRecord>> getAllByReference(
    String reference,
  ) async {
    final rows = await database.financialRecordsDao.getRecordsByReference(
      reference,
    );

    return rows.map(toDomain).toList();
  }

  Future<List<domain.FinancialRecord>> getAll() async {
    final rows = await database.financialRecordsDao.getAllRecords();

    return rows.map(toDomain).toList();
  }

  Future<domain.FinancialRecord?> getById(int id) async {
    final row = await (database.select(
      database.financialRecords,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return row == null ? null : toDomain(row);
  }

  Future<List<domain.FinancialRecord>> getForPeriod(
    FinancialPeriod period,
  ) async {
    final rows = await database.financialRecordsDao.getRecordsForPeriod(period);
    return rows.map(toDomain).toList();
  }

  Future<List<domain.FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
    ActivityCursor? before,
  }) async {
    if (offset < 0 || (limit != null && limit <= 0)) {
      throw ArgumentError('Invalid page bounds');
    }
    if (filter.party != null ||
        filter.endpoint?.identity != null ||
        filter.provider != null) {
      // SQLite lower/trim do not implement Dart's Unicode normalization.
      // Resolve identities with the shared policy in bounded, period-filtered
      // batches, before applying the requested result offset and limit.
      final candidateFilter = ActivityFilter(
        period: filter.period,
        search: filter.search,
        category: filter.category,
        scope: filter.scope,
        subtype: filter.subtype,
        provider: filter.provider,
        partyPresence: filter.partyPresence,
        resolution: filter.resolution,
        direction: filter.direction,
        central: filter.central,
        endpoint: filter.endpoint == null
            ? null
            : AccountEndpoint(filter.endpoint!.type),
      );
      const batchSize = 100;
      final matches = <domain.FinancialRecord>[];
      ActivityCursor? candidateCursor = before;
      var matchedCount = 0;
      while (true) {
        final rows = await database.financialRecordsDao.getActivityCandidates(
          candidateFilter,
          limit: batchSize,
          before: candidateCursor,
        );
        for (final row in rows) {
          final record = toDomain(row);
          if (!filter.matches(record)) continue;
          if (matchedCount++ < offset) continue;
          matches.add(record);
          if (limit != null && matches.length == limit) return matches;
        }
        if (rows.length < batchSize) return matches;
        candidateCursor = ActivityCursor.fromRecord(toDomain(rows.last));
      }
    }
    final rows = await database.financialRecordsDao.getActivityCandidates(
      filter,
      limit: limit,
      offset: offset,
      before: before,
    );
    return rows.map(toDomain).toList();
  }

  Future<Set<DateTime>> getEffectiveMonths() =>
      database.financialRecordsDao.getEffectiveMonths();

  /// Count the same filtered dataset as Activity without retaining full history.
  Future<int> countActivity(ActivityFilter filter) async {
    if (filter.party == null &&
        filter.endpoint?.identity == null &&
        filter.provider == null) {
      return database.financialRecordsDao.countActivityCandidates(filter);
    }
    final candidates = ActivityFilter(
      period: filter.period,
      search: filter.search,
      category: filter.category,
      scope: filter.scope,
      subtype: filter.subtype,
      provider: filter.provider,
      partyPresence: filter.partyPresence,
      resolution: filter.resolution,
      direction: filter.direction,
      central: filter.central,
      endpoint: filter.endpoint == null
          ? null
          : AccountEndpoint(filter.endpoint!.type),
    );
    var count = 0;
    var offset = 0;
    const batchSize = 100;
    while (true) {
      final rows = await database.financialRecordsDao.getActivityCandidates(
        candidates,
        limit: batchSize,
        offset: offset,
      );
      count += rows.map(toDomain).where(filter.matches).length;
      if (rows.length < batchSize) return count;
      offset += rows.length;
    }
  }

  Future<({DateTime? first, DateTime? last})> getEffectiveDateBounds() =>
      database.financialRecordsDao.getEffectiveDateBounds();

  domain.FinancialRecord toDomain(FinancialRecord row) {
    return domain.FinancialRecord(
      id: row.id,
      reversesRecordId: row.reversesRecordId,
      reference: row.reference,
      transactionDate: row.transactionDate,
      amount: row.amount,
      balance: row.balance,
      type: FinancialRecordType.values.byName(row.interpretedType ?? row.type),
      subtype: RecordSubtype.values.byName(
        row.interpretedSubtype ?? row.subtype,
      ),
      parsedType: FinancialRecordType.values.byName(row.type),
      parsedSubtype: RecordSubtype.values.byName(row.subtype),
      interpretationMappingId: row.interpretationMappingId,
      status: TransactionStatus.values.byName(row.status),
      title: row.title,
      transactionCost: row.transactionCost ?? 0,
      rawMessage: row.rawMessage,
      receivedAt: row.receivedAt,
      sourceMessageId: row.sourceMessageId,
      party: _buildParty(row),
    );
  }

  Party? _buildParty(FinancialRecord row) {
    if (row.partyName == null) {
      return null;
    }

    return Party(
      name: row.partyName!,
      type: PartyType.values.byName(row.partyType ?? 'unknown'),
      phone: row.partyPhone,
      account: row.partyAccount,
      identifier: row.partyIdentifier,
    );
  }
}
