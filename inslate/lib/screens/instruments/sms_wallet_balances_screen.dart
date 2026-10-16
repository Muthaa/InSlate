import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../models/balance_observation.dart';
import '../../providers/balance_evidence_provider.dart';
import 'historical_balance_extraction_section.dart';
import 'sms_balance_history_screen.dart';

/// Latest recorded balance per SMS wallet/product; never a calculated balance.
class SmsBalanceObservationsScreen extends ConsumerStatefulWidget {
  final bool unattributedOnly;
  const SmsBalanceObservationsScreen({
    super.key,
    this.unattributedOnly = false,
  });

  @override
  ConsumerState<SmsBalanceObservationsScreen> createState() =>
      _SmsWalletsState();
}

class _SmsWalletsState extends ConsumerState<SmsBalanceObservationsScreen> {
  late bool _needsAssociation = widget.unattributedOnly;

  @override
  Widget build(BuildContext context) {
    final colors = SlateColors.of(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: const Text('SMS balance observations'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const HistoricalBalanceExtractionSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your wallet balances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One card per wallet or product. Balances reflect the latest recorded SMS, not a live balance.',
                    style: TextStyle(color: colors.muted),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('All wallets')),
                      ButtonSegment(
                        value: true,
                        label: Text('Needs association'),
                      ),
                    ],
                    selected: {_needsAssociation},
                    onSelectionChanged: (values) =>
                        setState(() => _needsAssociation = values.single),
                  ),
                ],
              ),
            ),
            ref
                .watch(smsWalletBalancesProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(smsWalletBalancesProvider),
                      child: const Text(
                        'Unable to load wallet balances. Retry',
                      ),
                    ),
                  ),
                  data: (wallets) {
                    final visible = wallets
                        .where(
                          (wallet) =>
                              !_needsAssociation ||
                              (!wallet.isMeasuredWallet &&
                                  wallet.latest.accountId == null),
                        )
                        .toList();
                    final count = wallets.fold(
                      0,
                      (sum, wallet) => sum + wallet.observationCount,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '$count SMS observations',
                            style: TextStyle(color: colors.muted),
                          ),
                          const SizedBox(height: 12),
                          if (visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 40,
                                    color: colors.muted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _needsAssociation
                                        ? 'No wallets need association.'
                                        : 'No SMS balance observations.',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    wallets.isEmpty
                                        ? 'Supported balances will appear when recorded. You can also extract balances from stored SMS above.'
                                        : 'M-PESA is the measured wallet and needs no attribution.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colors.muted),
                                  ),
                                ],
                              ),
                            ),
                          for (final wallet in visible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _WalletCard(
                                key: ValueKey('sms.wallet.${wallet.key}'),
                                wallet: wallet,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final SmsWalletBalance wallet;
  const _WalletCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final e = wallet.latest;
    final measured = wallet.isMeasuredWallet;
    final date =
        'As of ${DateFormat.yMMMd().add_jm().format(e.asOf.toLocal())}';
    return Material(
      color: AppTheme.darkBlue,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF185C91), AppTheme.darkBlue],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      measured
                          ? Icons.account_balance_wallet_outlined
                          : Icons.account_balance_outlined,
                      color: measured
                          ? SlateColors.brandYellow
                          : SlateColors.brandBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.subjectLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (measured)
                    const Icon(
                      Icons.contactless_outlined,
                      color: Color(0xFFDCEAF5),
                      size: 24,
                    )
                  else
                    IconButton(
                      key: ValueKey('sms.associate.${e.id}'),
                      tooltip: e.accountId == null
                          ? 'Associate latest'
                          : 'Review association',
                      icon: const Icon(
                        Icons.link,
                        color: SlateColors.brandBlue,
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            SmsBalanceAssociationDialog(evidence: e),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${e.kind.label} · SMS-reported',
                style: const TextStyle(color: Color(0xFFDCEAF5), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                e.amountText,
                key: ValueKey('sms.wallet.amount.${wallet.key}'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Tooltip(
                    message: e.timeBasisLabel,
                    child: Text(
                      date,
                      semanticsLabel: '$date. ${e.timeBasisLabel}',
                      style: const TextStyle(
                        color: Color(0xFFDCEAF5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: ValueKey('sms.wallet.history.${wallet.key}'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.history, size: 18),
                    label: Text('History (${wallet.observationCount})'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SmsBalanceHistoryScreen(
                          subjectFamily: e.subjectFamily,
                          currency: e.currency,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                measured
                    ? 'Measured M-PESA wallet · no attribution needed'
                    : 'Latest observation: ${e.associationLabel}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
