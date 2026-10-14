import 'package:flutter/material.dart';
import '../presentation/financial_presentation.dart';
import 'design_tokens.dart';

export 'design_tokens.dart';

class SlateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const SlateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SlateSpace.xl),
    this.color,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: padding, child: child),
  );
}

/// Full precision and tabular figures. Never converts a movement to a balance.
class SlateAmount extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Color? color;
  final String prefix;
  final bool pending;
  const SlateAmount({
    super.key,
    required this.amount,
    this.style,
    this.color,
    this.prefix = '',
    this.pending = false,
  });
  @override
  Widget build(BuildContext context) => Text(
    pending ? '—' : '$prefix${formatMoney(amount)}',
    style: (style ?? Theme.of(context).textTheme.titleMedium!).copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

class SlateSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SlateSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?action,
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: SlateSpace.xs),
        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

enum SlateTone { neutral, income, spending, movement, attention }

Color slateToneColor(BuildContext context, SlateTone tone) {
  final p = SlateColors.of(context);
  return switch (tone) {
    SlateTone.neutral => p.muted,
    SlateTone.income => p.income,
    SlateTone.spending => p.spending,
    SlateTone.movement => p.movement,
    SlateTone.attention => p.attention,
  };
}

class SlateStatus extends StatelessWidget {
  final String label;
  final IconData icon;
  final SlateTone tone;
  const SlateStatus({
    super.key,
    required this.label,
    required this.icon,
    this.tone = SlateTone.neutral,
  });
  @override
  Widget build(BuildContext context) {
    final color = slateToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SlateRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keyboard-accessible period/tab control; minimum touch target 48 logical px.
class SlateChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  const SlateChoice({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    final p = SlateColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: TextButton(
        onPressed: onSelected,
        style: TextButton.styleFrom(
          backgroundColor: selected ? p.hero : p.surface,
          foregroundColor: selected ? p.onHero : p.ink,
          disabledForegroundColor: p.muted,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: p.line),
        ),
        child: Text(label),
      ),
    );
  }
}

enum SlateStateKind { loading, empty, error }

class SlateState extends StatelessWidget {
  final SlateStateKind kind;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SlateState({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    final p = SlateColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(SlateSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.inset,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              switch (kind) {
                SlateStateKind.loading => Icons.hourglass_top_rounded,
                SlateStateKind.empty => Icons.auto_stories_outlined,
                SlateStateKind.error => Icons.refresh_rounded,
              },
              size: 30,
              color: p.movement,
            ),
          ),
          const SizedBox(height: SlateSpace.lg),
          Semantics(
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: SlateSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: SlateSpace.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Scrollable content and safe insets; no fixed-height forms or clipped text.
Future<T?> showSlateSheet<T>(BuildContext context, {required Widget child}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: SlateMotion.duration(context),
        reverseDuration: SlateMotion.duration(context),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SlateSpace.xl),
            child: child,
          ),
        ),
      ),
    );
