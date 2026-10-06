import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../helpers/activity_test_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase database;
  late ActivityTestRepository repository;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ActivityTestRepository(database, []);
  });
  tearDown(() => database.close());

  Future<void> open(WidgetTester tester, {ActivityFilter? filter}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            initialFilter: filter ?? ActivityFilter(period: period),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'presentation never treats loans or unresolved records as wallet outflow',
    () {
      for (final subtype in [
        RecordSubtype.fulizaLoan,
        RecordSubtype.fulizaRepayment,
        RecordSubtype.loanDisbursement,
        RecordSubtype.loanRepayment,
        RecordSubtype.unknown,
      ]) {
        expect(
          TransactionPresentation.forRecord(record(subtype, 10)).amountPrefix,
          '',
        );
      }
      for (final subtype in [
        RecordSubtype.mshwariWithdrawal,
        RecordSubtype.kcbWithdrawal,
        RecordSubtype.investmentRedemption,
      ]) {
        final row = TransactionPresentation.forRecord(record(subtype, 10));
        expect(row.directionLabel, startsWith('Into M-PESA'));
        expect(row.amountPrefix, '+');
      }
      for (final subtype in [
        RecordSubtype.mshwariDeposit,
        RecordSubtype.kcbDeposit,
        RecordSubtype.investmentPurchase,
      ]) {
        final row = TransactionPresentation.forRecord(record(subtype, 10));
        expect(row.directionLabel, startsWith('From M-PESA'));
        expect(row.amountPrefix, '−');
      }
    },
  );

  testWidgets(
    'rows show principal, fee and correct direction; class chips filter',
    (tester) async {
      repository.records = [
        record(RecordSubtype.receiveMoney, 1000),
        record(RecordSubtype.sendMoney, 200, fee: 10),
        record(RecordSubtype.fulizaLoan, 613, fee: 6.13),
      ];
      await open(tester);
      expect(find.text('+KSh 1,000.00'), findsOneWidget);
      expect(find.text('−KSh 200.00'), findsOneWidget);
      expect(find.text('Fee KSh 10.00'), findsOneWidget);
      expect(find.text('KSh 613.00'), findsOneWidget);
      expect(find.text('Fee KSh 6.13'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Expenses'));
      await tester.pumpAndSettle();
      expect(repository.lastFilter!.scope, ActivityScope.expenses);
      expect(find.text('+KSh 1,000.00'), findsNothing);
      expect(find.text('−KSh 200.00'), findsOneWidget);
    },
  );

  testWidgets('empty state, error and retry are real', (tester) async {
    repository.fail = true;
    await open(tester);
    expect(find.text('Unable to load activity.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('No activity found for this period and filters.'),
      findsOneWidget,
    );
  });

  testWidgets('loading is visible while the period query is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    repository.pendingRead = gate.future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: ActivityScreen(initialFilter: ActivityFilter(period: period)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('No activity found for this period and filters.'),
      findsOneWidget,
    );
  });

  testWidgets('transfer rows fit a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repository.records = [
      record(RecordSubtype.kcbWithdrawal, 1234567.89, fee: 6.13),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financialRecordsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: ActivityScreen(
            initialFilter: ActivityFilter(
              period: period,
              scope: ActivityScope.internalTransfers,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Into M-PESA · from KCB M-PESA'), findsOneWidget);
  });

  testWidgets('paged explorer resets after refresh and filter change', (
    tester,
  ) async {
    repository.records = [
      for (var i = 0; i < 55; i++)
        record(RecordSubtype.sendMoney, i.toDouble()),
    ];
    await open(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('−KSh 54.00'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Refresh activity'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('initial typed transfer drill-down works and can clear filters', (
    tester,
  ) async {
    repository.records = [
      record(RecordSubtype.mshwariDeposit, 30),
      record(RecordSubtype.mshwariWithdrawal, 20),
      record(RecordSubtype.investmentPurchase, 10),
    ];
    await open(
      tester,
      filter: ActivityFilter(
        period: period,
        scope: ActivityScope.internalTransfers,
        direction: TransferDirection.intoCentral,
        endpoint: const AccountEndpoint(AccountType.mshwariSavings),
      ),
    );
    expect(find.text('Into M-PESA · from M-Shwari'), findsOneWidget);
    expect(find.text('−KSh 30.00'), findsNothing);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(repository.lastFilter!.scope, ActivityScope.all);
    expect(repository.lastFilter!.direction, isNull);
  });

  testWidgets('month selection queries the chosen period', (tester) async {
    repository.records = [
      record(RecordSubtype.receiveMoney, 100, date: DateTime(2026, 8)),
      record(RecordSubtype.receiveMoney, 200),
    ];
    await open(tester);
    await tester.tap(find.text('September 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('August 2026').last);
    await tester.pumpAndSettle();
    expect(
      repository.lastFilter!.period,
      FinancialPeriod.month(DateTime(2026, 8)),
    );
    expect(find.text('+KSh 100.00'), findsOneWidget);
  });
}
