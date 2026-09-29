import 'package:drift/drift.dart';

import '../core/enums/financial_record_type.dart';
import '../core/enums/party_type.dart';
import '../core/enums/record_subtype.dart';
import '../core/enums/transaction_status.dart';
import '../database/app_database.dart';
import '../models/financial_records.dart' as domain;
import '../models/party.dart';

class FinancialRecordsRepository {
  final AppDatabase database;

  FinancialRecordsRepository(this.database);

  Future<void> save(domain.FinancialRecord record) async {
    await database.financialRecordsDao.insertRecord(
      FinancialRecordsCompanion.insert(
        reference: record.reference,
        transactionDate: Value(record.transactionDate),
        amount: record.amount,
        balance: Value(record.balance),
        transactionCost: Value(record.transactionCost),
        type: record.type.name,
        subtype: record.subtype.name,
        status: record.status.name,
        title: record.title,
        rawMessage: record.rawMessage,
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
              amount: record.amount,
              balance: Value(record.balance),
              transactionCost: Value(record.transactionCost),
              type: record.type.name,
              subtype: record.subtype.name,
              status: record.status.name,
              title: record.title,
              rawMessage: record.rawMessage,
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

  Future<domain.FinancialRecord?> getByReference(String reference) async {
    final row = await database.financialRecordsDao.getRecordByReference(
      reference,
    );

    if (row == null) {
      return null;
    }

    return _toDomain(row);
  }

  Future<List<domain.FinancialRecord>> getAll() async {
    final rows = await database.financialRecordsDao.getAllRecords();

    return rows.map(_toDomain).toList();
  }

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
