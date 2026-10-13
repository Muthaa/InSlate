import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/repositories/paybill_reversals_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/screens/activity/transaction_detail_screen.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/screens/profile/verified_reversals_section.dart';
import 'package:inslate/screens/insights/insights_screen.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import '../repositories/paybill_reversals_test.dart' show confirmation;

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  Future<int> seed({
    bool reverse = true,
    String reference = 'ORIGINAL01',
    String source = 'reverse',
    String reversalRef = 'REVERSAL01',
  }) async {
    final id = await db
        .into(db.financialRecords)
        .insert(
          FinancialRecordsCompanion.insert(
            reference: reference,
            receivedAt: DateTime(2026, 9, 10),
            transactionDate: Value(DateTime(2026, 9, 10)),
            amount: 1000.25,
            transactionCost: const Value(23),
            type: 'expense',
            subtype: 'payBill',
            status: 'successful',
            title: 'Synthetic PayBill',
            rawMessage: '',
          ),
        );
    await RawMessagesRepository(db).saveAll([
      confirmation(id: source, ref: reversalRef, original: reference),
    ]);
    if (reverse) await PayBillReversalsRepository(db).process([source]);
    return id;
  }

  Future<void> open(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  void ui(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pump(Duration.zero);
          await tester.runAsync(() => db.close());
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.binding.setSurfaceSize(null);
        }
      });
  ui(
    'reversal displays inherited category and navigates to original without independent editing',
    (tester) async {
      final id = await seed();
      await CategoriesRepository(
        db,
      ).assign(recordId: id, categoryId: 'builtin.expense.food');
      final reverseId = (await db.select(db.financialRecords).get()).last.id;
      await open(tester, TransactionDetailScreen(recordId: reverseId));
      expect(
        find.text('Expense reversal · principal returned'),
        findsOneWidget,
      );
      expect(find.text('Inherited from original transaction'), findsOneWidget);
      expect(find.text('Change category'), findsNothing);
      expect(find.text('Food & groceries'), findsOneWidget);
      await tester.tap(find.text('View original PayBill'));
      await tester.pumpAndSettle();
      expect(find.text('Change category'), findsOneWidget);
      await tester.ensureVisible(find.text('View principal reversal'));
      await tester.tap(find.text('View principal reversal'));
      await tester.pumpAndSettle();
      expect(find.text('Inherited from original transaction'), findsOneWidget);
    },
  );
  ui(
    'Activity retains expense filter and period after original/reversal navigation',
    (tester) async {
      await seed();
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        scope: ActivityScope.expenses,
      );
      await open(tester, ActivityScreen(initialFilter: filter));
      expect(find.textContaining('Expense reversal'), findsOneWidget);
      await tester.ensureVisible(find.text('REVERSAL01'));
      await tester.tap(find.text('REVERSAL01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View original PayBill'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.textContaining('Expense reversal'), findsOneWidget);
      expect(find.text('September 2026'), findsWidgets);
    },
  );
  ui(
    'bounded operation requires confirmation, reports actual creations and repeat duplicates',
    (tester) async {
      for (var i = 0; i < 5; i++) {
        await seed(
          reverse: false,
          reference: 'ORIGINAL0${i + 1}',
          source: 'sms$i',
          reversalRef: 'REVERSAL0${i + 1}',
        );
      }
      await open(tester, const Scaffold(body: VerifiedReversalsSection()));
      await tester.tap(find.text('Process five audited confirmations'));
      await tester.pumpAndSettle();
      expect(await db.select(db.financialRecords).get(), hasLength(5));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await db.select(db.financialRecords).get(), hasLength(5));
      await tester.tap(find.text('Process five audited confirmations'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Process five'));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 adjustments created'), findsOneWidget);
      expect(await db.select(db.financialRecords).get(), hasLength(10));
      await tester.tap(find.text('Process five audited confirmations'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Process five'));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 already stored'), findsOneWidget);
    },
  );
  ui('changed retained population is rejected without mutation', (
    tester,
  ) async {
    await seed(reverse: false);
    await open(tester, const Scaffold(body: VerifiedReversalsSection()));
    await tester.tap(find.text('Process five audited confirmations'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No changes committed'), findsOneWidget);
    expect(await db.select(db.financialRecords).get(), hasLength(1));
  });
  ui(
    'refund-only month shows a negative expense rather than income or a clamped zero',
    (tester) async {
      await seed(reverse: false);
      await (db.delete(
        db.rawMessages,
      )..where((r) => r.sourceId.equals('reverse'))).go();
      await RawMessagesRepository(db).saveAll([confirmation(date: '1/10/26')]);
      await PayBillReversalsRepository(db).process(['reverse']);
      await open(
        tester,
        InsightsScreen(
          initialPeriod: FinancialPeriod.month(DateTime(2026, 10)),
        ),
      );
      await tester.scrollUntilVisible(
        find.textContaining('Share unavailable (negative net total)'),
        200,
      );
      expect(
        find.textContaining('Share unavailable (negative net total)'),
        findsOneWidget,
      );
      expect(find.textContaining('-KSh 1,000.25'), findsWidgets);
    },
  );
}
