import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_instrument.dart';
import '../../providers/financial_instruments_provider.dart';
import '../../providers/repository_providers.dart';
import 'instrument_form_screen.dart';
import 'instrument_mapping_screen.dart';
import 'instrument_activity_section.dart';
import 'instrument_balance_section.dart';
import 'instrument_presentation.dart';

class InstrumentDetailScreen extends ConsumerStatefulWidget {
  final String uuid;
  const InstrumentDetailScreen({super.key, required this.uuid});
  @override
  ConsumerState<InstrumentDetailScreen> createState() =>
      _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState
    extends ConsumerState<InstrumentDetailScreen> {
  bool _busy = false;
  Future<void> _setArchived(FinancialInstrument instrument) async {
    final archive = instrument.isActive;
    final action = archive ? 'Archive' : 'Restore';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.account_balance_outlined,
        title: Text('$action ${instrument.name}?'),
        content: Text(
          archive
              ? 'Move this instrument to Archived? Its details will be kept and existing transactions will stay unchanged.'
              : 'Move this instrument back to Active?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(financialInstrumentsRepositoryProvider)
          .setArchived(instrument.uuid, archive);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to ${action.toLowerCase()} instrument. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, String? value) => value == null
      ? const SizedBox.shrink()
      : ListTile(
          title: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          subtitle: SelectableText(
            value,
            style: const TextStyle(color: AppTheme.darkBlue),
          ),
        );
  Widget _details(FinancialInstrument i) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(instrumentTypeIcon(i.type), color: AppTheme.teal, size: 36),
              const SizedBox(height: 12),
              Text(
                i.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(instrumentTypeLabel(i.type), textAlign: TextAlign.center),
              Chip(label: Text(i.isActive ? 'Active' : 'Archived')),
            ],
          ),
        ),
      ),
      Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Column(
          children: [
            _field('Provider / institution', i.provider ?? 'Not provided'),
            _field('Account number', i.identifiers?.accountNumber),
            _field('Wallet number / phone', i.identifiers?.walletNumber),
            _field('Membership number', i.identifiers?.membershipNumber),
            _field('Policy number', i.identifiers?.policyNumber),
            _field('Reference', i.identifiers?.reference),
            if (i.identifiers == null)
              const ListTile(title: Text('No identifiers provided')),
          ],
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy
            ? null
            : () => Navigator.of(context).push<FinancialInstrument>(
                MaterialPageRoute(
                  builder: (_) => InstrumentFormScreen(instrument: i),
                ),
              ),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit instrument'),
      ),
      TextButton.icon(
        onPressed: _busy ? null : () => _setArchived(i),
        icon: Icon(
          i.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
        ),
        label: Text(i.isActive ? 'Archive instrument' : 'Restore instrument'),
      ),
      if (_busy) const LinearProgressIndicator(),
      if (i.isActive)
        InstrumentMappingScreen(
          key: ValueKey('mapping.${i.id}.${i.provider}'),
          instrument: i,
          embedded: true,
        ),
      InstrumentBalanceSection(
        key: ValueKey('balance.${i.id}'),
        accountId: i.id,
      ),
      InstrumentActivitySection(key: ValueKey(i.id), accountId: i.id),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      title: const Text('Instrument details'),
      backgroundColor: AppTheme.darkBlue,
      foregroundColor: Colors.white,
    ),
    body: ref
        .watch(allFinancialInstrumentsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(allFinancialInstrumentsProvider),
              child: const Text('Unable to load instrument. Retry'),
            ),
          ),
          data: (all) {
            final instrument = all
                .where((i) => i.uuid == widget.uuid)
                .firstOrNull;
            return instrument == null
                ? const Center(
                    child: Text('Instrument is no longer available.'),
                  )
                : _details(instrument);
          },
        ),
  );
}
