import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialRecordsRepository records;
  late CategoriesRepository categories;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  const food = ActivityCategoryFilter.category('builtin.expense.food');
  const uncategorized = ActivityCategoryFilter.uncategorized();
  const alice = Party(
    name: 'Alice',
    type: PartyType.person,
    identifier: ' ID ',
  );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    records = FinancialRecordsRepository(db);
    categories = CategoriesRepository(db);
  });
  tearDown(() => db.close());
  Future<List<int>> seed() async {
    await records.saveAll([
      record(RecordSubtype.sendMoney, 1, party: alice),
      record(RecordSubtype.sendMoney, 2, party: alice),
      record(RecordSubtype.sendMoney, 3),
      record(RecordSubtype.receiveMoney, 4, party: alice),
      record(RecordSubtype.mshwariDeposit, 5, party: alice),
      record(RecordSubtype.unknown, 6),
      record(RecordSubtype.sendMoney, 7, date: DateTime(2026, 8), party: alice),
    ]);
    final ids = (await db.financialRecordsDao.getAllRecords())
        .map((r) => r.id)
        .toList();
    await categories.assign(recordId: ids[0], categoryId: food.categoryId!);
    await categories.assign(
      recordId: ids[1],
      categoryId: food.categoryId!,
      origin: CategoryAssignmentOrigin.ruleDerived,
    );
    await categories.removeAssignment(ids[2]);
    await categories.assign(
      recordId: ids[3],
      categoryId: 'builtin.income.salary',
    );
    await categories.assign(recordId: ids[6], categoryId: food.categoryId!);
    return ids;
  }

  test('typed category participates in equality and every filter copy', () {
    final f = ActivityFilter(period: period, category: food);
    expect(
      f,
      ActivityFilter(
        period: period,
        category: const ActivityCategoryFilter.category('builtin.expense.food'),
      ),
    );
    expect(f.hashCode, ActivityFilter(period: period, category: food).hashCode);
    expect(f, isNot(f.withCategory(null)));
    expect(f.withCategory(uncategorized), isNot(f.withCategory(null)));
    expect(f.withScope(ActivityScope.expenses).category, food);
    expect(f.withSearch('Alice').category, food);
    expect(
      f.withPeriod(FinancialPeriod.month(DateTime(2026, 8))).category,
      food,
    );
    expect(f.copyWith(subtype: RecordSubtype.sendMoney).category, food);
  });
  test(
    'manual and automatic category matches compose with period search and scope',
    () async {
      await seed();
      final f = ActivityFilter(
        period: period,
        category: food,
        scope: ActivityScope.expenses,
        search: 'alice',
        subtype: RecordSubtype.sendMoney,
        partyPresence: PartyPresence.identified,
        resolution: SemanticResolution.resolved,
      );
      expect(await records.countActivity(f), 2);
      expect(await records.getActivity(f, limit: 50), hasLength(2));
      expect(await records.countActivity(f.withScope(ActivityScope.income)), 0);
      expect(
        await records.countActivity(
          ActivityFilter(
            period: period,
            scope: ActivityScope.income,
            search: 'alice',
            category: const ActivityCategoryFilter.category(
              'builtin.income.salary',
            ),
          ),
        ),
        1,
      );
      expect(await records.countActivity(f.withSearch('absent')), 0);
      expect(
        await records.countActivity(
          f.withPeriod(FinancialPeriod.month(DateTime(2026, 8))).withSearch(''),
        ),
        1,
      );
    },
  );
  test(
    'uncategorized includes missing and explicit overrides across semantics',
    () async {
      final ids = await seed();
      final f = ActivityFilter(period: period, category: uncategorized);
      expect((await records.getActivity(f)).map((r) => r.id).toSet(), {
        ids[2],
        ids[4],
        ids[5],
      });
      expect(await records.countActivity(f), 3);
      expect(
        await records.countActivity(f.withScope(ActivityScope.expenses)),
        1,
      );
      expect(
        await records.countActivity(
          f.withScope(ActivityScope.internalTransfers),
        ),
        1,
      );
      expect(
        await records.countActivity(
          f.copyWith(resolution: SemanticResolution.unresolved),
        ),
        1,
      );
    },
  );
  test(
    'identity-qualified candidate batches retain category SQL before count and pagination',
    () async {
      await seed();
      final f = ActivityFilter(
        period: period,
        category: food,
        party: PartyIdentity.fromParty(alice),
      );
      expect(await records.countActivity(f), 2);
      expect(await records.getActivity(f, limit: 1, offset: 1), hasLength(1));
      expect(await records.getActivity(f, limit: 1, offset: 2), isEmpty);
      final endpoint = ActivityFilter(
        period: period,
        category: uncategorized,
        scope: ActivityScope.internalTransfers,
        endpoint: AccountEndpoint(
          AccountType.mshwariSavings,
          identity: PartyIdentity.fromParty(alice),
        ),
        direction: TransferDirection.fromCentral,
      );
      expect(await records.countActivity(endpoint), 1);
      expect(await records.getActivity(endpoint), hasLength(1));
      expect(
        await records.countActivity(
          endpoint.copyWith(direction: TransferDirection.intoCentral),
        ),
        0,
      );
    },
  );
  test(
    'hidden assignments stay filterable; deleted or invalid IDs return exact zero',
    () async {
      final ids = await seed();
      await categories.setHidden(food.categoryId!, true);
      expect(
        await records.countActivity(
          ActivityFilter(period: period, category: food),
        ),
        2,
      );
      final custom = await categories.createCustom(
        name: 'Custom',
        kind: CategoryKind.expense,
      );
      await categories.assign(recordId: ids[0], categoryId: custom.id);
      final f = ActivityFilter(
        period: period,
        category: ActivityCategoryFilter.category(custom.id),
      );
      expect(await records.countActivity(f), 1);
      await categories.deleteCustom(custom.id);
      expect(await records.countActivity(f), 0);
      expect(await records.getActivity(f), isEmpty);
      expect(
        await records.countActivity(
          ActivityFilter(
            period: period,
            category: const ActivityCategoryFilter.category('invalid'),
          ),
        ),
        0,
      );
      expect(
        await records.countActivity(
          ActivityFilter(period: period, category: uncategorized),
        ),
        4,
      );
    },
  );
  test(
    'category predicate precedes exact counts and 50-row pagination',
    () async {
      await records.saveAll(
        List.generate(
          121,
          (i) => record(RecordSubtype.sendMoney, i.toDouble(), party: alice),
        ),
      );
      final rows = await db.financialRecordsDao.getAllRecords();
      await db.batch(
        (b) => b.insertAll(db.recordCategoryAssignments, [
          for (final r in rows.take(61))
            RecordCategoryAssignmentsCompanion.insert(
              financialRecordId: r.id,
              categoryId: Value(food.categoryId),
              origin: 'manual',
            ),
        ]),
      );
      final f = ActivityFilter(period: period, category: food, search: 'alice');
      expect(await records.countActivity(f), 61);
      final first = await records.getActivity(f, limit: 50);
      final second = await records.getActivity(f, limit: 50, offset: 50);
      expect(first, hasLength(50));
      expect(second, hasLength(11));
      expect({
        ...first.map((r) => r.id),
        ...second.map((r) => r.id),
      }, hasLength(61));
      await categories.removeAssignment(rows.first.id);
      expect(await records.countActivity(f), 60);
    },
  );
}
