import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_instrument.dart';
import '../../providers/repository_providers.dart';
import 'instrument_presentation.dart';

class InstrumentFormScreen extends ConsumerStatefulWidget {
  final FinancialInstrument? instrument;
  final String? suggestedProvider;
  final String? suggestedName;
  final InstrumentType? suggestedType;
  const InstrumentFormScreen({
    super.key,
    this.instrument,
    this.suggestedProvider,
    this.suggestedName,
    this.suggestedType,
  });
  @override
  ConsumerState<InstrumentFormScreen> createState() =>
      _InstrumentFormScreenState();
}

class _InstrumentFormScreenState extends ConsumerState<InstrumentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _name,
      _provider,
      _account,
      _wallet,
      _membership,
      _policy,
      _reference;
  InstrumentType? _type;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.instrument;
    _name = TextEditingController(text: i?.name ?? widget.suggestedName);
    _provider = TextEditingController(
      text: i?.provider ?? widget.suggestedProvider,
    );
    _type = widget.suggestedType;
    _account = TextEditingController(text: i?.identifiers?.accountNumber);
    _wallet = TextEditingController(text: i?.identifiers?.walletNumber);
    _membership = TextEditingController(text: i?.identifiers?.membershipNumber);
    _policy = TextEditingController(text: i?.identifiers?.policyNumber);
    _reference = TextEditingController(text: i?.identifiers?.reference);
    if (i != null &&
        InstrumentType.values.any((t) => t.storageValue == i.storedType)) {
      _type = i.type;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _name,
      _provider,
      _account,
      _wallet,
      _membership,
      _policy,
      _reference,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_form.currentState!.validate()) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(financialInstrumentsRepositoryProvider);
      final identifiers = InstrumentIdentifiers(
        accountNumber: _account.text,
        walletNumber: _wallet.text,
        membershipNumber: _membership.text,
        policyNumber: _policy.text,
        reference: _reference.text,
      );
      final existing = widget.instrument;
      final saved = existing == null
          ? await repository.create(
              name: _name.text,
              type: _type!,
              provider: _provider.text,
              identifiers: identifiers,
            )
          : await repository.update(
              uuid: existing.uuid,
              name: _name.text,
              type: _type!,
              provider: _provider.text,
              identifiers: identifiers,
            );
      if (mounted) Navigator.pop(context, saved);
    } on ArgumentError catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = e.message?.toString() ?? 'Check the instrument details.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to save instrument. Your input has been kept. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      validator: required
          ? (v) => v == null || v.trim().isEmpty
                ? 'Enter an instrument name'
                : null
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(
          widget.instrument == null ? 'New instrument' : 'Edit instrument',
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.instrument == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Register only a product that belongs to you. Saving confirms your registration; it does not link or change any transactions. Review account references next.',
                  ),
                ),
              _field(
                'instrument.name',
                'Instrument name',
                _name,
                required: true,
              ),
              DropdownButtonFormField<InstrumentType>(
                key: const ValueKey('instrument.type'),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Instrument type',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Choose a type'),
                items: [
                  for (final type in InstrumentType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(
                        instrumentTypeLabel(type),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _saving ? null : (v) => setState(() => _type = v),
                validator: (v) =>
                    v == null ? 'Choose an instrument type' : null,
              ),
              if (widget.instrument != null &&
                  !InstrumentType.values.any(
                    (t) => t.storageValue == widget.instrument!.storedType,
                  ))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Choose a supported type before saving this instrument.',
                  ),
                ),
              const SizedBox(height: 16),
              _field(
                'instrument.provider',
                'Provider / institution (optional)',
                _provider,
              ),
              Text(
                'Optional identifiers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _field('instrument.account', 'Account number', _account),
              _field('instrument.wallet', 'Wallet number / phone', _wallet),
              _field('instrument.membership', 'Membership number', _membership),
              _field('instrument.policy', 'Policy number', _policy),
              _field('instrument.reference', 'Reference', _reference),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (_saving) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save instrument'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
