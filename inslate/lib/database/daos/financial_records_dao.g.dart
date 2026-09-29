// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_records_dao.dart';

// ignore_for_file: type=lint
mixin _$FinancialRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FinancialRecordsTable get financialRecords =>
      attachedDatabase.financialRecords;
  FinancialRecordsDaoManager get managers => FinancialRecordsDaoManager(this);
}

class FinancialRecordsDaoManager {
  final _$FinancialRecordsDaoMixin _db;
  FinancialRecordsDaoManager(this._db);
  $$FinancialRecordsTableTableManager get financialRecords =>
      $$FinancialRecordsTableTableManager(
        _db.attachedDatabase,
        _db.financialRecords,
      );
}
