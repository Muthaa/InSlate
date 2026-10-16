import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_instrument.dart';
import '../../repositories/detected_providers_repository.dart';
import '../../core/constants/instrument_catalogue.dart';
import '../../providers/financial_instruments_provider.dart';
import '../../providers/detected_providers_provider.dart';
import '../activity/activity_screen.dart';
import 'instrument_form_screen.dart';
import 'instrument_detail_screen.dart';
import 'instrument_mapping_screen.dart';

class DetectedProvidersScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const DetectedProvidersScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DetectedProvidersScreen> createState() =>
      _DetectedProvidersScreenState();
}

class _DetectedProvidersScreenState
    extends ConsumerState<DetectedProvidersScreen> {
  int _page = 0;
  // Display grouping only: transaction identities remain independent.
  List<List<DetectedProvider>> _groups(List<DetectedProvider> providers) {
    final groups = <String, List<DetectedProvider>>{};
    for (final provider in providers) {
      final name = InstrumentCatalogue.providerKey(provider.name);
      final key = name;
      (groups[key] ??= []).add(provider);
    }
    return groups.values.toList()..sort((a, b) {
      final count = b
          .fold<int>(0, (sum, p) => sum + p.count)
          .compareTo(a.fold<int>(0, (sum, p) => sum + p.count));
      return count != 0 ? count : a.first.name.compareTo(b.first.name);
    });
  }

  Future<void> _review(
    BuildContext context,
    List<DetectedProvider> group,
  ) async {
    final provider = group.length == 1
        ? group.single
        : await showModalBottomSheet<DetectedProvider>(
            context: context,
            isScrollControlled: true,
            builder: (context) => SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${group.first.name} activity groups',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Separate transaction identities are retained. These groups do not confirm separate accounts or ownership.',
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: group.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(
                            group[index].providerReference?.reference == null
                                ? 'No account reference reported'
                                : InstrumentMappingScreen.maskReference(
                                    group[index].providerReference!.reference!,
                                  ),
                          ),
                          subtitle: Text(
                            '${group[index].count} matching transactions',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, group[index]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    if (provider == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ActivityScreen(
          initialFilter: provider.filter,
          preserveDrillDown: true,
        ),
      ),
    );
  }

  Future<void> _openRegistered(
    BuildContext context,
    List<FinancialInstrument> instruments,
  ) async {
    final selected = instruments.length == 1
        ? instruments.single
        : await showModalBottomSheet<FinancialInstrument>(
            context: context,
            builder: (context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    title: Text('Choose your registered instrument'),
                  ),
                  for (final instrument in instruments)
                    ListTile(
                      title: Text(instrument.name),
                      onTap: () => Navigator.pop(context, instrument),
                    ),
                ],
              ),
            ),
          );
    if (selected != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => InstrumentDetailScreen(uuid: selected.uuid),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _body(context, ref)
      : Scaffold(
          backgroundColor: AppTheme.appBackground,
          appBar: AppBar(
            title: const Text('Detected providers'),
            backgroundColor: AppTheme.darkBlue,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(top: false, child: _body(context, ref)),
        );

  Widget _body(BuildContext context, WidgetRef ref) => ref
      .watch(detectedProvidersPageProvider(_page))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(detectedProvidersProvider),
            child: const Text('Unable to load detected providers. Retry'),
          ),
        ),
        data: (providers) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'These providers appear in stored investment, savings or unspecified financial-provider activity. Accounts to review are setup tasks, not Purpose unspecified movements. Recognition does not confirm ownership or the number of accounts. Register an instrument only if it belongs to you.',
              style: TextStyle(color: Colors.blueGrey, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (providers.isEmpty)
              const Text(
                'No identified financial providers in stored activity.',
              ),
            for (final group
                in (_groups(providers)..sort(
                      (a, b) => InstrumentCatalogue.providerKey(a.first.name)
                          .compareTo(
                            InstrumentCatalogue.providerKey(b.first.name),
                          ),
                    ))
                    .take(20))
              for (final provider in [group.first])
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              color: AppTheme.teal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ref
                            .watch(allFinancialInstrumentsProvider)
                            .when(
                              loading: () => const Text(
                                'Checking registered instruments...',
                                style: TextStyle(fontSize: 12),
                              ),
                              error: (_, _) => const Text(
                                'Registration status unavailable',
                                style: TextStyle(fontSize: 12),
                              ),
                              data: (instruments) {
                                final matches =
                                    InstrumentCatalogue.registrations(
                                      provider.name,
                                      provider.suggestedType,
                                      instruments,
                                    );
                                if (matches.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final active = matches
                                    .where((i) => i.isActive)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    active > 0
                                        ? 'Registered: $active active instrument(s) with this provider/type'
                                        : 'Registered instruments archived',
                                    style: const TextStyle(
                                      color: AppTheme.teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                        Text(
                          '${group.fold<int>(0, (sum, p) => sum + p.count)} matching transactions',
                        ),
                        if (group.length == 1 &&
                            provider.providerReference != null)
                          Text(
                            'Reference: ${provider.providerReference!.reference == null ? 'not reported' : InstrumentMappingScreen.maskReference(provider.providerReference!.reference!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        if (group.length > 1)
                          Text(
                            '${group.length} activity groups under this provider',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        if (provider.unspecified)
                          const Text(
                            'Purpose unspecified. Confirm the product purpose using an exact customer account reference.',
                          ),
                        const Text(
                          'Provider recognition only; ownership not confirmed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              key: ValueKey(
                                'detected.register.${provider.name}',
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                ref
                                            .watch(
                                              allFinancialInstrumentsProvider,
                                            )
                                            .asData
                                            ?.value
                                            .any(
                                              (i) =>
                                                  InstrumentCatalogue.registrations(
                                                    provider.name,
                                                    provider.suggestedType,
                                                    [i],
                                                  ).isNotEmpty,
                                            ) ==
                                        true
                                    ? 'Add another instrument'
                                    : 'Register an instrument',
                              ),
                              onPressed: () async {
                                final instrument =
                                    await Navigator.push<FinancialInstrument>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => InstrumentFormScreen(
                                          suggestedProvider: provider.name,
                                          suggestedType: provider.suggestedType,
                                        ),
                                      ),
                                    );
                                if (instrument != null && context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => InstrumentDetailScreen(
                                        uuid: instrument.uuid,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (ref
                                    .watch(allFinancialInstrumentsProvider)
                                    .asData
                                    ?.value
                                    .any(
                                      (instrument) =>
                                          instrument.isActive &&
                                          instrument.provider != null &&
                                          InstrumentCatalogue.providerKey(
                                                instrument.provider!,
                                              ) ==
                                              InstrumentCatalogue.providerKey(
                                                provider.name,
                                              ),
                                    ) ==
                                true)
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18,
                                ),
                                label: const Text('Open registered instrument'),
                                onPressed: () => _openRegistered(
                                  context,
                                  ref
                                      .read(allFinancialInstrumentsProvider)
                                      .asData!
                                      .value
                                      .where(
                                        (instrument) =>
                                            instrument.isActive &&
                                            instrument.provider != null &&
                                            InstrumentCatalogue.providerKey(
                                                  instrument.provider!,
                                                ) ==
                                                InstrumentCatalogue.providerKey(
                                                  provider.name,
                                                ),
                                      )
                                      .toList(),
                                ),
                              ),
                            TextButton.icon(
                              key: ValueKey('detected.review.${provider.name}'),
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                                size: 18,
                              ),
                              label: const Text('Review activity'),
                              onPressed: () => _review(context, group),
                            ),
                          ],
                        ),
                        const Text(
                          'Already registered? Open Instrument Details to map an exact provider and customer reference, or link individual transactions in Activity.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _page == 0 ? null : () => setState(() => _page--),
                  child: const Text('Previous providers'),
                ),
                Text('Page ${_page + 1}'),
                TextButton(
                  onPressed: _groups(providers).length <= 20
                      ? null
                      : () => setState(() => _page++),
                  child: const Text('Next providers'),
                ),
              ],
            ),
          ],
        ),
      );
}
