import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/core/design/slate_components.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart' show AppDatabase;
import 'package:inslate/main.dart';
import 'package:inslate/models/import_progress.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/import_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/app_shell.dart';
import 'package:inslate/screens/instruments/financial_instruments_screen.dart';
import 'package:inslate/screens/instruments/instrument_form_screen.dart';
import 'package:inslate/screens/profile/profile_screen.dart';
import 'package:inslate/widgets/app_dialog.dart';
import 'package:inslate/widgets/app_viewport.dart';
import '../services/financial_summary_service_test.dart' show record;

class _QuietImporter extends ImportNotifier {
  @override
  ImportProgress build() => const ImportProgress(status: ImportStatus.idle);
  @override
  void startIncomingSmsListener() {}
  @override
  Future<void> catchUpNewMessages() async {}
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importProvider.overrideWith(() => _QuietImporter()),
      ],
    );
  });
  void uiTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpAndSettle();
          container.dispose();
          await tester.pump(Duration.zero);
          await tester.runAsync(() => db.close());
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });
  void device(
    WidgetTester tester, {
    double bottom = 34,
    double keyboard = 0,
    bool landscape = false,
  }) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = landscape
        ? const Size(844, 390)
        : const Size(390, 844);
    tester.view.viewPadding = FakeViewPadding(
      top: landscape ? 0 : 24,
      bottom: bottom,
      left: landscape ? 44 : 0,
      right: landscape ? 24 : 0,
    );
    tester.view.padding = FakeViewPadding(
      top: landscape ? 0 : 24,
      bottom: keyboard > 0 ? 0 : bottom,
      left: landscape ? 44 : 0,
      right: landscape ? 24 : 0,
    );
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });
  }

  Future<void> open(
    WidgetTester tester, {
    Widget? home,
    bool protect = true,
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: home == null
            ? const InSlateApp()
            : MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                builder: protect
                    ? (context, child) => AppViewport(child: child!)
                    : null,
                home: home,
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String name) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(name),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final bottom in [0.0, 24.0, 48.0]) {
    uiTest(
      'all tabs reserve the app bar and phone inset $bottom exactly once',
      (tester) async {
        device(tester, bottom: bottom);
        await open(tester);
        expect(find.byType(AppViewport), findsOneWidget);
        for (final name in ['Home', 'Activity', 'Insights', 'Profile']) {
          await tab(tester, name);
          final navigation = tester.getRect(find.byType(NavigationBar));
          expect(navigation.bottom, 844 - bottom);
          expect(navigation.height, 72);
          expect(
            tester.getRect(find.byType(IndexedStack).first).bottom,
            tester
                .getRect(
                  find
                      .ancestor(
                        of: find.byType(NavigationBar),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .top,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  uiTest(
    'search focus and text survive the keyboard changing the available height',
    (tester) async {
      device(tester);
      await open(tester);
      await tab(tester, 'Activity');
      final search = find.widgetWithText(TextField, 'Search transactions');
      expect(
        tester.getRect(find.widgetWithText(TextButton, 'Filters')).left,
        16,
      );
      await tester.tap(search);
      await tester.enterText(search, 'retained');
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.viewInsets = const FakeViewPadding(bottom: 420);
      tester.view.padding = const FakeViewPadding(top: 24);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.widget<TextField>(search).controller!.text, 'retained');
      expect(
        tester.getRect(find.byTooltip('Next page')).bottom,
        lessThanOrEqualTo(424),
      );
      expect(tester.takeException(), isNull);
      FocusManager.instance.primaryFocus?.unfocus();
    },
  );
  uiTest('Activity pagination and snackbars stay above the app navigation', (
    tester,
  ) async {
    device(tester, bottom: 48);
    await tester.runAsync(
      () => FinancialRecordsRepository(db).saveAll([
        for (var i = 0; i < 55; i++)
          record(RecordSubtype.sendMoney, i.toDouble(), date: DateTime.now()),
      ]),
    );
    await open(tester);
    await tab(tester, 'Activity');
    final navigation = tester.getRect(find.byType(NavigationBar));
    expect(
      tester.getRect(find.byTooltip('Next page')).bottom,
      lessThanOrEqualTo(navigation.top),
    );
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(AppShell)),
    ).showSnackBar(const SnackBar(content: Text('Navigation test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(navigation.top),
    );
    ScaffoldMessenger.of(
      tester.element(find.byType(AppShell)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
  });
  uiTest(
    'pushed instrument page clears phone navigation and system back restores the tab',
    (tester) async {
      device(tester);
      await open(tester);
      await tab(tester, 'Profile');
      await tester.ensureVisible(find.text('Financial Instruments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Financial Instruments'));
      await tester.pumpAndSettle();
      expect(find.byType(FinancialInstrumentsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.getRect(find.byType(FloatingActionButton)).bottom,
        lessThanOrEqualTo(810),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(tester.getRect(find.byType(NavigationBar)).bottom, 810);
    },
  );
  uiTest('landscape cutouts and navigation leave all tab controls usable', (
    tester,
  ) async {
    device(tester, bottom: 24, landscape: true);
    await open(tester);
    for (final name in ['Home', 'Activity', 'Insights', 'Profile']) {
      await tab(tester, name);
      final navigation = tester.getRect(find.byType(NavigationBar));
      expect(navigation.left, 44);
      expect(navigation.right, 820);
      expect(navigation.bottom, 366);
      if (name == 'Activity') {
        await tester.ensureVisible(find.text('Filters'));
        await tester.pumpAndSettle();
        expect(find.text('Filters').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });
  uiTest(
    'a page without a local SafeArea keeps its final profile action above phone navigation',
    (tester) async {
      device(tester, bottom: 48);
      await open(tester, home: const ProfileScreen());
      final last = find.widgetWithText(ListTile, 'Initial SMS import');
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.getRect(last).bottom, lessThanOrEqualTo(796));
      expect(tester.getRect(find.byType(ListView)).bottom, 796);
    },
  );
  for (final keyboard in [0.0, 300.0]) {
    uiTest(
      'instrument form save remains reachable with keyboard inset $keyboard',
      (tester) async {
        device(tester, bottom: 34, keyboard: keyboard);
        await open(tester, home: const InstrumentFormScreen());
        final save = find.widgetWithText(FilledButton, 'Save instrument');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        final limit = keyboard > 0 ? 844 - keyboard : 810.0;
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(limit));
        expect(tester.getRect(save).top, greaterThanOrEqualTo(80));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final protect in [false, true]) {
    for (final keyboard in [0.0, 300.0]) {
      uiTest(
        'shared sheet respects device and keyboard insets (app boundary $protect, keyboard $keyboard)',
        (tester) async {
          device(tester, keyboard: keyboard);
          await open(
            tester,
            protect: protect,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showSlateSheet<void>(
                    context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TextField(
                          decoration: InputDecoration(labelText: 'Sheet field'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Sheet action'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open sheet'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open sheet'));
          await tester.pumpAndSettle();
          final limit = keyboard > 0 ? 844 - keyboard : 810.0;
          final action = find.widgetWithText(FilledButton, 'Sheet action');
          expect(tester.getRect(action).bottom, lessThanOrEqualTo(limit));
          expect(tester.getRect(action).bottom, greaterThan(limit - 80));
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Sheet action'), findsNothing);
        },
      );
    }
  }
  uiTest(
    'dialogs clear phone navigation and system back dismisses only the dialog',
    (tester) async {
      device(tester, bottom: 48);
      await open(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSlateDialog<void>(
                context,
                builder: (context) => AppDialog(
                  title: const Text('Inset test'),
                  content: const Text(
                    'Confirmation stays within the usable screen.',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
              child: const Text('Open dialog'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(AlertDialog)).bottom,
        lessThanOrEqualTo(796),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Open dialog'), findsOneWidget);
    },
  );
  uiTest('system navigation icons follow the current theme', (tester) async {
    device(tester);
    for (final dark in [false, true]) {
      await open(
        tester,
        dark: dark,
        home: const Scaffold(body: Text('System navigation')),
      );
      final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(
        regions.any(
          (region) =>
              region.value.systemNavigationBarIconBrightness ==
                  (dark ? Brightness.light : Brightness.dark) &&
              region.value.systemNavigationBarContrastEnforced == true,
        ),
        isTrue,
      );
    }
  });
}
