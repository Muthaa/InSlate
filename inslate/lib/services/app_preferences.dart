import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._preferences);

  final SharedPreferences _preferences;

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _initialImportCompletedKey = 'initial_import_completed';

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
