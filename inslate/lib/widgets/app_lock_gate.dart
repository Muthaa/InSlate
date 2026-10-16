import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_lock_provider.dart';
import '../providers/app_preferences_provider.dart';

/// Covers the entire Navigator, including pushed routes and dialogs.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appLockProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      controller.foreground();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      controller.background();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final covered = !lock.ready || lock.locked;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: covered,
          child: ExcludeFocus(excluding: covered, child: widget.child),
        ),
        if (covered)
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: AppTheme.darkBlue,
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'InSlate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lock.ready
                              ? 'Unlock with your phone’s screen lock.'
                              : 'Loading privacy settings…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (lock.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              lock.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (lock.ready)
                          FilledButton.icon(
                            key: const ValueKey('app-lock.unlock'),
                            onPressed: lock.busy
                                ? null
                                : ref.read(appLockProvider.notifier).unlock,
                            icon: const Icon(Icons.lock_open_rounded),
                            label: Text(lock.busy ? 'Verifying…' : 'Unlock'),
                          )
                        else if (lock.error != null)
                          FilledButton(
                            onPressed: () {
                              ref.invalidate(appPreferencesProvider);
                              ref.read(appLockProvider.notifier).initialize();
                            },
                            child: const Text('Retry privacy settings'),
                          )
                        else
                          const CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
