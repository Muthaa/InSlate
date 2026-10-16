import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_filter.dart';
import '../../models/transaction_category.dart';
import '../../core/enums/record_subtype.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../providers/category_provider.dart';

class ActivityAdvancedFilters extends ConsumerStatefulWidget {
  final ActivityFilter filter, constraints;
  const ActivityAdvancedFilters({
    super.key,
    required this.filter,
    required this.constraints,
  });
  @override
  ConsumerState<ActivityAdvancedFilters> createState() =>
      _ActivityAdvancedFiltersState();
}

class _ActivityAdvancedFiltersState
    extends ConsumerState<ActivityAdvancedFilters> {
  late ActivityFilter _draft = widget.filter;
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Advanced filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(categoriesProvider),
                  child: const Text('Unable to load categories. Retry'),
                ),
                data: (all) {
                  final valid =
                      _draft.category?.categoryId == null ||
                      all.any((c) => c.id == _draft.category!.categoryId);
                  final selected = valid ? _draft.category : null;
                  return DropdownButtonFormField<ActivityCategoryFilter>(
                    key: ValueKey(('category', selected)),
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    hint: const Text('All categories'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All categories'),
                      ),
                      const DropdownMenuItem(
                        value: ActivityCategoryFilter.uncategorized(),
                        child: Text('Uncategorized'),
                      ),
                      for (final kind in CategoryKind.values)
                        for (final c in all.where((c) => c.kind == kind))
                          DropdownMenuItem(
                            value: ActivityCategoryFilter.category(c.id),
                            child: Text(
                              '${c.name} (${c.kind.name})${c.isHidden ? ' (hidden)' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    ],
                    onChanged: widget.constraints.category != null
                        ? null
                        : (v) =>
                              setState(() => _draft = _draft.withCategory(v)),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecordSubtype>(
                initialValue: _draft.subtype,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Transaction subtype',
                ),
                hint: const Text('All subtypes'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All subtypes'),
                  ),
                  for (final s in RecordSubtype.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        subtypeLabel(s),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: widget.constraints.subtype != null
                    ? null
                    : (v) =>
                          setState(() => _draft = _draft.copyWith(subtype: v)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PartyPresence>(
                initialValue: _draft.partyPresence,
                decoration: const InputDecoration(labelText: 'Party'),
                hint: const Text('All parties'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All parties')),
                  DropdownMenuItem(
                    value: PartyPresence.identified,
                    child: Text('Identified party'),
                  ),
                  DropdownMenuItem(
                    value: PartyPresence.unidentified,
                    child: Text('Unidentified party'),
                  ),
                ],
                onChanged: widget.constraints.partyPresence != null
                    ? null
                    : (v) => setState(
                        () => _draft = _draft.copyWith(partyPresence: v),
                      ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SemanticResolution>(
                initialValue: _draft.resolution,
                decoration: const InputDecoration(
                  labelText: 'Financial meaning',
                ),
                hint: const Text('All financial meanings'),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All financial meanings'),
                  ),
                  DropdownMenuItem(
                    value: SemanticResolution.resolved,
                    child: Text('Resolved financial meaning'),
                  ),
                  DropdownMenuItem(
                    value: SemanticResolution.unresolved,
                    child: Text('Unresolved financial meaning'),
                  ),
                ],
                onChanged: widget.constraints.resolution != null
                    ? null
                    : (v) => setState(
                        () => _draft = _draft.copyWith(resolution: v),
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final all = categories.valueOrNull;
                  final id = _draft.category?.categoryId;
                  final result =
                      id != null && all != null && !all.any((c) => c.id == id)
                      ? _draft.withCategory(null)
                      : _draft;
                  Navigator.pop(context, result);
                },
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
