import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/transaction_status.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_records.dart' as domain;
import 'package:inslate/models/party.dart';
import 'package:inslate/repositories/financial_records_repository.dart';

void main() {
  late AppDatabase database;
  late FinancialRecordsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinancialRecordsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and retrieves a FinancialRecord with Party', () async {
    const reference = 'TEST-REPO-001';

    final original = domain.FinancialRecord(
      reference: reference,
      transactionDate: DateTime(2026, 9, 14, 11, 30),
      amount: 1500.0,
      balance: 8500.0,
      type: FinancialRecordType.expense,
      subtype: RecordSubtype.sendMoney,
      status: TransactionStatus.successful,
      title: 'Sent Money',
      transactionCost: 15.0,
      rawMessage: 'Test M-PESA message',
      party: const Party(
        name: 'John Doe',
        type: PartyType.person,
        phone: '0712345678',
        account: null,
        identifier: 'PERSON-001',
      ),
    );

    await repository.save(original);

    final retrieved = await repository.getByReference(reference);

    expect(retrieved != null, true);

    expect(retrieved!.reference, original.reference);
    expect(retrieved.transactionDate, original.transactionDate);
    expect(retrieved.amount, original.amount);
    expect(retrieved.balance, original.balance);
    expect(retrieved.type, original.type);
    expect(retrieved.subtype, original.subtype);
    expect(retrieved.status, original.status);
    expect(retrieved.title, original.title);
    expect(retrieved.transactionCost, original.transactionCost);
    expect(retrieved.rawMessage, original.rawMessage);

    expect(retrieved.party != null, true);
    expect(retrieved.party!.name, 'John Doe');
    expect(retrieved.party!.type, PartyType.person);
    expect(retrieved.party!.phone, '0712345678');
    expect(retrieved.party!.identifier, 'PERSON-001');
  });
}
