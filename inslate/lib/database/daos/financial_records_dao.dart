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

  Expression<DateTime> get _effectiveDate => const CustomExpression<DateTime>(
    'COALESCE(transaction_date, received_at)',
  );

  Expression<bool> _activityPredicate(ActivityFilter filter) {
    Expression<bool> predicate =
        _effectiveDate.isBiggerOrEqualValue(filter.period.start) &
        _effectiveDate.isSmallerThanValue(filter.period.end);
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
              (financialRecords.subtype.equals(subtype.name) &
                  financialRecords.type.equals(expected.name));
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
              (financialRecords.subtype.equals(subtype.name) &
                  financialRecords.type.equals(policy.expectedType!.name));
        }
      }
      predicate = predicate & membership;
    } else if (filter.subtype != null) {
      predicate =
          predicate &
          financialRecords.subtype.isIn(
            subtypes.map((subtype) => subtype.name),
          );
    }
    return predicate;
  }

  Future<List<FinancialRecord>> getRecordsForPeriod(FinancialPeriod period) =>
      getActivityCandidates(ActivityFilter(period: period));

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
