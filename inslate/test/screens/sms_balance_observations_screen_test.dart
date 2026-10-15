import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/balance_evidence_provider.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/screens/instruments/sms_balance_observations_screen.dart';
import 'package:inslate/screens/instruments/financial_instruments_screen.dart';
import 'package:inslate/screens/instruments/instrument_detail_screen.dart';

class _Repository extends BalanceEvidenceRepository {
  bool fail = false;
  _Repository(super.database);
  @override
  Future<void> associateSms({
    required String id,
    required int? expectedAccountId,
    required int expectedRevision,
    required int? accountId,
    bool confirmReplacement = false,
    bool confirmUncertainCompatibility = false,
  }) {
    if (fail) throw Exception('test storage failure');
    return super.associateSms(
      id: id,
      expectedAccountId: expectedAccountId,
      expectedRevision: expectedRevision,
      accountId: accountId,
      confirmReplacement: confirmReplacement,
      confirmUncertainCompatibility: confirmUncertainCompatibility,
    );
  }
}

void main() {
  late AppDatabase db;
  late _Repository repo;
  late FinancialInstrumentsRepository instruments;
  late FinancialInstrument wallet;
  final date = DateTime.utc(2026, 6, 1);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _Repository(db);
    instruments = FinancialInstrumentsRepository(db);
    wallet = await instruments.create(
      name: 'My wallet',
      type: InstrumentType.savingsProduct,
      provider: 'M-Shwari',
    );
  });
  void testUi(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        // Close Drift inside the widget test before Flutter checks pending
        // timers. Its stream cache otherwise schedules disposal timers.
        // Drain Timer.run callbacks from disposed stream caches without
        // advancing fake time by an arbitrary duration.
        await tester.pump(Duration.zero);
        await tester.runAsync(() => db.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  Future<String> sms(String id, {DateTime? asOf}) async {
    await RawMessagesRepository(db).save(
      domain.RawMessage(
        id: id,
        sender: 'MPESA',
        body: 'New M-Shwari balance is Ksh0.00.',
        receivedAt: asOf ?? date,
      ),
    );
    await repo.extractNewMpesaMessages([id]);
    return 'sms:mshwari-savings:$id';
  }

  Future<void> open(
    WidgetTester tester, {
    Widget home = const SmsBalanceHistoryScreen(unattributedOnly: true),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          balanceEvidenceRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
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

  Future<void> choose(WidgetTester tester, String name) async {
    await tap(tester, find.byKey(const ValueKey('sms.instrument')));
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> link(String id) => repo.associateSms(
    id: id,
    expectedAccountId: null,
    expectedRevision: 0,
    accountId: wallet.id,
  );

  testUi(
    'Financial Instruments navigation exposes bounded SMS review and empty state',
    (tester) async {
      await open(tester, home: const FinancialInstrumentsScreen());
      await tap(tester, find.text('Review SMS balance observations'));
      expect(find.text('SMS balance observations'), findsOneWidget);
      expect(find.text('No SMS balance observations.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Financial Instruments'), findsOneWidget);
    },
  );
  testUi(
    'review shows exact provenance and explicit association moves item from unattributed',
    (tester) async {
      final id = await sms('one');
      await open(tester);
      expect(find.text('M-Shwari savings'), findsOneWidget);
      expect(find.text('0.00 KES'), findsOneWidget);
      expect(find.text('SMS-reported'), findsOneWidget);
      expect(
        find.text('SMS receipt time (observation-time proxy)'),
        findsOneWidget,
      );
      expect(find.text('Instrument: Unattributed'), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('sms.associate.$id')));
      await choose(tester, 'My wallet');
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      expect(
        find.text('No unattributed SMS balance observations.'),
        findsOneWidget,
      );
      await tap(tester, find.text('All SMS'));
      expect(find.text('Instrument: My wallet'), findsOneWidget);
      expect(
        find.text(
          'Association confirmed by user; ownership is not SMS-verified.',
        ),
        findsOneWidget,
      );
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Remove'), findsNothing);
    },
  );
  testUi(
    'replacement and unlink each require confirmation and preserve evidence',
    (tester) async {
      final id = await sms('replace');
      await link(id);
      await instruments.create(
        name: 'Second wallet',
        type: InstrumentType.savingsProduct,
        provider: 'M-Shwari',
      );
      await open(
        tester,
        home: const SmsBalanceHistoryScreen(unattributedOnly: false),
      );
      await tap(tester, find.byKey(ValueKey('sms.associate.$id')));
      await choose(tester, 'Second wallet');
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      expect(find.text('Replace existing association?'), findsOneWidget);
      await tap(tester, find.widgetWithText(TextButton, 'Cancel').last);
      expect((await repo.latest(wallet.id))!.id, id);
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Replace'));
      expect(find.text('Instrument: Second wallet'), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('sms.unlink.$id')));
      await tap(tester, find.widgetWithText(TextButton, 'Cancel'));
      expect(find.text('Instrument: Second wallet'), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('sms.unlink.$id')));
      await tap(tester, find.widgetWithText(FilledButton, 'Unlink'));
      expect(find.text('Instrument: Unattributed'), findsOneWidget);
      expect((await repo.smsHistory()).count, 1);
    },
  );
  testUi(
    'unknown metadata requires compatibility confirmation; conflicting types blocked',
    (tester) async {
      final id = await sms('compatibility');
      await instruments.create(
        name: 'Unnamed provider',
        type: InstrumentType.savingsProduct,
      );
      await instruments.create(
        name: 'Insurance',
        type: InstrumentType.insurancePolicy,
      );
      await open(tester);
      await tap(tester, find.byKey(ValueKey('sms.associate.$id')));
      await choose(tester, 'Insurance');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm association'),
            )
            .onPressed,
        isNull,
      );
      await choose(tester, 'Unnamed provider');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm association'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, find.byType(CheckboxListTile));
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      expect((await repo.smsHistory()).count, 0);
    },
  );
  testUi(
    'archived and legacy targets excluded; archived association remains reviewable',
    (tester) async {
      final id = await sms('archived');
      await link(id);
      await instruments.setArchived(wallet.uuid, true);
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: 'legacy',
              name: 'Legacy',
              type: 'mpesa',
            ),
          );
      await open(
        tester,
        home: const SmsBalanceHistoryScreen(unattributedOnly: false),
      );
      expect(find.text('Instrument: My wallet (Archived)'), findsOneWidget);
      await tap(tester, find.byKey(ValueKey('sms.associate.$id')));
      expect(
        find.text('Register or restore an active instrument first.'),
        findsOneWidget,
      );
      expect(find.text('Legacy'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm association'),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testUi('persistence errors preserve selection and permit retry', (
    tester,
  ) async {
    final id = await sms('failure');
    await open(tester);
    await tap(tester, find.byKey(ValueKey('sms.associate.$id')));
    await choose(tester, 'My wallet');
    repo.fail = true;
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm association'));
    expect(find.text('Unable to save association. Try again.'), findsOneWidget);
    expect(find.text('My wallet'), findsOneWidget);
    repo.fail = false;
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm association'));
    expect((await repo.smsHistory()).count, 0);
  });
  testUi('20-record pagination clamps when last unattributed page disappears', (
    tester,
  ) async {
    for (var i = 0; i < 21; i++) {
      await sms('page-$i', asOf: date.add(Duration(minutes: i)));
    }
    await open(tester);
    expect(find.text('21 SMS observations'), findsOneWidget);
    await tap(tester, find.text('Next SMS observations'));
    expect(find.text('SMS page 2 of 2'), findsOneWidget);
    await tap(
      tester,
      find.byKey(const ValueKey('sms.associate.sms:mshwari-savings:page-0')),
    );
    await choose(tester, 'My wallet');
    await tap(tester, find.widgetWithText(FilledButton, 'Confirm association'));
    expect(find.text('20 SMS observations'), findsOneWidget);
    expect(find.text('SMS page 1 of 1'), findsOneWidget);
  });
  testUi(
    'Instrument Details coexists with manual snapshots and exposes no SMS content edits',
    (tester) async {
      final id = await sms('old');
      await link(id);
      final manual = await repo.createManual(
        accountId: wallet.id,
        amount: '1.25',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: date.add(const Duration(days: 1)),
      );
      await open(tester, home: InstrumentDetailScreen(uuid: wallet.uuid));
      await tap(tester, find.text('Review SMS balance observations'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('balance.latest.amount')),
      );
      expect(amount.data, '1.25 KES');
      final history = find.byKey(ValueKey('balance.entry.$id'));
      await tap(tester, find.byKey(ValueKey('balance.correct.${manual.id}')));
      expect(find.text('Save observation'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(history));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: history, matching: find.text('SMS-reported')),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('balance.correct.$id')), findsNothing);
      expect(find.byKey(ValueKey('balance.remove.$id')), findsNothing);
      final newer = await sms('new', asOf: date.add(const Duration(days: 2)));
      await link(newer);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('balance.latest.amount')))
            .data,
        '0.00 KES',
      );
    },
  );
}
