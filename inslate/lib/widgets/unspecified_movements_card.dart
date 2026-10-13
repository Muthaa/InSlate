import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/presentation/financial_presentation.dart';
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
  Widget build(BuildContext context, WidgetRef ref) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blueGrey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Purpose unspecified',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Principal awaiting a confirmed purpose. Separate from income and expenses; fees remain in Fees.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          ref
              .watch(unspecifiedMovementsProvider(period))
              .when(
                loading: () => const LinearProgressIndicator(),
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
                    : Row(
                        children: [
                          for (final incoming in [false, true])
                            Expanded(
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
                                        incoming ? 'Payment in' : 'Payment out',
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          formatMoney(
                                            incoming
                                                ? summary.incoming
                                                : summary.outgoing,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${incoming ? summary.incomingCount : summary.outgoingCount} transactions',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
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
