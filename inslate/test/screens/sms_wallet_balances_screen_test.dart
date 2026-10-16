import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/balance_evidence_provider.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/screens/instruments/sms_balance_observations_screen.dart';

void main() {
  late AppDatabase db;
  late BalanceEvidenceRepository repo;
  final date = DateTime.utc(2026, 6, 1);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceEvidenceRepository(db);
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

  Future<void> sms(String id, String body, {int minute = 0}) async {
    await RawMessagesRepository(db).save(
      domain.RawMessage(
        id: id,
        sender: 'MPESA',
        body: body,
        receivedAt: date.add(Duration(minutes: minute)),
      ),
    );
    await repo.extractNewMpesaMessages([id]);
  }

  Future<void> open(
    WidgetTester tester, {
    bool large = false,
    bool dark = false,
    GlobalKey? boundary,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...overrides],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
              child: child!,
            ),
            home: const SmsBalanceObservationsScreen(),
          ),
        ),
      ),
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testUi(
    'wallet is unique across 20+ observations and updates in place without attribution',
    (tester) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 24; i++) {
          await sms('wallet-$i', 'New M-PESA balance is Ksh$i.00.', minute: i);
        }
      });
      await open(tester);
      await tester.pumpAndSettle();
      const key = ValueKey('sms.wallet.mpesa:KES');
      expect(find.byKey(key), findsOneWidget);
      expect(find.text('23.00 KES'), findsOneWidget);
      expect(find.text('History (24)'), findsOneWidget);
      expect(find.textContaining('Unattributed'), findsNothing);
      expect(find.text('Associate latest'), findsNothing);
      await tester.runAsync(
        () => sms('new', 'New M-PESA balance is Ksh0.00.', minute: 25),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      expect(find.text('0.00 KES'), findsOneWidget);
      await tester.runAsync(
        () => sms('late', 'New M-PESA balance is Ksh999.00.', minute: 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('0.00 KES'), findsOneWidget);
      expect(find.text('999.00 KES'), findsNothing);
      await tap(tester, find.text('Needs association'));
      expect(find.byKey(key), findsNothing);
      expect(find.text('No wallets need association.'), findsOneWidget);
    },
  );
  testUi(
    'M-Shwari and KCB remain distinct and can be associated; history is scoped',
    (tester) async {
      await tester.runAsync(() async {
        await sms(
          'one',
          'New M-PESA balance is Ksh7.00. New M-Shwari balance is Ksh20.00.',
        );
        await sms(
          'two',
          'New M-Shwari account available balance is Ksh30.00.',
          minute: 1,
        );
        await sms('kcb', 'KCB M-PESA Account balance is Ksh40.00.');
        final instruments = FinancialInstrumentsRepository(db);
        await instruments.create(
          name: 'My M-Shwari',
          type: InstrumentType.savingsProduct,
          provider: 'M-Shwari',
        );
        await instruments.create(
          name: 'My KCB',
          type: InstrumentType.savingsProduct,
          provider: 'KCB M-PESA',
        );
      });
      await open(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sms.wallet.mpesa:KES')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sms.wallet.mshwariSavings:KES')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sms.wallet.kcbMpesa:KES')),
        findsOneWidget,
      );
      await tap(
        tester,
        find.byKey(const ValueKey('sms.associate.sms:mshwari-savings:two')),
      );
      expect(find.text('Confirm instrument association'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('sms.instrument')));
      await tester.tap(find.text('My M-Shwari').last);
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      expect(find.text('Latest observation: My M-Shwari'), findsOneWidget);
      await tap(
        tester,
        find.byKey(const ValueKey('sms.associate.sms:kcb-mpesa-savings:kcb')),
      );
      await tap(tester, find.byKey(const ValueKey('sms.instrument')));
      await tester.tap(find.text('My KCB').last);
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirm association'),
      );
      expect(find.text('Latest observation: My KCB'), findsOneWidget);
      await tap(
        tester,
        find.byKey(const ValueKey('sms.wallet.history.mshwariSavings:KES')),
      );
      expect(find.byType(SmsBalanceHistoryScreen), findsOneWidget);
      expect(find.text('30.00 KES'), findsOneWidget);
      expect(find.text('20.00 KES'), findsOneWidget);
      expect(find.text('7.00 KES'), findsNothing);
      expect(find.text('40.00 KES'), findsNothing);
    },
  );
  testUi('empty, loading and retry states remain explicit', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('No SMS balance observations.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      overrides: [
        smsWalletBalancesProvider.overrideWith(
          (ref) => Completer<List<SmsWalletBalance>>().future,
        ),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      overrides: [
        smsWalletBalancesProvider.overrideWith(
          (ref) => Future<List<SmsWalletBalance>>.error(
            StateError('private failure'),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load wallet balances. Retry'), findsOneWidget);
    expect(find.textContaining('private failure'), findsNothing);
  });
  for (final dark in [false, true]) {
    testUi('wallet cards fit narrow screens and doubled text: dark $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => sms('large', 'New M-PESA balance is Ksh999,999,999.99.'),
      );
      await open(tester, large: true, dark: dark);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('999999999.99 KES'), 250);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testUi('capture wallet balances: dark $dark', (tester) async {
      final dir = Platform.environment['SLATE_CAPTURE_DIR'];
      if (dir == null) return;
      tester.view.physicalSize = const Size(430, 1120);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fontDirectory = Platform.environment['SLATE_FONT_DIR'];
      if (fontDirectory != null) {
        await tester.runAsync(() async {
          final body = FontLoader('Roboto');
          for (final name in [
            'Roboto-Regular.ttf',
            'Roboto-Medium.ttf',
            'Roboto-Bold.ttf',
          ]) {
            body.addFont(
              File(
                '$fontDirectory/$name',
              ).readAsBytes().then(ByteData.sublistView),
            );
          }
          await body.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(
              File(
                '$fontDirectory/MaterialIcons-Regular.otf',
              ).readAsBytes().then(ByteData.sublistView),
            );
          await icons.load();
        });
      }
      await tester.runAsync(() async {
        await sms(
          'capture-one',
          'New M-PESA balance is Ksh18,450.25. New M-Shwari balance is Ksh25,000.00.',
        );
        await sms(
          'capture-two',
          'New M-PESA balance is Ksh20,100.50.',
          minute: 10,
        );
      });
      final boundary = GlobalKey();
      await open(tester, boundary: boundary, dark: dark);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(dir).create(recursive: true);
        await File(
          '$dir/wallets-${dark ? 'dark' : 'light'}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
