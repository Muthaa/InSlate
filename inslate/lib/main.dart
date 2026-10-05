import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: InSlateApp()));
}

class InSlateApp extends StatelessWidget {
  const InSlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InSlate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const StartupScreen(),
    );
  }
}
