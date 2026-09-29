import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and retrieves a RawMessage', () async {
    const sourceId = 'SMS-RAW-001';

    final message = RawMessagesCompanion.insert(
      sourceId: sourceId,
      sender: 'MPESA',
      body: 'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    await database.rawMessagesDao.insertMessage(message);

    final retrieved = await database.rawMessagesDao.getBySourceId(sourceId);

    expect(retrieved != null, true);

    expect(retrieved!.sourceId, sourceId);
    expect(retrieved.sender, 'MPESA');
    expect(
      retrieved.body,
      'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI',
    );
    expect(retrieved.receivedAt, DateTime(2026, 6, 28, 11, 47));
  });

  test('detects an existing RawMessage by source ID', () async {
    const sourceId = 'SMS-RAW-002';

    final message = RawMessagesCompanion.insert(
      sourceId: sourceId,
      sender: 'MPESA',
      body: 'Test M-PESA message',
      receivedAt: DateTime(2026, 6, 28, 12, 00),
    );

    expect(await database.rawMessagesDao.messageExists(sourceId), false);

    await database.rawMessagesDao.insertMessage(message);

    expect(await database.rawMessagesDao.messageExists(sourceId), true);
  });
}
