import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/import_progress.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/screens/insights/insights_screen.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import 'package:inslate/providers/financial_records_provider.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/providers/import_provider.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/screens/app_shell.dart';
import 'package:inslate/services/financial_summary_service.dart';
import '../helpers/activity_test_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

class ShellTestImporter extends ImportNotifier {
  int listenerStarts = 0;
  int reconciliations = 0;
  @override
  ImportProgress build() => const ImportProgress(status: ImportStatus.idle);
  @override
  void startIncomingSmsListener() {
    listenerStarts++;
  }

  @override
  Future<void> catchUpNewMessages() async {
    reconciliations++;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'Activity loads lazily, retains its page and preserves resume reconciliation',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = ActivityTestRepository(database, [
        for (var i = 0; i < 55; i++)
          record(
            RecordSubtype.sendMoney,
            i.toDouble(),
            receivedAt: DateTime.now(),
          ),
      ]);
      final importer = ShellTestImporter();
      final now = DateTime.now();
      final summary = FinancialSummaryService().calculate(
        repository.records,
        period: now,
      );
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              financialRecordsRepositoryProvider.overrideWithValue(repository),
              financialSummaryProvider.overrideWith((ref) async => summary),
              availableMonthsProvider.overrideWith(
                (ref) async => {DateTime(now.year, now.month)},
              ),
              monthRangeProvider.overrideWith(
                (ref) async => (
                  start: DateTime(now.year, now.month),
                  end: DateTime(now.year, now.month + 1),
                ),
              ),
              importProvider.overrideWith(() => importer),
            ],
            child: const MaterialApp(home: AppShell()),
          ),
        );
        await tester.pumpAndSettle();
        expect(repository.activityReads, 0);
        expect(importer.listenerStarts, 1);
        expect(importer.reconciliations, 1);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.history_rounded),
          ),
        );
        await tester.pumpAndSettle();
        expect(repository.activityReads, 1);
        await tester.tap(find.byTooltip('Next page'));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.insights_outlined),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.history_rounded),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 of 2'), findsOneWidget);
        // Follow platform transitions; EditableText's lifecycle listener validates
        // the sequence now that Activity includes a search field.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(importer.reconciliations, 2);
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => database.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets('More opens instruments and preserves Categories navigation', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            importProvider.overrideWith(() => ShellTestImporter()),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.person_outline_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Budgets'), 150);
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No budgets.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      SharedPreferences.setMockInitialValues({});
      await tester.scrollUntilVisible(
        find.byTooltip('Edit local profile'),
        -200,
      );
      await tester.ensureVisible(find.byTooltip('Edit local profile'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Profile'), findsNothing);
      await tester.tap(find.byTooltip('Edit local profile'));
      await tester.pumpAndSettle();
      expect(find.text('Your local profile'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Your Data'), 150);
      await tester.tap(find.text('Your Data'));
      await tester.pumpAndSettle();
      expect(find.text('Raw SMS messages: 0'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Financial Instruments'), 150);
      await tester.tap(find.text('Financial Instruments'));
      await tester.pumpAndSettle();
      expect(find.text('No active instruments'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Financial Instruments'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Categories'), 150);
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Financial Instruments'), findsOneWidget);
    } finally {
      await tester.pump(Duration.zero);
      await tester.runAsync(() => database.close());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'Insights loads on navigation and retains its chosen period across tabs',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
              importProvider.overrideWith(ShellTestImporter.new),
            ],
            child: const MaterialApp(home: AppShell()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(InsightsScreen, skipOffstage: false), findsNothing);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.insights_outlined),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No records in this period'), findsOneWidget);
        await tester.tap(
          find.byType(DropdownButtonFormField<InsightPeriodChoice>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Previous month').last);
        await tester.pumpAndSettle();
        final now = DateTime.now();
        final previous = FinancialPeriod.month(
          DateTime(now.year, now.month - 1),
        );
        expect(find.text(periodLabel(previous)), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.person_outline_rounded),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.insights_outlined),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(periodLabel(previous)), findsOneWidget);
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => database.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'Dashboard Insights action reuses the tab and adopts Dashboard period',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(database),
              importProvider.overrideWith(ShellTestImporter.new),
            ],
            child: const MaterialApp(home: AppShell()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.insights_outlined),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byType(DropdownButtonFormField<InsightPeriodChoice>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Previous month').last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.dashboard_outlined),
          ),
        );
        await tester.pumpAndSettle();
        final dashboard = tester.element(find.byType(DashboardScreen));
        final scope = ProviderScope.containerOf(dashboard);
        final current = FinancialPeriod.month(DateTime.now());
        expect(scope.read(selectedMonthProvider), current.start);
        await tester.tap(find.byKey(const ValueKey('dashboard.insights')));
        await tester.pumpAndSettle();
        expect(
          find.byType(InsightsScreen, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2,
        );
        expect(
          Navigator.of(tester.element(find.byType(InsightsScreen))).canPop(),
          isFalse,
        );
        expect(find.text(periodLabel(current)), findsOneWidget);

        // Repeating the same Dashboard period must also replace a user-selected
        // Insights period without replacing the tab's state or pushing a route.
        await tester.tap(
          find.byType(DropdownButtonFormField<InsightPeriodChoice>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Previous month').last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(Icons.dashboard_outlined),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('dashboard.insights')));
        await tester.pumpAndSettle();
        expect(find.text(periodLabel(current)), findsOneWidget);
        expect(
          find.byType(InsightsScreen, skipOffstage: false),
          findsOneWidget,
        );
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => database.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
}
