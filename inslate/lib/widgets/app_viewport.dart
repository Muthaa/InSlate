import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Navigator and all of its routes/overlays share one device-safe viewport.
///
/// Reserve phone navigation and side cutouts once, including on pages without
/// their own SafeArea. Descendant SafeAreas and NavigationBar receive consumed
/// padding, so they do not add the same inset again. Scaffolds still reserve
/// the app tab bar and keyboard space; no navigation-bar heights are hard-coded.
/// Top insets remain available to AppBars and custom page headers.
class AppViewport extends StatelessWidget {
  final Widget child;
  const AppViewport({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: true,
      ),
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}
