import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inslate/core/constants/instrument_catalogue.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/screens/instruments/instrument_catalogue_screen.dart';
import 'package:inslate/screens/instruments/instrument_form_screen.dart';

void main() {
  test('consolidation preserves the exact existing SMS recognition terms', () {
    expect(InstrumentCatalogue.investmentKeywords.toSet(), {
      'money market',
      'money market fund',
      'mmf',
      'cytonn',
      'etica',
      'mali',
      'britam',
      'sanlam',
      'old mutual',
      'icea',
      'apollo',
      'ziidi',
      'ndovu',
      'suluhu',
    });
    expect(InstrumentCatalogue.investmentKeywords.length, 14);
    expect(
      InstrumentCatalogue.providers
          .singleWhere((p) => p.id == 'cic_insurance')
          .investmentKeywords,
      isEmpty,
    );
    expect(
      InstrumentCatalogue.providers
          .singleWhere((p) => p.id == 'binance')
          .investmentKeywords,
      isEmpty,
    );
  });
  test(
    'catalogue keeps products separate, exact aliases and sourced payment routes',
    () {
      expect(
        InstrumentCatalogue.providers.map((p) => p.id).toSet().length,
        InstrumentCatalogue.providers.length,
      );
      for (final entry in InstrumentCatalogue.providers) {
        for (final route in entry.routes) {
          expect(route.paybill, matches(RegExp(r'^\d+$')));
          expect(route.source, startsWith('https://'));
          expect(route.referenceDescription, isNotEmpty);
        }
      }
      expect(
        InstrumentCatalogue.providerKey(' Etica  Capital '),
        InstrumentCatalogue.providerKey('ETICA'),
      );
      expect(
        InstrumentCatalogue.providerKey('CIC Insurance'),
        isNot(InstrumentCatalogue.providerKey('CIC Asset Management')),
      );
      expect(
        InstrumentCatalogue.providerKey('Etica customer'),
        isNot(InstrumentCatalogue.providerKey('Etica')),
      );
      expect(
        InstrumentProduct.treasuryBills.type,
        InstrumentType.investmentAccount,
      );
      expect(InstrumentProduct.cryptoWallet.type, InstrumentType.other);
      final i = FinancialInstrument(
        id: 1,
        uuid: 'one',
        name: 'My fund',
        type: InstrumentType.investmentAccount,
        storedType: 'investment_account',
        provider: 'Etica',
        isActive: false,
        createdAt: DateTime(2026),
      );
      expect(
        InstrumentCatalogue.registrations(
          'Etica Capital',
          InstrumentType.investmentAccount,
          [i],
        ),
        [i],
      );
      expect(
        InstrumentCatalogue.registrations(
          'Etica',
          InstrumentType.insurancePolicy,
          [i],
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'catalogue searches providers and prefills explicit registration',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: InstrumentCatalogueScreen()),
        ),
      );
      await tester.enterText(find.byType(TextField), 'CIC Asset');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Money market funds'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CIC Asset Management').hitTestable());
      await tester.pumpAndSettle();
      final form = tester.widget<InstrumentFormScreen>(
        find.byType(InstrumentFormScreen),
      );
      expect(form.suggestedProvider, 'CIC Asset Management');
      expect(form.suggestedType, InstrumentType.investmentAccount);
      expect(form.suggestedName, 'Money market funds');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
