import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/repositories/financial_records_repository.dart';

class ActivityTestRepository extends FinancialRecordsRepository {
  List<FinancialRecord> records;
  bool fail = false;
  Future<void>? pendingRead;
  int activityReads = 0;
  int monthReads = 0;
  int periodReads = 0;
  final requestedPeriods = <FinancialPeriod>[];
  ActivityFilter? lastFilter;
  ActivityTestRepository(super.database, this.records);

  @override
  Future<List<FinancialRecord>> getForPeriod(FinancialPeriod period) async {
    periodReads++;
    requestedPeriods.add(period);
    await pendingRead;
    if (fail) throw StateError('Test query failure');
    final selected =
        records
            .where(
              (record) =>
                  period.contains(record.transactionDate ?? record.receivedAt),
            )
            .toList()
          ..sort((a, b) {
            final comparison = (b.transactionDate ?? b.receivedAt).compareTo(
              a.transactionDate ?? a.receivedAt,
            );
            return comparison != 0
                ? comparison
                : records.indexOf(b).compareTo(records.indexOf(a));
          });
    return selected;
  }

  @override
  Future<({DateTime? first, DateTime? last})> getEffectiveDateBounds() async {
    final dates =
        records
            .map((record) => record.transactionDate ?? record.receivedAt)
            .toList()
          ..sort();
    return (
      first: dates.isEmpty ? null : dates.first,
      last: dates.isEmpty ? null : dates.last,
    );
  }

  @override
  Future<List<FinancialRecord>> getAll() =>
      throw StateError('Activity must not load complete history');

  @override
  Future<List<FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
  }) async {
    activityReads++;
    lastFilter = filter;
    await pendingRead;
    if (fail) throw StateError('Test query failure');
    final matches = records.where(filter.matches).toList();
    return matches.skip(offset).take(limit ?? matches.length).toList();
  }

  @override
  Future<int> countActivity(ActivityFilter filter) async {
    await pendingRead;
    if (fail) throw StateError('Test query failure');
    return records.where(filter.matches).length;
  }

  @override
  Future<Set<DateTime>> getEffectiveMonths() async {
    monthReads++;
    return records.map((record) {
      final date = record.transactionDate ?? record.receivedAt;
      return DateTime(date.year, date.month);
    }).toSet();
  }
}
