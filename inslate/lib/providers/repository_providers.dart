import '../repositories/instrument_links_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/financial_records_repository.dart';
import '../repositories/raw_messages_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/financial_instruments_repository.dart';
import 'database_provider.dart';

final financialRecordsRepositoryProvider = Provider<FinancialRecordsRepository>(
  (ref) {
    return FinancialRecordsRepository(ref.watch(databaseProvider));
  },
);

final rawMessagesRepositoryProvider = Provider<RawMessagesRepository>((ref) {
  return RawMessagesRepository(ref.watch(databaseProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

final financialInstrumentsRepositoryProvider =
    Provider<FinancialInstrumentsRepository>(
      (ref) => FinancialInstrumentsRepository(ref.watch(databaseProvider)),
    );

final instrumentLinksRepositoryProvider = Provider<InstrumentLinksRepository>(
  (ref) => InstrumentLinksRepository(ref.watch(databaseProvider)),
);
