import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAllAccounts() {
    return select(accounts).get();
  }

  Future<Account?> getAccountByUuid(String uuid) {
    return (select(
      accounts,
    )..where((account) => account.uuid.equals(uuid))).getSingleOrNull();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }
}
