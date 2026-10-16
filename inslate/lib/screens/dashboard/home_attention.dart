import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/instrument_catalogue.dart';
import '../../core/design/slate_components.dart';
import '../../providers/detected_providers_provider.dart';
import '../../providers/financial_instruments_provider.dart';
import '../instruments/detected_providers_screen.dart';

/// Review tasks are all-time recognition, never a count of owned accounts.
/// Registration/mapping remains entirely in the existing account workflow.
class HomeAttention extends ConsumerWidget {
  const HomeAttention({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detected = ref.watch(detectedProvidersProvider);
    final instruments = ref.watch(allFinancialInstrumentsProvider);
    if (detected.hasError || instruments.hasError) {
      return SlateCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SlateSectionHeading(title: 'Attention'),
            const Text('Account review tasks are unavailable.'),
            TextButton(
              onPressed: () {
                ref.invalidate(detectedProvidersProvider);
                ref.invalidate(allFinancialInstrumentsProvider);
              },
              child: const Text('Retry account review'),
            ),
          ],
        ),
      );
    }
    // Do not advertise an invented zero while either source is loading.
    if (!detected.hasValue || !instruments.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Checking account review tasks…'),
      );
    }
    final names = detected.requireValue
        .where(
          (provider) => InstrumentCatalogue.registrations(
            provider.name,
            provider.suggestedType,
            instruments.requireValue,
          ).isEmpty,
        )
        .map((provider) => InstrumentCatalogue.providerKey(provider.name))
        .toSet();
    if (names.isEmpty) return const SizedBox.shrink();
    final p = SlateColors.of(context);
    return SlateCard(
      color: p.attentionSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SlateStatus(
            label: 'Needs your review',
            icon: Icons.fact_check_outlined,
            tone: SlateTone.attention,
          ),
          const SizedBox(height: 12),
          Text(
            'Accounts to review',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Across your recorded history, ${names.length} ${names.length == 1 ? 'provider appears' : 'providers appear'} without a matching registered instrument. Detection does not confirm ownership.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('home.reviewAccounts'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DetectedProvidersScreen(),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Review discovered providers'),
          ),
        ],
      ),
    );
  }
}
