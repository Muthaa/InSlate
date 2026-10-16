import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/instrument_mappings_repository.dart';
import 'package:inslate/screens/instruments/instrument_mapping_screen.dart';
import 'package:inslate/screens/instruments/instrument_detail_screen.dart';
import 'package:inslate/screens/instruments/detected_providers_screen.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/core/constants/instrument_catalogue.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/party.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  testWidgets(
    'future-only account mapping requires preview and explicit confirmation',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final instrument = await FinancialInstrumentsRepository(db).create(
        name: 'Product',
        type: InstrumentType.other,
        provider: 'Provider',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: InstrumentMappingScreen(instrument: instrument),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Confirm mapping'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm mapping'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Exact customer account reference'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Exact customer account reference'),
        'ABC-1',
      );
      await tester.ensureVisible(find.text('Preview matching transactions'));
      await tester.tap(find.text('Preview matching transactions'));
      await tester.pumpAndSettle();
      expect(find.textContaining('0 matching transactions'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Confirm mapping'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm mapping'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm account mapping?'), findsOneWidget);
      expect(
        await InstrumentMappingsRepository(db).list(instrument.id),
        isEmpty,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(FilledButton, 'Confirm mapping'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (await InstrumentMappingsRepository(
          db,
        ).list(instrument.id)).single.reference,
        'abc-1',
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Remove mapping'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove mapping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        await InstrumentMappingsRepository(db).list(instrument.id),
        hasLength(1),
      );
      await tester.tap(find.byTooltip('Remove mapping'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(FilledButton, 'Remove mapping'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        await InstrumentMappingsRepository(db).list(instrument.id),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    },
  );
  testWidgets(
    'unspecified providers offer registration and accurate unspecified drill-down',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final provider = InstrumentCatalogue.providers
            .firstWhere(
              (p) =>
                  p.products.contains(InstrumentProduct.insurance) &&
                  p.investmentKeywords.isEmpty,
            )
            .name;
        await FinancialRecordsRepository(db).save(
          record(
            RecordSubtype.payBill,
            30,
            party: Party(name: provider, type: PartyType.business),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: DetectedProvidersScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(provider), findsOneWidget);
        expect(find.text('Register an instrument'), findsOneWidget);
        expect(find.text('Review activity'), findsOneWidget);
        expect(find.textContaining('Purpose unspecified.'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await db.close();
      }
    },
  );
  testWidgets(
    'detected reference is masked, purpose preview reconciles and shared references require individual review',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final instrument = await FinancialInstrumentsRepository(db).create(
          name: 'Savings pot',
          type: InstrumentType.savingsProduct,
          provider: 'Example',
        );
        await FinancialRecordsRepository(db).save(
          record(
            RecordSubtype.payBill,
            25,
            party: const Party(
              name: 'Example',
              type: PartyType.business,
              account: 'ACCOUNT12345',
            ),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: InstrumentDetailScreen(uuid: instrument.uuid),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('mapping.reference.Example.ACCOUNT12345')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.textContaining('ACCOUNT12345'), findsNothing);
        expect(find.textContaining('2345'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('mapping.reference.Example.ACCOUNT12345')),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('1 matching transactions'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('1 matching transactions'), findsOneWidget);
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<InstrumentPurpose>),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byType(DropdownButtonFormField<InstrumentPurpose>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Savings').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Preview matching transactions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preview matching transactions'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('Savings deposit'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Savings deposit'), findsOneWidget);
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Confirm mapping'),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirm mapping'),
              )
              .onPressed,
          isNull,
        );
        expect(
          await InstrumentMappingsRepository(db).list(instrument.id),
          isEmpty,
        );
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Confirm mapping'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Confirm mapping'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.widgetWithText(FilledButton, 'Confirm mapping'),
          ),
        );
        await tester.pumpAndSettle();
        final rows = await db.select(db.financialRecords).get();
        expect(rows.single.destinationAccountId, instrument.id);
        expect(rows.single.subtype, 'payBill');
        expect(rows.single.interpretedSubtype, 'registeredSavingsDeposit');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await db.close();
      }
    },
  );
}
