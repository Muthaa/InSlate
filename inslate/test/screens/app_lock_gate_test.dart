import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inslate/screens/profile/settings_screen.dart';
import 'package:inslate/providers/app_preferences_provider.dart';
import 'package:inslate/services/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/providers/app_lock_provider.dart';
import 'package:inslate/widgets/app_lock_gate.dart';
import '../helpers/fake_device_unlock_service.dart';

void main() {
  testWidgets(
    'failed preference load stays covered and retry reloads persisted protection',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final store = await SharedPreferences.getInstance();
      var reads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceUnlockServiceProvider.overrideWithValue(
              FakeDeviceUnlockService(),
            ),
            appPreferencesProvider.overrideWith((ref) async {
              reads++;
              if (reads == 1) throw StateError('private storage details');
              return AppPreferences(store);
            }),
          ],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const Scaffold(body: Text('Private home')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private home'), findsNothing);
      expect(find.textContaining('private storage details'), findsNothing);
      await tester.tap(find.text('Retry privacy settings'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('Private home'), findsNothing);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Private home'), findsOneWidget);
    },
  );
  testWidgets(
    'enabling through settings survives OS-prompt lifecycle and locks on the next background',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeDeviceUnlockService()
        ..pendingAuthentication = Completer<bool>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceUnlockServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: const SettingsScreen(setting: ProfileSetting.privacy),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.app-lock')));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      service.pendingAuthentication!.complete(true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('settings.app-lock')),
            )
            .value,
        isTrue,
      );
      expect(find.text('Unlock'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      service.pendingAuthentication = null;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    },
  );
  testWidgets(
    'lock covers root, pushed routes and dialogs until device verification succeeds',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
      final service = FakeDeviceUnlockService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceUnlockServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            builder: (context, child) => AppLockGate(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Private financial dialog'),
                    ),
                  ),
                  child: const Text('Private financial home'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private financial home'), findsNothing);
      service.verified = false;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Private financial home'), findsNothing);
      service.verified = true;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Private financial home'), findsOneWidget);
      await tester.tap(find.text('Private financial home'));
      await tester.pumpAndSettle();
      expect(find.text('Private financial dialog'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Private financial dialog'), findsNothing);
      expect(find.text('Private financial home'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Private financial dialog'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Private financial home'), findsNothing);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Private financial home'), findsOneWidget);
    },
  );
}
