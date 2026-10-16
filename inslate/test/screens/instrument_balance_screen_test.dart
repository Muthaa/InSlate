import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/balance_evidence_provider.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/screens/instruments/instrument_detail_screen.dart';

class _Repository extends BalanceEvidenceRepository {
  bool fail = false;
  _Repository(super.database);
  @override
  Future<BalanceObservation> createManual({
    required int accountId,
    required String amount,
    required String currency,
    required BalanceKind kind,
    required DateTime asOf,
    subjectFamily,
  }) {
    if (fail) throw Exception('storage failure');
    return super.createManual(
      accountId: accountId,
      amount: amount,
      currency: currency,
      kind: kind,
      asOf: asOf,
      subjectFamily: subjectFamily,
    );
  }
}

void main() {
  late AppDatabase db;
  late _Repository repo;
  late FinancialInstrument instrument;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _Repository(db);
    instrument = await FinancialInstrumentsRepository(
      db,
    ).create(name: 'Wallet', type: InstrumentType.mobileWallet);
  });
  tearDown(() => db.close());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          balanceEvidenceRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: InstrumentDetailScreen(uuid: instrument.uuid)),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('balance.record'));
    if (button.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        button,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await Scrollable.ensureVisible(tester.element(button));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester,
    String amount, {
    String date = '2025-01-02 03:04',
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('balance.amount')),
      amount,
    );
    await tester.enterText(find.byKey(const ValueKey('balance.asOf')), date);
    await tap(tester, find.text('Save observation'));
  }

  void screenTest(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });
  screenTest(
    'empty state, creation and known zero refresh latest and dated history',
    (tester) async {
      await open(tester);
      expect(find.text('No balance observations recorded.'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('balance.record')));
      await fill(tester, '0');
      expect(
        find.byKey(const ValueKey('balance.latest.amount')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('balance.latest.amount')))
            .data,
        '0.00 KES',
      );
      expect(find.text('Manually recorded'), findsNWidgets(2));
      expect(find.text('1 observation'), findsOneWidget);
      expect((await repo.latest(instrument.id))!.amountMinor, 0);
    },
  );
  screenTest(
    'correction cancellation, confirmed edit and removal refresh observations',
    (tester) async {
      final e = await repo.createManual(
        accountId: instrument.id,
        amount: '1',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: DateTime(2025),
      );
      await open(tester);
      await tap(tester, find.byKey(ValueKey('balance.correct.${e.id}')));
      await fill(tester, '2.29');
      await tap(tester, find.text('Cancel'));
      expect((await repo.latest(instrument.id))!.amountMinor, 100);
      await tap(tester, find.text('Save observation'));
      await tap(tester, find.text('Correct'));
      expect((await repo.latest(instrument.id))!.amountMinor, 229);
      await tap(tester, find.byKey(ValueKey('balance.remove.${e.id}')));
      await tap(tester, find.text('Cancel'));
      expect((await repo.history(instrument.id)).count, 1);
      await tap(tester, find.byKey(ValueKey('balance.remove.${e.id}')));
      await tap(tester, find.widgetWithText(FilledButton, 'Remove'));
      expect(find.text('No balance observations recorded.'), findsOneWidget);
    },
  );
  screenTest(
    'precision and invalid date errors retain input; save failure allows retry',
    (tester) async {
      await open(tester);
      await tap(tester, find.byKey(const ValueKey('balance.record')));
      await fill(tester, '1.234');
      expect(find.text('KES allows 2 decimal places.'), findsOneWidget);
      await fill(tester, '1.23', date: 'not a date');
      expect(
        find.text('Enter a valid date and time: YYYY-MM-DD HH:mm.'),
        findsOneWidget,
      );
      repo.fail = true;
      await fill(tester, '1.23');
      expect(
        find.text(
          'Unable to save observation. Your input has been kept. Please try again.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('balance.amount')))
            .controller!
            .text,
        '1.23',
      );
      repo.fail = false;
      await tap(tester, find.text('Save observation'));
      expect((await repo.latest(instrument.id))!.amountMinor, 123);
    },
  );
  screenTest(
    'currency and debt kind remain explicit and archived instruments retain history',
    (tester) async {
      await FinancialInstrumentsRepository(
        db,
      ).setArchived(instrument.uuid, true);
      await open(tester);
      await tap(tester, find.byKey(const ValueKey('balance.record')));
      await tap(tester, find.byKey(const ValueKey('balance.currency')));
      await tap(tester, find.text('KWD').last);
      await tap(tester, find.byKey(const ValueKey('balance.kind')));
      await tap(tester, find.text('Outstanding debt').last);
      await fill(tester, '1.234');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('balance.latest.amount')))
            .data,
        '1.234 KWD',
      );
      expect(
        (await repo.latest(instrument.id))!.kind,
        BalanceKind.outstandingDebt,
      );
      expect(
        (await FinancialInstrumentsRepository(
          db,
        ).getByUuid(instrument.uuid))!.isArchived,
        isTrue,
      );
    },
  );
  screenTest(
    'history paginates twenty entries and latest follows as-of rather than insertion',
    (tester) async {
      for (var i = 20; i >= 0; i--) {
        await repo.createManual(
          accountId: instrument.id,
          amount: '$i',
          currency: 'KES',
          kind: BalanceKind.available,
          asOf: DateTime(2025, 1, 1, i),
        );
      }
      await open(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('balance.latest.amount')))
            .data,
        '20.00 KES',
      );
      expect(find.text('21 observations'), findsOneWidget);
      await tap(tester, find.text('Next observations'));
      expect(find.text('Observations page 2 of 2'), findsOneWidget);
      await tap(tester, find.text('Previous observations'));
      expect(find.text('Observations page 1 of 2'), findsOneWidget);
    },
  );
}
