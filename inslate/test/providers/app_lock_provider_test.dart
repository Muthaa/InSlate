import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/providers/app_lock_provider.dart';
import 'package:inslate/services/app_preferences.dart';
import '../helpers/fake_device_unlock_service.dart';

class _FailingPreferences extends AppPreferences {
  _FailingPreferences(super.preferences);
  @override
  Future<void> setAppLockEnabled(bool value) async =>
      throw StateError('private storage details');
}

void main() {
  late AppPreferences preferences;
  late SharedPreferences store;
  late FakeDeviceUnlockService service;
  Future<AppLockController> open({
    bool enabled = false,
    bool failWrite = false,
  }) async {
    SharedPreferences.setMockInitialValues({'app_lock_enabled': enabled});
    store = await SharedPreferences.getInstance();
    preferences = failWrite
        ? _FailingPreferences(store)
        : AppPreferences(store);
    service = FakeDeviceUnlockService();
    final controller = AppLockController(
      service: service,
      loadPreferences: () async => preferences,
      onPreferenceChanged: () {},
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    return controller;
  }

  test(
    'enable requires verification, persists, protects screen and starts next session locked',
    () async {
      final controller = await open();
      expect(controller.state.locked, isFalse);
      await controller.setEnabled(true);
      expect(controller.state.enabled, isTrue);
      expect(controller.state.locked, isFalse);
      expect(service.authenticationCalls, 1);
      expect(preferences.appLockEnabled, isTrue);
      expect(service.protection, [false, true]);
      final restarted = AppLockController(
        service: service,
        loadPreferences: () async => AppPreferences(store),
        onPreferenceChanged: () {},
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.state.locked, isTrue);
    },
  );
  test('unavailable credentials cannot enable protection', () async {
    final controller = await open();
    service.available = false;
    await controller.setEnabled(true);
    expect(preferences.appLockEnabled, isFalse);
    expect(service.authenticationCalls, 0);
    expect(controller.state.enabled, isFalse);
  });
  test(
    'cancelled verification does not change the setting or trap an unprotected app',
    () async {
      final controller = await open();
      service.verified = false;
      controller.background();
      await controller.setEnabled(true);
      expect(preferences.appLockEnabled, isFalse);
      expect(controller.state.locked, isFalse);
      expect(controller.state.enabled, isFalse);
    },
  );
  test(
    'unlock cancellation and platform errors keep financial data locked',
    () async {
      final controller = await open(enabled: true);
      service.verified = false;
      await controller.unlock();
      expect(controller.state.locked, isTrue);
      service.failAuth = true;
      await controller.unlock();
      expect(controller.state.locked, isTrue);
      expect(controller.state.error, isNot(contains('private platform')));
    },
  );
  test(
    'disabling requires fresh verification and cancellation preserves persisted lock',
    () async {
      final controller = await open(enabled: true);
      await controller.unlock();
      service.verified = false;
      await controller.setEnabled(false);
      expect(preferences.appLockEnabled, isTrue);
      service.verified = true;
      await controller.setEnabled(false);
      expect(preferences.appLockEnabled, isFalse);
      expect(controller.state.locked, isFalse);
      expect(service.protection.last, isFalse);
      expect(service.authenticationCalls, 3);
    },
  );
  for (final enabled in [false, true]) {
    test(
      'write failure restores previous protection, enabled $enabled',
      () async {
        final controller = await open(enabled: enabled, failWrite: true);
        await controller.setEnabled(!enabled);
        expect(preferences.appLockEnabled, enabled);
        expect(controller.state.enabled, enabled);
        expect(service.protection.last, enabled);
        expect(controller.state.error, isNot(contains('private storage')));
      },
    );
  }
  test(
    'native protection failure cannot commit a changed lock preference',
    () async {
      final controller = await open(enabled: true);
      service.failProtection = false;
      await controller.setEnabled(false);
      expect(preferences.appLockEnabled, isTrue);
      expect(controller.state.locked, isTrue);
      expect(service.protection.last, isTrue);
    },
  );
  test(
    'background locks immediately; a late authentication cannot unlock in background',
    () async {
      final controller = await open(enabled: true);
      await controller.unlock();
      expect(controller.state.locked, isFalse);
      controller.background();
      expect(controller.state.locked, isTrue);
      controller.foreground();
      service.pendingAuthentication = Completer<bool>();
      final authentication = controller.unlock();
      controller.background();
      service.pendingAuthentication!.complete(true);
      await authentication;
      expect(controller.state.locked, isTrue);
      controller.foreground();
      expect(controller.state.locked, isTrue);
    },
  );
  test('overlapping requests create only one device prompt', () async {
    final controller = await open(enabled: true);
    service.pendingAuthentication = Completer<bool>();
    final first = controller.unlock();
    await controller.unlock();
    expect(service.authenticationCalls, 1);
    service.pendingAuthentication!.complete(true);
    await first;
    expect(controller.state.locked, isFalse);
  });
  test('privacy load failure is closed and can be retried', () async {
    var fail = true;
    SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
    final store = await SharedPreferences.getInstance();
    final controller = AppLockController(
      service: FakeDeviceUnlockService(),
      loadPreferences: () async {
        if (fail) throw StateError('private details');
        return AppPreferences(store);
      },
      onPreferenceChanged: () {},
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.state.ready, isFalse);
    expect(controller.state.locked, isTrue);
    fail = false;
    await controller.initialize();
    expect(controller.state.ready, isTrue);
    expect(controller.state.locked, isTrue);
  });
}
