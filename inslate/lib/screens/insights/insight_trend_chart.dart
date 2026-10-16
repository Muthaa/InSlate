import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity_filter.dart';
import '../../models/insights.dart';

class InsightTrendChart extends StatefulWidget {
  final List<InsightTrend> trends;
  final bool monthly;
  final ValueChanged<ActivityFilter> onOpen;
  const InsightTrendChart({
    super.key,
    required this.trends,
    required this.monthly,
    required this.onOpen,
  });

  @override
  State<InsightTrendChart> createState() => _InsightTrendChartState();
}

class _InsightTrendChartState extends State<InsightTrendChart> {
  DateTime? _selected;
  bool _tooltipVisible = false;

  @override
  Widget build(BuildContext context) {
    final trends = widget.trends;
    if (trends.isEmpty) return const Text('No trend data for this period.');
    var index = trends.indexWhere((t) => t.period.start == _selected);
    if (index < 0) {
      index = trends.indexWhere((t) => t.income != 0 || t.expenses != 0);
      if (index < 0) index = 0;
    }
    final selected = trends[index];
    String date(DateTime value) => widget.monthly
        ? DateFormat.yMMM().format(value)
        : DateFormat.MMMd().format(value);
    Widget amount(ActivityScope scope, double value, Color color) => TextButton(
      key: ValueKey(
        'insights.trend.${scope.name}.${selected.period.start.millisecondsSinceEpoch}',
      ),
      onPressed: () => widget.onOpen(selected.filter(scope)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: color, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  scope == ActivityScope.income ? 'Income' : 'Expenses',
                  style: TextStyle(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              formatMoney(value),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label: 'Income and expense time series in KES',
            child: GestureDetector(
              key: const ValueKey('insights.trend.chart'),
              onTapDown: (details) {
                final width = constraints.maxWidth - 52;
                final fraction = ((details.localPosition.dx - 44) / width)
                    .clamp(0.0, 1.0);
                final first = trends.first.period.start.millisecondsSinceEpoch;
                final span =
                    trends.last.period.start.millisecondsSinceEpoch - first;
                final target = first + span * fraction;
                final nearest = trends.reduce(
                  (a, b) =>
                      (a.period.start.millisecondsSinceEpoch - target).abs() <=
                          (b.period.start.millisecondsSinceEpoch - target).abs()
                      ? a
                      : b,
                );
                setState(() {
                  _selected = nearest.period.start;
                  _tooltipVisible = true;
                });
              },
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _TrendPainter(trends, index, widget.monthly),
                    size: Size(constraints.maxWidth, 220),
                  ),
                  if (_tooltipVisible && _selected == selected.period.start)
                    Positioned(
                      top: 28,
                      left: 44,
                      right: 8,
                      child: Align(
                        alignment: index < trends.length / 2
                            ? Alignment.topLeft
                            : Alignment.topRight,
                        child: Material(
                          key: const ValueKey('insights.trend.tooltip'),
                          color: Colors.white,
                          elevation: 5,
                          shadowColor: AppTheme.darkBlue.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 260),
                            padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        date(selected.period.start),
                                        style: const TextStyle(
                                          color: AppTheme.darkBlue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Close chart tooltip',
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(
                                        () => _tooltipVisible = false,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 8),
                                const SizedBox(height: 4),
                                Text(
                                  'Income ${formatMoney(selected.income)}',
                                  style: const TextStyle(
                                    color: AppTheme.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Expenses ${formatMoney(selected.expenses)}',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: widget.monthly ? 'Previous month' : 'Previous day',
              onPressed: index == 0
                  ? null
                  : () => setState(
                      () => _selected = trends[index - 1].period.start,
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('insights.trend.selectDate'),
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(date(selected.period.start)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selected.period.start,
                    firstDate: trends.first.period.start,
                    lastDate: trends.last.period.end.subtract(
                      const Duration(days: 1),
                    ),
                    helpText: widget.monthly
                        ? 'Choose a month using any date'
                        : 'Choose a day',
                    cancelText: 'Cancel',
                    confirmText: 'Select date',
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppTheme.teal,
                          onPrimary: Colors.white,
                          surface: AppTheme.appBackground,
                          onSurface: AppTheme.darkBlue,
                        ),
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: AppTheme.appBackground,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          headerBackgroundColor: AppTheme.darkBlue,
                          headerForegroundColor: Colors.white,
                          headerHeadlineStyle: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                          headerHelpStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          dividerColor: Colors.transparent,
                          todayForegroundColor: const WidgetStatePropertyAll(
                            AppTheme.teal,
                          ),
                          todayBorder: const BorderSide(color: AppTheme.teal),
                          dayShape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked == null || !mounted) return;
                  final match = trends.indexWhere(
                    (t) =>
                        !picked.isBefore(t.period.start) &&
                        picked.isBefore(t.period.end),
                  );
                  if (match >= 0) {
                    setState(() => _selected = trends[match].period.start);
                  }
                },
              ),
            ),
            IconButton(
              tooltip: widget.monthly ? 'Next month' : 'Next day',
              onPressed: index == trends.length - 1
                  ? null
                  : () => setState(
                      () => _selected = trends[index + 1].period.start,
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: amount(
                ActivityScope.income,
                selected.income,
                AppTheme.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: amount(
                ActivityScope.expenses,
                selected.expenses,
                Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<InsightTrend> trends;
  final int selected;
  final bool monthly;
  _TrendPainter(this.trends, this.selected, this.monthly);

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(44, 32, size.width - 8, size.height - 28);
    if (plot.width <= 0) return;
    var low = 0.0;
    var high = 0.0;
    for (final t in trends) {
      low = math.min(low, math.min(t.income, t.expenses));
      high = math.max(high, math.max(t.income, t.expenses));
    }
    if (low == high) high = low + 1;
    final first = trends.first.period.start.millisecondsSinceEpoch;
    final span = trends.last.period.start.millisecondsSinceEpoch - first;
    double x(int i) => span == 0
        ? plot.center.dx
        : plot.left +
              (trends[i].period.start.millisecondsSinceEpoch - first) /
                  span *
                  plot.width;
    double y(double value) =>
        plot.bottom - (value - low) / (high - low) * plot.height;
    void label(
      String text,
      Offset position, {
      double width = 40,
      TextAlign align = TextAlign.right,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(minWidth: width, maxWidth: width);
      painter.paint(canvas, position);
    }

    final grid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final value = low + (high - low) * i / 4;
      final position = y(value);
      canvas.drawLine(
        Offset(plot.left, position),
        Offset(plot.right, position),
        grid,
      );
      label(NumberFormat.compact().format(value), Offset(0, position - 6));
    }
    label('KES', const Offset(0, 0));
    canvas.drawLine(
      Offset(plot.left, y(0)),
      Offset(plot.right, y(0)),
      Paint()..color = Colors.grey.shade400,
    );
    final dateFormat = monthly ? DateFormat('MMM yy') : DateFormat('d MMM');
    // Keep labels legible on narrow screens and include both period endpoints.
    final labelCount = math.min(
      trends.length,
      math.max(1, (plot.width / 84).floor()),
    );
    final ticks = labelCount == 1
        ? [selected]
        : List.generate(
            labelCount,
            (i) => (i * (trends.length - 1) / (labelCount - 1)).round(),
          );
    for (final i in ticks) {
      final position = (x(i) - 32).clamp(
        plot.left,
        math.max(plot.left, plot.right - 64),
      );
      canvas.drawLine(
        Offset(x(i), plot.bottom),
        Offset(x(i), plot.bottom + 4),
        grid,
      );
      label(
        dateFormat.format(trends[i].period.start),
        Offset(position.toDouble(), plot.bottom + 10),
        width: 64,
        align: i == 0 && trends.length > 1
            ? TextAlign.left
            : i == trends.length - 1 && trends.length > 1
            ? TextAlign.right
            : TextAlign.center,
      );
    }
    canvas.drawLine(
      Offset(x(selected), plot.top),
      Offset(x(selected), plot.bottom),
      grid,
    );
    void series(double Function(InsightTrend) value, Color color) {
      final path = Path();
      for (var i = 0; i < trends.length; i++) {
        if (i == 0) {
          path.moveTo(x(i), y(value(trends[i])));
        } else {
          path.lineTo(x(i), y(value(trends[i])));
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(x(selected), y(value(trends[selected]))),
        4,
        Paint()..color = color,
      );
    }

    series((t) => t.income, AppTheme.teal);
    series((t) => t.expenses, Colors.deepOrange);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      trends != oldDelegate.trends ||
      selected != oldDelegate.selected ||
      monthly != oldDelegate.monthly;
}
