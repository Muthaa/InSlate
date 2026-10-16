import 'package:drift/native.dart';
import 'package:inslate/core/theme/app_theme.dart';
import '../helpers/widget_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/import_progress.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/app_preferences_provider.dart';
import 'package:inslate/services/app_preferences.dart';
import 'package:inslate/providers/import_provider.dart';
import 'package:inslate/providers/your_data_provider.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/screens/profile/profile_screen.dart';
import 'package:inslate/screens/profile/your_data_screen.dart';

class TestImporter extends ImportNotifier {
  static int importRequests = 0;
  @override
  Future<void> importMessages() async {
    importRequests++;
    state = const ImportProgress(status: ImportStatus.processing, total: 10);
  }

  @override
  ImportProgress build() => const ImportProgress(
    status: ImportStatus.completed,
    total: 10,
    processed: 10,
    imported: 3,
    skipped: 4,
    duplicate: 2,
    failed: 1,
    rawCreated: 8,
    evidenceCreated: 5,
    reasons: {'PARSE_FAILED': 1},
  );
}

class FailingNamePreferences extends AppPreferences {
  FailingNamePreferences(super.preferences);
  @override
  Future<void> setLocalDisplayName(String value) async =>
      throw StateError('Private storage details');
}

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    TestImporter.importRequests = 0;
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

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    bool large = false,
    bool dark = false,
    GlobalKey? boundary,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          importProvider.overrideWith(TestImporter.new),
        ],
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
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final large in [false, true]) {
    testUi('Your Data grid remains readable and reachable, large text $large', (
      tester,
    ) async {
      tester.view.physicalSize = Size(large ? 320 : 430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadCaptureFonts(tester);
      final boundary = GlobalKey();
      await open(
        tester,
        const YourDataScreen(),
        large: large,
        boundary: boundary,
      );
      final records = tester.getRect(
        find.byKey(const ValueKey('your-data.Financial records')),
      );
      final sms = tester.getRect(
        find.byKey(const ValueKey('your-data.Raw SMS messages')),
      );
      if (large) {
        expect(sms.top, greaterThan(records.bottom));
        expect(sms.left, records.left);
      } else {
        final balanceCard = find.byKey(
          const ValueKey('your-data.Balance observations'),
        );
        expect(tester.getRect(balanceCard).height, lessThan(120));
        final header = find
            .descendant(of: balanceCard, matching: find.byType(Row))
            .first;
        expect(
          find.descendant(
            of: header,
            matching: find.text('Balance observations: 0'),
          ),
          findsOneWidget,
        );
        final instruments = tester.getRect(
          find.byKey(
            const ValueKey('your-data.Registered financial instruments'),
          ),
        );
        final reversals = tester.getRect(
          find
              .ancestor(
                of: find.text('Verified PayBill reversals'),
                matching: find.byType(Card),
              )
              .first,
        );
        expect(reversals.top - instruments.bottom, greaterThanOrEqualTo(16));
        expect(sms.top, records.top);
        expect(sms.left, greaterThan(records.right));
        await captureWidget(tester, boundary, 'your-data');
      }
      await tester.ensureVisible(
        find.text('Registered financial instruments: 0'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testUi(
    'Profile persists optional local name without duplicate data navigation',
    (tester) async {
      await open(tester, const ProfileScreen());
      expect(find.textContaining('no online account'), findsOneWidget);
      await tester.tap(find.text('Add a local display name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '  Alex  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('local_display_name'),
        'Alex',
      );
      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Add a local display name'), findsOneWidget);
      expect(find.text('Your Data'), findsNothing);
    },
  );
  testUi(
    'Your Data shows real counts, live updates and no sensitive SMS content',
    (tester) async {
      await open(tester, const YourDataScreen());
      expect(find.text('Financial records: 0'), findsOneWidget);
      expect(find.text('Categories & rules'), findsOneWidget);
      expect(find.textContaining('0 categorization rules.'), findsOneWidget);
      expect(find.text('Categorization rules: 0'), findsNothing);
      expect(
        find.textContaining('Stored locally on this device;'),
        findsNothing,
      );
      await tester.tap(find.byTooltip('About your device data'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Stored locally on this device;'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'SMS storage and financial transactions are separate.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Stored locally on this device;'),
        findsNothing,
      );
      await tester.runAsync(
        () => RawMessagesRepository(db).save(
          domain.RawMessage(
            id: 'private-id',
            sender: '0712345678',
            body: 'PRIVATE SMS BODY',
            receivedAt: DateTime.utc(2026),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Raw SMS messages: 1'), findsOneWidget);
      expect(find.text('Financial records: 0'), findsOneWidget);
      expect(find.textContaining('PRIVATE SMS BODY'), findsNothing);
      expect(find.textContaining('0712345678'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Import status (this session)'),
        250,
      );
      expect(find.text('10 SMS checked'), findsOneWidget);
      for (final outcome in {
        'Imported': 3,
        'Skipped': 4,
        'Duplicate': 2,
        'Failed': 1,
      }.entries) {
        expect(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text(outcome.key),
                  matching: find.byType(Container),
                )
                .first,
            matching: find.text('${outcome.value}'),
          ),
          findsOneWidget,
        );
      }
      expect(find.textContaining('not lifetime totals'), findsOneWidget);
      expect(
        find.text('Import finished with failures requiring review.'),
        findsOneWidget,
      );
      expect(find.text('8 new stored SMS'), findsOneWidget);
      expect(find.text('5 new balance observations'), findsOneWidget);
      await tester.ensureVisible(find.text('Outcome details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outcome details'));
      await tester.pumpAndSettle();
      expect(
        find.text('Recognized messages that could not be parsed'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Reconcile SMS inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Reconcile SMS inbox').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Reconcile SMS inbox'));
      await tester.pumpAndSettle();
      expect(TestImporter.importRequests, 1);
      expect(
        tester
            .widget<FilledButton>(
              find
                  .ancestor(
                    of: find.text('Reconcile SMS inbox'),
                    matching: find.byWidgetPredicate(
                      (widget) => widget is FilledButton,
                    ),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
    },
  );
  testUi('Your Data retains counts without duplicate management routes', (
    tester,
  ) async {
    await open(tester, const YourDataScreen());
    expect(find.text('Balance observations: 0'), findsOneWidget);
    expect(find.text('SMS balance observations: 0'), findsNothing);
    final balances = tester.getRect(
      find.byKey(const ValueKey('your-data.Balance observations')),
    );
    final records = tester.getRect(
      find.byKey(const ValueKey('your-data.Financial records')),
    );
    final sms = tester.getRect(
      find.byKey(const ValueKey('your-data.Raw SMS messages')),
    );
    expect(balances.bottom, lessThan(records.top));
    expect(records.top, sms.top);
    expect(records.right, lessThan(sms.left));
    await tester.ensureVisible(find.text('Financial records: 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Financial records: 0'));
    await tester.pumpAndSettle();
    expect(find.text('Your financial timeline'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    for (final label in [
      'Categories & rules',
      'Registered financial instruments: 0',
    ]) {
      await tester.scrollUntilVisible(find.textContaining(label), 150);
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('your-data.${label.split(':').first}'));
      final tile = tester.widget<InkWell>(
        find.descendant(of: card, matching: find.byType(InkWell)),
      );
      expect(tile.onTap, isNull);
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.arrow_outward_rounded),
        ),
        findsNothing,
      );
    }
    await tester.ensureVisible(find.text('Balance observations: 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance observations: 0'));
    await tester.pumpAndSettle();
    expect(find.byType(YourDataScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('0 SMS observations'), findsOneWidget);
  });
  testUi('count failures provide a retry without exposing exception content', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importProvider.overrideWith(TestImporter.new),
          yourDataSummaryProvider.overrideWith((ref) {
            requests++;
            return Stream.error(StateError('PRIVATE DATABASE PATH'));
          }),
        ],
        child: const MaterialApp(home: YourDataScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load stored data counts.'), findsOneWidget);
    expect(find.textContaining('PRIVATE DATABASE PATH'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
  });
  testUi('SMS metadata navigation paginates without revealing source content', (
    tester,
  ) async {
    await tester.runAsync(
      () => RawMessagesRepository(db).saveAll(
        List.generate(
          51,
          (i) => domain.RawMessage(
            id: 'sms-$i',
            sender: '0712345678',
            body: 'PRIVATE SMS BODY',
            receivedAt: DateTime.utc(2026),
          ),
        ),
      ),
    );
    await open(tester, const YourDataScreen());
    await tester.tap(find.text('Raw SMS messages: 51'));
    await tester.pumpAndSettle();
    expect(find.text('51 stored messages'), findsOneWidget);
    expect(find.textContaining('PRIVATE SMS BODY'), findsNothing);
    expect(find.textContaining('0712345678'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Stored SMS'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Raw SMS messages: 51'), findsOneWidget);
  });
  testUi(
    'name persistence failure retains user input and does not expose errors',
    (tester) async {
      final preferences = FailingNamePreferences(
        await SharedPreferences.getInstance(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith((ref) async => preferences),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a local display name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Keep my input');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to save name. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Keep my input'), findsOneWidget);
      expect(find.textContaining('Private storage details'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
