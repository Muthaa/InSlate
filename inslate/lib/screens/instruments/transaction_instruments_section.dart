import '../../services/financial_semantics.dart';
import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_instrument.dart';
import '../../models/financial_records.dart';
import '../../providers/financial_instruments_provider.dart';
import '../../providers/instrument_links_provider.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/instrument_links_repository.dart';
import 'instrument_presentation.dart';

class TransactionInstrumentsSection extends ConsumerStatefulWidget {
  final FinancialRecord record;
  final bool embedded;
  final Widget? categorySection;
  const TransactionInstrumentsSection({
    super.key,
    required this.record,
    this.embedded = false,
    this.categorySection,
  });
  @override
  ConsumerState<TransactionInstrumentsSection> createState() =>
      _TransactionInstrumentsSectionState();
}

class _TransactionInstrumentsSectionState
    extends ConsumerState<TransactionInstrumentsSection> {
  bool _busy = false;
  String _label(InstrumentEndpoint endpoint) =>
      endpoint == InstrumentEndpoint.source ? 'Source' : 'Destination';
  String _description(FinancialInstrument instrument) {
    final identifiers = instrument.identifiers?.toJson().values.join(' / ');
    return [
      instrumentTypeLabel(instrument.type),
      if (instrument.provider != null) instrument.provider!,
      if (identifiers != null && identifiers.isNotEmpty) identifiers,
      'Instrument #${instrument.id}',
    ].join(' - ');
  }

  Future<void> _change(
    InstrumentEndpoint endpoint,
    int? current, {
    bool remove = false,
  }) async {
    int? selected;
    if (!remove) {
      selected = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => Consumer(
          builder: (context, ref, _) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Choose ${_label(endpoint).toLowerCase()} instrument',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ref
                        .watch(allFinancialInstrumentsProvider)
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => Center(
                            child: TextButton(
                              onPressed: () => ref.invalidate(
                                allFinancialInstrumentsProvider,
                              ),
                              child: const Text(
                                'Unable to load instruments. Retry',
                              ),
                            ),
                          ),
                          data: (all) {
                            final active = all
                                .where((i) => i.isActive && i.id != current)
                                .toList();
                            if (active.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No other active registered instruments. Add or restore one through More > Financial Instruments.',
                                  ),
                                ),
                              );
                            }
                            return ListView(
                              children: [
                                for (final i in active)
                                  ListTile(
                                    key: ValueKey('link.choose.${i.id}'),
                                    title: Text(i.name),
                                    subtitle: Text(_description(i)),
                                    onTap: () => Navigator.pop(context, i.id),
                                  ),
                              ],
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (selected == null || !mounted) return;
    }
    if (current != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          icon: Icons.link_outlined,
          title: Text(
            '${remove ? 'Remove' : 'Replace'} ${_label(endpoint).toLowerCase()} association?',
          ),
          content: const Text('Only this transaction association will change.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(remove ? 'Remove' : 'Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(instrumentLinksRepositoryProvider)
          .setLink(
            recordId: widget.record.id!,
            endpoint: endpoint,
            instrumentId: selected,
            expectedCurrentId: current,
          );
    } catch (error) {
      if (mounted) {
        final message = error is ArgumentError
            ? error.message.toString()
            : error is StateError
            ? error.message
            : 'Unable to update instrument association. Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _endpoint(
    InstrumentEndpoint endpoint,
    InstrumentLinks links,
    List<FinancialInstrument> instruments,
  ) {
    final id = links.at(endpoint);
    final supported = InstrumentLinksRepository.supports(
      widget.record,
      endpoint,
    );
    if (!supported && id == null) return const SizedBox.shrink();
    final instrument = instruments.where((i) => i.id == id).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label(endpoint),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            id == null
                ? 'Not associated'
                : instrument == null
                ? 'Existing account association (unconfirmed or unavailable)'
                : '${instrument.name}${instrument.isArchived ? ' (archived)' : ''}',
          ),
          if (instrument != null) Text(_description(instrument)),
          if (!supported)
            const Text('Endpoint unresolved; existing association retained.'),
          Wrap(
            spacing: 8,
            children: [
              if (supported)
                TextButton(
                  key: ValueKey('link.${endpoint.name}.choose'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: _busy ? null : () => _change(endpoint, id),
                  child: Text(
                    id == null
                        ? 'Choose ${_label(endpoint).toLowerCase()}'
                        : 'Replace ${_label(endpoint).toLowerCase()}',
                  ),
                ),
              if (id != null)
                TextButton(
                  key: ValueKey('link.${endpoint.name}.remove'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _change(endpoint, id, remove: true),
                  child: Text('Remove ${_label(endpoint).toLowerCase()}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.record.id;
    if (id == null) return const SizedBox.shrink();
    final incoming =
        const FinancialSemantics().classify(widget.record) ==
            MovementClass.income ||
        const FinancialSemantics().classify(widget.record) ==
            MovementClass.loanBorrowing ||
        FinancialSemantics.isExpenseReversal(widget.record) ||
        widget.record.subtype.name == 'instrumentReceipt';
    final primaryEndpoint = incoming
        ? InstrumentEndpoint.destination
        : InstrumentEndpoint.source;
    final secondaryEndpoint = primaryEndpoint == InstrumentEndpoint.source
        ? InstrumentEndpoint.destination
        : InstrumentEndpoint.source;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.categorySection == null)
            const Text(
              'Instruments',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),
          ref
              .watch(instrumentLinksProvider(id))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(instrumentLinksProvider(id)),
                  child: const Text('Unable to load associations. Retry'),
                ),
                data: (links) => links == null
                    ? const Text('Transaction no longer available.')
                    : ref
                          .watch(allFinancialInstrumentsProvider)
                          .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => TextButton(
                              onPressed: () => ref.invalidate(
                                allFinancialInstrumentsProvider,
                              ),
                              child: const Text(
                                'Unable to load instruments. Retry',
                              ),
                            ),
                            data: (instruments) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!InstrumentEndpoint.values.any(
                                  (e) =>
                                      InstrumentLinksRepository.supports(
                                        widget.record,
                                        e,
                                      ) ||
                                      links.at(e) != null,
                                ))
                                  const Text(
                                    'No supported instrument endpoints for this transaction.',
                                  ),
                                if (widget.categorySection != null) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: widget.categorySection!),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child:
                                            InstrumentLinksRepository.supports(
                                                  widget.record,
                                                  primaryEndpoint,
                                                ) ||
                                                links.at(primaryEndpoint) !=
                                                    null
                                            ? _endpoint(
                                                primaryEndpoint,
                                                links,
                                                instruments,
                                              )
                                            : const Text(
                                                'Instrument association unavailable for this transaction.',
                                              ),
                                      ),
                                    ],
                                  ),
                                  _endpoint(
                                    secondaryEndpoint,
                                    links,
                                    instruments,
                                  ),
                                ] else
                                  for (final endpoint
                                      in InstrumentEndpoint.values)
                                    _endpoint(endpoint, links, instruments),
                              ],
                            ),
                          ),
              ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
    if (widget.embedded) return content;
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: content,
    );
  }
}
