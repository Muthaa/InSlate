import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_preferences.dart';
import '../services/device_unlock_service.dart';
import 'app_preferences_provider.dart';

final deviceUnlockServiceProvider = Provider<DeviceUnlockService>(
  (ref) => const DeviceUnlockService(),
);
final deviceUnlockAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(deviceUnlockServiceProvider).isAvailable(),
);
final appLockProvider = StateNotifierProvider<AppLockController, AppLockState>((
  ref,
) {
  final controller = AppLockController(
    service: ref.watch(deviceUnlockServiceProvider),
    loadPreferences: () => ref.read(appPreferencesProvider.future),
    onPreferenceChanged: () => ref.invalidate(appPreferencesProvider),
  );
  controller.initialize();
  return controller;
});

class AppLockState {
  final bool ready, enabled, locked, busy;
  final String? error;
  const AppLockState({
    this.ready = false,
    this.enabled = false,
    this.locked = true,
    this.busy = false,
    this.error,
  });
}

class AppLockController extends StateNotifier<AppLockState> {
  final DeviceUnlockService service;
  final Future<AppPreferences> Function() loadPreferences;
  final void Function() onPreferenceChanged;
  bool _foreground = true;
  bool _initializing = false;
  AppLockController({
    required this.service,
    required this.loadPreferences,
    required this.onPreferenceChanged,
  }) : super(const AppLockState());

  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;
    state = const AppLockState();
    try {
      final preferences = await loadPreferences();
      if (!mounted) return;
      final enabled = preferences.appLockEnabled;
      await service.protectScreen(enabled);
      if (!mounted) return;
      state = AppLockState(ready: true, enabled: enabled, locked: enabled);
    } catch (_) {
      if (mounted) {
        state = const AppLockState(
          error: 'Unable to load privacy settings. Try again.',
        );
      }
    } finally {
      _initializing = false;
    }
  }

  void background() {
    _foreground = false;
    if (state.enabled) {
      state = AppLockState(
        ready: state.ready,
        enabled: true,
        locked: true,
        busy: state.busy,
      );
    }
  }

  void foreground() => _foreground = true;

  Future<void> unlock() async {
    if (!state.ready || !state.enabled || state.busy) return;
    state = const AppLockState(
      ready: true,
      enabled: true,
      locked: true,
      busy: true,
    );
    try {
      final verified = await service.authenticate();
      if (!mounted) return;
      if (verified && _foreground) await service.protectScreen(true);
      if (!mounted) return;
      state = AppLockState(
        ready: true,
        enabled: true,
        locked: !verified || !_foreground,
        error: verified && _foreground
            ? null
            : 'App remains locked. Tap Unlock to try again.',
      );
    } catch (_) {
      if (mounted) {
        state = const AppLockState(
          ready: true,
          enabled: true,
          locked: true,
          error: 'Unable to verify your device lock. Try again.',
        );
      }
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (!state.ready || state.busy || enabled == state.enabled) return;
    final previous = state;
    state = AppLockState(
      ready: true,
      enabled: previous.enabled,
      locked: previous.locked,
      busy: true,
    );
    try {
      if (!await service.isAvailable()) {
        throw StateError('Device lock unavailable');
      }
      final verified = await service.authenticate();
      if (!mounted) return;
      if (!verified) {
        if (mounted) {
          state = AppLockState(
            ready: true,
            enabled: previous.enabled,
            locked: previous.enabled && (state.locked || !_foreground),
            error: 'Device verification cancelled. App lock is unchanged.',
          );
        }
        return;
      }
      if (!_foreground) throw StateError('App is not foreground');
      // Apply native protection before committing the matching preference.
      await service.protectScreen(enabled);
      final preferences = await loadPreferences();
      if (!mounted) return;
      await preferences.setAppLockEnabled(enabled);
      if (!mounted) return;
      state = AppLockState(
        ready: true,
        enabled: enabled,
        locked: enabled && !_foreground,
      );
      onPreferenceChanged();
    } catch (_) {
      // Restore protection if a write failed; keep an existing lock closed.
      try {
        await service.protectScreen(previous.enabled);
      } catch (_) {
        /* Retry retains the lock. */
      }
      if (mounted) {
        state = AppLockState(
          ready: true,
          enabled: previous.enabled,
          locked: previous.enabled && (state.locked || !_foreground),
          error:
              'Unable to change app lock. Check your phone screen lock and try again.',
        );
      }
    }
  }
}
