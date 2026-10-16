import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/financial_records.dart' as domain;
import '../services/financial_semantics.dart';
import 'financial_records_repository.dart';

enum InstrumentEndpoint { source, destination }

/// Explicit metadata associations; never inputs to FinancialSemantics.
class InstrumentLinks {
  final int? sourceId, destinationId;
  const InstrumentLinks(this.sourceId, this.destinationId);
  int? at(InstrumentEndpoint endpoint) =>
      endpoint == InstrumentEndpoint.source ? sourceId : destinationId;
}

class InstrumentLinksRepository {
  final AppDatabase database;
  InstrumentLinksRepository(this.database);

  /// Explicit associations may identify either endpoint of a resolved movement.
  /// Instrument metadata alone never establishes ownership or changes semantics.
  static bool supports(
    domain.FinancialRecord record,
    InstrumentEndpoint endpoint,
  ) {
    if (FinancialSemantics.isExpenseReversal(record)) {
      return endpoint == InstrumentEndpoint.destination;
    }
    // Explicit endpoint associations do not alter financial meaning.
    return const FinancialSemantics().classify(record) !=
            MovementClass.unresolved ||
        record.subtype.name == 'instrumentPayment' ||
        record.subtype.name == 'instrumentReceipt';
  }

  Stream<InstrumentLinks?> watch(int recordId) =>
      (database.select(
        database.financialRecords,
      )..where((r) => r.id.equals(recordId))).watchSingleOrNull().map(
        (row) => row == null
            ? null
            : InstrumentLinks(row.sourceAccountId, row.destinationAccountId),
      );

  /// expectedCurrentId is mandatory for both replacement and unlinking.
  /// Validate and update in one transaction to reject stale editors.
  Future<void> setLink({
    required int recordId,
    required InstrumentEndpoint endpoint,
    required int? instrumentId,
    required int? expectedCurrentId,
  }) => database.transaction(() async {
    final row = await (database.select(
      database.financialRecords,
    )..where((r) => r.id.equals(recordId))).getSingleOrNull();
    if (row == null) throw ArgumentError('Transaction no longer exists.');
    final current = endpoint == InstrumentEndpoint.source
        ? row.sourceAccountId
        : row.destinationAccountId;
    if (current != expectedCurrentId) {
      throw StateError('This association changed. Review it and try again.');
    }
    if (instrumentId != null) {
      final record = (await FinancialRecordsRepository(
        database,
      ).getById(recordId))!;
      if (!supports(record, endpoint)) {
        throw ArgumentError('This transaction does not support that endpoint.');
      }
      final account = await (database.select(
        database.accounts,
      )..where((a) => a.id.equals(instrumentId))).getSingleOrNull();
      if (account == null || !account.isUserRegistered) {
        throw ArgumentError('Choose a registered instrument.');
      }
      if (!account.isActive) {
        throw ArgumentError('Archived instruments cannot receive new links.');
      }
    }
    await (database.update(
      database.financialRecords,
    )..where((r) => r.id.equals(recordId))).write(
      endpoint == InstrumentEndpoint.source
          ? FinancialRecordsCompanion(sourceAccountId: Value(instrumentId))
          : FinancialRecordsCompanion(
              destinationAccountId: Value(instrumentId),
            ),
    );
  });
}
