import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

class AppTheme {
  AppTheme._();
  // Compatibility aliases for screens awaiting their own v2 milestones.
  static const teal = Color(0xFF0F9D8A);
  static const darkBlue = Color(0xFF0B1F3A);
  static const white = Colors.white;
  static const darkTeal = Color(0xFF1B3251);
  static const appBackground = Color(0xFFF4F7F8);
  static const cardBackground = Colors.white;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final p = brightness == Brightness.light
        ? SlateColors.light
        : SlateColors.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: darkBlue,
          brightness: brightness,
        ).copyWith(
          primary: p.movement,
          onPrimary: brightness == Brightness.light ? Colors.white : darkBlue,
          secondary: p.income,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          outline: p.line,
          error: p.spending,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme
        .apply(bodyColor: p.ink, displayColor: p.ink)
        .copyWith(
          displaySmall: TextStyle(
            fontSize: 36,
            height: 1.15,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            height: 1.2,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            height: 1.3,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: p.ink,
          ),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: p.ink),
          bodySmall: TextStyle(fontSize: 12, height: 1.5, color: p.muted),
          labelLarge: TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: p.ink,
          ),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SlateRadius.control),
    );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(shape),
    );
    return base.copyWith(
      extensions: [p],
      textTheme: text.apply(fontFamily: 'Roboto'),
      scaffoldBackgroundColor: p.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: SlateElevation.flat,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SlateRadius.card),
          side: BorderSide(color: p.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 24),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: SlateElevation.overlay,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SlateRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: SlateElevation.overlay,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SlateRadius.sheet),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: SlateElevation.overlay,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inset,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SlateRadius.control),
          borderSide: BorderSide(color: p.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: button.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: button),
      textButtonTheme: TextButtonThemeData(style: button),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.inset,
        selectedColor: p.hero,
        labelStyle: text.labelLarge,
        side: BorderSide(color: p.line),
        shape: shape,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.movement,
        unselectedLabelColor: p.muted,
        indicatorColor: p.movement,
        dividerColor: p.line,
        labelStyle: text.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        indicatorColor: p.inset,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
    );
  }
}
