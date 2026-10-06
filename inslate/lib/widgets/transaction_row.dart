import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/enums/account_type.dart';
import '../core/enums/transaction_status.dart';
import '../models/financial_records.dart';
import '../services/financial_semantics.dart';
import '../core/presentation/financial_presentation.dart';

class TransactionRow extends StatelessWidget {
  final FinancialRecord record;
  final AccountEndpoint central;
  const TransactionRow({
    super.key,
    required this.record,
    this.central = const AccountEndpoint(AccountType.mpesa),
  });

  @override
  Widget build(BuildContext context) {
    final presentation = TransactionPresentation.forRecord(
      record,
      central: central,
    );
    final color = switch (presentation.movement) {
      MovementClass.income => const Color(0xFF0F9D8A),
      MovementClass.expense => const Color(0xFFD95C5C),
      _ => const Color(0xFF0B1F3A),
    };
    final icon = switch (presentation.movement) {
      MovementClass.income => Icons.south_west_rounded,
      MovementClass.expense => Icons.north_east_rounded,
      MovementClass.internalTransfer => Icons.swap_horiz_rounded,
      MovementClass.loanBorrowing ||
      MovementClass.loanRepayment => Icons.account_balance_outlined,
      MovementClass.unresolved => Icons.help_outline_rounded,
    };
    final partyName = record.party?.name.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  presentation.directionLabel,
                  style: TextStyle(fontSize: 12, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${subtypeLabel(record.subtype)} · ${DateFormat.jm().format(record.transactionDate ?? record.receivedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  record.reference,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (record.status != TransactionStatus.successful)
                  Text(
                    'Status: ${record.status.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${presentation.amountPrefix}${formatMoney(record.amount)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                if (record.transactionCost != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fee ${formatMoney(record.transactionCost)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
