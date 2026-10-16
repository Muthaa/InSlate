import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/balance_observation.dart';
import '../../providers/balance_evidence_provider.dart';
import 'balance_form_screen.dart';
import 'sms_balance_observations_screen.dart';

class InstrumentBalanceSection extends ConsumerStatefulWidget {
  final int accountId;
  const InstrumentBalanceSection({super.key, required this.accountId});
  @override
  ConsumerState<InstrumentBalanceSection> createState() =>
      _InstrumentBalanceSectionState();
}

class _InstrumentBalanceSectionState
    extends ConsumerState<InstrumentBalanceSection>
    with AutomaticKeepAliveClientMixin {
  int _page = 0;
  bool _busy = false;
  @override
  bool get wantKeepAlive => true;
  void _form([BalanceObservation? observation]) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BalanceFormScreen(
            accountId: widget.accountId,
            observation: observation,
          ),
        ),
      );
  Future<void> _remove(BalanceObservation e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.delete_outline,
        destructive: true,
        title: const Text('Remove this observation?'),
        content: Text('${e.amountText} - ${e.kind.label}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(balanceEvidenceRepositoryProvider)
          .deleteManual(
            id: e.id,
            accountId: widget.accountId,
            expectedRevision: e.revision,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to remove observation. Reload and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(BalanceObservation e) =>
      DateFormat.yMMMd().add_jm().format(e.asOf.toLocal());
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = (accountId: widget.accountId, page: _page);
    ref.listen(balanceHistoryProvider(query), (_, next) {
      final page = next.asData?.value.page;
      if (page != null && page != _page) setState(() => _page = page);
    });
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Latest recorded observation',
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            ref
                .watch(latestBalanceProvider(widget.accountId))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => TextButton(
                    onPressed: () =>
                        ref.invalidate(latestBalanceProvider(widget.accountId)),
                    child: const Text('Unable to load balance. Retry'),
                  ),
                  data: (e) => e == null
                      ? const Text('No balance observations recorded.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.amountText,
                              key: const ValueKey('balance.latest.amount'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                            Text(e.kind.label),
                            Text('As of ${_date(e)}'),
                            Text(e.sourceLabel),
                            if (!e.isManual) ...[
                              Text(e.subjectLabel),
                              Text(e.timeBasisLabel),
                              const Text(
                                'Association confirmed by user; ownership is not SMS-verified.',
                              ),
                            ],
                          ],
                        ),
                ),
            TextButton.icon(
              key: const ValueKey('balance.record'),
              onPressed: _busy ? null : () => _form(),
              icon: const Icon(Icons.add),
              label: const Text('Record Balance'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const SmsBalanceObservationsScreen(
                    unattributedOnly: false,
                  ),
                ),
              ),
              child: const Text('Review SMS balance observations'),
            ),
            const Divider(),
            const Text(
              'Balance history',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ref
                .watch(balanceHistoryProvider(query))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => TextButton(
                    onPressed: () =>
                        ref.invalidate(balanceHistoryProvider(query)),
                    child: const Text('Unable to load balance history. Retry'),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${data.count} ${data.count == 1 ? 'observation' : 'observations'}',
                      ),
                      for (final e in data.entries)
                        Padding(
                          key: ValueKey('balance.entry.${e.id}'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.amountText),
                              Text('${e.kind.label} - As of ${_date(e)}'),
                              Text(e.sourceLabel),
                              if (!e.isManual) ...[
                                Text(e.subjectLabel),
                                Text(e.timeBasisLabel),
                                const Text(
                                  'Association confirmed by user; ownership is not SMS-verified.',
                                ),
                              ],
                              if (e.isManual)
                                Wrap(
                                  children: [
                                    TextButton(
                                      key: ValueKey('balance.correct.${e.id}'),
                                      onPressed: _busy ? null : () => _form(e),
                                      child: const Text('Correct'),
                                    ),
                                    TextButton(
                                      key: ValueKey('balance.remove.${e.id}'),
                                      onPressed: _busy
                                          ? null
                                          : () => _remove(e),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      if (data.count > 0)
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton(
                              onPressed: data.page == 0
                                  ? null
                                  : () => setState(() => _page = data.page - 1),
                              child: const Text('Previous observations'),
                            ),
                            Text(
                              'Observations page ${data.page + 1} of ${data.totalPages}',
                            ),
                            TextButton(
                              onPressed: data.page + 1 >= data.totalPages
                                  ? null
                                  : () => setState(() => _page = data.page + 1),
                              child: const Text('Next observations'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
