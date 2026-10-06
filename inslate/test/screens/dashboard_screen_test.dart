import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/providers/dashboard_provider.dart';
import 'package:inslate/providers/activity_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import 'package:inslate/screens/dashboard/financial_breakdown_screen.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/widgets/financial_group_row.dart';
import 'package:inslate/widgets/transaction_row.dart';
import '../helpers/activity_test_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase database;
  late ActivityTestRepository repository;
  late ProviderContainer container;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  const alice = Party(name: 'Alice', type: PartyType.person, identifier: ' A ');
  const fund = Party(name: 'Fund', type: PartyType.self, account: '123');
  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ActivityTestRepository(database, [
      record(RecordSubtype.receiveMoney, 1000, party: alice),
      record(RecordSubtype.sendMoney, 200, fee: 10, party: alice),
      record(RecordSubtype.buyGoods, 300, fee: 5),
      record(RecordSubtype.mshwariDeposit, 80, fee: 2),
      record(RecordSubtype.mshwariWithdrawal, 30),
      record(RecordSubtype.kcbWithdrawal, 20),
      record(RecordSubtype.investmentPurchase, 60, party: fund),
      record(RecordSubtype.investmentRedemption, 10, party: fund),
      record(RecordSubtype.fulizaLoan, 613, fee: 6.13),
      record(RecordSubtype.fulizaRepayment, 100),
    ]);
    container = ProviderContainer(
      overrides: [
        financialRecordsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.read(selectedMonthProvider.notifier).state = period.start;
  });
  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> open(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  ActivityFilter activityFilter(WidgetTester tester) =>
      tester.widget<ActivityScreen>(find.byType(ActivityScreen)).initialFilter!;

  testWidgets(
    'initial Dashboard load shows loading until period data arrives',
    (tester) async {
      final pending = Completer<void>();
      repository.pendingRead = pending.future;
      await open(tester, settle: false);
      await tester.pump();
      expect(find.text('Loading this period…'), findsOneWidget);
      expect(find.text('InSlate'), findsOneWidget);
      expect(find.text('Money movement'), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Money movement'), findsOneWidget);
    },
  );

  for (final refresh in [true, false]) {
    testWidgets(
      'same-period ${refresh ? 'refresh' : 'reload'} keeps Dashboard mounted',
      (tester) async {
        await open(tester);
        final selector = tester.element(find.text('InSlate'));
        final pending = Completer<void>();
        repository.pendingRead = pending.future;
        container.invalidate(periodRecordsProvider(period));
        if (refresh) container.invalidate(dashboardSummaryProvider);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        final state = container.read(dashboardSummaryProvider);
        expect(state.isLoading, isTrue);
        expect(refresh ? state.isRefreshing : state.isReloading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.element(find.text('InSlate')), same(selector));
        pending.complete();
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('reload failure surfaces an error despite previous valid data', (
    tester,
  ) async {
    await open(tester);
    repository.fail = true;
    container.read(financialDataRevisionProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('Unable to load your financial summary.'), findsOneWidget);
    expect(find.text('Money movement'), findsNothing);
  });

  testWidgets(
    'month switch does not show September principal under August selection',
    (tester) async {
      await open(tester);
      final header = tester.element(find.text('InSlate'));
      final monthRow = tester.element(find.text('Sep'));
      final movementCard = tester.element(find.text('Money movement'));
      final pending = Completer<void>();
      repository.pendingRead = pending.future;
      container.read(selectedMonthProvider.notifier).state = DateTime(2026, 8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(container.read(dashboardSummaryProvider).isLoading, isTrue);
      expect(tester.element(find.text('Money movement')), same(movementCard));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loading this period…'), findsNothing);
      expect(find.text('—'), findsWidgets);
      final receivedRow = find
          .ancestor(of: find.text('Received'), matching: find.byType(Column))
          .first;
      expect(
        find.descendant(of: receivedRow, matching: find.text('KSh 1,000.00')),
        findsNothing,
      );
      expect(tester.element(find.text('InSlate')), same(header));
      expect(tester.element(find.text('Sep')), same(monthRow));
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Money movement'), findsOneWidget);
      expect(tester.element(find.text('Money movement')), same(movementCard));
      expect(tester.element(find.text('InSlate')), same(header));
      expect(tester.element(find.text('Sep')), same(monthRow));
      expect(
        container.read(dashboardSummaryProvider).requireValue.totals.received,
        0,
      );
      final pendingYear = Completer<void>();
      repository.pendingRead = pendingYear.future;
      container.read(selectedMonthProvider.notifier).state = DateTime(2025, 9);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.element(find.text('InSlate')), same(header));
      expect(tester.element(find.text('Sep')), same(monthRow));
      expect(find.text('2025'), findsOneWidget);
      expect(tester.element(find.text('Money movement')), same(movementCard));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pendingYear.complete();
      await tester.pumpAndSettle();
      expect(tester.element(find.text('InSlate')), same(header));
      expect(find.text('Money movement'), findsOneWidget);
    },
  );

  testWidgets(
    'headline values are principal-only and historical month hides recent rows',
    (tester) async {
      await open(tester);
      expect(repository.periodReads, 1);
      expect(find.text('Into M-PESA'), findsOneWidget);
      expect(find.text('From M-PESA'), findsOneWidget);
      final expenses = find
          .ancestor(of: find.text('Expenses'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: expenses, matching: find.text('KSh 500.00')),
        findsOneWidget,
      );
      final fees = find
          .ancestor(of: find.text('Fees'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: fees, matching: find.text('KSh 23.13')),
        findsOneWidget,
      );
      final cash = find
          .ancestor(of: find.text('Net cash flow'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: cash, matching: find.text('KSh 476.87')),
        findsOneWidget,
      );
      expect(find.text('Net movement'), findsNothing);
      expect(find.byType(TransactionRow), findsNothing);
      expect(find.text('Recent activity'), findsNothing);
    },
  );

  testWidgets(
    'spending follows breakdown then subtype Activity with snapshot period',
    (tester) async {
      await open(tester);
      await tapVisible(tester, find.text('Expense categories'));
      expect(find.byType(FinancialBreakdownScreen), findsOneWidget);
      expect(find.byType(ActivityScreen), findsNothing);
      container.read(selectedMonthProvider.notifier).state = DateTime(2026, 8);
      await tester.pumpAndSettle();
      final send = find.widgetWithText(FinancialGroupRow, 'Send money');
      await tapVisible(tester, send);
      await tapVisible(tester, find.widgetWithText(FinancialGroupRow, 'Alice'));
      final filter = activityFilter(tester);
      expect(filter.period, period);
      expect(filter.scope, ActivityScope.expenses);
      expect(filter.subtype, RecordSubtype.sendMoney);
      expect(repository.lastFilter, filter);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(FinancialBreakdownScreen), findsOneWidget);
    },
  );

  for (final kind in [BreakdownKind.spending, BreakdownKind.incomeCategories]) {
    testWidgets('$kind category preview opens parties then exact Activity', (
      tester,
    ) async {
      await open(tester);
      final group = container
          .read(dashboardSummaryProvider)
          .requireValue
          .breakdown(kind)
          .groups
          .firstWhere(
            (group) =>
                group.filter.subtype ==
                (kind == BreakdownKind.spending
                    ? RecordSubtype.sendMoney
                    : RecordSubtype.receiveMoney),
          );
      expect(find.text('View spending breakdown'), findsNothing);
      await tapVisible(tester, find.byKey(ValueKey(group.filter)));
      final screen = tester.widget<FinancialBreakdownScreen>(
        find.byType(FinancialBreakdownScreen),
      );
      expect(
        screen.kind,
        kind == BreakdownKind.spending
            ? BreakdownKind.expenseParties
            : BreakdownKind.incomeParties,
      );
      expect(screen.filter.subtype, group.filter.subtype);
      expect(screen.filter.period, period);
      await tapVisible(tester, find.widgetWithText(FinancialGroupRow, 'Alice'));
      expect(activityFilter(tester).party, PartyIdentity.fromParty(alice));
      expect(activityFilter(tester).subtype, group.filter.subtype);
      expect(activityFilter(tester).period, period);
    });
  }

  for (final item in [
    (true, 'View all Expenses'),
    (false, 'View all Income'),
  ]) {
    testWidgets('${item.$2} opens parties then identity-filtered Activity', (
      tester,
    ) async {
      await open(tester);
      await tapVisible(tester, find.textContaining(item.$2));
      expect(find.byType(FinancialBreakdownScreen), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FinancialGroupRow, 'Alice'));
      final filter = activityFilter(tester);
      expect(filter.period, period);
      expect(
        filter.scope,
        item.$1 ? ActivityScope.expenses : ActivityScope.income,
      );
      expect(filter.party, PartyIdentity.fromParty(alice));
    });
  }

  testWidgets('Top Income row opens its exact Activity directly', (
    tester,
  ) async {
    await open(tester);
    final filter = container
        .read(dashboardSummaryProvider)
        .requireValue
        .breakdown(BreakdownKind.incomeParties)
        .groups
        .single
        .filter;
    await tapVisible(tester, find.byKey(ValueKey(filter)));
    expect(find.byType(FinancialBreakdownScreen), findsNothing);
    expect(activityFilter(tester), filter);
    expect(activityFilter(tester).party, PartyIdentity.fromParty(alice));
    expect(activityFilter(tester).period, period);
  });

  testWidgets('Top Expenses row opens its exact Activity directly', (
    tester,
  ) async {
    await open(tester);
    final filter = container
        .read(dashboardSummaryProvider)
        .requireValue
        .breakdown(BreakdownKind.expenseParties)
        .groups
        .singleWhere(
          (group) => group.filter.party == PartyIdentity.fromParty(alice),
        )
        .filter;
    await tapVisible(tester, find.byKey(ValueKey(filter)));
    expect(find.byType(FinancialBreakdownScreen), findsNothing);
    expect(activityFilter(tester), filter);
    expect(activityFilter(tester).scope, ActivityScope.expenses);
    expect(activityFilter(tester).party, PartyIdentity.fromParty(alice));
    expect(activityFilter(tester).period, period);
  });

  testWidgets(
    'internal movement opens family/direction grouping before Activity',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('internal-movement-link')));
      await tester.pumpAndSettle();
      expect(find.text('Into M-PESA'), findsOneWidget);
      await tapVisible(
        tester,
        find.widgetWithText(FinancialGroupRow, 'To Investments'),
      );
      final filter = activityFilter(tester);
      expect(filter.period, period);
      expect(filter.scope, ActivityScope.internalTransfers);
      expect(filter.direction, TransferDirection.fromCentral);
      expect(filter.endpoint, const AccountEndpoint(AccountType.investment));
    },
  );

  testWidgets(
    'Loans separates borrowed and repaid and drills by loan subtype',
    (tester) async {
      await open(tester);
      await tapVisible(tester, find.text('View loan breakdown'));
      expect(find.text('Borrowed'), findsOneWidget);
      for (
        var attempt = 0;
        find.text('Repaid').evaluate().isEmpty && attempt < 10;
        attempt++
      ) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -150));
        await tester.pumpAndSettle();
      }
      expect(find.text('Repaid'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.widgetWithText(FinancialGroupRow, 'Fuliza borrowing'),
      );
      final filter = activityFilter(tester);
      expect(filter.period, period);
      expect(filter.scope, ActivityScope.loans);
      expect(filter.subtype, RecordSubtype.fulizaLoan);
    },
  );

  testWidgets('Dashboard capital actions form two paired rows', (tester) async {
    await open(tester);
    final purchases = find.byKey(
      const ValueKey(BreakdownKind.investmentPurchases),
    );
    final redemptions = find.byKey(
      const ValueKey(BreakdownKind.investmentRedemptions),
    );
    final deposits = find.byKey(const ValueKey(BreakdownKind.savingsDeposits));
    final withdrawals = find.byKey(
      const ValueKey(BreakdownKind.savingsWithdrawals),
    );
    await tester.scrollUntilVisible(
      deposits,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getTopLeft(purchases).dy, tester.getTopLeft(redemptions).dy);
    expect(tester.getTopLeft(deposits).dy, tester.getTopLeft(withdrawals).dy);
    expect(
      tester.getTopLeft(redemptions).dx,
      greaterThan(tester.getTopLeft(purchases).dx),
    );
    expect(
      tester.getTopLeft(deposits).dy,
      greaterThan(tester.getTopLeft(purchases).dy),
    );
  });

  for (final kind in [
    BreakdownKind.investmentPurchases,
    BreakdownKind.investmentRedemptions,
    BreakdownKind.savingsDeposits,
    BreakdownKind.savingsWithdrawals,
  ]) {
    testWidgets(
      '$kind opens its instrument groups then exact period Activity',
      (tester) async {
        await open(tester);
        final group = container
            .read(dashboardSummaryProvider)
            .requireValue
            .breakdown(kind)
            .groups
            .first;
        await tapVisible(tester, find.byKey(ValueKey(kind)));
        final screen = tester.widget<FinancialBreakdownScreen>(
          find.byType(FinancialBreakdownScreen),
        );
        expect(screen.kind, kind);
        expect(screen.filter.period, period);
        await tapVisible(
          tester,
          find.widgetWithText(FinancialGroupRow, group.label),
        );
        expect(activityFilter(tester), group.filter);
        expect(activityFilter(tester).period, period);
      },
    );
  }

  testWidgets(
    'Savings and investments distinguish family and provider activity',
    (tester) async {
      await open(tester);
      await tapVisible(tester, find.text('View savings & investments'));
      expect(find.text('Savings'), findsOneWidget);
      for (
        var attempt = 0;
        find.text('Investments').evaluate().isEmpty && attempt < 10;
        attempt++
      ) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -150));
        await tester.pumpAndSettle();
      }
      expect(find.text('Investments'), findsOneWidget);
      await tapVisible(
        tester,
        find.widgetWithText(FinancialGroupRow, 'Fund · Invested'),
      );
      final filter = activityFilter(tester);
      expect(filter.period, period);
      expect(filter.scope, ActivityScope.investmentsAndSavings);
      expect(filter.endpoint!.type, AccountType.investment);
      expect(filter.endpoint!.identity, PartyIdentity.fromParty(fund));
      expect(filter.direction, TransferDirection.fromCentral);
    },
  );

  testWidgets(
    'current month recent preview reuses rows and opens all Activity',
    (tester) async {
      final current = FinancialPeriod.month(DateTime.now());
      container.read(selectedMonthProvider.notifier).state = current.start;
      repository.records = [
        record(
          RecordSubtype.investmentRedemption,
          25,
          receivedAt: current.start,
        ),
      ];
      await open(tester);
      await tapVisible(tester, find.text('View all activity'));
      expect(activityFilter(tester).period, current);
      expect(activityFilter(tester).scope, ActivityScope.all);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TransactionRow), findsOneWidget);
    },
  );

  testWidgets(
    'empty current month has truthful summaries and recent empty state',
    (tester) async {
      repository.records = [];
      container.read(selectedMonthProvider.notifier).state =
          FinancialPeriod.month(DateTime.now()).start;
      await open(tester);
      await tester.scrollUntilVisible(
        find.text('No activity for the current month.'),
        300,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('No activity for the current month.'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNothing);
    },
  );

  testWidgets('narrow Dashboard and breakdown layout does not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('View savings & investments'));
    expect(tester.takeException(), isNull);
  });

  for (final kind in [
    BreakdownKind.spending,
    BreakdownKind.incomeCategories,
    BreakdownKind.expenseParties,
    BreakdownKind.incomeParties,
  ]) {
    testWidgets('$kind breakdown handles narrow screens and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: FinancialBreakdownScreen(
              kind: kind,
              filter: ActivityFilter(
                period: period,
                scope:
                    kind == BreakdownKind.spending ||
                        kind == BreakdownKind.expenseParties
                    ? ActivityScope.expenses
                    : ActivityScope.income,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          kind == BreakdownKind.spending || kind == BreakdownKind.expenseParties
              ? 'Total expenses'
              : 'Total income',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          kind == BreakdownKind.expenseParties ||
                  kind == BreakdownKind.incomeParties
              ? 'Party amounts exclude fees.'
              : 'Category amounts and shares exclude fees.',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byType(FinancialGroupRow).last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final kind in [
    BreakdownKind.internalMovement,
    BreakdownKind.loans,
    BreakdownKind.investmentsAndSavings,
    BreakdownKind.investmentPurchases,
    BreakdownKind.investmentRedemptions,
    BreakdownKind.savingsDeposits,
    BreakdownKind.savingsWithdrawals,
  ]) {
    testWidgets(
      '$kind account movement layout supports narrow screens and enlarged text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: FinancialBreakdownScreen(
                kind: kind,
                filter: ActivityFilter(
                  period: period,
                  scope: kind == BreakdownKind.loans
                      ? ActivityScope.loans
                      : kind == BreakdownKind.internalMovement
                      ? ActivityScope.internalTransfers
                      : ActivityScope.investmentsAndSavings,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            kind == BreakdownKind.internalMovement
                ? 'Total internal movement'
                : kind == BreakdownKind.loans
                ? 'Total loan activity'
                : 'Total contributions & withdrawals',
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byType(FinancialGroupRow).last,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Dashboard error can retry the period query', (tester) async {
    repository.fail = true;
    await open(tester);
    expect(find.text('Unable to load your financial summary.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Expense categories'));
    expect(find.text('Expense categories'), findsOneWidget);
  });

  testWidgets(
    'breakdown retries a failed period query into a truthful empty state',
    (tester) async {
      repository.fail = true;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: FinancialBreakdownScreen(
              kind: BreakdownKind.spending,
              filter: ActivityFilter(
                period: period,
                scope: ActivityScope.expenses,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load this breakdown.'), findsOneWidget);
      repository.fail = false;
      repository.records = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No activity found for this period.'), findsOneWidget);
      expect(find.byType(FinancialGroupRow), findsNothing);
      expect(repository.periodReads, 2);
    },
  );
}
