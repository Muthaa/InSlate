import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design/design_tokens.dart';
import '../core/enums/account_type.dart';
import '../core/enums/transaction_status.dart';
import '../models/financial_records.dart';
import '../services/financial_semantics.dart';
import '../core/presentation/financial_presentation.dart';

class TransactionRow extends StatelessWidget {
  final FinancialRecord record;
  final AccountEndpoint central;
  final VoidCallback? onTap;
  final bool fullWidthMetadata;
  final double? nameFontSize;
  const TransactionRow({
    super.key,
    required this.record,
    this.onTap,
    this.fullWidthMetadata = false,
    this.nameFontSize,
    this.central = const AccountEndpoint(AccountType.mpesa),
  });

  @override
  Widget build(BuildContext context) {
    final presentation = TransactionPresentation.forRecord(
      record,
      central: central,
    );
    final palette = SlateColors.of(context);
    final color = switch (presentation.movement) {
      MovementClass.income => palette.income,
      MovementClass.expense => palette.spending,
      _ => palette.movement,
    };
    final icon = FinancialSemantics.isExpenseReversal(record)
        ? Icons.undo_rounded
        : switch (presentation.movement) {
            MovementClass.income => Icons.south_west_rounded,
            MovementClass.expense => Icons.north_east_rounded,
            MovementClass.internalTransfer => Icons.swap_horiz_rounded,
            MovementClass.loanBorrowing ||
            MovementClass.loanRepayment => Icons.account_balance_outlined,
            MovementClass.unresolved => Icons.help_outline_rounded,
          };
    final partyName = record.party?.name.trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partyName != null && partyName.isNotEmpty
                              ? partyName
                              : record.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          presentation.directionLabel,
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                        const SizedBox(height: 4),
                        if (!fullWidthMetadata) _metadata(context),
                        if (!fullWidthMetadata &&
                            record.status != TransactionStatus.successful)
                          Text(
                            'Status: ${record.status.name}',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${presentation.amountPrefix}${formatMoney(record.amount)}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: color,
                          ),
                        ),
                        if (record.transactionCost != 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Fee ${formatMoney(record.transactionCost)}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (fullWidthMetadata) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: _metadata(context),
              ),
              if (record.status != TransactionStatus.successful)
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Text(
                    'Status: ${record.status.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metadata(BuildContext context, {bool singleLine = false}) {
    final palette = SlateColors.of(context);
    final items = [
      Text(subtypeLabel(record.subtype)),
      Text(DateFormat.jm().format(record.transactionDate ?? record.receivedAt)),
      Text(record.reference),
    ];
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 11,
        color: palette.muted,
        fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
      ),
      child: singleLine
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  items[i],
                ],
              ],
            )
          : Wrap(spacing: 6, runSpacing: 2, children: items),
    );
  }
}
