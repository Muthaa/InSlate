import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late CategoriesRepository categories;
  late FinancialRecordsRepository records;
  const food = 'builtin.expense.food';
  const transport = 'builtin.expense.transport';
  const party = Party(
    name: 'Shop',
    type: PartyType.business,
    identifier: ' STORE ',
    phone: '123',
    account: '456',
  );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = CategoriesRepository(db);
    records = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());
  Future<int> save({
    Party? who = party,
    RecordSubtype subtype = RecordSubtype.buyGoods,
  }) async {
    await records.save(record(subtype, 100, party: who));
    return (await (db.select(db.financialRecords)
              ..orderBy([(r) => OrderingTerm.desc(r.id)])
              ..limit(1))
            .getSingle())
        .id;
  }

  test(
    'transaction only creates no rule; similar applies historical and future, idempotently',
    () async {
      final first = await save();
      final second = await save();
      await categories.assign(recordId: first, categoryId: food);
      expect(await db.select(db.categoryRules).get(), isEmpty);
      expect(await categories.getAssignment(second), isNull);
      await categories.assignSimilar(recordId: first, categoryId: food);
      final derived = (await categories.getAssignment(second))!;
      expect(derived.origin, CategoryAssignmentOrigin.ruleDerived);
      expect(derived.ruleId, isNotNull);
      expect(
        (await categories.getAssignment(first))!.origin,
        CategoryAssignmentOrigin.manual,
      );
      await categories.applyRules();
      expect(
        (await categories.getAssignment(second))!.assignedAt,
        derived.assignedAt,
      );
      final third = await save();
      expect((await categories.getAssignment(third))!.categoryId, food);
      await records.saveAll([
        record(RecordSubtype.buyGoods, 50, party: party),
        record(RecordSubtype.receiveMoney, 50, party: party),
      ]);
      final rows = await db.financialRecordsDao.getAllRecords();
      expect((await categories.getAssignment(rows[3].id))!.categoryId, food);
      expect(await categories.getAssignment(rows[4].id), isNull);
    },
  );
  test('manual and explicit uncategorized override rule updates', () async {
    final first = await save();
    final manual = await save();
    final cleared = await save();
    await categories.assign(recordId: manual, categoryId: transport);
    await categories.assignSimilar(recordId: first, categoryId: food);
    await categories.removeAssignment(cleared);
    await categories.assignSimilar(recordId: first, categoryId: transport);
    expect(await db.select(db.categoryRules).get(), hasLength(1));
    expect((await categories.getAssignment(manual))!.categoryId, transport);
    final override = (await categories.getAssignment(cleared))!;
    expect(override.categoryId, isNull);
    expect(override.origin, CategoryAssignmentOrigin.manualUncategorized);
    await categories.applyRules();
    expect((await categories.getAssignment(cleared))!.categoryId, isNull);
    await categories.assign(recordId: cleared, categoryId: food);
    await categories.applyRules();
    expect((await categories.getAssignment(cleared))!.categoryId, food);
  });
  test(
    'strongest shared identity wins with exact normalization and kind separation',
    () async {
      final first = await save();
      await categories.assignSimilar(recordId: first, categoryId: food);
      final same = await save(
        who: const Party(
          name: 'Renamed',
          type: PartyType.person,
          identifier: 'store',
          phone: '999',
        ),
      );
      expect((await categories.getAssignment(same))!.categoryId, food);
      final weaker = await save(
        who: const Party(name: 'Shop', type: PartyType.business, phone: '123'),
      );
      expect(await categories.getAssignment(weaker), isNull);
      final different = await save(
        who: const Party(
          name: 'Shop',
          type: PartyType.business,
          identifier: 'other',
          phone: '123',
        ),
      );
      expect(await categories.getAssignment(different), isNull);
      final income = await save(subtype: RecordSubtype.receiveMoney);
      expect(await categories.getAssignment(income), isNull);
      await expectLater(
        categories.assignSimilar(recordId: income, categoryId: food),
        throwsArgumentError,
      );
      await categories.assignSimilar(
        recordId: income,
        categoryId: 'builtin.income.salary',
      );
      expect(await db.select(db.categoryRules).get(), hasLength(2));
    },
  );
  test(
    'phone and account rules use shared policy; name or absent party is insufficient',
    () async {
      for (final who in [
        const Party(name: 'A', type: PartyType.person, phone: ' 123 '),
        const Party(name: 'B', type: PartyType.business, account: ' ACCOUNT '),
      ]) {
        final first = await save(who: who);
        await categories.assignSimilar(recordId: first, categoryId: food);
        expect(
          (await categories.getAssignment(await save(who: who)))!.categoryId,
          food,
        );
      }
      for (final who in [
        null,
        const Party(name: 'Shop', type: PartyType.business),
        const Party(name: '', type: PartyType.person, identifier: ' '),
      ]) {
        final id = await save(who: who);
        await expectLater(
          categories.assignSimilar(recordId: id, categoryId: food),
          throwsArgumentError,
        );
        expect(await categories.getAssignment(id), isNull);
      }
    },
  );
  test(
    'hidden categories keep existing assignments and reject new rule matches',
    () async {
      final first = await save();
      await categories.assignSimilar(recordId: first, categoryId: food);
      final existing = await save();
      await categories.setHidden(food, true);
      expect((await categories.getAssignment(existing))!.categoryId, food);
      expect(await categories.getAssignment(await save()), isNull);
      await expectLater(
        categories.assignSimilar(recordId: first, categoryId: food),
        throwsArgumentError,
      );
    },
  );
  test(
    'rule deletion keeps financial records and assignments but stops future matching',
    () async {
      final first = await save();
      await categories.assignSimilar(recordId: first, categoryId: food);
      final second = await save();
      final rule = (await db.select(db.categoryRules).get()).single;
      await categories.deleteRule(rule.id);
      expect(
        (await categories.getAssignment(second))!.origin,
        CategoryAssignmentOrigin.ruleDerived,
      );
      expect((await categories.getAssignment(second))!.ruleId, isNull);
      expect(
        (await categories.getAssignment(first))!.origin,
        CategoryAssignmentOrigin.manual,
      );
      expect(await categories.getAssignment(await save()), isNull);
      expect(await records.getById(second), isNotNull);
    },
  );
  test(
    'custom category deletion cascades rules and assignments only',
    () async {
      final custom = await categories.createCustom(
        name: 'Shop',
        kind: CategoryKind.expense,
      );
      final first = await save();
      await categories.assignSimilar(recordId: first, categoryId: custom.id);
      final second = await save();
      await categories.deleteCustom(custom.id);
      expect(await db.select(db.categoryRules).get(), isEmpty);
      expect(await categories.getAssignment(first), isNull);
      expect(await categories.getAssignment(second), isNull);
      expect(await records.getById(second), isNotNull);
    },
  );
  test(
    'historical application crosses bounded pages without touching manual overrides',
    () async {
      await records.saveAll(
        List.generate(
          601,
          (_) => record(RecordSubtype.buyGoods, 10, party: party),
        ),
      );
      final rows = await db.financialRecordsDao.getAllRecords();
      await categories.assign(recordId: rows[300].id, categoryId: transport);
      await categories.removeAssignment(rows[500].id);
      await categories.assignSimilar(recordId: rows.first.id, categoryId: food);
      final assignments = await db.select(db.recordCategoryAssignments).get();
      expect(assignments, hasLength(601));
      expect(
        assignments.where((a) => a.origin == 'ruleDerived'),
        hasLength(598),
      );
      expect(
        (await categories.getAssignment(rows[300].id))!.categoryId,
        transport,
      );
      expect(
        (await categories.getAssignment(rows[500].id))!.categoryId,
        isNull,
      );
    },
  );
  test(
    'v5 migration preserves manual and rule-derived assignments and financial rows',
    () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'inslate_rules_migration_',
      );
      final file = File('${directory.path}/migration.db');
      db = AppDatabase.forTesting(NativeDatabase(file));
      records = FinancialRecordsRepository(db);
      categories = CategoriesRepository(db);
      final first = await save();
      final second = await save();
      await categories.assign(recordId: first, categoryId: food);
      await categories.assign(
        recordId: second,
        categoryId: transport,
        origin: CategoryAssignmentOrigin.ruleDerived,
      );
      final before = (await db.financialRecordsDao.getAllRecords())
          .map((r) => r.toJson())
          .toList();
      // Remove every later-phase table before simulating a genuine v5 DB.
      await db.customStatement('DROP TABLE budgets');
      await db.customStatement(
        'ALTER TABLE record_category_assignments RENAME TO old_assignments',
      );
      await db.customStatement(
        "CREATE TABLE record_category_assignments (financial_record_id INTEGER NOT NULL PRIMARY KEY REFERENCES financial_records(id) ON DELETE CASCADE, category_id TEXT NOT NULL REFERENCES transaction_categories(id) ON DELETE CASCADE, origin TEXT NOT NULL CHECK (origin IN ('manual', 'ruleDerived')), assigned_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))) WITHOUT ROWID",
      );
      await db.customStatement(
        'INSERT INTO record_category_assignments SELECT financial_record_id, category_id, origin, assigned_at FROM old_assignments',
      );
      await db.customStatement('DROP TABLE old_assignments');
      await db.customStatement('DROP TABLE category_rules');
      await db.customStatement(
        'ALTER TABLE accounts DROP COLUMN is_user_registered',
      );
      await db.customStatement('ALTER TABLE accounts DROP COLUMN identifiers');
      await db.customStatement('DROP TABLE balance_evidence');
      await db.customStatement('DROP INDEX financial_reversal_original_idx');
      await db.customStatement('DROP INDEX financial_reversal_reference_idx');
      await db.customStatement(
        'ALTER TABLE financial_records DROP COLUMN reverses_record_id',
      );
      await db.customStatement('DROP TABLE instrument_mappings');
      await db.customStatement(
        'ALTER TABLE financial_records DROP COLUMN interpreted_type',
      );
      await db.customStatement(
        'ALTER TABLE financial_records DROP COLUMN interpreted_subtype',
      );
      await db.customStatement(
        'ALTER TABLE financial_records DROP COLUMN interpretation_mapping_id',
      );
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      categories = CategoriesRepository(db);
      records = FinancialRecordsRepository(db);
      try {
        expect(
          (await categories.getAssignment(first))!.origin,
          CategoryAssignmentOrigin.manual,
        );
        expect(
          (await categories.getAssignment(second))!.origin,
          CategoryAssignmentOrigin.ruleDerived,
        );
        expect(
          (await db.financialRecordsDao.getAllRecords())
              .map((r) => r.toJson())
              .toList(),
          before,
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        await categories.removeAssignment(second);
        expect((await categories.getAssignment(second))!.categoryId, isNull);
        await categories.assignSimilar(recordId: first, categoryId: food);
        expect(
          (await categories.getAssignment(await save()))!.categoryId,
          food,
        );
      } finally {
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        await directory.delete(recursive: true);
      }
    },
  );
}
