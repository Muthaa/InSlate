import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/enums/account_type.dart';
import '../../core/presentation/financial_presentation.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_records.dart';
import '../../models/transaction_category.dart';
import '../../repositories/categories_repository.dart';
import '../../providers/category_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/financial_semantics.dart';
import '../categories/categories_screen.dart';
import '../instruments/transaction_instruments_section.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final int recordId;
  final AccountEndpoint central;
  const TransactionDetailScreen({
    super.key,
    required this.recordId,
    this.central = const AccountEndpoint(AccountType.mpesa),
  });
  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _busy = false;

  Future<void> _save(String? categoryId, {bool similar = false}) async {
    setState(() => _busy = true);
    try {
      final repository = ref.read(categoriesRepositoryProvider);
      if (categoryId == null) {
        await repository.removeAssignment(widget.recordId);
      } else if (similar) {
        await repository.assignSimilar(
          recordId: widget.recordId,
          categoryId: categoryId,
        );
      } else {
        await repository.assign(
          recordId: widget.recordId,
          categoryId: categoryId,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update category. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(CategoryKind kind) async {
    final selected = await showModalBottomSheet<String>(
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
                    'Choose ${kind.name} category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ref
                      .watch(categoriesProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Center(
                          child: TextButton(
                            onPressed: () => ref.invalidate(categoriesProvider),
                            child: const Text(
                              'Unable to load categories. Retry',
                            ),
                          ),
                        ),
                        data: (all) {
                          final choices = all
                              .where((c) => c.kind == kind && !c.isHidden)
                              .toList();
                          if (choices.isEmpty) {
                            return const Center(
                              child: Text(
                                'No visible categories. Manage categories to add or unhide one.',
                              ),
                            );
                          }
                          return ListView(
                            children: [
                              for (final category in choices)
                                ListTile(
                                  key: ValueKey('choose.${category.id}'),
                                  title: Text(category.name),
                                  onTap: () =>
                                      Navigator.pop(context, category.id),
                                ),
                            ],
                          );
                        },
                      ),
                ),
                if (ref.watch(transactionDetailProvider(widget.recordId)).value
                    case final record?
                    when CategoriesRepository.ruleIdentity(record) == null)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'This transaction only: no reliable party identifier, phone or account is available.',
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  ),
                  child: const Text('Manage categories'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final record = ref.read(transactionDetailProvider(widget.recordId)).value;
    final reliable =
        record != null && CategoriesRepository.ruleIdentity(record) != null;
    if (!reliable) {
      await _save(selected);
      return;
    }
    final similar = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('This transaction only'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              title: const Text('This and similar transactions'),
              subtitle: const Text(
                'Apply to existing and future transactions with the same party identity and income/expense kind.',
              ),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (similar != null && mounted) await _save(selected, similar: similar);
  }

  Widget _category(CategoryKind kind, {int? originalId}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        ref
            .watch(recordCategoryProvider(originalId ?? widget.recordId))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(
                  recordCategoryProvider(originalId ?? widget.recordId),
                ),
                child: const Text('Unable to load assignment. Retry'),
              ),
              data: (assignment) => ref
                  .watch(categoriesProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => TextButton(
                      onPressed: () => ref.invalidate(categoriesProvider),
                      child: const Text('Unable to load categories. Retry'),
                    ),
                    data: (all) {
                      final matching = all.where(
                        (c) => c.id == assignment?.categoryId,
                      );
                      final category = matching.isEmpty ? null : matching.first;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment?.categoryId == null
                                ? 'Uncategorized'
                                : category == null
                                ? 'Category no longer available'
                                : '${category.name}${category.isHidden ? ' (hidden)' : ''}',
                          ),
                          if (assignment?.origin ==
                              CategoryAssignmentOrigin.ruleDerived)
                            Text(
                              assignment?.ruleId == null
                                  ? 'Automatically categorized by a previous rule'
                                  : 'Automatically categorized by a saved rule',
                            ),
                          if (originalId != null)
                            const Text('Inherited from original transaction'),
                          if (originalId == null)
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: _busy ? null : () => _choose(kind),
                                  child: Text(
                                    assignment?.categoryId == null
                                        ? 'Add category'
                                        : 'Change category',
                                  ),
                                ),
                                if (assignment?.categoryId != null)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: _busy ? null : () => _save(null),
                                    child: const Text('Clear category'),
                                  ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
            ),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );

  Widget _details(FinancialRecord record) {
    final presentation = TransactionPresentation.forRecord(
      record,
      central: widget.central,
    );
    final kind = switch (presentation.movement) {
      MovementClass.income => CategoryKind.income,
      MovementClass.expense => CategoryKind.expense,
      _ => null,
    };
    final color = kind == CategoryKind.income
        ? Colors.green.shade700
        : kind == CategoryKind.expense
        ? Colors.red.shade700
        : AppTheme.darkBlue;
    final party = record.party?.name.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  record.reference,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  party != null && party.isNotEmpty ? party : record.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${presentation.amountPrefix}${formatMoney(record.amount)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  presentation.directionLabel,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: TransactionInstrumentsSection(
            record: record,
            embedded: true,
            categorySection: kind != null
                ? _category(kind, originalId: record.reversesRecordId)
                : const Text(
                    'Categories apply to ordinary income and expenses.',
                  ),
          ),
        ),
        const SizedBox(height: 8),
        _detailCard('Transaction information', [
          _informationRow('Transaction', record.title),
          _informationRow(
            record.transactionDate == null ? 'Received at' : 'Transaction date',
            DateFormat.yMMMd().add_jm().format(
              record.transactionDate ?? record.receivedAt,
            ),
          ),
          _informationRow('Transaction type', record.type.name),
          _informationRow('Subtype', subtypeLabel(record.subtype)),
          if (record.parsedSubtype != null &&
              record.parsedSubtype != record.subtype) ...[
            _informationRow(
              'Interpretation source',
              record.interpretationMappingId == null
                  ? 'Recognized provider; purpose unspecified'
                  : 'User-confirmed account mapping',
            ),
            _informationRow(
              'Parsed subtype',
              subtypeLabel(record.parsedSubtype!),
            ),
          ],
          _reversalLinks(record),
        ]),
        const SizedBox(height: 8),
        _detailCard('Fees & status', [
          _informationRow('Recorded fee', formatMoney(record.transactionCost)),
          _informationRow('Status', record.status.name),
          if (record.reversesRecordId != null)
            _informationRow(
              'Adjustment policy',
              'Principal only; original fee retained. SMS time has minute precision.',
            ),
        ]),
      ],
    );
  }

  Widget _reversalLinks(FinancialRecord record) => ref
      .watch(relatedReversalProvider(widget.recordId))
      .when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => TextButton(
          onPressed: () =>
              ref.invalidate(relatedReversalProvider(widget.recordId)),
          child: const Text('Unable to load related transaction. Retry'),
        ),
        data: (relatedId) => relatedId == null
            ? const SizedBox.shrink()
            : ListTile(
                title: Text(
                  record.reversesRecordId == null
                      ? 'View principal reversal'
                      : 'View original PayBill',
                ),
                subtitle: const Text(
                  'Separate records; original payment and fee are preserved.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionDetailScreen(
                      recordId: relatedId,
                      central: widget.central,
                    ),
                  ),
                ),
              ),
      );

  Widget _detailCard(String title, List<Widget> children) => Card(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );

  Widget _informationRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkBlue),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      title: const Text('Transaction details'),
      backgroundColor: AppTheme.darkBlue,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      top: false,
      child: ref
          .watch(transactionDetailProvider(widget.recordId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(transactionDetailProvider(widget.recordId)),
                child: const Text('Unable to load transaction. Retry'),
              ),
            ),
            data: (record) => record == null
                ? const Center(child: Text('Transaction no longer available.'))
                : _details(record),
          ),
    ),
  );
}
