import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/historical_balance_extraction.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/balance_evidence_provider.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/screens/instruments/sms_balance_observations_screen.dart';

class _GatedRepository extends BalanceEvidenceRepository {
  Completer<void>? gate;
  final entered = Completer<void>();
  _GatedRepository(super.database);
  @override
  Future<HistoricalBalanceCheckpoint> historicalExtractionBatch(
    HistoricalBalanceCheckpoint checkpoint,
  ) async {
    if (!entered.isCompleted) entered.complete();
    await gate?.future;
    return super.historicalExtractionBatch(checkpoint);
  }
}

void main() {
  late AppDatabase db;
  late _GatedRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _GatedRepository(db);
  });
  void testUi(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => db.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  Future<void> seed(int count) => RawMessagesRepository(db).saveAll(
    List.generate(
      count,
      (i) => domain.RawMessage(
        id: 'history-$i',
        sender: 'MPESA',
        body: 'New M-PESA balance is Ksh0.00.',
        receivedAt: DateTime.utc(2026, 6, 1),
      ),
    ),
  );
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          balanceEvidenceRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: SmsBalanceObservationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testUi(
    'user confirmation starts history extraction and completion shows actual reconciliation',
    (tester) async {
      await seed(2);
      await open(tester);
      expect(await db.select(db.balanceEvidence).get(), isEmpty);
      await tester.tap(find.byKey(const ValueKey('sms.history.extract')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await db.select(db.balanceEvidence).get(), isEmpty);
      await tester.tap(find.byKey(const ValueKey('sms.history.extract')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Extract'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Extraction complete: 2 messages scanned; 2 observations created; 0 already existing; 0 unsupported/ambiguous',
        ),
        findsOneWidget,
      );
      expect(find.text('2 SMS observations'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sms.history.extract')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Extract'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          '2 messages scanned; 0 observations created; 2 already existing',
        ),
        findsOneWidget,
      );
    },
  );
  testUi(
    'cancellation stops after committed batch and resume completes the bounded run',
    (tester) async {
      await seed(201);
      repo.gate = Completer<void>();
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('sms.history.extract')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Extract'));
      await tester.pump();
      await tester.runAsync(() => repo.entered.future);
      await tester.pump();
      expect(find.text('Processing stored SMS?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sms.history.cancel')));
      await tester.pump();
      expect(find.text('Stopping after this batch?'), findsOneWidget);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Extraction paused: 200 messages scanned; 200 observations created',
        ),
        findsOneWidget,
      );
      expect(find.text('Resume historical extraction'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sms.history.extract')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Extraction complete: 201 messages scanned; 201 observations created',
        ),
        findsOneWidget,
      );
      expect(await db.select(db.balanceEvidence).get(), hasLength(201));
    },
  );
}
