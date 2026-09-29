import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_preferences_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'onboarding/welcome_screen.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);

    return preferences.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to start the app.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (preferences) {
        if (preferences.onboardingCompleted) {
          return const DashboardScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}
