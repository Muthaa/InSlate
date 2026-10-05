import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_preferences_provider.dart';
import 'app_shell.dart';
import 'onboarding/welcome_screen.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);

    return preferences.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0B1F3A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'IS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'InSlate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Financial intelligence',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0F9D8A),
                ),
              ),
            ],
          ),
        ),
      ),
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
          return const AppShell();
        }

        return const WelcomeScreen();
      },
    );
  }
}
