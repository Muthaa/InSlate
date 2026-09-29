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

  Future<FinancialRecord?> getRecordByReference(String reference) {
    return (select(
      financialRecords,
    )..where((record) => record.reference.equals(reference))).getSingleOrNull();
  }

  Future<int> insertRecord(FinancialRecordsCompanion record) {
    return into(financialRecords).insert(record);
  }

  Future<bool> recordExists(String reference) async {
    final record = await getRecordByReference(reference);
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

  Future<void> insertRecords(List<FinancialRecordsCompanion> records) async {
    if (records.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(financialRecords, records);
    });
  }
}
