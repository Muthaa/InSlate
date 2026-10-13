import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_period.dart';
import '../models/instrument_history.dart';
import 'repository_providers.dart';
import 'activity_provider.dart';

typedef InstrumentHistoryQuery = ({
  int accountId,
  FinancialPeriod period,
  int page,
});
final instrumentHistoryProvider = FutureProvider.autoDispose
    .family<InstrumentHistoryPage, InstrumentHistoryQuery>((ref, query) {
      ref.watch(financialDataRevisionProvider);
      return ref
          .watch(financialInstrumentsRepositoryProvider)
          .history(
            accountId: query.accountId,
            period: query.period,
            page: query.page,
          );
    });
final instrumentHistoryMonthsProvider = FutureProvider.autoDispose
    .family<Set<DateTime>, int>((ref, id) {
      ref.watch(financialDataRevisionProvider);
      return ref
          .watch(financialInstrumentsRepositoryProvider)
          .historyMonths(id);
    });
