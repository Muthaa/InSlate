import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:inslate/database/app_database.dart';
//import 'package:inslate/database/tables/accounts.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and retrieves an account', () async {
    const uuid = 'test-mpesa-wallet-001';

    await database.accountsDao.insertAccount(
      AccountsCompanion.insert(
        uuid: uuid,
        name: 'M-PESA Wallet',
        type: 'wallet',
        institution: const Value('Safaricom'),
      ),
    );

    final account = await database.accountsDao.getAccountByUuid(uuid);

    expect(account, isNotNull);
    expect(account!.uuid, uuid);
    expect(account.name, 'M-PESA Wallet');
    expect(account.type, 'wallet');
    expect(account.institution, 'Safaricom');
    expect(account.isActive, true);
  });
}
