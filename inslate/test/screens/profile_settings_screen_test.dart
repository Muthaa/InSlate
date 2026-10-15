import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/main.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/providers/app_lock_provider.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/screens/profile/profile_overview_screen.dart';
import 'package:inslate/screens/profile/settings_screen.dart';
import '../helpers/fake_device_unlock_service.dart';
import '../helpers/widget_capture.dart';

void main() {
  testWidgets(
    'Profile settings open real destinations and backup is visibly future-only',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              deviceUnlockServiceProvider.overrideWithValue(
                FakeDeviceUnlockService(),
              ),
            ],
            child: const MaterialApp(home: ProfileOverviewScreen()),
          ),
        );
        await tester.pumpAndSettle();
        for (final title in [
          'Appearance',
          'Privacy & app lock',
          'Backup & restore',
          'Help & about',
        ]) {
          final menu = find.byKey(ValueKey('profile.menu.$title'));
          await tester.scrollUntilVisible(menu, 200);
          await tester.ensureVisible(menu);
          await tester.pumpAndSettle();
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.byType(SettingsScreen), findsOneWidget);
          if (title == 'Appearance') {
            await tester.tap(
              find.byKey(const ValueKey('settings.reduce-motion')),
            );
            await tester.pumpAndSettle();
            expect(
              (await SharedPreferences.getInstance()).getBool('reduce_motion'),
              isTrue,
            );
          }
          if (title == 'Privacy & app lock') {
            await tester.tap(find.byKey(const ValueKey('settings.app-lock')));
            await tester.pumpAndSettle();
            expect(
              (await SharedPreferences.getInstance()).getBool(
                'app_lock_enabled',
              ),
              isTrue,
            );
            expect(
              tester
                  .widget<SwitchListTile>(
                    find.byKey(const ValueKey('settings.app-lock')),
                  )
                  .value,
              isTrue,
            );
          }
          if (title == 'Backup & restore') {
            expect(find.text('Future implementation'), findsOneWidget);
            expect(find.textContaining('not available yet'), findsOneWidget);
          }
          if (title == 'Help & about') {
            await tester.tap(find.text('Cash flow and balance'));
            await tester.pumpAndSettle();
            expect(
              find.textContaining('It is not your account balance.'),
              findsOneWidget,
            );
            await tester.ensureVisible(find.text('Open-source licenses'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Open-source licenses'));
            await tester.pumpAndSettle();
            expect(find.byType(LicensePage), findsOneWidget);
            await tester.pageBack();
            await tester.pumpAndSettle();
          }
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      } finally {
        await tester.pump(Duration.zero);
        await tester.runAsync(() => db.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'reduce motion applies to the production app and survives a restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      Future<void> open() async {
        await tester.pumpWidget(const ProviderScope(child: InSlateApp()));
        await tester.pumpAndSettle();
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const SettingsScreen(setting: ProfileSetting.appearance),
              ),
            );
        await tester.pumpAndSettle();
      }

      await open();
      await tester.tap(find.byKey(const ValueKey('settings.reduce-motion')));
      await tester.pumpAndSettle();
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.byType(SettingsScreen)),
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await open();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('settings.reduce-motion')),
            )
            .value,
        isTrue,
      );
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.byType(SettingsScreen)),
        ),
        isTrue,
      );
    },
  );
  testWidgets('privacy does not offer a fake app lock on unsupported devices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeDeviceUnlockService()..available = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceUnlockServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: SettingsScreen(setting: ProfileSetting.privacy),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings.app-lock')),
          )
          .onChanged,
      isNull,
    );
    expect(
      find.textContaining('Device verification is unavailable'),
      findsOneWidget,
    );
    expect(service.authenticationCalls, 0);
  });
  testWidgets('settings remain reachable with large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadCaptureFonts(tester);
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const SettingsScreen(setting: ProfileSetting.backup),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Review your local data'));
    expect(tester.takeException(), isNull);
  });
}
