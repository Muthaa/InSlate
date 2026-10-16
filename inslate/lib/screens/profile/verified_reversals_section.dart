import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/activity_provider.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/paybill_reversals_repository.dart';

/// Phase 11R's explicitly bounded, user-initiated operation. A changed population
/// cannot silently broaden the approved five-source operation.
class VerifiedReversalsSection extends ConsumerStatefulWidget {
  const VerifiedReversalsSection({super.key});
  @override
  ConsumerState<VerifiedReversalsSection> createState() =>
      _VerifiedReversalsSectionState();
}

class _VerifiedReversalsSectionState
    extends ConsumerState<VerifiedReversalsSection> {
  bool busy = false;
  bool confirming = false;
  String? result;
  Future<void> process() async {
    setState(() {
      busy = true;
      result = null;
    });
    try {
      final revision = ref.read(financialDataRevisionProvider.notifier);
      final repository = PayBillReversalsRepository(
        ref.read(financialRecordsRepositoryProvider).database,
      );
      final ids = await repository.retainedConfirmationIds();
      if (ids.length != 5) {
        throw StateError(
          'The retained population differs from the five audited confirmations. No records changed.',
        );
      }
      if (!mounted) return;
      setState(() => confirming = true);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          icon: Icons.undo_rounded,
          title: const Text('Process five retained reversals?'),
          content: const Text(
            'Only five retained confirmations will be validated. Each must match one successful PayBill and its full principal. Original payments and fees stay unchanged. No other transactions are reimported.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Process five'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => confirming = false);
      if (confirmed != true) return;
      final entries = await repository.process(ids, requireAllSupported: true);
      final created = entries.where((r) => r.imported).length;
      if (created > 0) revision.state++;
      if (mounted) {
        setState(
          () => result =
              '${entries.length} checked; $created adjustments created; ${entries.where((r) => r.duplicate).length} already stored; ${entries.fold<int>(0, (sum, r) => sum + r.evidenceCreated)} wallet observations created. Original payments and fees preserved.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => result =
              'Unable to validate the five audited confirmations. No changes committed. Review required.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verified PayBill reversals',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Principal-only expense adjustments. Fee refunds and other reversal formats are unsupported.',
          ),
          TextButton(
            onPressed: busy ? null : process,
            child: const Text('Process five audited confirmations'),
          ),
          if (busy && !confirming) const LinearProgressIndicator(),
          if (result != null) Text(result!),
        ],
      ),
    ),
  );
}
