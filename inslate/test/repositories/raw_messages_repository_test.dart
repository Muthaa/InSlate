import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/repositories/raw_messages_repository.dart';

void main() {
  late AppDatabase database;
  late RawMessagesRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RawMessagesRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and retrieves a RawMessage', () async {
    final original = domain.RawMessage(
      id: 'SMS-REPO-001',
      sender: 'MPESA',
      body: 'UFSNY9B1NP Confirmed. Ksh300.00 sent to VIVIAN  KARANI',
      receivedAt: DateTime(2026, 6, 28, 11, 47),
    );

    await repository.save(original);

    final retrieved = await repository.getBySourceId(original.id);

    expect(retrieved != null, true);

    expect(retrieved!.id, original.id);
    expect(retrieved.sender, original.sender);
    expect(retrieved.body, original.body);
    expect(retrieved.receivedAt, original.receivedAt);
  });

  test('detects an existing RawMessage', () async {
    final message = domain.RawMessage(
      id: 'SMS-REPO-002',
      sender: 'MPESA',
      body: 'Test M-PESA message',
      receivedAt: DateTime(2026, 6, 28, 12, 00),
    );

    expect(await repository.exists(message.id), false);

    await repository.save(message);

    expect(await repository.exists(message.id), true);
  });
}
