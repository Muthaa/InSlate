import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/instruments/financial_instruments_screen.dart';
import 'package:inslate/screens/instruments/instrument_form_screen.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  testWidgets(
    'detected provider review and explicit registration preserve ownership and transaction links',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await tester.runAsync(
          () => FinancialRecordsRepository(db).save(
            record(
              RecordSubtype.investmentPurchase,
              100,
              party: const Party(
                name: 'Example Fund',
                type: PartyType.business,
                identifier: 'example',
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => FinancialRecordsRepository(db).save(
            record(
              RecordSubtype.investmentPurchase,
              200,
              party: const Party(
                name: 'example fund',
                type: PartyType.business,
                identifier: 'another-account',
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: FinancialInstrumentsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No active instruments'), findsOneWidget);
        await tester.tap(find.text('Accounts to review'));
        await tester.pumpAndSettle();
        expect(find.text('Example Fund'), findsOneWidget);
        expect(find.text('example fund'), findsNothing);
        expect(find.text('2 matching transactions'), findsOneWidget);
        expect(
          find.text('2 activity groups under this provider'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('detected.review.Example Fund')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Example Fund activity groups'), findsOneWidget);
        expect(find.text('1 matching transactions'), findsNWidgets(2));
        await tester.tap(find.text('No account reference reported').first);
        await tester.pumpAndSettle();
        final activity = tester.widget<ActivityScreen>(
          find.byType(ActivityScreen),
        );
        expect(activity.initialFilter!.party!.value, 'example');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('detected.register.Example Fund')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('instrument.provider')),
              )
              .controller!
              .text,
          'Example Fund',
        );
        await tester.enterText(
          find.byKey(const ValueKey('instrument.name')),
          'My investment',
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Save instrument').hitTestable(),
          200,
          scrollable: find
              .descendant(
                of: find.byType(InstrumentFormScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save instrument'));
        await tester.pumpAndSettle();
        final accounts = await tester.runAsync(
          () => db.select(db.accounts).get(),
        );
        expect(accounts!.single.isUserRegistered, isTrue);
        expect(accounts.single.institution, 'Example Fund');
        await tester.pumpAndSettle();
        expect(find.text('Instrument details'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Registered: 1 active instrument(s) with this provider/type',
          ),
          findsOneWidget,
        );
        expect(find.text('Add another instrument'), findsOneWidget);
        expect(find.text('Open registered instrument'), findsOneWidget);
        await tester.ensureVisible(find.text('Open registered instrument'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open registered instrument'));
        await tester.pumpAndSettle();
        expect(find.text('Instrument details'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        final rows = await tester.runAsync(
          () => db.select(db.financialRecords).get(),
        );
        expect(rows!.length, 2);
        expect(
          rows.every(
            (r) => r.sourceAccountId == null && r.destinationAccountId == null,
          ),
          isTrue,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(db.close);
        await tester.pump();
      }
    },
  );
}
