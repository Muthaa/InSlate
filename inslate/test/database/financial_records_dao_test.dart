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
        receivedAt: DateTime(2026, 9, 14, 10, 30),
        amount: 500.0,
        balance: const Value(4500.0),
        type: 'expense',
        subtype: 'sendMoney',
        status: 'completed',
        title: 'Sent Money',
        rawMessage: 'Test M-PESA transaction',
      ),
    );

    final records = await database.financialRecordsDao.getRecordsByReference(
      reference,
    );
    final record = records.single;

    expect(records, hasLength(1));
    expect(record.reference, reference);
    expect(record.amount, 500.0);
    expect(record.balance, 4500.0);
    expect(record.type, 'expense');
    expect(record.subtype, 'sendMoney');
    expect(record.status, 'completed');
    expect(record.title, 'Sent Money');
    expect(record.rawMessage, 'Test M-PESA transaction');
  });

  test(
    'migrates reference to a non-unique index and preserves records',
    () async {
      await database.close();
      final migratedDatabase = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (db) {
            db.execute('''
            CREATE TABLE financial_records (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              reference TEXT NOT NULL UNIQUE,
              source_message_id TEXT NULL,
              transaction_date INTEGER NULL,
              received_at INTEGER NOT NULL,
              amount REAL NOT NULL,
              balance REAL NULL,
              transaction_cost REAL NULL,
              type TEXT NOT NULL,
              subtype TEXT NOT NULL,
              status TEXT NOT NULL,
              title TEXT NOT NULL,
              raw_message TEXT NOT NULL,
              source_account_id INTEGER NULL,
              destination_account_id INTEGER NULL,
              party_name TEXT NULL,
              party_type TEXT NULL,
              party_phone TEXT NULL,
              party_account TEXT NULL,
              party_identifier TEXT NULL,
              created_at INTEGER NOT NULL DEFAULT (
                CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
              )
            );
          ''');
            db.execute('''
            CREATE TABLE raw_messages (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              source_id TEXT NOT NULL UNIQUE,
              sender TEXT NOT NULL,
              body TEXT NOT NULL,
              received_at INTEGER NOT NULL,
              created_at INTEGER NOT NULL DEFAULT (
                CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
              )
            );
          ''');
            db.execute('''
            INSERT INTO financial_records (
              reference, source_message_id, received_at, amount, type,
              subtype, status, title, raw_message
            ) VALUES (
              'MIGRATION-REF', 'SMS-EXISTING', 1790934897, 125.0,
              'expense', 'sendMoney', 'successful', 'Sent Money', 'Existing SMS'
            );
          ''');
            db.execute('''
            INSERT INTO raw_messages (
              source_id, sender, body, received_at
            ) VALUES (
              'SMS-RAW-EXISTING', 'MPESA', 'Existing raw SMS', 1790934897
            );
          ''');
            db.execute('PRAGMA user_version = 2;');
          },
        ),
      );

      try {
        final migratedRecords = await migratedDatabase.financialRecordsDao
            .getRecordsByReference('MIGRATION-REF');

        expect(migratedRecords, hasLength(1));
        expect(migratedRecords.single.sourceMessageId, 'SMS-EXISTING');
        expect(migratedRecords.single.rawMessage, 'Existing SMS');

        final migratedRawMessage = await migratedDatabase.rawMessagesDao
            .getBySourceId('SMS-RAW-EXISTING');
        expect(migratedRawMessage?.body, 'Existing raw SMS');

        await migratedDatabase.financialRecordsDao.insertRecord(
          FinancialRecordsCompanion.insert(
            reference: 'MIGRATION-REF',
            sourceMessageId: const Value('SMS-SECOND'),
            receivedAt: DateTime(2026, 10, 2),
            amount: 250.0,
            type: 'expense',
            subtype: 'sendMoney',
            status: 'successful',
            title: 'Sent Money',
            rawMessage: 'Second SMS',
          ),
        );

        final recordsWithSameReference = await migratedDatabase
            .financialRecordsDao
            .getRecordsByReference('MIGRATION-REF');

        expect(recordsWithSameReference, hasLength(2));
        expect(
          recordsWithSameReference.map((record) => record.sourceMessageId),
          containsAll(['SMS-EXISTING', 'SMS-SECOND']),
        );
      } finally {
        await migratedDatabase.close();
      }
    },
  );
}
