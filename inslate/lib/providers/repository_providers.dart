import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/financial_records_repository.dart';
import '../repositories/raw_messages_repository.dart';
import 'database_provider.dart';

final financialRecordsRepositoryProvider = Provider<FinancialRecordsRepository>(
  (ref) {
    return FinancialRecordsRepository(ref.watch(databaseProvider));
  },
);

final rawMessagesRepositoryProvider = Provider<RawMessagesRepository>((ref) {
  return RawMessagesRepository(ref.watch(databaseProvider));
});
