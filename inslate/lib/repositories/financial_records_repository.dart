import 'package:drift/drift.dart';

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
    await database.financialRecordsDao.insertRecord(
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
  }

  Future<List<domain.FinancialRecord>> getAllByReference(
    String reference,
  ) async {
    final rows = await database.financialRecordsDao.getRecordsByReference(
      reference,
    );

    return rows.map(_toDomain).toList();
  }

  Future<List<domain.FinancialRecord>> getAll() async {
    final rows = await database.financialRecordsDao.getAllRecords();

    return rows.map(_toDomain).toList();
  }

  Future<List<domain.FinancialRecord>> getForPeriod(
    FinancialPeriod period,
  ) async {
    final rows = await database.financialRecordsDao.getRecordsForPeriod(period);
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
  }) async {
    if (offset < 0 || (limit != null && limit <= 0)) {
      throw ArgumentError('Invalid page bounds');
    }
    if (filter.party != null || filter.endpoint?.identity != null) {
      // SQLite lower/trim do not implement Dart's Unicode normalization.
      // Resolve identities with the shared policy in bounded, period-filtered
      // batches, before applying the requested result offset and limit.
      final candidateFilter = ActivityFilter(
        period: filter.period,
        scope: filter.scope,
        subtype: filter.subtype,
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
      var candidateOffset = 0;
      var matchedCount = 0;
      while (true) {
        final rows = await database.financialRecordsDao.getActivityCandidates(
          candidateFilter,
          limit: batchSize,
          offset: candidateOffset,
        );
        for (final row in rows) {
          final record = _toDomain(row);
          if (!filter.matches(record)) continue;
          if (matchedCount++ < offset) continue;
          matches.add(record);
          if (limit != null && matches.length == limit) return matches;
        }
        if (rows.length < batchSize) return matches;
        candidateOffset += rows.length;
      }
    }
    final rows = await database.financialRecordsDao.getActivityCandidates(
      filter,
      limit: limit,
      offset: offset,
    );
    return rows.map(_toDomain).toList();
  }

  Future<Set<DateTime>> getEffectiveMonths() =>
      database.financialRecordsDao.getEffectiveMonths();
  Future<({DateTime? first, DateTime? last})> getEffectiveDateBounds() =>
      database.financialRecordsDao.getEffectiveDateBounds();

  domain.FinancialRecord _toDomain(FinancialRecord row) {
    return domain.FinancialRecord(
      reference: row.reference,
      transactionDate: row.transactionDate,
      amount: row.amount,
      balance: row.balance,
      type: FinancialRecordType.values.byName(row.type),
      subtype: RecordSubtype.values.byName(row.subtype),
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
