import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/startup_screen.dart';
import 'widgets/app_viewport.dart';
import 'widgets/app_lock_gate.dart';
import 'providers/app_preferences_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: InSlateApp()));
}

class InSlateApp extends ConsumerWidget {
  const InSlateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced =
        ref.watch(appPreferencesProvider).valueOrNull?.reduceMotion ?? false;
    final theme = AppTheme.light();
    return MaterialApp(
      title: 'InSlate',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: reduced ? Duration.zero : kThemeAnimationDuration,
      theme: reduced
          ? theme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: _InstantPageTransitions(),
                  TargetPlatform.iOS: _InstantPageTransitions(),
                  TargetPlatform.macOS: _InstantPageTransitions(),
                  TargetPlatform.windows: _InstantPageTransitions(),
                  TargetPlatform.linux: _InstantPageTransitions(),
                  TargetPlatform.fuchsia: _InstantPageTransitions(),
                },
              ),
            )
          : theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced || MediaQuery.disableAnimationsOf(context),
        ),
        child: AppViewport(child: AppLockGate(child: child!)),
      ),
      home: const StartupScreen(),
    );
  }
}

class _InstantPageTransitions extends PageTransitionsBuilder {
  const _InstantPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
