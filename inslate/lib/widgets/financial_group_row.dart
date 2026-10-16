import 'package:flutter/material.dart';
import '../core/design/design_tokens.dart';
import '../models/financial_breakdown.dart';
import '../core/presentation/financial_presentation.dart';

/// Shared by Dashboard previews and all financial breakdowns.
class FinancialGroupRow extends StatelessWidget {
  final FinancialGroup group;
  final VoidCallback onTap;
  final bool showShare;
  final bool compact;
  final Color? accentColor;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;
  const FinancialGroupRow({
    super.key,
    required this.group,
    required this.onTap,
    this.showShare = false,
    this.compact = false,
    this.accentColor,
    this.labelStyle,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style:
                          labelStyle ??
                          TextStyle(
                            fontSize: compact ? 13 : null,
                            fontWeight: FontWeight.w700,
                            color: SlateColors.of(context).ink,
                          ),
                    ),
                    if (group.detail != null)
                      Text(
                        group.detail!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      '${group.count} transaction${group.count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 11 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  formatMoney(group.amount),
                  textAlign: TextAlign.end,
                  style:
                      amountStyle ??
                      TextStyle(
                        fontSize: compact ? 13 : null,
                        fontWeight: FontWeight.w800,
                        color: accentColor ?? SlateColors.of(context).ink,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
          if (showShare) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: group.share.clamp(0, 1),
                    minHeight: 5,
                    color: accentColor ?? SlateColors.of(context).income,
                    backgroundColor: SlateColors.of(context).inset,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(group.share * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: compact ? 11 : null,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
