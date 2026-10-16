import 'package:drift/drift.dart' show Value;
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/services/financial_breakdown_service.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late CategoriesRepository categories;
  late FinancialRecordsRepository records;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = CategoriesRepository(db);
    records = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());

  Future<int> save(RecordSubtype subtype, {FinancialRecordType? type}) async {
    await records.save(record(subtype, 100, type: type));
    return (await db.financialRecordsDao.getAllRecords()).last.id;
  }

  test(
    'fresh schema seeds stable defaults once without assigning transactions',
    () async {
      final defaults = await categories.getCategories();
      expect(defaults, hasLength(builtInCategories.length));
      expect(
        defaults.map((category) => category.id).toSet(),
        builtInCategories.map((category) => category.id).toSet(),
      );
      expect(
        defaults.every((category) => category.isBuiltIn && !category.isHidden),
        isTrue,
      );
      expect(
        await categories.getCategories(kind: CategoryKind.income),
        isNotEmpty,
      );
      expect(
        await categories.getCategories(kind: CategoryKind.expense),
        isNotEmpty,
      );
      await categories.seedBuiltIns();
      await categories.seedBuiltIns();
      expect(await categories.getCategories(), hasLength(defaults.length));
      final id = await save(RecordSubtype.sendMoney);
      expect(await categories.getAssignment(id), isNull);
      expect((await records.getById(id))!.id, id);
    },
  );

  test(
    'built-in rename/hide persists across seeding without changing identity or links',
    () async {
      final id = await save(RecordSubtype.sendMoney);
      const categoryId = 'builtin.expense.food';
      await categories.assign(recordId: id, categoryId: categoryId);
      await categories.rename(categoryId, ' Meals ');
      await categories.setHidden(categoryId, true);
      await categories.seedBuiltIns();
      final category = (await categories.getCategory(categoryId))!;
      expect(category.name, 'Meals');
      expect(category.isHidden, isTrue);
      expect(category.isBuiltIn, isTrue);
      expect(category.kind, CategoryKind.expense);
      expect((await categories.getAssignment(id))!.categoryId, categoryId);
      expect(
        (await categories.getCategories()).any(
          (category) => category.id == categoryId,
        ),
        isFalse,
      );
      expect(
        (await categories.getCategories(
          includeHidden: true,
        )).any((category) => category.id == categoryId),
        isTrue,
      );
      await expectLater(
        categories.assign(recordId: id, categoryId: categoryId),
        throwsArgumentError,
      );
      await expectLater(
        categories.deleteCustom(categoryId),
        throwsArgumentError,
      );
      await categories.setHidden(categoryId, false);
      expect((await categories.getCategory(categoryId))!.isHidden, isFalse);
    },
  );

  test(
    'custom identities stay separate even when names match built-ins',
    () async {
      final first = await categories.createCustom(
        name: ' Salary ',
        kind: CategoryKind.income,
      );
      final second = await categories.createCustom(
        name: 'Salary',
        kind: CategoryKind.income,
      );
      expect(first.name, 'Salary');
      expect(first.isBuiltIn, isFalse);
      expect(first.id, startsWith('custom.'));
      expect(first.id, isNot(second.id));
      await categories.rename(first.id, 'Consulting');
      await categories.setHidden(first.id, true);
      expect(
        (await categories.getCategory('builtin.income.salary'))!.name,
        'Salary',
      );
      final id = await save(RecordSubtype.receiveMoney);
      await categories.assign(recordId: id, categoryId: second.id);
      await categories.deleteCustom(second.id);
      expect(await categories.getAssignment(id), isNull);
      expect(await records.getById(id), isNotNull);
      expect(await categories.getCategory(second.id), isNull);
      await expectLater(
        categories.createCustom(name: '  ', kind: CategoryKind.expense),
        throwsArgumentError,
      );
      await expectLater(categories.rename(first.id, ''), throwsArgumentError);
    },
  );

  test(
    'one assignment per row can replace/remove and preserve provenance; references can repeat',
    () async {
      final first = await save(RecordSubtype.sendMoney);
      final second = await save(RecordSubtype.sendMoney);
      await categories.assign(
        recordId: first,
        categoryId: 'builtin.expense.food',
      );
      final initial = (await categories.getAssignment(first))!;
      expect(initial.origin, CategoryAssignmentOrigin.manual);
      expect(initial.assignedAt, isA<DateTime>());
      expect(await categories.getAssignment(second), isNull);
      await categories.assign(
        recordId: first,
        categoryId: 'builtin.expense.transport',
        origin: CategoryAssignmentOrigin.ruleDerived,
      );
      expect(
        (await categories.getAssignment(first))!.origin,
        CategoryAssignmentOrigin.manual,
      );
      expect(
        (await categories.getAssignment(first))!.categoryId,
        'builtin.expense.food',
      );
      expect(await db.select(db.recordCategoryAssignments).get(), hasLength(1));
      await expectLater(
        db
            .into(db.recordCategoryAssignments)
            .insert(
              RecordCategoryAssignmentsCompanion.insert(
                financialRecordId: first,
                categoryId: Value('builtin.expense.food'),
                origin: 'manual',
              ),
            ),
        throwsException,
      );
      await categories.removeAssignment(first);
      await categories.removeAssignment(first);
      expect(
        (await categories.getAssignment(first))!.origin,
        CategoryAssignmentOrigin.manualUncategorized,
      );
      expect(await records.getAllByReference('sendMoney'), hasLength(2));
    },
  );

  test(
    'assignment requires compatible resolved income/expense; invalid requests leave prior assignment intact',
    () async {
      final expense = await save(RecordSubtype.sendMoney);
      await categories.assign(
        recordId: expense,
        categoryId: 'builtin.expense.food',
      );
      await expectLater(
        categories.assign(
          recordId: expense,
          categoryId: 'builtin.income.salary',
        ),
        throwsArgumentError,
      );
      await expectLater(
        categories.assign(recordId: expense, categoryId: 'missing'),
        throwsArgumentError,
      );
      await expectLater(
        categories.assign(recordId: 9999, categoryId: 'builtin.expense.food'),
        throwsArgumentError,
      );
      for (final subtype in [
        RecordSubtype.mshwariDeposit,
        RecordSubtype.investmentPurchase,
        RecordSubtype.loanDisbursement,
        RecordSubtype.loanRepayment,
        RecordSubtype.unknown,
      ]) {
        final id = await save(subtype);
        await expectLater(
          categories.assign(recordId: id, categoryId: 'builtin.expense.food'),
          throwsArgumentError,
        );
        expect(await categories.getAssignment(id), isNull);
      }
      final mismatched = await save(
        RecordSubtype.sendMoney,
        type: FinancialRecordType.income,
      );
      await expectLater(
        categories.assign(
          recordId: mismatched,
          categoryId: 'builtin.income.salary',
        ),
        throwsArgumentError,
      );
      expect(
        (await categories.getAssignment(expense))!.categoryId,
        'builtin.expense.food',
      );
    },
  );

  test(
    'foreign keys and checks reject dangling assignments and invalid persisted kinds/origins',
    () async {
      final id = await save(RecordSubtype.sendMoney);
      await expectLater(
        db
            .into(db.recordCategoryAssignments)
            .insert(
              RecordCategoryAssignmentsCompanion.insert(
                financialRecordId: id,
                categoryId: Value('missing'),
                origin: 'manual',
              ),
            ),
        throwsException,
      );
      await expectLater(
        db
            .into(db.recordCategoryAssignments)
            .insert(
              RecordCategoryAssignmentsCompanion.insert(
                financialRecordId: 9999,
                categoryId: Value('builtin.expense.food'),
                origin: 'manual',
              ),
            ),
        throwsException,
      );
      await expectLater(
        db
            .into(db.recordCategoryAssignments)
            .insert(
              RecordCategoryAssignmentsCompanion.insert(
                financialRecordId: id,
                categoryId: Value('builtin.expense.food'),
                origin: 'invalid',
              ),
            ),
        throwsException,
      );
      await expectLater(
        db
            .into(db.transactionCategories)
            .insert(
              TransactionCategoriesCompanion.insert(
                id: 'invalid',
                displayName: 'Invalid',
                kind: 'loan',
              ),
            ),
        throwsException,
      );
      await categories.assign(recordId: id, categoryId: 'builtin.expense.food');
      await (db.delete(
        db.financialRecords,
      )..where((row) => row.id.equals(id))).go();
      expect(await categories.getAssignment(id), isNull);
      expect(await categories.getCategory('builtin.expense.food'), isNotNull);
    },
  );

  test(
    'category operations never alter record fields, existing financial meaning or breakdown totals',
    () async {
      await records.saveAll([
        record(RecordSubtype.receiveMoney, 1000),
        record(RecordSubtype.sendMoney, 200, fee: 10),
        record(RecordSubtype.mshwariDeposit, 80),
        record(RecordSubtype.loanDisbursement, 300),
      ]);
      final rowsBefore = await db.financialRecordsDao.getAllRecords();
      final period = FinancialPeriod.month(DateTime(2026, 9));
      final before = const FinancialBreakdownService().dashboard(
        await records.getAll(),
        period,
      );
      await categories.assign(
        recordId: rowsBefore[0].id,
        categoryId: 'builtin.income.salary',
      );
      await categories.assign(
        recordId: rowsBefore[1].id,
        categoryId: 'builtin.expense.food',
      );
      await categories.rename('builtin.expense.food', 'Lunch');
      await categories.setHidden('builtin.expense.food', true);
      final rowsAfter = await db.financialRecordsDao.getAllRecords();
      expect(
        rowsAfter.map((row) => row.toJson()).toList(),
        rowsBefore.map((row) => row.toJson()).toList(),
      );
      final after = const FinancialBreakdownService().dashboard(
        await records.getAll(),
        period,
      );
      expect(after.totals.income, before.totals.income);
      expect(after.totals.expenses, before.totals.expenses);
      expect(after.totals.fees, before.totals.fees);
      expect(after.totals.netCashFlow, before.totals.netCashFlow);
      expect(after.totals.received, before.totals.received);
      expect(after.totals.sent, before.totals.sent);
      expect(after.totals.borrowed, before.totals.borrowed);
      expect(after.totals.internalTransfers, before.totals.internalTransfers);
      for (final kind in BreakdownKind.values) {
        expect(after.breakdown(kind).amount, before.breakdown(kind).amount);
        expect(after.breakdown(kind).count, before.breakdown(kind).count);
      }
      expect(
        const FinancialSemantics().classify(
          (await records.getById(rowsBefore[1].id))!,
        ),
        MovementClass.expense,
      );
    },
  );

  test(
    'v4 migration preserves records/raw messages/IDs and creates only unassigned category foundation',
    () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'inslate_category_migration_',
      );
      final file = File('${directory.path}/migration.db');
      db = AppDatabase.forTesting(NativeDatabase(file));
      records = FinancialRecordsRepository(db);
      await records.saveAll([
        record(RecordSubtype.sendMoney, 80),
        record(RecordSubtype.loanRepayment, 20),
      ]);
      await db.rawMessagesDao.insertMessage(
        RawMessagesCompanion.insert(
          sourceId: 'old-sms',
          sender: 'MPESA',
          body: 'Existing raw message',
          receivedAt: DateTime(2026, 9),
        ),
      );
      final oldRecords = (await db.financialRecordsDao.getAllRecords())
          .map((row) => row.toJson())
          .toList();
      final oldRaw = (await db.rawMessagesDao.getAllMessages())
          .map((row) => row.toJson())
          .toList();
      // The remaining tables are exactly the unchanged v4 schema.
      await db.customStatement('DROP TABLE budgets');
      await db.customStatement('DROP TABLE record_category_assignments');
      await db.customStatement('DROP TABLE category_rules');
      await db.customStatement('DROP TABLE transaction_categories');
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
      await db.customStatement('PRAGMA user_version = 4');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      categories = CategoriesRepository(db);
      records = FinancialRecordsRepository(db);
      try {
        expect(
          await categories.getCategories(),
          hasLength(builtInCategories.length),
        );
        expect(
          (await db.financialRecordsDao.getAllRecords())
              .map((row) => row.toJson())
              .toList(),
          oldRecords,
        );
        expect(
          (await db.rawMessagesDao.getAllMessages())
              .map((row) => row.toJson())
              .toList(),
          oldRaw,
        );
        expect(await db.select(db.recordCategoryAssignments).get(), isEmpty);
        final id = (await records.getAll()).first.id!;
        await categories.assign(
          recordId: id,
          categoryId: 'builtin.expense.food',
        );
        await categories.rename('builtin.expense.food', 'Meals');
        await categories.setHidden('builtin.expense.food', true);
        final custom = await categories.createCustom(
          name: 'Travel',
          kind: CategoryKind.expense,
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        categories = CategoriesRepository(db);
        expect(
          (await categories.getCategory('builtin.expense.food'))!.name,
          'Meals',
        );
        expect(
          (await categories.getCategory('builtin.expense.food'))!.isHidden,
          isTrue,
        );
        expect(await categories.getCategory(custom.id), isNotNull);
        expect(
          (await categories.getAssignment(id))!.origin,
          CategoryAssignmentOrigin.manual,
        );
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          11,
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        await directory.delete(recursive: true);
      }
    },
  );
}
