import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/design/slate_components.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart' show AppDatabase;
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import 'package:inslate/screens/dashboard/home_attention.dart';
import 'package:inslate/screens/dashboard/home_comparison.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/screens/instruments/detected_providers_screen.dart';
import 'package:inslate/widgets/app_dialog.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  final selected = FinancialPeriod.month(DateTime(2026, 9));
  final previous = FinancialPeriod.month(DateTime(2026, 8));
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    container.read(selectedMonthProvider.notifier).state = selected.start;
  });
  tearDown(() => container.dispose());

  void homeTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          container.dispose();
          await tester.pump(Duration.zero);
          await tester.runAsync(() => db.close());
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });
  Future<void> save(WidgetTester tester, List<FinancialRecord> records) async {
    await tester.runAsync(
      () => FinancialRecordsRepository(db).saveAll(records),
    );
  }

  Future<void> open(
    WidgetTester tester, {
    Widget child = const DashboardScreen(),
    bool dark = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      240,
      maxScrolls: 100,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    homeTest(
      '${dark ? 'dark' : 'light'} Home keeps negative cash flow and separates principal',
      (tester) async {
        await save(tester, [
          record(RecordSubtype.receiveMoney, 100, date: selected.start),
          record(RecordSubtype.sendMoney, 200, fee: 10, date: selected.start),
          record(RecordSubtype.fulizaLoan, 900, fee: 5, date: selected.start),
          record(RecordSubtype.mshwariDeposit, 50, date: selected.start),
        ]);
        await open(tester, dark: dark);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('home.netCashFlow')),
            matching: find.text('-KSh 115.00'),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Income − spending − fees. Not your account balance.'),
          findsOneWidget,
        );
        await reveal(tester, find.text('Loans'));
        expect(find.text('KSh 900.00'), findsOneWidget);
        expect(find.textContaining('Borrowing is not income'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  homeTest(
    'empty selected month offers truthful guidance without fabricated figures',
    (tester) async {
      await open(tester);
      expect(find.text('Your story starts with a record'), findsOneWidget);
      expect(find.byKey(const ValueKey('home.netCashFlow')), findsNothing);
      expect(find.text('KSh 0.00'), findsNothing);
      expect(
        find.text(
          'No financial records for this month. Choose a month with activity to see your income, spending and money movements.',
        ),
        findsOneWidget,
      );
    },
  );

  for (final size in [const Size(320, 900), const Size(1280, 1000)]) {
    homeTest('Home reflows at ${size.width} with 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await save(tester, [
        record(RecordSubtype.receiveMoney, 123456789.01, date: selected.start),
      ]);
      await open(tester, dark: true, scale: 2);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text('View all activity'));
      expect(tester.takeException(), isNull);
      final scroll = tester.getSize(find.byType(CustomScrollView).first);
      expect(scroll.width, lessThanOrEqualTo(SlateSpace.pageWidth));
    });
  }
  homeTest(
    'account attention uses discovered providers and opens existing review',
    (tester) async {
      await save(tester, [
        record(
          RecordSubtype.investmentPurchase,
          80,
          date: selected.start,
          party: const Party(
            name: 'CYTONN MONEY MARKET FUND',
            type: PartyType.self,
            account: '12345',
          ),
        ),
      ]);
      await open(tester, child: const Scaffold(body: HomeAttention()));
      expect(find.text('Accounts to review'), findsOneWidget);
      expect(find.textContaining('1 provider appears'), findsOneWidget);
      expect(
        find.textContaining('Detection does not confirm ownership.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home.reviewAccounts')));
      await tester.pumpAndSettle();
      expect(find.byType(DetectedProvidersScreen), findsOneWidget);
    },
  );
  homeTest('attention disappears when no discovered provider exists', (
    tester,
  ) async {
    await open(tester, child: const Scaffold(body: HomeAttention()));
    expect(find.text('Accounts to review'), findsNothing);
    expect(find.textContaining('provider appears'), findsNothing);
  });
  homeTest(
    'comparison needs records in both months and never invents a baseline',
    (tester) async {
      await save(tester, [
        record(RecordSubtype.receiveMoney, 100, date: selected.start),
      ]);
      await open(
        tester,
        child: Scaffold(body: HomeComparison(period: selected)),
      );
      expect(
        find.textContaining(
          'A comparison needs recorded activity in both months.',
        ),
        findsOneWidget,
      );
      expect(find.text('Previous month'), findsNothing);
    },
  );
  homeTest(
    'comparison uses existing totals and opens the preceding-month snapshot',
    (tester) async {
      await save(tester, [
        record(RecordSubtype.receiveMoney, 200, date: selected.start),
        record(RecordSubtype.buyGoods, 40, fee: 5, date: selected.start),
        record(RecordSubtype.receiveMoney, 100, date: previous.start),
        record(RecordSubtype.buyGoods, 30, fee: 2, date: previous.start),
      ]);
      await open(
        tester,
        child: Scaffold(
          body: SingleChildScrollView(child: HomeComparison(period: selected)),
        ),
      );
      expect(
        find.text('KSh 100.00 more than the previous month'),
        findsOneWidget,
      );
      expect(
        find.text('KSh 10.00 more than the previous month'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('home.comparison.income.Previous month')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ActivityScreen>(find.byType(ActivityScreen))
            .initialFilter!
            .period,
        previous,
      );
    },
  );
  homeTest(
    'cash-flow explanation is shared, dismissible and leaves data unchanged',
    (tester) async {
      await save(tester, [
        record(RecordSubtype.receiveMoney, 100, date: selected.start),
      ]);
      await open(tester);
      await tester.tap(find.byTooltip('How net cash flow is calculated'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      expect(
        find.textContaining('It excludes savings and investment transfers'),
        findsOneWidget,
      );
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('KSh 100.00'), findsWidgets);
    },
  );
  homeTest('reduced motion confirmations treat dismissal as cancellation', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                expect(SlateMotion.duration(context), Duration.zero);
                result = await showSlateConfirmation(
                  context,
                  title: 'Review action',
                  message: 'Keep the existing records?',
                  confirmLabel: 'Continue',
                );
              },
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, false);
  });

  test('financial text colors meet WCAG AA contrast on their surfaces', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
    }

    for (final p in [SlateColors.light, SlateColors.dark]) {
      for (final color in [p.ink, p.muted, p.income, p.spending, p.movement]) {
        expect(contrast(color, p.surface), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(p.attention, p.attentionSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(p.onHero, p.hero), greaterThanOrEqualTo(4.5));
    }
  });
}
