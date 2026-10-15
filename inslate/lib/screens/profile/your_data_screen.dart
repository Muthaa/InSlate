import 'verified_reversals_section.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/responsive_card_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/import_progress.dart';
import '../../providers/import_provider.dart';
import '../../providers/your_data_provider.dart';
import '../activity/activity_screen.dart';
import 'stored_sms_screen.dart';
import '../instruments/sms_balance_observations_screen.dart';

class YourDataScreen extends ConsumerWidget {
  const YourDataScreen({super.key});
  static const _deviceDataDescription =
      'Stored locally on this device; not synchronized to an online account. '
      'SMS storage and financial transactions are separate. Stored messages may include '
      'failed attempts, duplicates or notifications that are not financial movements.';
  Widget _tile(
    BuildContext context,
    String title,
    String detail, [
    Widget? target,
  ]) {
    final icon = title.startsWith('Financial records')
        ? Icons.receipt_long_outlined
        : title.startsWith('Raw SMS')
        ? Icons.sms_outlined
        : title.startsWith('Categories')
        ? Icons.category_outlined
        : title.startsWith('Categorization')
        ? Icons.rule_outlined
        : title.startsWith('Registered')
        ? Icons.account_balance_outlined
        : Icons.account_balance_wallet_outlined;
    return Material(
      key: ValueKey('your-data.${title.split(':').first}'),
      color: const Color(0xFFE7EEF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: target == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => target),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: AppTheme.darkBlue),
                  ),
                  const Spacer(),
                  if (target != null)
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: AppTheme.darkBlue,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF465C73),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(yourDataSummaryProvider);
    final progress = ref.watch(importProvider);
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Data'),
                  Text(
                    'A clear view of what is stored locally',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phonelink_lock_outlined,
                    color: AppTheme.darkBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your device. Your data.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'About your device data',
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppTheme.darkBlue,
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AppDialog(
                        title: const Text('Your device. Your data.'),
                        icon: Icons.phonelink_lock_outlined,
                        content: const SingleChildScrollView(
                          child: Text(_deviceDataDescription),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Stored on this device',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
            summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Column(
                children: [
                  const Text('Unable to load stored data counts.'),
                  TextButton(
                    onPressed: () => ref.invalidate(yourDataSummaryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (s) => Column(
                children: [
                  _tile(
                    context,
                    'Balance observations: ${s.smsBalances}',
                    'Latest recorded wallet balances and SMS history.',
                    const SmsBalanceObservationsScreen(unattributedOnly: false),
                  ),
                  const SizedBox(height: 12),
                  ResponsiveCardGrid(
                    children: [
                      _tile(
                        context,
                        'Financial records: ${s.records}',
                        '${s.successfulRecords} successful. View stored records in Activity.',
                        const ActivityScreen(),
                      ),
                      _tile(
                        context,
                        'Raw SMS messages: ${s.messages}',
                        'Stored source messages. Review receipt times.',
                        const StoredSmsScreen(),
                      ),
                      _tile(
                        context,
                        'Categories & rules',
                        '${s.categories} categories (${s.hiddenCategories} hidden); ${s.rules} categorization rules.',
                      ),
                      _tile(
                        context,
                        'Registered financial instruments: ${s.activeInstruments + s.archivedInstruments}',
                        '${s.activeInstruments} active; ${s.archivedInstruments} archived. Registered instruments only.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const VerifiedReversalsSection(),
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sync_rounded,
                            color: AppTheme.teal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import status (this session)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'SMS inbox reconciliation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'About import status',
                          icon: const Icon(Icons.info_outline, size: 20),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AppDialog(
                              title: const Text('About import status'),
                              icon: Icons.sync_rounded,
                              content: const Text(
                                'Session results are not lifetime totals. Duplicates were previously encountered. Skipped SMS include failed financial attempts and unsupported notifications. Balance observations are separate from financial movements. Background catch-up runs when the app resumes; it does not provide a persisted reconciliation ledger.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Session results are not lifetime totals.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: switch (progress.status) {
                        ImportStatus.requestingPermission ||
                        ImportStatus.loadingMessages ||
                        ImportStatus.processing ||
                        ImportStatus.saving => null,
                        _ =>
                          () => ref
                              .read(importProvider.notifier)
                              .importMessages(),
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Reconcile SMS inbox'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Previously processed SMS are not reimported.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.appBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        switch (progress.status) {
                          ImportStatus.idle =>
                            'No manual import result in this session.',
                          ImportStatus.requestingPermission =>
                            'Requesting SMS permission.',
                          ImportStatus.loadingMessages =>
                            'Loading SMS messages.',
                          ImportStatus.processing =>
                            'Processing SMS messages: ${progress.processed} of ${progress.total}.',
                          ImportStatus.saving => 'Saving import results.',
                          ImportStatus.completed =>
                            progress.failed > 0
                                ? 'Import finished with failures requiring review.'
                                : 'Import completed.',
                          ImportStatus.failed =>
                            'Import failed. Previously stored data is retained.',
                        },
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ),
                    if (progress.status != ImportStatus.idle) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${progress.total} SMS checked',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          Widget outcome(
                            String label,
                            int count,
                            Color color,
                            IconData icon,
                          ) => Container(
                            width: (constraints.maxWidth - 10) / 2,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, size: 18, color: color),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              outcome(
                                'Imported',
                                progress.imported,
                                AppTheme.teal,
                                Icons.check_circle_outline,
                              ),
                              outcome(
                                'Skipped',
                                progress.skipped,
                                Colors.amber.shade800,
                                Icons.skip_next_outlined,
                              ),
                              outcome(
                                'Duplicate',
                                progress.duplicate,
                                Colors.blueGrey,
                                Icons.content_copy_outlined,
                              ),
                              outcome(
                                'Failed',
                                progress.failed,
                                Colors.red.shade700,
                                Icons.error_outline,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Checked = Imported + Skipped + Duplicate + Failed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (progress.isComplete &&
                          progress.total !=
                              progress.imported +
                                  progress.skipped +
                                  progress.duplicate +
                                  progress.failed)
                        Text(
                          'Outcome counts do not reconcile. Review this import before treating it as complete.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                    ],
                    if (progress.isComplete) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.appBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Newly stored data',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text('${progress.rawCreated} new stored SMS'),
                            Text(
                              '${progress.evidenceCreated} new balance observations',
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Separate from imported financial movements.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (progress.reasons.isNotEmpty)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: const Text(
                            'Outcome details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Reasons and actual counts',
                            style: TextStyle(fontSize: 12),
                          ),
                          children: [
                            for (final reason
                                in (progress.reasons.entries.toList()
                                  ..sort((a, b) {
                                    bool failure(String key) => const {
                                      'PROCESSING_EXCEPTION',
                                      'PERSISTENCE_FAILED',
                                      'SOURCE_ID_COLLISION',
                                    }.contains(key);
                                    final priority = (failure(a.key) ? 0 : 1)
                                        .compareTo(failure(b.key) ? 0 : 1);
                                    return priority != 0
                                        ? priority
                                        : _reasonLabel(
                                            a.key,
                                          ).compareTo(_reasonLabel(b.key));
                                  })))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _reasonLabel(reason.key),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${reason.value}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _reasonLabel(String reason) => switch (reason) {
  'TRANSACTION_FAILED' => 'Recognized failed financial attempts',
  'UNKNOWN_CLASSIFICATION' => 'Unsupported or non-movement messages',
  'NO_PARSER' => 'Unsupported transaction format',
  'PARSE_FAILED' => 'Recognized messages that could not be parsed',
  'PROCESSING_EXCEPTION' => 'Unexpected processing errors',
  'PERSISTENCE_FAILED' => 'Rolled-back storage failures (retryable)',
  'SOURCE_ID_COLLISION' => 'Conflicting SMS source identities',
  'EXISTING_SOURCE_ID' => 'Previously encountered source identities',
  'EXISTING_FINANCIAL_SOURCE_ID' => 'Previously stored financial sources',
  'IDENTICAL_BODY' => 'Identical sender and message content',
  'REVERSAL_PERSISTED' => 'Validated principal-only PayBill reversals',
  'EXISTING_REVERSAL' => 'Previously stored reversals',
  'REVERSAL_ORIGINAL_NOT_UNIQUE' =>
    'Reversals without a unique successful PayBill',
  'REVERSAL_PRINCIPAL_MISMATCH' => 'Reversals without an exact principal match',
  'REVERSAL_INVALID_CHRONOLOGY' => 'Reversals without valid chronology',
  'REVERSAL_ALREADY_REVERSED' => 'Original PayBills already fully reversed',
  'REVERSAL_REFERENCE_CONFLICT' => 'Reversal reference conflicts',
  'REVERSAL_SOURCE_CONFLICT' => 'Reversal source conflicts',
  'MOVEMENT_PERSISTED' => 'Valid financial movements saved',
  _ => 'Other outcomes',
};
