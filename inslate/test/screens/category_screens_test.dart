import '../helpers/activity_scroll.dart';
import 'package:inslate/models/activity_cursor.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart' hide FinancialRecord;
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/transaction_category.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/screens/activity/transaction_detail_screen.dart';
import 'package:inslate/screens/categories/categories_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

class _CountingRepository extends FinancialRecordsRepository {
  int pageReads = 0;
  _CountingRepository(super.database);
  @override
  Future<List<FinancialRecord>> getActivity(
    ActivityFilter filter, {
    int? limit,
    int offset = 0,
    ActivityCursor? before,
  }) async {
    pageReads++;
    return super.getActivity(
      filter,
      limit: limit,
      offset: offset,
      before: before,
    );
  }
}

void main() {
  late AppDatabase db;
  late CategoriesRepository categories;
  late _CountingRepository records;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = CategoriesRepository(db);
    records = _CountingRepository(db);
    await categories.seedBuiltIns();
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          financialRecordsRepositoryProvider.overrideWithValue(records),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<int> save(RecordSubtype subtype) async {
    await records.save(record(subtype, 100, fee: 2));
    return (await records.getAll()).last.id!;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.1);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String name, String action) async {
    await tap(tester, find.byTooltip('Manage $name'));
    await tap(tester, find.text(action).last);
  }

  void categoryTest(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  categoryTest(
    'management creates categories in selected kind and validates names',
    (tester) async {
      await open(tester, const CategoriesScreen());
      expect(find.text('Food & groceries'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
      await tap(tester, find.text('Income'));
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food & groceries'), findsNothing);
      await tap(tester, find.text('New category'));
      await tap(tester, find.text('Save'));
      expect(find.text('Enter a category name'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Contract work');
      await tap(tester, find.text('Save'));
      expect(find.text('Contract work'), findsOneWidget);
      final custom = (await categories.getCategories(
        kind: CategoryKind.income,
      )).singleWhere((c) => c.name == 'Contract work');
      expect(custom.isBuiltIn, isFalse);
      await menu(tester, 'Contract work', 'Rename');
      await tester.enterText(find.byType(TextFormField), 'Consulting');
      await tap(tester, find.text('Save'));
      expect((await categories.getCategory(custom.id))!.name, 'Consulting');
    },
  );

  categoryTest('built-ins rename hide and unhide with no delete action', (
    tester,
  ) async {
    await open(tester, const CategoriesScreen());
    await tap(tester, find.byTooltip('Manage Food & groceries'));
    expect(find.text('Delete'), findsNothing);
    await tap(tester, find.text('Rename'));
    await tester.enterText(find.byType(TextFormField), 'Meals');
    await tap(tester, find.text('Save'));
    await menu(tester, 'Meals', 'Hide');
    expect(
      (await categories.getCategory('builtin.expense.food'))!.isHidden,
      isTrue,
    );
    await tap(tester, find.text('Hidden categories (1)'));
    await menu(tester, 'Meals', 'Unhide');
    expect(
      (await categories.getCategory('builtin.expense.food'))!.isHidden,
      isFalse,
    );
    expect(find.text('Meals'), findsOneWidget);
  });

  categoryTest(
    'custom deletion warns, cancels safely, then clears assignments only',
    (tester) async {
      final id = await save(RecordSubtype.sendMoney);
      final custom = await categories.createCustom(
        name: 'A custom expense',
        kind: CategoryKind.expense,
      );
      await categories.assign(recordId: id, categoryId: custom.id);
      await open(tester, const CategoriesScreen());
      await menu(tester, custom.name, 'Delete');
      expect(
        find.textContaining('Financial records will not be deleted.'),
        findsOneWidget,
      );
      await tap(tester, find.text('Cancel'));
      expect(await categories.getAssignment(id), isNotNull);
      await menu(tester, custom.name, 'Delete');
      await tap(tester, find.text('Delete'));
      expect(await categories.getCategory(custom.id), isNull);
      expect(await categories.getAssignment(id), isNull);
      expect(await records.getById(id), isNotNull);
    },
  );

  categoryTest('expense detail adds reassigns and clears a manual category', (
    tester,
  ) async {
    final id = await save(RecordSubtype.sendMoney);
    await open(tester, TransactionDetailScreen(recordId: id));
    await tester.ensureVisible(find.text('Uncategorized'));
    expect(find.text('Uncategorized'), findsOneWidget);
    await tap(tester, find.text('Add category'));
    expect(find.text('Salary'), findsNothing);
    await tap(tester, find.text('Food & groceries'));
    expect(
      (await categories.getAssignment(id))!.categoryId,
      'builtin.expense.food',
    );
    expect(
      (await categories.getAssignment(id))!.origin,
      CategoryAssignmentOrigin.manual,
    );
    await tap(tester, find.text('Change category'));
    await tap(tester, find.text('Bills & utilities'));
    expect(
      (await categories.getAssignment(id))!.categoryId,
      'builtin.expense.utilities',
    );
    await tap(tester, find.text('Clear category'));
    expect(
      (await categories.getAssignment(id))!.origin,
      CategoryAssignmentOrigin.manualUncategorized,
    );
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(records.pageReads, 0);
  });

  categoryTest(
    'income choices exclude expense and hidden categories; current hidden assignment remains',
    (tester) async {
      final id = await save(RecordSubtype.receiveMoney);
      await categories.assign(
        recordId: id,
        categoryId: 'builtin.income.salary',
      );
      await categories.setHidden('builtin.income.salary', true);
      await open(tester, TransactionDetailScreen(recordId: id));
      await tester.ensureVisible(find.text('Salary (hidden)'));
      expect(find.text('Salary (hidden)'), findsOneWidget);
      await tap(tester, find.text('Change category'));
      expect(find.text('Salary'), findsNothing);
      expect(find.text('Food & groceries'), findsNothing);
      await tap(tester, find.text('Business income'));
      expect(
        (await categories.getAssignment(id))!.categoryId,
        'builtin.income.business',
      );
    },
  );

  categoryTest('management edits and deletion update an already-open detail', (
    tester,
  ) async {
    final id = await save(RecordSubtype.receiveMoney);
    final custom = await categories.createCustom(
      name: 'A revenue',
      kind: CategoryKind.income,
    );
    await categories.assign(recordId: id, categoryId: custom.id);
    await open(tester, TransactionDetailScreen(recordId: id));
    await tap(tester, find.text('Change category'));
    await tap(tester, find.text('Manage categories'));
    await tap(tester, find.text('Income'));
    await menu(tester, custom.name, 'Rename');
    await tester.enterText(find.byType(TextFormField), 'A renamed revenue');
    await tap(tester, find.text('Save'));
    await menu(tester, 'A renamed revenue', 'Delete');
    await tap(tester, find.text('Delete'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Choose income category'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(await records.getById(id), isNotNull);
  });

  categoryTest('open detail observes category rename hide and deletion', (
    tester,
  ) async {
    final id = await save(RecordSubtype.sendMoney);
    final custom = await categories.createCustom(
      name: 'Original purpose',
      kind: CategoryKind.expense,
    );
    await categories.assign(recordId: id, categoryId: custom.id);
    await open(tester, TransactionDetailScreen(recordId: id));
    expect(find.text('Original purpose'), findsOneWidget);
    await categories.rename(custom.id, 'Updated purpose');
    await tester.pumpAndSettle();
    expect(find.text('Updated purpose'), findsOneWidget);
    await categories.setHidden(custom.id, true);
    await tester.pumpAndSettle();
    expect(find.text('Updated purpose (hidden)'), findsOneWidget);
    await categories.deleteCustom(custom.id);
    await tester.pumpAndSettle();
    expect(find.text('Uncategorized'), findsOneWidget);
  });

  categoryTest(
    'shared transaction reference does not share category identity',
    (tester) async {
      await records.save(record(RecordSubtype.sendMoney, 100));
      await records.save(record(RecordSubtype.sendMoney, 200));
      final stored = await records.getAll();
      final first = stored.singleWhere((r) => r.amount == 100).id!;
      final second = stored.singleWhere((r) => r.amount == 200).id!;
      await categories.assign(
        recordId: first,
        categoryId: 'builtin.expense.food',
      );
      await open(tester, TransactionDetailScreen(recordId: second));
      expect(find.text('Uncategorized'), findsOneWidget);
      await tap(tester, find.text('Add category'));
      await tap(tester, find.text('Bills & utilities'));
      expect(
        (await categories.getAssignment(first))!.categoryId,
        'builtin.expense.food',
      );
      expect(
        (await categories.getAssignment(second))!.categoryId,
        'builtin.expense.utilities',
      );
    },
  );

  categoryTest(
    'detail workflow offers only and similar and manages saved rules',
    (tester) async {
      const who = Party(
        name: 'Shop',
        type: PartyType.business,
        identifier: '123',
      );
      await records.saveAll([
        record(RecordSubtype.buyGoods, 10, party: who),
        record(RecordSubtype.buyGoods, 20, party: who),
      ]);
      final rows = await records.getAll();
      final id = rows.first.id!;
      await open(tester, TransactionDetailScreen(recordId: id));
      await tap(tester, find.text('Add category'));
      await tap(tester, find.text('Food & groceries'));
      expect(find.text('This transaction only'), findsOneWidget);
      expect(find.text('This and similar transactions'), findsOneWidget);
      await tap(tester, find.text('This transaction only'));
      expect(await db.select(db.categoryRules).get(), isEmpty);
      expect(await categories.getAssignment(rows.last.id!), isNull);
      await tap(tester, find.text('Change category'));
      await tap(tester, find.text('Bills & utilities'));
      await tap(tester, find.text('This and similar transactions'));
      expect(
        (await categories.getAssignment(rows.last.id!))!.origin,
        CategoryAssignmentOrigin.ruleDerived,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await open(tester, const CategoriesScreen());
      await tester.scrollUntilVisible(
        find.text('Automatic categorization rules'),
        300,
      );
      await tap(tester, find.text('Automatic categorization rules'));
      expect(find.byTooltip('Remove rule'), findsOneWidget);
      await tap(tester, find.byTooltip('Remove rule'));
      expect(await db.select(db.categoryRules).get(), isEmpty);
      expect(
        (await categories.getAssignment(rows.last.id!))!.categoryId,
        'builtin.expense.utilities',
      );
    },
  );

  for (final subtype in [
    RecordSubtype.fulizaLoan,
    RecordSubtype.loanRepayment,
    RecordSubtype.mshwariDeposit,
    RecordSubtype.savingsDeposit,
    RecordSubtype.savingsWithdrawal,
    RecordSubtype.investmentPurchase,
    RecordSubtype.investmentRedemption,
    RecordSubtype.unknown,
  ]) {
    categoryTest('$subtype detail cannot edit income or expense categories', (
      tester,
    ) async {
      final id = await save(subtype);
      await open(tester, TransactionDetailScreen(recordId: id));
      expect(find.text('Category'), findsNothing);
      expect(find.text('Add category'), findsNothing);
      expect(find.text('Change category'), findsNothing);
      expect(find.text('Transaction details'), findsOneWidget);
    });
  }

  categoryTest('missing persisted transaction has a clear empty state', (
    tester,
  ) async {
    await open(tester, const TransactionDetailScreen(recordId: 999));
    expect(find.text('Transaction no longer available.'), findsOneWidget);
  });

  categoryTest(
    'Activity opens persisted ID and category edits preserve page reads and filters',
    (tester) async {
      await records.saveAll(
        List.generate(
          51,
          (i) => record(
            RecordSubtype.sendMoney,
            i + 1.0,
            party: const Party(
              name: 'Shop',
              type: PartyType.business,
              identifier: 'shop',
            ),
          ),
        ),
      );
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        scope: ActivityScope.expenses,
      );
      final id = (await records.getActivity(
        filter,
        limit: 1,
        offset: 50,
      )).single.id!;
      await open(tester, ActivityScreen(initialFilter: filter));
      await scrollActivityToEnd(tester);
      final before = records.pageReads;
      await tap(
        tester,
        find.descendant(
          of: find.byKey(ValueKey('activity.record.$id')),
          matching: find.text('Shop'),
        ),
      );
      expect(find.text('Transaction details'), findsOneWidget);
      await tap(tester, find.text('Add category'));
      await tap(tester, find.text('Food & groceries'));
      await tap(tester, find.text('This and similar transactions'));
      expect(
        (await categories.getAssignment(id))!.categoryId,
        'builtin.expense.food',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(records.pageReads, before);
      expect(find.byTooltip('Next page'), findsNothing);
      expect(find.text('September 2026'), findsOneWidget);
    },
  );
}
