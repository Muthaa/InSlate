import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/presentation/financial_presentation.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/widgets/unspecified_movements_card.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  for (final incoming in [false, true]) {
    testWidgets(
      '${incoming ? 'incoming' : 'outgoing'} summary opens exact period and subtype and returns intact',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final period = FinancialPeriod.month(DateTime(2026, 9));
        try {
          await FinancialRecordsRepository(db).saveAll([
            record(RecordSubtype.instrumentPayment, 100),
            record(RecordSubtype.instrumentReceipt, 0),
          ]);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [databaseProvider.overrideWithValue(db)],
              child: MaterialApp(
                home: Scaffold(body: UnspecifiedMovementsCard(period: period)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Purpose unspecified'), findsOneWidget);
          expect(find.text(formatMoney(0)), findsOneWidget);
          expect(find.text('1 transactions'), findsNWidgets(2));
          await tester.tap(
            find.byKey(
              ValueKey('unspecified.${incoming ? 'incoming' : 'outgoing'}'),
            ),
          );
          await tester.pumpAndSettle();
          final screen = tester.widget<ActivityScreen>(
            find.byType(ActivityScreen),
          );
          expect(screen.initialFilter!.period, period);
          expect(
            screen.initialFilter!.subtype,
            incoming
                ? RecordSubtype.instrumentReceipt
                : RecordSubtype.instrumentPayment,
          );
          expect(find.text('1 transactions'), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.text('Purpose unspecified'), findsOneWidget);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await db.close();
        }
      },
    );
  }
  testWidgets('empty period explicitly reports no unspecified movements', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: UnspecifiedMovementsCard(
                period: FinancialPeriod.month(DateTime(2026, 9)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No purpose-unspecified movements in this period.'),
        findsOneWidget,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    }
  });
}
