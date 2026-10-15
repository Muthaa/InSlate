# Profile avatar and finance menu

Dashboard keeps its original layout, with a white avatar icon. The bottom app navigation matches the navy app bar and uses light labels and yellow selected icons for contrast. The app-bar shortcut now shows the locally selected avatar and opens the existing Profile tab, retaining the bottom navigation. Insights remains available through its own tab. When Dashboard is used outside AppShell, the shortcut pushes the same Profile overview as a normal route.

The rocket (`LocalAvatar.astronaut`, the existing stored enum value) is the default for unset or unrecognized preferences. Existing selections, including a saved robot, are retained. Saving a selection in Profile refreshes both the Profile avatar and Dashboard shortcut. No database migration or financial logic changes are required.

The four destinations under **Manage your finances** use a two-column grid with equal-height cards in each row. The grid switches to one column below 340 logical pixels of available width or when a 16-point font scales above 22 points. Content determines card height, and the page scrolls normally. Destinations and their behavior remain the same.

Cards use a compact horizontal layout with the icon, wrapping title and arrow on the same row. Descriptions remain available to assistive technologies without adding visible height. Cards use the shared semantic surface, border, text and muted-text tokens, with rounded corners and restrained teal, blue and yellow icon backgrounds. Light and dark themes retain readable headings and surfaces. The avatar picker uses its actual sheet constraints, scrolls when needed, and respects device safe areas.

## Review captures

These are rendered Flutter widget captures with real Roboto and Material icon fonts. Dashboard records are synthetic. Captures omit system navigation; the production inset tests cover the app and phone navigation boundaries.

- [Dashboard with rocket shortcut](v2-captures/profile/home.png)
- [Profile light](v2-captures/profile/profile-light.png)
- [Profile dark](v2-captures/profile/profile-dark.png)
- [Previous Dashboard shortcut](v2-captures/restored/home.png)

## Verification

70 focused tests pass across Dashboard, Profile/Your Data, avatar preferences and selection, AppShell, device/navigation insets and responsive Profile grid checks. After compacting the cards, changing the Dashboard avatar to white and matching the bottom navigation to the navy app bar, all 25 related grid, AppShell, navigation and capture tests pass again. Application code and the changed/new tests analyze cleanly; changed Dart files pass formatting and whitespace checks.

The avatar-selection test now scrolls its target into view before tapping; its earlier failure came from an offscreen target. Checks cover rocket defaults, preservation of explicit selections, live Dashboard updates, Profile-tab reuse, light/dark surfaces and doubled text size. Physical Android testing and the full test suite were not run.
