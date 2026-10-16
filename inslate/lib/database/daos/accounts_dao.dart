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

  SimpleSelectStatement<$AccountsTable, Account> _registeredQuery(
    bool includeArchived,
  ) {
    final query = select(accounts)
      ..where((a) => a.isUserRegistered.equals(true));
    if (!includeArchived) query.where((a) => a.isActive.equals(true));
    return query..orderBy([
      (a) => OrderingTerm.asc(a.name),
      (a) => OrderingTerm.asc(a.id),
    ]);
  }

  Future<List<Account>> getRegistered({bool includeArchived = false}) =>
      _registeredQuery(includeArchived).get();
  Stream<List<Account>> watchRegistered({bool includeArchived = false}) =>
      _registeredQuery(includeArchived).watch();

  Future<Account?> getRegisteredByUuid(String uuid) =>
      (select(accounts)..where(
            (a) => a.uuid.equals(uuid) & a.isUserRegistered.equals(true),
          ))
          .getSingleOrNull();
  Future<Account?> getRegisteredById(int id) =>
      (select(accounts)
            ..where((a) => a.id.equals(id) & a.isUserRegistered.equals(true)))
          .getSingleOrNull();
  Future<int> updateRegistered(String uuid, AccountsCompanion changes) =>
      (update(accounts)..where(
            (a) => a.uuid.equals(uuid) & a.isUserRegistered.equals(true),
          ))
          .write(changes);
}
