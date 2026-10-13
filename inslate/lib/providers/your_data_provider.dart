import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/your_data_repository.dart';
import 'database_provider.dart';

final yourDataRepositoryProvider = Provider<YourDataRepository>(
  (ref) => YourDataRepository(ref.watch(databaseProvider)),
);
final yourDataSummaryProvider = StreamProvider.autoDispose<YourDataSummary>(
  (ref) => ref.watch(yourDataRepositoryProvider).watchSummary(),
);

final storedSmsDatesProvider = StreamProvider.autoDispose
    .family<List<DateTime>, int>(
      (ref, page) =>
          ref.watch(yourDataRepositoryProvider).watchSmsReceiptDates(page),
    );
