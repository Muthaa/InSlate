import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/balance_observation.dart';
import '../repositories/balance_evidence_repository.dart';
import 'database_provider.dart';

final balanceEvidenceRepositoryProvider = Provider<BalanceEvidenceRepository>(
  (ref) => BalanceEvidenceRepository(ref.watch(databaseProvider)),
);
final _balanceRevisionProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(balanceEvidenceRepositoryProvider).changes(),
);
final latestBalanceProvider = FutureProvider.autoDispose
    .family<BalanceObservation?, int>((ref, id) {
      ref.watch(_balanceRevisionProvider.select((v) => v.valueOrNull ?? 0));
      return ref.watch(balanceEvidenceRepositoryProvider).latest(id);
    });
typedef BalanceHistoryQuery = ({int accountId, int page});
final balanceHistoryProvider = FutureProvider.autoDispose
    .family<BalanceHistoryPage, BalanceHistoryQuery>((ref, query) {
      ref.watch(_balanceRevisionProvider.select((v) => v.valueOrNull ?? 0));
      return ref
          .watch(balanceEvidenceRepositoryProvider)
          .history(query.accountId, page: query.page);
    });

typedef SmsBalanceQuery = ({bool unattributedOnly, int page});
final smsBalanceHistoryProvider = FutureProvider.autoDispose
    .family<BalanceHistoryPage, SmsBalanceQuery>((ref, query) {
      ref.watch(_balanceRevisionProvider.select((v) => v.valueOrNull ?? 0));
      return ref
          .watch(balanceEvidenceRepositoryProvider)
          .smsHistory(
            unattributedOnly: query.unattributedOnly,
            page: query.page,
          );
    });
