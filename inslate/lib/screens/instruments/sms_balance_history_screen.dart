import '../../core/enums/account_type.dart';
import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/balance_observation.dart';
import '../../models/financial_instrument.dart';
import '../../providers/balance_evidence_provider.dart';
import '../../providers/financial_instruments_provider.dart';
import 'historical_balance_extraction_section.dart';

String _date(BalanceObservation e) =>
    DateFormat.yMMMd().add_jm().format(e.asOf.toLocal());

class SmsBalanceHistoryScreen extends ConsumerStatefulWidget {
  final bool unattributedOnly;
  final AccountType? subjectFamily;
  final String currency;
  const SmsBalanceHistoryScreen({
    super.key,
    this.unattributedOnly = false,
    this.subjectFamily,
    this.currency = 'KES',
  });
  @override
  ConsumerState<SmsBalanceHistoryScreen> createState() =>
      _SmsBalanceHistoryScreenState();
}

class _SmsBalanceHistoryScreenState
    extends ConsumerState<SmsBalanceHistoryScreen> {
  late bool _unattributed = widget.unattributedOnly;
  int _page = 0;
  bool _busy = false;
  Future<void> _unlink(BalanceObservation e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.link_outlined,
        title: const Text('Unlink this observation?'),
        content: const Text(
          'The SMS observation will be kept without an instrument association.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(balanceEvidenceRepositoryProvider)
          .associateSms(
            id: e.id,
            expectedAccountId: e.accountId,
            expectedRevision: e.revision,
            accountId: null,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Unable to unlink. Reload and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = (unattributedOnly: _unattributed, page: _page);
    final history = widget.subjectFamily == null
        ? smsBalanceHistoryProvider(query)
        : smsWalletHistoryProvider((
            family: widget.subjectFamily!,
            currency: widget.currency,
            page: _page,
          ));
    ref.listen(history, (_, next) {
      final actual = next.asData?.value.page;
      if (actual != null && actual != _page) setState(() => _page = actual);
    });
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance observation history'),
                  Text(
                    'Recorded balances from your SMS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        child: Column(
          children: [
            if (widget.subjectFamily == null)
              const HistoricalBalanceExtractionSection(),
            if (widget.subjectFamily == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Unattributed')),
                    ButtonSegment(value: false, label: Text('All SMS')),
                  ],
                  selected: {_unattributed},
                  onSelectionChanged: _busy
                      ? null
                      : (values) => setState(() {
                          _unattributed = values.single;
                          _page = 0;
                        }),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.subjectFamily == AccountType.mpesa
                    ? 'M-PESA is the measured wallet. These observations need no attribution.'
                    : 'Instrument ownership is confirmed by you, not verified by SMS.',
              ),
            ),
            Expanded(
              child: ref
                  .watch(history)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: () => ref.invalidate(history),
                        child: const Text('Unable to load observations. Retry'),
                      ),
                    ),
                    data: (data) => Column(
                      children: [
                        Text('${data.count} SMS observations'),
                        Expanded(
                          child: data.count == 0
                              ? Center(
                                  child: Text(
                                    _unattributed
                                        ? 'No unattributed SMS balance observations.'
                                        : 'No SMS balance observations.',
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: data.entries.length,
                                  itemBuilder: (context, index) {
                                    final e = data.entries[index];
                                    return Card(
                                      key: ValueKey('sms.evidence.${e.id}'),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      color: Colors.white,
                                      surfaceTintColor: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.subjectLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.darkBlue,
                                              ),
                                            ),
                                            Text(
                                              e.amountText,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.teal,
                                              ),
                                            ),
                                            Text(e.kind.label),
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.appBackground,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'SMS-reported',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'As of ${_date(e)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(e.timeBasisLabel),
                                            Text(
                                              e.subjectFamily ==
                                                      AccountType.mpesa
                                                  ? 'Measured M-PESA wallet · no attribution needed'
                                                  : 'Instrument: ${e.associationLabel}',
                                            ),
                                            if (e.accountId != null &&
                                                e.subjectFamily !=
                                                    AccountType.mpesa)
                                              const Text(
                                                'Association confirmed by user; ownership is not SMS-verified.',
                                              ),
                                            if (e.matchedClause != null)
                                              Text(e.matchedClause!),
                                            Text(
                                              'Source message ${e.rawMessageId ?? 'unavailable'} ? ${e.extractionVersion ?? 'version unavailable'}',
                                            ),
                                            if (e.subjectFamily !=
                                                AccountType.mpesa)
                                              Wrap(
                                                children: [
                                                  TextButton(
                                                    key: ValueKey(
                                                      'sms.associate.${e.id}',
                                                    ),
                                                    onPressed: _busy
                                                        ? null
                                                        : () => showDialog<void>(
                                                            context: context,
                                                            builder: (_) =>
                                                                SmsBalanceAssociationDialog(
                                                                  evidence: e,
                                                                ),
                                                          ),
                                                    child: Text(
                                                      e.accountId == null
                                                          ? 'Associate'
                                                          : 'Replace association',
                                                    ),
                                                  ),
                                                  if (e.accountId != null)
                                                    TextButton(
                                                      key: ValueKey(
                                                        'sms.unlink.${e.id}',
                                                      ),
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _unlink(e),
                                                      child: const Text(
                                                        'Unlink',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (data.count > 0)
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _busy || data.page == 0
                                    ? null
                                    : () =>
                                          setState(() => _page = data.page - 1),
                                child: const Text('Previous SMS observations'),
                              ),
                              Text(
                                'SMS page ${data.page + 1} of ${data.totalPages}',
                              ),
                              TextButton(
                                onPressed:
                                    _busy || data.page + 1 >= data.totalPages
                                    ? null
                                    : () =>
                                          setState(() => _page = data.page + 1),
                                child: const Text('Next SMS observations'),
                              ),
                            ],
                          ),
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

class SmsBalanceAssociationDialog extends ConsumerStatefulWidget {
  final BalanceObservation evidence;
  const SmsBalanceAssociationDialog({super.key, required this.evidence});
  @override
  ConsumerState<SmsBalanceAssociationDialog> createState() =>
      _SmsBalanceAssociationDialogState();
}

class _SmsBalanceAssociationDialogState
    extends ConsumerState<SmsBalanceAssociationDialog> {
  int? _target;
  bool _confirmedCompatibility = false, _busy = false;
  String? _error;
  Future<void> _save(FinancialInstrument instrument) async {
    final e = widget.evidence;
    if (e.subjectFamily == AccountType.mpesa) return;
    if (e.accountId != null && e.accountId != instrument.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          icon: Icons.link_outlined,
          title: const Text('Replace existing association?'),
          content: Text(
            'Move this observation from ${e.associationLabel} to ${instrument.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(balanceEvidenceRepositoryProvider)
          .associateSms(
            id: e.id,
            expectedAccountId: e.accountId,
            expectedRevision: e.revision,
            accountId: instrument.id,
            confirmReplacement: e.accountId != null,
            confirmUncertainCompatibility: _confirmedCompatibility,
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : error is StateError
              ? error.message.toString()
              : 'Unable to save association. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AppDialog(
      icon: Icons.link_outlined,
      title: const Text('Confirm instrument association'),
      content: SizedBox(
        width: 400,
        child: ref
            .watch(financialInstrumentsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(financialInstrumentsProvider),
                child: const Text('Unable to load instruments. Retry'),
              ),
              data: (instruments) {
                final selected = instruments
                    .where((i) => i.id == _target)
                    .firstOrNull;
                final compatibility = selected == null
                    ? null
                    : smsBalanceCompatibility(widget.evidence, selected);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.evidence.subjectLabel} ? ${widget.evidence.amountText}',
                      ),
                      const Text(
                        'Confirm that this observation belongs to your instrument. SMS does not verify ownership.',
                      ),
                      if (instruments.isEmpty)
                        const Text(
                          'Register or restore an active instrument first.',
                        ),
                      DropdownButtonFormField<int>(
                        key: const ValueKey('sms.instrument'),
                        initialValue: selected?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Active registered instrument',
                        ),
                        items: [
                          for (final i in instruments)
                            DropdownMenuItem(value: i.id, child: Text(i.name)),
                        ],
                        onChanged: _busy
                            ? null
                            : (id) => setState(() {
                                _target = id;
                                _confirmedCompatibility = false;
                                _error = null;
                              }),
                      ),
                      if (compatibility == BalanceCompatibility.incompatible)
                        const Text(
                          'The instrument type or provider conflicts with this balance subject.',
                        ),
                      if (compatibility ==
                          BalanceCompatibility.confirmationRequired)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _confirmedCompatibility,
                          onChanged: _busy
                              ? null
                              : (v) => setState(
                                  () => _confirmedCompatibility = v == true,
                                ),
                          title: const Text(
                            'I confirm compatibility despite incomplete or unrecognized instrument metadata.',
                          ),
                        ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (_busy) const LinearProgressIndicator(),
                      FilledButton(
                        onPressed:
                            _busy ||
                                widget.evidence.subjectFamily ==
                                    AccountType.mpesa ||
                                selected == null ||
                                selected.id == widget.evidence.accountId ||
                                compatibility ==
                                    BalanceCompatibility.incompatible ||
                                (compatibility ==
                                        BalanceCompatibility
                                            .confirmationRequired &&
                                    !_confirmedCompatibility)
                            ? null
                            : () => _save(selected),
                        child: const Text('Confirm association'),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
