import 'package:flutter_test/flutter_test.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:inslate/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and retrieves a financial record', () async {
    const reference = 'TEST123456';

    await database.financialRecordsDao.insertRecord(
      FinancialRecordsCompanion.insert(
        reference: reference,
        transactionDate: Value(DateTime(2026, 9, 14, 10, 30)),
        amount: 500.0,
        balance: const Value(4500.0),
        type: 'expense',
        subtype: 'sendMoney',
        status: 'completed',
        title: 'Sent Money',
        rawMessage: 'Test M-PESA transaction',
      ),
    );

    final record = await database.financialRecordsDao.getRecordByReference(
      reference,
    );

    // ignore: deprecated_member_use
    expect(record != null, true);
    expect(record!.reference, reference);
    expect(record.amount, 500.0);
    expect(record.balance, 4500.0);
    expect(record.type, 'expense');
    expect(record.subtype, 'sendMoney');
    expect(record.status, 'completed');
    expect(record.title, 'Sent Money');
    expect(record.rawMessage, 'Test M-PESA transaction');
  });
}
