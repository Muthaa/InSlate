import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_preferences_provider.dart';
import '../../models/import_progress.dart';
import '../../providers/import_provider.dart';
import '../dashboard/dashboard_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startImport();
    });
  }

  Future<void> _startImport() async {
    if (_started) {
      return;
    }

    _started = true;

    await ref.read(importProvider.notifier).importMessages();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(importProvider);

    ref.listen<ImportProgress>(importProvider, (previous, next) async {
      if (next.status == ImportStatus.completed &&
          previous?.status != ImportStatus.completed) {
        final preferences = await ref.read(appPreferencesProvider.future);

        await preferences.setOnboardingCompleted();

        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    });

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _buildContent(context, theme, colors, progress),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    ImportProgress progress,
  ) {
    switch (progress.status) {
      case ImportStatus.idle:
      case ImportStatus.requestingPermission:
        return _buildLoading(
          theme,
          colors,
          'Setting up your Insights...',
          'Requesting SMS permission',
        );

      case ImportStatus.loadingMessages:
        return _buildLoading(
          theme,
          colors,
          'Loading your messages...',
          'Finding your M-PESA transactions',
        );

      case ImportStatus.processing:
        return _buildProgress(
          theme,
          colors,
          progress,
          'Understanding your transactions...',
        );

      case ImportStatus.saving:
        return _buildProgress(
          theme,
          colors,
          progress,
          'Saving your financial history...',
        );

      case ImportStatus.completed:
        return _buildCompleted(theme, colors, progress);

      case ImportStatus.failed:
        return _buildFailed(theme, colors, progress);
    }
  }

  Widget _buildLoading(
    ThemeData theme,
    ColorScheme colors,
    String title,
    String subtitle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: colors.primary),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(
    ThemeData theme,
    ColorScheme colors,
    ImportProgress progress,
    String title,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_balance_wallet_rounded,
          size: 52,
          color: colors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${progress.processed} / ${progress.total}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress.percentage,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: colors.primary,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 20),
        Text('Imported: ${progress.imported}'),
        Text('Skipped: ${progress.skipped}'),
        Text('Failed: ${progress.failed}'),
      ],
    );
  }

  Widget _buildCompleted(
    ThemeData theme,
    ColorScheme colors,
    ImportProgress progress,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 72, color: colors.primary),
        const SizedBox(height: 24),
        Text(
          'Your finances are ready',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We imported ${progress.imported} transactions.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildFailed(
    ThemeData theme,
    ColorScheme colors,
    ImportProgress progress,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: colors.error),
        const SizedBox(height: 24),
        Text(
          'Setup could not be completed',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          progress.error ?? 'Something went wrong.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
