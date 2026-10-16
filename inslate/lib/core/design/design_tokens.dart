import 'package:flutter/material.dart';

/// InSlate's semantic palette. Brand cyan/yellow are accents, never body text
/// on white. Financial meaning is also expressed through labels and icons.
@immutable
class SlateColors extends ThemeExtension<SlateColors> {
  final Color canvas, surface, inset, ink, muted, line;
  final Color income, spending, movement, attention, attentionSurface;
  final Color hero, onHero;
  const SlateColors({
    required this.canvas,
    required this.surface,
    required this.inset,
    required this.ink,
    required this.muted,
    required this.line,
    required this.income,
    required this.spending,
    required this.movement,
    required this.attention,
    required this.attentionSurface,
    required this.hero,
    required this.onHero,
  });
  static const brandBlue = Color(0xFF38B6FF);
  static const brandYellow = Color(0xFFFFDE59);
  static const light = SlateColors(
    canvas: Color(0xFFF4F7F8),
    surface: Color(0xFFFFFFFF),
    inset: Color(0xFFEDF2F5),
    ink: Color(0xFF0B1F3A),
    muted: Color(0xFF526274),
    line: Color(0xFFDCE4EB),
    income: Color(0xFF087568),
    spending: Color(0xFFB33D45),
    movement: Color(0xFF285E88),
    attention: Color(0xFF795600),
    attentionSurface: Color(0xFFFFF5CC),
    hero: Color(0xFF0B1F3A),
    onHero: Color(0xFFF4F7F8),
  );
  static const dark = SlateColors(
    canvas: Color(0xFF091522),
    surface: Color(0xFF122438),
    inset: Color(0xFF1C3148),
    ink: Color(0xFFF4F7F8),
    muted: Color(0xFFB1C0CF),
    line: Color(0xFF344B62),
    income: Color(0xFF70D9C2),
    spending: Color(0xFFFFA4AA),
    movement: Color(0xFF8BCEFF),
    attention: Color(0xFFFFDE59),
    attentionSurface: Color(0xFF342C15),
    hero: Color(0xFF16324E),
    onHero: Color(0xFFF4F7F8),
  );
  static SlateColors of(BuildContext context) =>
      Theme.of(context).extension<SlateColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  SlateColors copyWith({
    Color? canvas,
    Color? surface,
    Color? inset,
    Color? ink,
    Color? muted,
    Color? line,
    Color? income,
    Color? spending,
    Color? movement,
    Color? attention,
    Color? attentionSurface,
    Color? hero,
    Color? onHero,
  }) => SlateColors(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    inset: inset ?? this.inset,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    income: income ?? this.income,
    spending: spending ?? this.spending,
    movement: movement ?? this.movement,
    attention: attention ?? this.attention,
    attentionSurface: attentionSurface ?? this.attentionSurface,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
  );
  @override
  SlateColors lerp(covariant SlateColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SlateColors(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      inset: mix(inset, other.inset),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      income: mix(income, other.income),
      spending: mix(spending, other.spending),
      movement: mix(movement, other.movement),
      attention: mix(attention, other.attention),
      attentionSurface: mix(attentionSurface, other.attentionSurface),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
    );
  }
}

abstract final class SlateSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 24.0, xxl = 32.0, section = 40.0;
  static const pageWidth = 760.0;
}

abstract final class SlateRadius {
  static const control = 12.0, card = 24.0, sheet = 28.0;
}

abstract final class SlateMotion {
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
}

abstract final class SlateElevation {
  static const flat = 0.0, overlay = 6.0;
}
