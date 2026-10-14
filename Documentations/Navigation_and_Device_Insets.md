# Navigation and device-safe layout

`InSlateApp` wraps its Navigator in `AppViewport`. Every tab, pushed screen and Navigator overlay therefore shares the same usable device area, including pages whose bodies use explicitly padded lists instead of their own `SafeArea`.

- The viewport consumes the phone's bottom navigation inset and landscape side cutouts once. It uses Flutter's live `MediaQuery` insets rather than an assumed gesture-bar or three-button-bar height.
- Existing inner safe areas and the Material navigation bar receive already-consumed padding. They do not add the same phone inset a second time.
- AppShell's Scaffold still reserves the app's bottom tab bar, including its separator. Tab content, Activity pagination and snackbars stay above it.
- Pushed routes keep their existing full-screen behavior and back stack. System Back returns to the previous selected tab or dismisses the current dialog/sheet; this change does not introduce a separate Navigator or change app-exit behavior.
- Top padding remains available to each AppBar or custom header. The restored Dashboard's layout and styling are unchanged.
- Keyboard resizing remains owned by Scaffold. The viewport does not permanently reserve `viewPadding.bottom` while the keyboard is open, which would create an extra gap above the keyboard.
- System navigation icons use the current theme's contrast, with Android contrast enforcement retained. The app paints behind the reserved area and requests a transparent system navigation background; the OS controls supported edge-to-edge behavior.

The shared `showSlateSheet` helper also applies its own bottom safe area, making it safe when used outside the app viewport. It retains scrollable content and keyboard padding. Existing Material dialogs, menus, pickers and other modal routes benefit from the app-level boundary without individual fixed bottom offsets. Modals retain their normal barrier behavior over the tab bar.

## Activity on short screens

Activity's controls can exceed the available height in landscape or with a large keyboard. `_ActivityLayout` makes the control area scrollable when usable height is limited, while retaining a transaction viewport and keeping pagination above navigation. Filters/Clear filters wrap at narrow widths or larger text sizes. The layout hierarchy stays stable during resizing so search focus, text, query state and the transaction scroll controller are retained. Portrait controls retain their original placement.

## Validation

`test/screens/navigation_insets_test.dart` adds 16 functional widget checks against the production app entry point and representative screens/overlays:

- All four tabs with zero, gesture-sized and three-button-sized bottom insets, without duplicate safe padding.
- Pagination and snackbars above the app tab bar.
- Landscape side cutouts, reachable filter controls and native back navigation from a pushed instruments page.
- A profile page without a local safe area and the final instrument-form save action.
- Keyboard resizing with search focus/text retained and reachable form/pagination actions.
- Shared sheets both inside and outside the app viewport, with and without keyboard insets.
- Dialog dismissal by system Back and theme-aware system navigation icon contrast.

The 37 focused navigation, Activity/search and app-shell checks pass. A broader run passed 126 checks and reproduced five pre-existing failures: four category-filter tests still expect obsolete pagination labels, and an avatar-selection test leaves its picker open after selection. The same five failures were reproduced on the unchanged baseline; those files and behaviors were not changed here. Application code and the new test file analyze cleanly; changed Dart files pass formatting and whitespace checks. Device insets are simulated in widget tests; physical Android gesture/three-button modes have not been exercised here. Financial data, schema, repository behavior and calculations are unchanged.

Subsequent Profile work corrected the avatar picker's use of screen width instead of sheet constraints, enabled its full-height safe scrolling, and updated the selection test to scroll its target into view before tapping. The avatar selection check now passes; see [Profile avatar and menu](Profile_Avatar_and_Menu.md) for current validation and captures.
