import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/financial_instrument.dart';
import '../../providers/database_provider.dart';
import '../../providers/activity_provider.dart';
import '../../repositories/instrument_mappings_repository.dart';
import '../../widgets/app_dialog.dart';
import '../../core/presentation/financial_presentation.dart';
import '../activity/transaction_detail_screen.dart';

class InstrumentMappingScreen extends ConsumerStatefulWidget {
  final FinancialInstrument instrument;
  final bool embedded;
  const InstrumentMappingScreen({
    super.key,
    required this.instrument,
    this.embedded = false,
  });
  static String maskReference(String value) => value.length <= 4
      ? '\u2022\u2022\u2022\u2022'
      : '\u2022\u2022\u2022\u2022${value.substring(value.length - 4)}';
  @override
  ConsumerState<InstrumentMappingScreen> createState() =>
      _InstrumentMappingScreenState();
}

class _InstrumentMappingScreenState
    extends ConsumerState<InstrumentMappingScreen> {
  final _provider = TextEditingController(),
      _reference = TextEditingController();
  InstrumentPurpose _purpose = InstrumentPurpose.unknown;
  MappingResult? _preview;
  String? _error, _summary;
  bool _busy = false, _shared = false;
  late bool _manual;
  int _previewPage = 0;
  List<MappingPreviewTransaction> _transactions = [];
  int _page = 0;
  late Future<List<DetectedReferenceReview>> _references;
  late Future<List<InstrumentMapping>> _mappings;
  InstrumentMappingsRepository get _repository =>
      InstrumentMappingsRepository(ref.read(databaseProvider));
  @override
  void initState() {
    super.initState();
    _provider.text = widget.instrument.provider ?? '';
    _manual = !widget.embedded;
    _reload();
  }

  void _reload() {
    _mappings = _repository.list(widget.instrument.id);
    _references = _mappings.then((mappings) {
      return _repository.referenceReviewPage(
        accountId: widget.instrument.id,
        offset: _page * 50,
        provider: widget.instrument.provider,
      );
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _run(bool confirm) async {
    if (_busy) return;
    if (confirm) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: const Text('Confirm account mapping?'),
          content: const Text(
            'Apply this purpose and instrument link to matching history and future persisted transactions? Existing conflicting links are preserved. Loan wording and reversed payment pairs retain their original treatment. Unknown-purpose amounts are excluded from income/expense totals. Original SMS and parsed fields remain intact.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm mapping'),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = confirm
          ? null
          : await _repository.previewPage(
              accountId: widget.instrument.id,
              provider: _provider.text,
              reference: _reference.text,
              purpose: _purpose,
            );
      final result =
          page?.summary ??
          await _repository.confirm(
            accountId: widget.instrument.id,
            provider: _provider.text,
            reference: _reference.text,
            purpose: _purpose,
          );
      final transactions = page?.transactions ?? <MappingPreviewTransaction>[];
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _previewPage = 0;
          if (confirm) {
            ref.read(financialDataRevisionProvider.notifier).state++;
          }
          _preview = confirm ? null : result;
          _summary = confirm
              ? 'Mapping saved. ${result.linked} links created; ${result.interpreted} purpose updates; ${result.conflicts} conflicts skipped; ${result.protected} protected transactions.'
              : null;
          if (confirm) _reload();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ArgumentError || e is StateError
              ? e.toString().replaceFirst(
                  RegExp(r'^(Invalid argument\(s\)|Bad state): '),
                  '',
                )
              : 'Unable to save mapping. Your input is retained; try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(InstrumentMapping mapping) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: const Text('Remove mapping?'),
        content: const Text(
          'Restore parsed financial treatment and stop future matching. Historical instrument links remain; remove those explicitly in Transaction Details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove mapping'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.remove(mapping.id, widget.instrument.id);
      if (mounted) {
        ref.read(financialDataRevisionProvider.notifier).state++;
        setState(() {
          _preview = null;
          _summary =
              'Mapping removed. Historical instrument links are retained.';
          _reload();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to remove mapping. Refresh and retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewNext(int page) async {
    setState(() => _busy = true);
    try {
      final preview = await _repository.previewPage(
        accountId: widget.instrument.id,
        provider: _provider.text,
        reference: _reference.text,
        purpose: _purpose,
        offset: page * 20,
      );
      if (mounted) {
        setState(() {
          _transactions = preview.transactions;
          _preview = preview.summary;
          _previewPage = page;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load preview. Retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String purposeLabel(InstrumentPurpose purpose) => switch (purpose) {
    InstrumentPurpose.savings => 'Savings',
    InstrumentPurpose.investment => 'Investment',
    InstrumentPurpose.loan => 'Loan',
    InstrumentPurpose.unknown => 'Not sure',
  };

  @override
  Widget build(BuildContext context) => widget.embedded
      ? Card(child: _content())
      : Scaffold(
          appBar: AppBar(title: const Text('Account reference mapping')),
          body: SafeArea(top: false, child: _content()),
        );

  Widget _content() {
    final children = <Widget>[
      Text(
        'Accounts to review',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Purpose is confirmed per provider and account reference, not for every transaction at this provider. Choose a detected reference or enter one for future messages. Provider alone is not ownership evidence.',
      ),
      const SizedBox(height: 8),
      const Text(
        'A reference may cover multiple products. If it is shared, review transactions individually instead of confirming one purpose. Choose Not sure to track direction without guessing a purpose. Conflicting links are never replaced automatically.',
        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
      ),
      FutureBuilder(
        future: _references,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Detected references unavailable. You can enter a reference manually.',
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final rows = snapshot.data!;
          return Column(
            children: [
              ExpansionTile(
                initiallyExpanded: true,
                title: const Text('Detected account references'),
                children: [
                  if (rows.isEmpty)
                    const ListTile(
                      title: Text('No detected references on this page'),
                    ),
                  for (final row in rows)
                    ListTile(
                      key: ValueKey(
                        'mapping.reference.${row.provider}.${row.reference}',
                      ),
                      title: Text(row.provider),
                      subtitle: Text(
                        '${InstrumentMappingScreen.maskReference(row.reference)} - ${row.detected} detected; ${row.eligible} eligible; ${row.conflicts} conflicts - ${row.mappedAccountId == null
                            ? 'Awaiting review'
                            : row.mappedAccountId == widget.instrument.id
                            ? 'Reviewed and mapped here'
                            : 'Mapped elsewhere - manual review'}',
                      ),
                      onTap: _busy || row.mappedAccountId != null
                          ? null
                          : () async {
                              setState(() {
                                _provider.text = row.provider;
                                _reference.text = row.reference;
                                _manual = false;
                                _preview = null;
                              });
                              await _run(false);
                            },
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _busy || _page == 0
                        ? null
                        : () => setState(() {
                            _page--;
                            _reload();
                          }),
                    child: const Text('Previous references'),
                  ),
                  TextButton(
                    onPressed: _busy || rows.length < 50
                        ? null
                        : () => setState(() {
                            _page++;
                            _reload();
                          }),
                    child: const Text('Next references'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      const Text(
        'Select a detected reference above, or enter one manually below. Registration alone never links transactions.',
      ),
      if (!_manual && _reference.text.isNotEmpty)
        ListTile(
          title: Text(
            'Selected reference ${InstrumentMappingScreen.maskReference(_reference.text)}',
          ),
          subtitle: Text(_provider.text),
        ),
      TextButton.icon(
        onPressed: _busy ? null : () => setState(() => _manual = !_manual),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Enter a reference manually'),
      ),
      if (_manual)
        TextField(
          controller: _provider,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Exact provider name'),
          onChanged: (_) => setState(() => _preview = null),
        ),
      if (_manual)
        TextField(
          controller: _reference,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Exact customer account reference',
          ),
          onChanged: (_) => setState(() => _preview = null),
        ),
      DropdownButtonFormField<InstrumentPurpose>(
        initialValue: _purpose,
        decoration: const InputDecoration(
          labelText: 'Confirmed purpose for this reference',
        ),
        items: [
          for (final p in [
            InstrumentPurpose.savings,
            InstrumentPurpose.investment,
            InstrumentPurpose.loan,
            InstrumentPurpose.unknown,
          ])
            DropdownMenuItem(value: p, child: Text(purposeLabel(p))),
        ],
        onChanged: _busy
            ? null
            : (p) => setState(() {
                _purpose = p!;
                _preview = null;
              }),
      ),
      const Text(
        'Savings: money saved or taken out. Investment: money invested or redeemed. Loan: money repaid or borrowed. Not sure: track money paid and received without guessing its purpose.',
        style: TextStyle(fontSize: 12),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('This reference may serve multiple products'),
        subtitle: const Text(
          'If selected, review and link individual transactions instead. A shared reference cannot safely have one purpose.',
        ),
        value: _shared,
        onChanged: _busy ? null : (value) => setState(() => _shared = value!),
      ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      if (_summary != null) Text(_summary!),
      if (_preview != null)
        Text(
          'Eligible preview: ${_preview!.matching} matching transactions; ${_preview!.matching - _preview!.conflicts} eligible to link; ${_preview!.linked} new links; ${_preview!.interpreted} purpose updates; ${_preview!.conflicts} conflicts require manual review; ${_preview!.protected} protected. Detected counts also include unsupported transaction shapes.',
        ),
      if (_preview != null) ...[
        const Text(
          'Historical transaction preview',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        for (final transaction in _transactions)
          ListTile(
            dense: true,
            title: Text(
              '${transaction.incoming ? 'Money received' : 'Money paid'} - ${formatMoney(transaction.amount)}',
            ),
            subtitle: Text(
              '${transaction.asOf.toIso8601String().split('T').first} - ${transaction.treatment}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      TransactionDetailScreen(recordId: transaction.id),
                ),
              );
              if (mounted) await _previewNext(_previewPage);
            },
          ),
        if (_preview!.matching == 0)
          const Text(
            'No matching history. This mapping will apply to eligible future messages only.',
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _busy || _previewPage == 0
                  ? null
                  : () => _previewNext(_previewPage - 1),
              child: const Text('Previous preview'),
            ),
            TextButton(
              onPressed: _busy || (_previewPage + 1) * 20 >= _preview!.matching
                  ? null
                  : () => _previewNext(_previewPage + 1),
              child: const Text('Next preview'),
            ),
          ],
        ),
      ],
      TextButton(
        onPressed: _busy ? null : () => _run(false),
        child: const Text('Preview matching transactions'),
      ),
      FilledButton(
        onPressed: _busy || _shared || _preview == null
            ? null
            : () => _run(true),
        child: const Text('Confirm mapping'),
      ),
      if (_busy) const LinearProgressIndicator(),
      FutureBuilder(
        future: _mappings,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Saved mappings unavailable.');
          }
          if (!snapshot.hasData) return const SizedBox.shrink();
          return Column(
            children: [
              for (final m in snapshot.data!)
                ListTile(
                  title: Text(
                    '${m.provider} / ${InstrumentMappingScreen.maskReference(m.reference)}',
                  ),
                  subtitle: Text(
                    '${purposeLabel(m.purpose)} - Reviewed and mapped',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove mapping',
                    onPressed: _busy ? null : () => _remove(m),
                    icon: const Icon(Icons.link_off),
                  ),
                ),
            ],
          );
        },
      ),
    ];
    return widget.embedded
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : ListView(padding: const EdgeInsets.all(16), children: children);
  }
}
