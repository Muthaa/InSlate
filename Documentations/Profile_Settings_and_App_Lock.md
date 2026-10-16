# Profile settings and Android app lock

Profile now has a Settings grid beneath Manage your finances, using the same compact navy cards:

- **Appearance** saves a Reduce motion preference, applies instant page transitions and exposes reduced motion to supported shared components. System accessibility settings still take precedence, and text size follows the phone. A theme-mode selector is not included in this milestone.
- **Privacy & app lock** offers opt-in Android device-credential protection.
- **Backup & restore** is visibly marked **Future implementation**, both on its menu card and destination. No export, upload or restore operation is implemented.
- **Help & about** explains cash flow versus balances, separate savings/investment/loan movements and recorded SMS balances, and opens the real open-source license page.

## App lock behavior

Enabling and disabling app lock each require the phone's existing PIN, pattern or password through Android's system credential-confirmation screen. InSlate never reads or stores those credentials, and has no separate PIN implementation. The option is unavailable when device verification is unsupported or a phone screen lock is not configured.

The enabled preference is stored locally in SharedPreferences; unlocked session state exists only in memory. A protected session starts locked and covers the entire Navigator, including pushed routes and dialogs. Leaving the foreground locks it again and removes keyboard focus. Unlock cancellation, platform errors, unavailable privacy settings and late verification completed while backgrounded keep content covered. Retrying a preference-load error reloads the persisted lock rather than bypassing it. Concurrent verification requests are prevented.

Android's `FLAG_SECURE` blocks screenshots and recent-app content while protection is enabled. The native activity starts protected until Flutter has loaded the preference. Screen-protection changes are applied before committing the matching setting, and failed saves restore the preceding protection state. Successful unlock reasserts native screen protection. App lock protects access to the UI; it does not encrypt the database or implement backup encryption.

The implementation uses Android's existing Keyguard credential API and one MethodChannel. No new Flutter dependency, SMS permission, database schema or financial calculation changes are included.

## Insights changes

Expense and income purpose-category headers no longer display a duplicate total. Individual category amounts, counts, shares and drill-downs remain unchanged. Purpose unspecified is now the last Insights card, below income categories, with a 16-pixel top gap.

## Review captures

[Profile](v2-captures/settings/profile-light.png) · [Profile dark](v2-captures/settings/profile-dark.png) · [Appearance](v2-captures/settings/appearance.png) · [Privacy](v2-captures/settings/privacy.png) · [Locked app](v2-captures/settings/app-lock.png) · [Backup](v2-captures/settings/backup.png) · [Help](v2-captures/settings/help.png) · [Insights](v2-captures/settings/insights-categories.png)

Captures use actual Flutter rendering, synthetic financial records and a fake device-verification service. They do not show or simulate a real phone credential prompt.

## Validation and remaining device QA

66 focused unit/widget/render checks pass across lock state, the full Navigator gate, settings navigation and persistence, Profile, Insights, AppShell, avatar selection, Your Data and device insets. Checks cover cancellation, failed writes, unavailable device lock, background/resume, stale authentication, duplicate prompts, failed preference-load retry, dialogs, retained routes, reduced-motion persistence and large text.

Application code and affected tests analyze cleanly; formatting and whitespace checks pass. The native MainActivity compiles to JVM 17 bytecode against Android 36, this Flutter engine's embedding and its AndroidX lifecycle/annotation dependencies. This is a source compilation check, not a full Gradle/APK build. Physical Android testing remains necessary for real credential confirmation/cancellation, app restarts, screenshot blocking and recent-app previews. The full test suite was not run.
