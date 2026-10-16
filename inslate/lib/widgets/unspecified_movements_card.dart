import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design/slate_components.dart';
import '../models/financial_period.dart';
import '../providers/repository_providers.dart';
import '../providers/activity_provider.dart';
import '../repositories/unspecified_movements_repository.dart';
import '../screens/activity/activity_screen.dart';

final unspecifiedMovementsProvider = StreamProvider.autoDispose
    .family<UnspecifiedMovements, FinancialPeriod>((ref, period) {
      ref.watch(financialDataRevisionProvider);
      return UnspecifiedMovementsRepository(
        ref.watch(financialRecordsRepositoryProvider).database,
      ).watch(period);
    });

class UnspecifiedMovementsCard extends ConsumerWidget {
  final FinancialPeriod period;
  const UnspecifiedMovementsCard({super.key, required this.period});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SlateCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlateSectionHeading(
          title: 'Purpose unspecified',
          subtitle:
              'Principal awaiting a confirmed purpose. Separate from income and expenses; fees remain in Fees.',
        ),
        const SizedBox(height: 16),
        ref
            .watch(unspecifiedMovementsProvider(period))
            .when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Text('Loading unspecified movements…'),
              error: (_, _) => TextButton(
                onPressed: () =>
                    ref.invalidate(unspecifiedMovementsProvider(period)),
                child: const Text('Unable to load movements. Retry'),
              ),
              data: (summary) =>
                  summary.outgoingCount + summary.incomingCount == 0
                  ? const Text(
                      'No purpose-unspecified movements in this period.',
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final single =
                            constraints.maxWidth < 300 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            for (final incoming in [false, true])
                              SizedBox(
                                width: single
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 16) / 2,
                                child: InkWell(
                                  key: ValueKey(
                                    'unspecified.${incoming ? 'incoming' : 'outgoing'}',
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => ActivityScreen(
                                        initialFilter:
                                            UnspecifiedMovements.filter(
                                              period,
                                              incoming: incoming,
                                            ),
                                        preserveDrillDown: true,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          incoming
                                              ? 'Payment in'
                                              : 'Payment out',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 8),
                                        SlateAmount(
                                          amount: incoming
                                              ? summary.incoming
                                              : summary.outgoing,
                                          color: SlateColors.of(
                                            context,
                                          ).movement,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${incoming ? summary.incomingCount : summary.outgoingCount} transactions',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
      ],
    ),
  );
}
