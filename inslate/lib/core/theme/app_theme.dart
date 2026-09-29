import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color teal = Color(0xFF0F9D8A);
  static const Color darkBlue = Color(0xFF0B1F3A);
  static const Color white = Colors.white;
  static const Color darkTeal = Color(0xFF1B3251);

  // Dashboard surface
  static const Color appBackground = Color(0xFFF4F7F8);
  static const Color cardBackground = Colors.white;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: teal,
          secondary: darkBlue,
          surface: cardBackground,
          onSurface: darkBlue,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: appBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        foregroundColor: darkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
