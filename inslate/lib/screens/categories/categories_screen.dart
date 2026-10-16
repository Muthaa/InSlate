import '../../widgets/app_dialog.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/repository_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save category. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([TransactionCategory? category]) async {
    final kind = category?.kind ?? _kind;
    var name = category?.name ?? '';
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.label_outline_rounded,
        title: Text(
          category == null ? 'New ${kind.name} category' : 'Rename category',
        ),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Category name',
              hintText: kind == CategoryKind.income
                  ? 'e.g. Freelance work'
                  : 'e.g. Groceries',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.teal, width: 2),
              ),
            ),
            onChanged: (value) => name = value,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a category name'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, name.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await _run(() async {
      final repository = ref.read(categoriesRepositoryProvider);
      if (category == null) {
        await repository.createCustom(name: result, kind: kind);
      } else {
        await repository.rename(category.id, result);
      }
    });
  }

  Future<void> _delete(TransactionCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.label_outline_rounded,
        title: Text('Delete ${category.name}?'),
        content: const Text(
          'Its automatic rules and transaction assignments will be removed. Those transactions will become uncategorized. Financial records will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(
        () => ref.read(categoriesRepositoryProvider).deleteCustom(category.id),
      );
    }
  }

  String _identityLabel(String key) {
    final parts = (jsonDecode(key) as List).cast<String>();
    final label = switch (parts.first) {
      'phone' => 'Phone',
      'account' => 'Account',
      _ => 'Identifier',
    };
    return '$label: ${parts.last}';
  }

  Widget _row(TransactionCategory category) => ListTile(
    key: ValueKey(category.id),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category.isHidden
            ? Icons.visibility_off_outlined
            : category.kind == CategoryKind.income
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
        color: category.kind == CategoryKind.income
            ? AppTheme.teal
            : Colors.red.shade700,
        size: 22,
      ),
    ),
    title: Text(
      category.name,
      style: const TextStyle(
        color: AppTheme.darkBlue,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      '${category.isBuiltIn ? 'Built-in' : 'Custom'}${category.isHidden ? ' · Hidden' : ''}',
    ),
    trailing: PopupMenuButton<String>(
      enabled: !_busy,
      tooltip: 'Manage ${category.name}',
      onSelected: (action) {
        switch (action) {
          case 'rename':
            _edit(category);
          case 'visibility':
            _run(
              () => ref
                  .read(categoriesRepositoryProvider)
                  .setHidden(category.id, !category.isHidden),
            );
          case 'delete':
            _delete(category);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(
          value: 'visibility',
          child: Text(category.isHidden ? 'Unhide' : 'Hide'),
        ),
        if (!category.isBuiltIn)
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.label_outline_rounded, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories'),
                Text(
                  'Income and expense purposes',
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
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('New category'),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text('Expenses'),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text('Income'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.single),
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ref
                .watch(categoriesProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(categoriesProvider),
                      child: const Text('Unable to load categories. Retry'),
                    ),
                  ),
                  data: (all) {
                    final visible = all
                        .where((c) => c.kind == _kind && !c.isHidden)
                        .toList();
                    final hidden = all
                        .where((c) => c.kind == _kind && c.isHidden)
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Categories describe what your income or expenses were for.',
                          ),
                        ),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No visible categories. Create one or unhide a category below.',
                            ),
                          ),
                        if (visible.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            child: Column(children: visible.map(_row).toList()),
                          ),
                        ref
                            .watch(categoryRulesProvider)
                            .when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) => TextButton(
                                onPressed: () =>
                                    ref.invalidate(categoryRulesProvider),
                                child: const Text(
                                  'Unable to load rules. Retry',
                                ),
                              ),
                              data: (rules) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Automatic categorization rules',
                                  ),
                                  subtitle: const Text(
                                    'Removing a rule keeps existing categories; future transactions stop matching.',
                                  ),
                                  children: [
                                    for (final rule in rules.where(
                                      (r) => r.kind == _kind.name,
                                    ))
                                      ListTile(
                                        title: Text(
                                          all
                                                  .where(
                                                    (c) =>
                                                        c.id == rule.categoryId,
                                                  )
                                                  .map((c) => c.name)
                                                  .firstOrNull ??
                                              'Unavailable category',
                                        ),
                                        subtitle: Text(
                                          _identityLabel(rule.identityKey),
                                        ),
                                        trailing: IconButton(
                                          tooltip: 'Remove rule',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: _busy
                                              ? null
                                              : () => _run(
                                                  () => ref
                                                      .read(
                                                        categoriesRepositoryProvider,
                                                      )
                                                      .deleteRule(rule.id),
                                                ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        if (hidden.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            child: ExpansionTile(
                              title: Text(
                                'Hidden categories (${hidden.length})',
                              ),
                              children: hidden.map(_row).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    ),
  );
}
