import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/providers/app_lock_provider.dart';
import 'package:inslate/widgets/app_lock_gate.dart';
import 'package:inslate/screens/profile/settings_screen.dart';
import '../helpers/fake_device_unlock_service.dart';
import '../helpers/widget_capture.dart';

void main() {
  for (final setting in ProfileSetting.values) {
    testWidgets('render ${setting.name} settings', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadCaptureFonts(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceUnlockServiceProvider.overrideWithValue(
              FakeDeviceUnlockService(),
            ),
          ],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: SettingsScreen(setting: setting),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureWidget(tester, boundary, setting.name);
    });
  }
  testWidgets('render locked Navigator', (tester) async {
    SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadCaptureFonts(tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceUnlockServiceProvider.overrideWithValue(
            FakeDeviceUnlockService(),
          ),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('Private content must be hidden')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private content must be hidden'), findsNothing);
    await captureWidget(tester, boundary, 'app-lock');
  });
}
