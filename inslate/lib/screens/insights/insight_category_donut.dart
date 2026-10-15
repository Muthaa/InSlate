import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_filter.dart';
import '../../models/insights.dart';

/// Distribution of existing category totals; signed net values are never
/// converted to absolute values or silently omitted to fit a pie chart.
class InsightCategoryDonut extends StatelessWidget {
  final List<InsightCategory> groups;
  final double total;
  final bool expense;
  final ValueChanged<ActivityFilter> onOpen;
  const InsightCategoryDonut({
    super.key,
    required this.groups,
    required this.total,
    required this.onOpen,
    this.expense = false,
  });

  static const _palette = [
    Color(0xFF2876A8),
    Color(0xFF087568),
    Color(0xFF8E6423),
    Color(0xFF8553A6),
    Color(0xFFB33D45),
    Color(0xFF526F31),
    Color(0xFF337C87),
    Color(0xFF445E89),
  ];
  Color _color(int index) => index < _palette.length
      ? _palette[index]
      : HSLColor.fromAHSL(1, (index * 137.508) % 360, 0.55, 0.36).toColor();

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          expense
              ? 'No ordinary expenses in this period.'
              : 'No ordinary income in this period.',
        ),
      );
    }
    final sum = groups.fold<double>(0, (sum, group) => sum + group.amount);
    final nonnegative = groups.every((g) => g.amount.isFinite && g.amount >= 0);
    final available =
        total.isFinite &&
        total > 0 &&
        sum.isFinite &&
        sum > 0 &&
        nonnegative &&
        (sum - total).abs() <= math.max(1e-8, total.abs() * 1e-9);
    final colors = [for (var i = 0; i < groups.length; i++) _color(i)];
    final shares = [
      for (final group in groups) available ? group.amount / sum : 0.0,
    ];
    final accent = expense ? Colors.red.shade700 : AppTheme.teal;
    final explanation = total == 0
        ? 'Share unavailable (zero total)'
        : total < 0
        ? 'Share unavailable (negative net total)'
        : !nonnegative
        ? 'Donut unavailable for negative category values.'
        : 'Category distribution unavailable.';
    return Column(
      children: [
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter = math.min(224.0, constraints.maxWidth);
            final label = SizedBox(
              width: diameter * 0.58,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expense ? 'Expenses' : 'Income',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  if (!available)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No distribution',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
            final chart = SizedBox.square(
              dimension: diameter,
              child: CustomPaint(
                painter: _DonutPainter(shares: shares, colors: colors),
                child: Center(child: ExcludeSemantics(child: label)),
              ),
            );
            return Center(
              child: Semantics(
                label:
                    '${expense ? 'Expense' : 'Income'} category donut. Total ${formatMoney(total)}. ${available ? 'Use the categories below to open transactions.' : explanation}',
                child: GestureDetector(
                  key: ValueKey(
                    'insights.donut.${expense ? 'expenses' : 'income'}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: !available
                      ? null
                      : (details) {
                          final offset =
                              details.localPosition -
                              Offset(diameter / 2, diameter / 2);
                          final distance = offset.distance;
                          final radius = diameter / 2 - 16;
                          if (distance < radius - 14 ||
                              distance > radius + 14) {
                            return;
                          }
                          final angle =
                              (math.atan2(offset.dy, offset.dx) + math.pi / 2) %
                              (2 * math.pi);
                          var end = 0.0;
                          for (var i = 0; i < shares.length; i++) {
                            end += shares[i] * 2 * math.pi;
                            if (angle < end && shares[i] > 0) {
                              onOpen(groups[i].filter);
                              return;
                            }
                          }
                        },
                  child: chart,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          available
              ? 'Tap a segment or category to view transactions.'
              : explanation,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < groups.length; index++)
          _legend(context, groups[index], colors[index], accent),
      ],
    );
  }

  Widget _legend(
    BuildContext context,
    InsightCategory group,
    Color color,
    Color accent,
  ) {
    final share = group.share(total);
    final shareLabel = share == null
        ? ''
        : ' · ${(share * 100).toStringAsFixed(1)}%';
    return InkWell(
      key: ValueKey(
        'insights.category.${expense ? 'expenses' : 'income'}.${group.id ?? 'uncategorized'}',
      ),
      borderRadius: BorderRadius.circular(10),
      onTap: () => onOpen(group.filter),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${group.name}${group.hidden ? ' (hidden)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.count} ${group.count == 1 ? 'transaction' : 'transactions'}$shareLabel',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatMoney(group.amount),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> shares;
  final List<Color> colors;
  _DonutPainter({required this.shares, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    canvas.drawCircle(center, radius, paint..color = const Color(0xFFEDF2F5));
    var start = -math.pi / 2;
    for (var index = 0; index < shares.length; index++) {
      final sweep = shares[index] * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          paint..color = colors[index],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.shares != shares || oldDelegate.colors != colors;
}
