import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_instrument.dart';
import '../../providers/financial_instruments_provider.dart';
import 'instrument_detail_screen.dart';
import 'instrument_form_screen.dart';
import 'instrument_presentation.dart';
import 'sms_balance_observations_screen.dart';
import 'detected_providers_screen.dart';
import 'instrument_catalogue_screen.dart';

class FinancialInstrumentsScreen extends ConsumerStatefulWidget {
  const FinancialInstrumentsScreen({super.key});
  @override
  ConsumerState<FinancialInstrumentsScreen> createState() =>
      _FinancialInstrumentsScreenState();
}

class _FinancialInstrumentsScreenState
    extends ConsumerState<FinancialInstrumentsScreen> {
  bool _archived = false, _review = false;
  Future<void> _create() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final saved = await Navigator.of(context).push<FinancialInstrument>(
      MaterialPageRoute(builder: (_) => const InstrumentFormScreen()),
    );
    if (saved != null && mounted) {
      setState(() => _archived = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Instrument created.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: 'Browse instrument catalogue',
          icon: const Icon(Icons.library_books_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const InstrumentCatalogueScreen(),
            ),
          ),
        ),
      ],
      title: const Row(
        children: [
          Icon(Icons.account_balance_outlined, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Instruments'),
                Text(
                  'Registered products and accounts to review',
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
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: const Text('New instrument'),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Review SMS balance observations'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const SmsBalanceObservationsScreen(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Registered')),
                ButtonSegment(value: true, label: Text('Accounts to review')),
              ],
              selected: {_review},
              onSelectionChanged: (values) =>
                  setState(() => _review = values.single),
            ),
          ),
          if (!_review)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Active')),
                  ButtonSegment(value: true, label: Text('Archived')),
                ],
                selected: {_archived},
                onSelectionChanged: (v) => setState(() => _archived = v.single),
              ),
            ),
          Expanded(
            child: _review
                ? const DetectedProvidersScreen(embedded: true)
                : ref
                      .watch(allFinancialInstrumentsProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Center(
                          child: TextButton(
                            onPressed: () =>
                                ref.invalidate(allFinancialInstrumentsProvider),
                            child: const Text(
                              'Unable to load instruments. Retry',
                            ),
                          ),
                        ),
                        data: (all) {
                          final instruments = all
                              .where((i) => i.isArchived == _archived)
                              .toList();
                          if (instruments.isEmpty) {
                            return Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _archived
                                          ? Icons.archive_outlined
                                          : Icons
                                                .account_balance_wallet_outlined,
                                      size: 48,
                                      color: AppTheme.teal,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _archived
                                          ? 'No archived instruments'
                                          : 'No active instruments',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _archived
                                          ? 'Archived instruments will appear here for viewing or restoration.'
                                          : 'Register your accounts, wallets and other financial instruments, or start from Accounts to review. Detection does not confirm ownership.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: instruments.length,
                            itemBuilder: (context, index) {
                              final i = instruments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                child: ListTile(
                                  key: ValueKey('instrument.${i.uuid}'),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.appBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      instrumentTypeIcon(i.type),
                                      color: _archived
                                          ? Colors.blueGrey
                                          : AppTheme.teal,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    i.name,
                                    style: const TextStyle(
                                      color: AppTheme.darkBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      instrumentTypeLabel(i.type),
                                      if (i.provider != null) i.provider!,
                                    ].join('\n'),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => InstrumentDetailScreen(
                                          uuid: i.uuid,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}
