import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/financial_instrument.dart';
import '../models/financial_period.dart';
import '../models/instrument_history.dart';
import 'financial_records_repository.dart';

/// The only registration entry point. Never called by ingestion or classifiers.
/// UUID is the uniqueness boundary: names, providers and identifiers can repeat.
class FinancialInstrumentsRepository {
  final AppDatabase database;
  FinancialInstrumentsRepository(this.database);

  Future<List<FinancialInstrument>> list({
    bool includeArchived = false,
  }) async => (await database.accountsDao.getRegistered(
    includeArchived: includeArchived,
  )).map(_instrument).toList();
  Stream<List<FinancialInstrument>> watch({bool includeArchived = false}) =>
      database.accountsDao
          .watchRegistered(includeArchived: includeArchived)
          .map((rows) => rows.map(_instrument).toList());
  Future<FinancialInstrument?> getByUuid(String uuid) async {
    final row = await database.accountsDao.getRegisteredByUuid(uuid);
    return row == null ? null : _instrument(row);
  }

  Future<FinancialInstrument?> getById(int id) async {
    final row = await database.accountsDao.getRegisteredById(id);
    return row == null ? null : _instrument(row);
  }

  /// Archived registrations retain history. Unconfirmed/missing rows are never
  /// valid instrument history targets, even if old numeric references exist.
  Future<void> _requireRegistered(int accountId) async {
    if (await database.accountsDao.getRegisteredById(accountId) == null) {
      throw ArgumentError('Registered instrument no longer exists');
    }
  }

  Future<Set<DateTime>> historyMonths(int accountId) async {
    await _requireRegistered(accountId);
    return database.financialRecordsDao.getInstrumentMonths(accountId);
  }

  Future<InstrumentHistoryPage> history({
    required int accountId,
    required FinancialPeriod period,
    int page = 0,
  }) => database.transaction(() async {
    if (page < 0) throw ArgumentError('Invalid instrument page');
    await _requireRegistered(accountId);
    final dao = database.financialRecordsDao;
    final count = await dao.countInstrumentRecords(accountId, period);
    final last = count == 0 ? 0 : (count - 1) ~/ InstrumentHistoryPage.pageSize;
    final actualPage = page > last ? last : page;
    final rows = await dao.getInstrumentRecords(
      accountId,
      period,
      limit: InstrumentHistoryPage.pageSize,
      offset: actualPage * InstrumentHistoryPage.pageSize,
    );
    final mapper = FinancialRecordsRepository(database);
    return InstrumentHistoryPage(
      count: count,
      page: actualPage,
      entries: [
        for (final row in rows)
          InstrumentHistoryEntry(
            mapper.toDomain(row),
            row.sourceAccountId == accountId &&
                    row.destinationAccountId == accountId
                ? InstrumentTransactionRole.selfLinked
                : row.sourceAccountId == accountId
                ? InstrumentTransactionRole.outgoing
                : InstrumentTransactionRole.incoming,
          ),
      ],
    );
  });

  Future<FinancialInstrument> create({
    required String name,
    required InstrumentType type,
    String? provider,
    InstrumentIdentifiers? identifiers,
  }) => database.transaction(() async {
    final uuid = const Uuid().v4();
    await database.accountsDao.insertAccount(
      AccountsCompanion.insert(
        uuid: uuid,
        name: _name(name),
        type: type.storageValue,
        institution: Value(_optional(provider)),
        identifiers: Value(_identifiers(identifiers)),
        isUserRegistered: const Value(true),
      ),
    );
    return (await getByUuid(uuid))!;
  });

  /// Replaces editable metadata. Null optional fields clear their stored value.
  /// Identity, creation time and archive state are not editable here.
  Future<FinancialInstrument> update({
    required String uuid,
    required String name,
    required InstrumentType type,
    String? provider,
    InstrumentIdentifiers? identifiers,
  }) => database.transaction(() async {
    final changed = await database.accountsDao.updateRegistered(
      uuid,
      AccountsCompanion(
        name: Value(_name(name)),
        type: Value(type.storageValue),
        institution: Value(_optional(provider)),
        identifiers: Value(_identifiers(identifiers)),
      ),
    );
    if (changed == 0) {
      throw ArgumentError('Registered instrument does not exist');
    }
    return (await getByUuid(uuid))!;
  });

  /// Archive/restore only; no deletion or financial-record side effects.
  Future<void> setArchived(String uuid, bool archived) async {
    final changed = await database.accountsDao.updateRegistered(
      uuid,
      AccountsCompanion(isActive: Value(!archived)),
    );
    if (changed == 0) {
      throw ArgumentError('Registered instrument does not exist');
    }
  }

  String _name(String value) {
    final name = value.trim();
    if (name.isEmpty) throw ArgumentError('Instrument name must not be empty');
    return name;
  }

  String? _optional(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _identifiers(InstrumentIdentifiers? value) {
    if (value == null) return null;
    final normalized = InstrumentIdentifiers(
      accountNumber: _optional(value.accountNumber),
      walletNumber: _optional(value.walletNumber),
      membershipNumber: _optional(value.membershipNumber),
      policyNumber: _optional(value.policyNumber),
      reference: _optional(value.reference),
    ).toJson();
    return normalized.isEmpty ? null : jsonEncode(normalized);
  }

  FinancialInstrument _instrument(Account row) => FinancialInstrument(
    id: row.id,
    uuid: row.uuid,
    name: row.name,
    type: InstrumentType.fromStorage(row.type),
    storedType: row.type,
    provider: row.institution,
    identifiers: row.identifiers == null
        ? null
        : InstrumentIdentifiers.fromJson(
            jsonDecode(row.identifiers!) as Map<String, dynamic>,
          ),
    isActive: row.isActive,
    createdAt: row.createdAt,
  );
}
