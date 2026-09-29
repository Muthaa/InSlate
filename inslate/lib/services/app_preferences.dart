import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._preferences);

  final SharedPreferences _preferences;

  static const String _onboardingCompletedKey = 'onboarding_completed';

  bool get onboardingCompleted {
    return _preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await _preferences.setBool(_onboardingCompletedKey, true);
  }
}
