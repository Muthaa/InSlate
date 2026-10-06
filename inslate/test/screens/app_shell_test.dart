import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/import_progress.dart';
import 'package:inslate/providers/financial_records_provider.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/providers/import_provider.dart';
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
      addTearDown(database.close);
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
          matching: find.byIcon(Icons.receipt_long_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.activityReads, 1);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
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
          matching: find.byIcon(Icons.receipt_long_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(importer.reconciliations, 2);
    },
  );
}
