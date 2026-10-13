import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/balance_observation.dart';
import '../../providers/balance_evidence_provider.dart';

class BalanceFormScreen extends ConsumerStatefulWidget {
  final int accountId;
  final BalanceObservation? observation;
  const BalanceFormScreen({
    super.key,
    required this.accountId,
    this.observation,
  });
  @override
  ConsumerState<BalanceFormScreen> createState() => _BalanceFormScreenState();
}

class _BalanceFormScreenState extends ConsumerState<BalanceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _format = DateFormat('yyyy-MM-dd HH:mm');
  late final TextEditingController _amount, _date;
  late String _currency;
  late BalanceKind _kind;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final e = widget.observation;
    _currency = e?.currency ?? 'KES';
    _kind = e?.kind ?? BalanceKind.reported;
    _amount = TextEditingController(
      text: e == null ? '' : SnapshotMoney.decimal(e.amountMinor, e.currency),
    );
    _date = TextEditingController(
      text: _format.format((e?.asOf ?? DateTime.now()).toLocal()),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  DateTime _asOf() {
    final original = widget.observation?.asOf;
    if (original != null && _date.text == _format.format(original.toLocal())) {
      return original;
    }
    return _format.parseStrict(_date.text.trim());
  }

  Future<void> _pickDate() async {
    DateTime initial;
    try {
      initial = _asOf().toLocal();
    } catch (_) {
      initial = DateTime.now();
    }
    final today = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) || initial.year < 1900
          ? today
          : initial,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    _date.text = _format.format(
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
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
      _error = null;
    });
    try {
      final asOf = _asOf();
      final repository = ref.read(balanceEvidenceRepositoryProvider);
      final e = widget.observation;
      if (e == null) {
        setState(() => _busy = true);
        await repository.createManual(
          accountId: widget.accountId,
          amount: _amount.text,
          currency: _currency,
          kind: _kind,
          asOf: asOf,
        );
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AppDialog(
            icon: Icons.edit_outlined,
            title: const Text('Correct this observation?'),
            content: const Text(
              'This replaces the manually recorded amount and details.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Correct'),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
        setState(() => _busy = true);
        await repository.correctManual(
          id: e.id,
          accountId: widget.accountId,
          expectedRevision: e.revision,
          amount: _amount.text,
          currency: _currency,
          kind: _kind,
          asOf: asOf,
          subjectFamily: e.subjectFamily,
        );
      }
      if (mounted) Navigator.pop(context);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } on FormatException {
      if (mounted) {
        setState(
          () => _error = 'Enter a valid date and time: YYYY-MM-DD HH:mm.',
        );
      }
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to save observation. Your input has been kept. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(
          widget.observation == null ? 'Record balance' : 'Correct balance',
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Manually recorded observation. No balance is calculated from transactions.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('balance.amount'),
                controller: _amount,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) {
                  try {
                    SnapshotMoney.parse(v ?? '', _currency);
                    return null;
                  } on ArgumentError catch (e) {
                    return e.message.toString();
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('balance.currency'),
                initialValue: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final code in SnapshotMoney.scales.keys)
                    DropdownMenuItem(value: code, child: Text(code)),
                ],
                onChanged: _busy ? null : (v) => setState(() => _currency = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BalanceKind>(
                key: const ValueKey('balance.kind'),
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Balance kind',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final k in BalanceKind.values)
                    DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: _busy ? null : (v) => setState(() => _kind = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('balance.asOf'),
                controller: _date,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'As of (YYYY-MM-DD HH:mm)',
                  helperText: 'Local time (${DateTime.now().timeZoneName})',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _busy ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Save observation'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
