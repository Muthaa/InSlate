import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/financial_records.dart';

part 'financial_records_dao.g.dart';

@DriftAccessor(tables: [FinancialRecords])
class FinancialRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$FinancialRecordsDaoMixin {
  FinancialRecordsDao(super.db);

  Future<List<FinancialRecord>> getAllRecords() {
    return select(financialRecords).get();
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
