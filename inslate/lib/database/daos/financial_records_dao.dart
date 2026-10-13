import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/financial_records.dart';
import '../../models/financial_period.dart';
import '../../models/activity_filter.dart';
import '../../core/enums/record_subtype.dart';
import '../../services/financial_semantics.dart';

part 'financial_records_dao.g.dart';

@DriftAccessor(tables: [FinancialRecords])
class FinancialRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$FinancialRecordsDaoMixin {
  FinancialRecordsDao(super.db);

  Future<List<FinancialRecord>> getAllRecords() {
    return select(financialRecords).get();
  }

  Expression<String> get _interpretedType => CustomExpression<String>(
    FinancialSemantics.effectiveTypeSql('financial_records'),
  );
  Expression<String> get _interpretedSubtype => CustomExpression<String>(
    FinancialSemantics.effectiveSubtypeSql('financial_records'),
  );

  Expression<DateTime> get _effectiveDate => const CustomExpression<DateTime>(
    'COALESCE(transaction_date, received_at)',
  );

  Expression<bool> _activityPredicate(ActivityFilter filter) {
    Expression<bool> predicate =
        _effectiveDate.isBiggerOrEqualValue(filter.period.start) &
        _effectiveDate.isSmallerThanValue(filter.period.end);
    if (filter.category != null) {
      final assignments = db.recordCategoryAssignments;
      final categorized = db.selectOnly(assignments)
        ..addColumns([assignments.financialRecordId])
        ..where(
          assignments.financialRecordId.equalsExp(
                CustomExpression<int>(
                  FinancialSemantics.categoryRecordSql('financial_records'),
                ),
              ) &
              (filter.category!.categoryId == null
                  ? assignments.categoryId.isNotNull()
                  : assignments.categoryId.equals(
                      filter.category!.categoryId!,
                    )),
        );
      final membership = existsQuery(categorized);
      predicate =
          predicate &
          (filter.category!.categoryId == null ? membership.not() : membership);
    }
    if (filter.search.isNotEmpty) {
      // INSTR is literal substring matching: %, _ and quotes are not wildcards.
      Expression<bool> search = const Constant(false);
      for (final column in [
        financialRecords.partyName,
        financialRecords.title,
        financialRecords.reference,
        financialRecords.partyPhone,
        financialRecords.partyAccount,
        financialRecords.partyIdentifier,
      ]) {
        search =
            search |
            FunctionCallExpression<int>('instr', [
              FunctionCallExpression<String>('lower', [column]),
              Variable<String>(filter.search),
            ]).isBiggerThanValue(0);
      }
      predicate = predicate & search;
    }
    final subtypes = RecordSubtype.values.where(filter.acceptsSubtype).toList();
    if (filter.partyPresence != null) {
      predicate =
          predicate &
          (filter.partyPresence == PartyPresence.unidentified
              ? financialRecords.partyName.isNull()
              : financialRecords.partyName.isNotNull());
    }
    if (filter.resolution != null) {
      Expression<bool> resolved = const Constant(false);
      for (final subtype in RecordSubtype.values) {
        final expected = FinancialSemantics.forSubtype(subtype).expectedType;
        if (expected != null) {
          resolved =
              resolved |
              (_interpretedSubtype.equals(subtype.name) &
                  _interpretedType.equals(expected.name));
        }
      }
      predicate =
          predicate &
          (filter.resolution == SemanticResolution.resolved
              ? resolved
              : resolved.not());
    }
    if (filter.requiresResolvedSemantics) {
      Expression<bool> membership = const Constant(false);
      for (final subtype in subtypes) {
        final policy = FinancialSemantics.forSubtype(subtype);
        if (policy.expectedType != null) {
          membership =
              membership |
              (_interpretedSubtype.equals(subtype.name) &
                  _interpretedType.equals(policy.expectedType!.name));
        }
      }
      predicate = predicate & membership;
    } else if (filter.subtype != null || filter.provider?.unspecified == true) {
      predicate =
          predicate &
          _interpretedSubtype.isIn(subtypes.map((subtype) => subtype.name));
    }
    return predicate;
  }

  Future<List<FinancialRecord>> getRecordsForPeriod(FinancialPeriod period) =>
      getActivityCandidates(ActivityFilter(period: period));

  Future<int> countActivityCandidates(ActivityFilter filter) async {
    final count = financialRecords.id.count();
    final row =
        await (selectOnly(financialRecords)
              ..addColumns([count])
              ..where(_activityPredicate(filter)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Period, subtype, movement class, account family and direction are filtered
  /// in SQL. The repository resolves optional party identities before result
  /// pagination. ID makes equal-date ordering deterministic.
  Future<List<FinancialRecord>> getActivityCandidates(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
  }) {
    if (offset < 0 || (limit != null && limit <= 0)) {
      throw ArgumentError('Invalid page bounds');
    }
    final query = select(financialRecords)
      ..where((_) => _activityPredicate(filter))
      ..orderBy([
        (_) => OrderingTerm.desc(_effectiveDate),
        (row) => OrderingTerm.desc(row.id),
      ]);
    if (limit != null) query.limit(limit, offset: offset);
    if (limit == null && offset > 0) query.limit(-1, offset: offset);
    return query.get();
  }

  Expression<bool> _instrumentMembership(int accountId) =>
      financialRecords.sourceAccountId.equals(accountId) |
      financialRecords.destinationAccountId.equals(accountId);

  Expression<bool> _instrumentPeriod(int accountId, FinancialPeriod period) =>
      _instrumentMembership(accountId) &
      _effectiveDate.isBiggerOrEqualValue(period.start) &
      _effectiveDate.isSmallerThanValue(period.end);

  Future<int> countInstrumentRecords(
    int accountId,
    FinancialPeriod period,
  ) async {
    final count = financialRecords.id.count();
    final row =
        await (selectOnly(financialRecords)
              ..addColumns([count])
              ..where(_instrumentPeriod(accountId, period)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<FinancialRecord>> getInstrumentRecords(
    int accountId,
    FinancialPeriod period, {
    required int limit,
    required int offset,
  }) {
    if (limit <= 0 || limit > 50 || offset < 0) {
      throw ArgumentError('Invalid instrument page bounds');
    }
    return (select(financialRecords)
          ..where((_) => _instrumentPeriod(accountId, period))
          ..orderBy([
            (_) => OrderingTerm.desc(_effectiveDate),
            (r) => OrderingTerm.desc(r.id),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Only month keys cross the database boundary, never unbounded record rows.
  Future<Set<DateTime>> getInstrumentMonths(int accountId) async {
    const month = CustomExpression<String>(
      "strftime('%Y-%m-01', COALESCE(transaction_date, received_at), 'unixepoch', 'localtime')",
    );
    final rows =
        await (selectOnly(financialRecords, distinct: true)
              ..addColumns([month])
              ..where(_instrumentMembership(accountId)))
            .get();
    return rows.map((r) => DateTime.parse(r.read(month)!)).toSet();
  }

  Future<({DateTime? first, DateTime? last})> getEffectiveDateBounds() async {
    const first = CustomExpression<DateTime>(
      'MIN(COALESCE(transaction_date, received_at))',
    );
    const last = CustomExpression<DateTime>(
      'MAX(COALESCE(transaction_date, received_at))',
    );
    final row = await (selectOnly(
      financialRecords,
    )..addColumns([first, last])).getSingle();
    return (first: row.read(first), last: row.read(last));
  }

  /// SQL returns only month keys, not full records or raw SMS bodies.
  Future<Set<DateTime>> getEffectiveMonths() async {
    const month = CustomExpression<String>(
      "strftime('%Y-%m-01', COALESCE(transaction_date, received_at), 'unixepoch', 'localtime')",
    );
    final rows = await (selectOnly(
      financialRecords,
      distinct: true,
    )..addColumns([month])).get();
    return rows.map((row) => DateTime.parse(row.read(month)!)).toSet();
  }

  Future<List<FinancialRecord>> getRecordsByReference(String reference) {
    return (select(
      financialRecords,
    )..where((record) => record.reference.equals(reference))).get();
  }

  Future<int> insertRecord(FinancialRecordsCompanion record) {
    return into(financialRecords).insert(record);
  }

  Future<bool> recordExists(String reference) async {
    final record =
        await (select(financialRecords)
              ..where((row) => row.reference.equals(reference))
              ..limit(1))
            .getSingleOrNull();
    return record != null;
  }

  Future<List<String>> getExistingReferences(List<String> references) async {
    if (references.isEmpty) {
      return [];
    }

    final rows = await (select(
      financialRecords,
    )..where((record) => record.reference.isIn(references))).get();

    return rows.map((row) => row.reference).toList();
  }

  Future<List<String>> getExistingSourceMessageIds(
    List<String> sourceMessageIds,
  ) async {
    if (sourceMessageIds.isEmpty) {
      return [];
    }

    final rows = await (select(
      financialRecords,
    )..where((record) => record.sourceMessageId.isIn(sourceMessageIds))).get();

    return rows.map((row) => row.sourceMessageId).whereType<String>().toList();
  }

  Future<void> insertRecords(List<FinancialRecordsCompanion> records) async {
    if (records.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(financialRecords, records);
    });
  }
}
