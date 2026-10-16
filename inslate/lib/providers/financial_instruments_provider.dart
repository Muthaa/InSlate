import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_instrument.dart';
import 'repository_providers.dart';

final financialInstrumentsProvider =
    StreamProvider.autoDispose<List<FinancialInstrument>>(
      (ref) => ref.watch(financialInstrumentsRepositoryProvider).watch(),
    );
final allFinancialInstrumentsProvider =
    StreamProvider.autoDispose<List<FinancialInstrument>>(
      (ref) => ref
          .watch(financialInstrumentsRepositoryProvider)
          .watch(includeArchived: true),
    );
