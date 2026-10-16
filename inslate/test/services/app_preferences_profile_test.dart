import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/services/app_preferences.dart';

void main() {
  test(
    'optional local name persists, trims, clears and preserves setup flags',
    () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'initial_import_completed': true,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.localDisplayName, isNull);
      await prefs.setLocalDisplayName('  Local name  ');
      expect(prefs.localDisplayName, 'Local name');
      await expectLater(
        prefs.setLocalDisplayName('x' * 81),
        throwsArgumentError,
      );
      expect(prefs.localDisplayName, 'Local name');
      await prefs.setLocalDisplayName(' ');
      expect(prefs.localDisplayName, isNull);
      expect(prefs.onboardingCompleted, isTrue);
      expect(prefs.initialImportCompleted, isTrue);
    },
  );
}
