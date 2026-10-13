import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/historical_balance_provider.dart';

class HistoricalBalanceExtractionSection extends ConsumerWidget {
  const HistoricalBalanceExtractionSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(historicalBalanceProvider);
    final checkpoint = status.checkpoint;
    Future<void> run() async {
      if (checkpoint == null || checkpoint.complete) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AppDialog(
            icon: Icons.sms_outlined,
            title: const Text('Extract balances from stored SMS?'),
            content: const Text(
              'Process existing messages using the supported balance formats. Existing observations and associations are kept. Transactions are unchanged.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Extract'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
      }
      await ref.read(historicalBalanceProvider.notifier).run();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!status.running)
            TextButton.icon(
              key: const ValueKey('sms.history.extract'),
              onPressed: run,
              icon: const Icon(Icons.history),
              label: Text(
                checkpoint == null
                    ? 'Extract stored SMS balances'
                    : checkpoint.complete
                    ? 'Run historical extraction again'
                    : 'Resume historical extraction',
              ),
            ),
          if (status.running) ...[
            const LinearProgressIndicator(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    status.cancelling
                        ? 'Stopping after this batch?'
                        : 'Processing stored SMS?',
                  ),
                ),
                TextButton(
                  key: const ValueKey('sms.history.cancel'),
                  onPressed: status.cancelling
                      ? null
                      : ref.read(historicalBalanceProvider.notifier).cancel,
                  child: const Text('Cancel extraction'),
                ),
              ],
            ),
          ],
          if (checkpoint != null)
            Text(
              '${checkpoint.complete
                  ? 'Extraction complete'
                  : status.running
                  ? 'Progress'
                  : 'Extraction paused'}: ${checkpoint.scanned} messages scanned; '
              '${checkpoint.created} observations created; ${checkpoint.existing} already existing; '
              '${checkpoint.unsupported} unsupported/ambiguous messages (no supported observations).',
              key: const ValueKey('sms.history.summary'),
            ),
          if (status.error != null)
            Text(
              status.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
