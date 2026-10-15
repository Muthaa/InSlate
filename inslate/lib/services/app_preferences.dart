import 'package:shared_preferences/shared_preferences.dart';

enum LocalAvatar { robot, person, face, astronaut, pet, star }

class AppPreferences {
  AppPreferences(this._preferences);

  final SharedPreferences _preferences;

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _initialImportCompletedKey = 'initial_import_completed';

  LocalAvatar get localAvatar {
    final saved = _preferences.getString('local_avatar');
    return LocalAvatar.values
            .where((value) => value.name == saved)
            .firstOrNull ??
        LocalAvatar.astronaut;
  }

  Future<void> setLocalAvatar(LocalAvatar avatar) async {
    if (!await _preferences.setString('local_avatar', avatar.name)) {
      throw StateError('Unable to save avatar.');
    }
  }

  bool get reduceMotion => _preferences.getBool('reduce_motion') ?? false;
  Future<void> setReduceMotion(bool enabled) async {
    if (!await _preferences.setBool('reduce_motion', enabled)) {
      throw StateError('Unable to save appearance preference.');
    }
  }

  bool get appLockEnabled => _preferences.getBool('app_lock_enabled') ?? false;
  Future<void> setAppLockEnabled(bool enabled) async {
    if (!await _preferences.setBool('app_lock_enabled', enabled)) {
      throw StateError('Unable to save app lock preference.');
    }
  }

  String? get localDisplayName => _preferences.getString('local_display_name');

  Future<void> setLocalDisplayName(String value) async {
    final name = value.trim();
    if (name.length > 80) throw ArgumentError('Use at most 80 characters.');
    final saved = name.isEmpty
        ? await _preferences.remove('local_display_name')
        : await _preferences.setString('local_display_name', name);
    if (!saved) throw StateError('Unable to save local display name.');
  }

  bool get onboardingCompleted {
    return _preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  bool get initialImportCompleted {
    return _preferences.getBool(_initialImportCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await _preferences.setBool(_onboardingCompletedKey, true);
  }

  Future<void> setInitialImportCompleted() async {
    await _preferences.setBool(_initialImportCompletedKey, true);
  }
}
