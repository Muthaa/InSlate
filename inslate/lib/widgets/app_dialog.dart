import 'package:flutter/material.dart';
import '../core/design/design_tokens.dart';

/// Shared presentation for forms and confirmations; callers own every action.
class AppDialog extends StatelessWidget {
  final Widget title;
  final Widget? content;
  final List<Widget>? actions;
  final IconData icon;
  final bool destructive;
  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.actions,
    this.icon = Icons.info_outline,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = SlateColors.of(context);
    final accent = destructive ? palette.spending : palette.movement;
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? accent : theme.colorScheme.primary,
            foregroundColor: destructive
                ? (theme.brightness == Brightness.dark
                      ? SlateColors.dark.canvas
                      : Colors.white)
                : theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SlateRadius.control),
            ),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SlateRadius.sheet),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        scrollable: true,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SlateRadius.control),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.titleMedium!.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w700,
                ),
                child: title,
              ),
            ),
          ],
        ),
        content: content == null
            ? null
            : DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: palette.muted,
                  height: 1.5,
                ),
                child: content!,
              ),
        actions: actions,
      ),
    );
  }
}

/// Dismissal is cancellation. Financial actions remain owned by the caller.
Future<bool> showSlateConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showSlateDialog<bool>(
      context,
      builder: (context) => AppDialog(
        title: Text(title),
        content: Text(message),
        destructive: destructive,
        icon: destructive ? Icons.warning_amber_rounded : Icons.info_outline,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

/// One motion policy for informational dialogs and confirmations.
Future<T?> showSlateDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showDialog<T>(
  context: context,
  builder: builder,
  animationStyle: AnimationStyle(
    duration: SlateMotion.duration(context),
    reverseDuration: SlateMotion.duration(context),
  ),
);
