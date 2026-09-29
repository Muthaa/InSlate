import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_preferences.dart';

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final preferences = await SharedPreferences.getInstance();

  return AppPreferences(preferences);
});
