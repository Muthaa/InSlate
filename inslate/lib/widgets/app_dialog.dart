import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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
    final accent = destructive ? theme.colorScheme.error : AppTheme.teal;
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? accent : AppTheme.darkBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: AppTheme.appBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.titleMedium!.copyWith(
                  color: AppTheme.darkBlue,
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
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                child: content!,
              ),
        actions: actions,
      ),
    );
  }
}
