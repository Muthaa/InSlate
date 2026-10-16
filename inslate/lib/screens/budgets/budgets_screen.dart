import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../models/budget.dart';
import '../../models/balance_observation.dart';
import '../../models/financial_period.dart';
import '../../models/transaction_category.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/category_provider.dart';
import '../activity/activity_screen.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  final bool previousMonth;
  const BudgetsScreen({super.key, this.previousMonth = false});
  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late bool _previous = widget.previousMonth;
  Future<void> _edit([Budget? budget]) => showDialog<void>(
    context: context,
    builder: (_) => _BudgetForm(budget: budget),
  );
  Future<void> _action(Budget b, String action) async {
    if (action == 'edit') {
      await _edit(b);
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          icon: Icons.delete_outline,
          destructive: true,
          title: const Text('Delete budget?'),
          content: const Text(
            'This removes the target. Financial records and spending remain unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      final repo = ref.read(budgetsRepositoryProvider);
      if (action == 'delete') {
        await repo.delete(b.id);
      } else {
        await repo.setActive(b.id, !b.isActive);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ArgumentError
                  ? error.message.toString()
                  : 'Unable to save budget. Please try again.',
            ),
          ),
        );
      }
    }
  }

  double _visualFraction(BudgetProgress progress) {
    final points = progress.usedBasisPoints!;
    if (points < BigInt.zero) return 0;
    if (points > BigInt.from(10000)) return 1;
    return points.toInt() / 10000;
  }

  Widget _card(BudgetProgress progress) {
    final b = progress.budget;
    final available = progress.spentMinor != null;
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.darkBlue.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${b.label}${b.categoryHidden ? ' (hidden)' : ''}',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  key: ValueKey('budget.menu.${b.id}'),
                  onSelected: (value) => _action(b, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (b.available)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(b.isActive ? 'Pause' : 'Resume'),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: b.isActive
                    ? AppTheme.teal.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                b.isActive ? 'Active monthly target' : 'Paused target',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: b.isActive ? AppTheme.teal : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget: ${budgetMoney(BigInt.from(b.amountMinor))}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!b.available)
                    const Text(
                      'Category deleted. Choose a replacement category and resume this target.',
                    )
                  else if (!available)
                    const Text(
                      'Spending unavailable: a recorded amount cannot be represented safely in KES cents.',
                    )
                  else ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Spent: ${budgetMoney(progress.spentMinor!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        Text(
                          'Used: ${progress.usedPercentage}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: progress.overspentMinor! > BigInt.zero
                                ? Colors.deepOrange
                                : AppTheme.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Floating point is only a visual fraction; monetary arithmetic stays integer.
                    LinearProgressIndicator(
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      value: _visualFraction(progress),
                      color: progress.overspentMinor! > BigInt.zero
                          ? Colors.deepOrange
                          : AppTheme.teal,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Remaining: ${budgetMoney(progress.remainingMinor!)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: progress.overspentMinor! > BigInt.zero
                            ? Colors.deepOrange
                            : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (progress.count == 0)
                      const Text('No spending recorded this month.')
                    else if (progress.overspentMinor! > BigInt.zero)
                      Text(
                        'Over budget by ${budgetMoney(progress.overspentMinor!)}',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (progress.remainingMinor == BigInt.zero)
                      const Text('Budget fully used. Zero remaining.'),
                  ],
                ],
              ),
            ),
            if (progress.filter != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ActivityScreen(
                      initialFilter: progress.filter,
                      preserveDrillDown: true,
                    ),
                  ),
                ),
                label: const Text('View spending in Activity'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = FinancialPeriod.month(
      DateTime(now.year, now.month - (_previous ? 1 : 0)),
    );
    final result = ref.watch(budgetsProvider(period));
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'About budgets',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _BudgetsInformationDialog(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<bool>(
            isExpanded: true,
            initialValue: _previous,
            decoration: InputDecoration(
              labelText: 'Month',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: false, child: Text('Current month')),
              DropdownMenuItem(value: true, child: Text('Previous month')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _previous = value);
            },
          ),
          const SizedBox(height: 8),
          Text(periodLabel(period)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('New budget'),
          ),
          const SizedBox(height: 12),
          result.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              children: [
                const Text('Budget data unavailable.'),
                TextButton(
                  onPressed: () => ref.invalidate(budgetsProvider(period)),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (rows) => rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No budgets. Create a monthly target to compare it with recorded spending.',
                    ),
                  )
                : Column(children: rows.map(_card).toList()),
          ),
        ],
      ),
    );
  }
}

class _BudgetForm extends ConsumerStatefulWidget {
  final Budget? budget;
  const _BudgetForm({this.budget});
  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final _form = GlobalKey<FormState>();
  late String _scope = widget.budget == null || widget.budget!.overall
      ? 'overall'
      : widget.budget!.categoryId ?? 'deleted';
  late String _amount = widget.budget == null
      ? ''
      : SnapshotMoney.decimal(widget.budget!.amountMinor, 'KES');
  String? _error;
  bool _saving = false;
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(budgetsRepositoryProvider);
      final category = _scope == 'overall' ? null : _scope;
      if (widget.budget == null) {
        await repo.create(amount: _amount, categoryId: category);
      } else {
        await repo.update(
          id: widget.budget!.id,
          amount: _amount,
          categoryId: category,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ArgumentError
              ? error.message.toString()
              : 'Unable to save budget. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    InputDecoration fieldDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.teal, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        );
    return AlertDialog(
      backgroundColor: const Color(0xFFF4F7F8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppTheme.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.budget == null
                  ? 'New monthly budget'
                  : 'Edit monthly budget',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(categoriesProvider),
                  child: const Text('Unable to load categories. Retry'),
                ),
                data: (all) {
                  final expenses = all
                      .where((c) => c.kind == CategoryKind.expense)
                      .toList();
                  final valid =
                      _scope == 'overall' ||
                      expenses.any((c) => c.id == _scope);
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: valid ? _scope : 'deleted',
                    decoration: fieldDecoration(
                      'Scope',
                      Icons.category_outlined,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'overall',
                        child: Text(
                          'Overall expenses',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!valid)
                        const DropdownMenuItem(
                          value: 'deleted',
                          enabled: false,
                          child: Text(
                            'Choose a replacement category',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      for (final c in expenses)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.name}${c.isHidden ? ' (hidden)' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) => value == 'deleted' || value == null
                        ? 'Choose an expense category or overall expenses.'
                        : null,
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _scope = value);
                          },
                  );
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                enabled: !_saving,
                initialValue: _amount,
                onChanged: (value) => _amount = value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: fieldDecoration(
                  'Monthly amount (KES)',
                  Icons.payments_outlined,
                ),
                validator: (value) {
                  try {
                    parseBudgetMoney(value ?? '');
                    return null;
                  } on ArgumentError catch (error) {
                    return error.message.toString();
                  }
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'One active target per scope. Edits change the target in all displayed months, without changing spending. Overall and category targets overlap; do not add their spending totals together.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.darkBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _saving || !categories.hasValue ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _BudgetsInformationDialog extends StatelessWidget {
  const _BudgetsInformationDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppTheme.teal;
    const details = [
      (
        'Spending targets',
        'Monthly targets are not account balances. Ordinary expense principal only; fees, loans and internal transfers are excluded. Overall spending includes Uncategorized.',
      ),
      (
        'Monthly behavior',
        'Targets repeat each month. Edits apply to both current and previous-month views without changing recorded spending. Paused targets remain viewable.',
      ),
    ];
    return AlertDialog(
      backgroundColor: const Color(0xFFF4F7F8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'About budgets',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppTheme.darkBlue),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final detail in details) ...[
              Text(
                detail.$1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.$2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Overall and category targets overlap; their spending totals are not additive.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
