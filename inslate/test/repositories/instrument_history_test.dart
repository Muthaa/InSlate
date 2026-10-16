import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/instrument_history.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialInstrumentsRepository instruments;
  late FinancialRecordsRepository records;
  late FinancialInstrument instrument, other;
  final period = FinancialPeriod.month(DateTime(2026, 9));
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    instruments = FinancialInstrumentsRepository(db);
    records = FinancialRecordsRepository(db);
    instrument = await instruments.create(
      name: 'sendMoney',
      provider: 'sendMoney',
      type: InstrumentType.mobileWallet,
      identifiers: const InstrumentIdentifiers(reference: 'sendMoney'),
    );
    other = await instruments.create(
      name: 'sendMoney',
      type: InstrumentType.mobileWallet,
    );
  });
  tearDown(() => db.close());
  Future<int> save({
    int? source,
    int? destination,
    DateTime? date,
    DateTime? receivedAt,
    RecordSubtype subtype = RecordSubtype.mshwariDeposit,
  }) async {
    await records.save(record(subtype, 10, date: date, receivedAt: receivedAt));
    final id = (await db.financialRecordsDao.getAllRecords()).last.id;
    await (db.update(db.financialRecords)..where((r) => r.id.equals(id))).write(
      FinancialRecordsCompanion(
        sourceAccountId: Value(source),
        destinationAccountId: Value(destination),
      ),
    );
    return id;
  }

  Future<InstrumentHistoryPage> history([int page = 0]) =>
      instruments.history(accountId: instrument.id, period: period, page: page);
  test(
    'numeric membership preserves source/destination roles and counts self-linked once',
    () async {
      final source = await save(source: instrument.id, destination: 987);
      final destination = await save(
        source: other.id,
        destination: instrument.id,
      );
      final both = await save(
        source: instrument.id,
        destination: instrument.id,
      );
      await save(source: other.id, destination: other.id);
      await save(subtype: RecordSubtype.sendMoney);
      final result = await history();
      expect(result.count, 3);
      expect(result.entries.map((e) => e.record.id), [
        both,
        destination,
        source,
      ]);
      expect(result.entries.map((e) => e.role), [
        InstrumentTransactionRole.selfLinked,
        InstrumentTransactionRole.incoming,
        InstrumentTransactionRole.outgoing,
      ]);
    },
  );
  test(
    'empty/no-link history never matches names providers or identifiers',
    () async {
      await save(subtype: RecordSubtype.sendMoney);
      await save(source: 987, destination: 988);
      final result = await history();
      expect(result.count, 0);
      expect(result.entries, isEmpty);
      expect(result.totalPages, 0);
      expect(await instruments.historyMonths(instrument.id), isEmpty);
    },
  );
  test(
    'period is start inclusive/end exclusive with transaction date before received date',
    () async {
      final start = await save(
        source: instrument.id,
        date: DateTime(2026, 9),
        receivedAt: DateTime(2026, 10),
      );
      final end = await save(
        destination: instrument.id,
        date: DateTime(2026, 9, 30, 23, 59, 59),
      );
      await save(
        source: instrument.id,
        date: DateTime(2026, 10),
        receivedAt: DateTime(2026, 9),
      );
      await save(
        source: instrument.id,
        date: DateTime(2026, 8, 31, 23, 59, 59),
      );
      final fallback = await save(
        destination: instrument.id,
        receivedAt: DateTime(2026, 9, 15),
      );
      expect((await history()).entries.map((e) => e.record.id), [
        end,
        fallback,
        start,
      ]);
      expect(await instruments.historyMonths(instrument.id), {
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      });
    },
  );
  test(
    'exact count precedes bounded pages and equal dates have stable ID order',
    () async {
      await records.saveAll(
        List.generate(103, (_) => record(RecordSubtype.sendMoney, 10)),
      );
      await (db.update(db.financialRecords)).write(
        FinancialRecordsCompanion(sourceAccountId: Value(instrument.id)),
      );
      final first = await history();
      final middle = await history(1);
      final last = await history(2);
      expect([first.count, middle.count, last.count], [103, 103, 103]);
      expect(
        [first.entries.length, middle.entries.length, last.entries.length],
        [50, 50, 3],
      );
      expect(first.totalPages, 3);
      final ids = [
        ...first.entries,
        ...middle.entries,
        ...last.entries,
      ].map((e) => e.record.id!).toList();
      expect(ids, List.generate(103, (i) => 103 - i));
      expect((await history(999)).page, 2);
      await expectLater(history(-1), throwsArgumentError);
      await expectLater(
        () => db.financialRecordsDao.getInstrumentRecords(
          instrument.id,
          period,
          limit: 51,
          offset: 0,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'archived instrument history survives metadata edits and archive/restore',
    () async {
      final id = await save(source: instrument.id);
      await instruments.setArchived(instrument.uuid, true);
      expect((await history()).entries.single.record.id, id);
      await instruments.update(
        uuid: instrument.uuid,
        name: 'Renamed',
        type: InstrumentType.other,
      );
      expect((await history()).count, 1);
      await instruments.setArchived(instrument.uuid, false);
      expect((await history()).count, 1);
    },
  );
  test(
    'missing, deleted and unconfirmed history targets are rejected',
    () async {
      final legacy = await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'legacy',
          name: 'Legacy',
          type: 'wallet',
        ),
      );
      await save(source: legacy, destination: instrument.id);
      for (final id in [-1, legacy]) {
        await expectLater(
          instruments.history(accountId: id, period: period),
          throwsArgumentError,
        );
        await expectLater(instruments.historyMonths(id), throwsArgumentError);
      }
      await (db.delete(
        db.accounts,
      )..where((a) => a.id.equals(instrument.id))).go();
      await expectLater(history(), throwsArgumentError);
    },
  );
  test(
    'replacement/removal corrects vanished last page without inferring other links',
    () async {
      await records.saveAll(
        List.generate(51, (_) => record(RecordSubtype.sendMoney, 10)),
      );
      await db
          .update(db.financialRecords)
          .write(
            FinancialRecordsCompanion(sourceAccountId: Value(instrument.id)),
          );
      final last = (await history(1)).entries.single.record.id!;
      await InstrumentLinksRepository(db).setLink(
        recordId: last,
        endpoint: InstrumentEndpoint.source,
        instrumentId: other.id,
        expectedCurrentId: instrument.id,
      );
      final corrected = await history(1);
      expect(corrected.page, 0);
      expect(corrected.count, 50);
      expect(corrected.entries.length, 50);
      expect(
        (await instruments.history(accountId: other.id, period: period)).count,
        1,
      );
      await InstrumentLinksRepository(db).setLink(
        recordId: last,
        endpoint: InstrumentEndpoint.source,
        instrumentId: null,
        expectedCurrentId: other.id,
      );
      expect(
        (await instruments.history(accountId: other.id, period: period)).count,
        0,
      );
    },
  );
  test(
    'read-side history leaves financial rows and semantic totals unchanged',
    () async {
      for (final subtype in RecordSubtype.values.where(
        (s) => s != RecordSubtype.payBillReversal,
      )) {
        await save(
          source: instrument.id,
          destination: subtype == RecordSubtype.mshwariDeposit
              ? instrument.id
              : null,
          subtype: subtype,
        );
      }
      final before = (await db.financialRecordsDao.getAllRecords())
          .map((r) => r.toJson())
          .toList();
      final totals = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      await history();
      await instruments.historyMonths(instrument.id);
      expect(
        (await db.financialRecordsDao.getAllRecords())
            .map((r) => r.toJson())
            .toList(),
        before,
      );
      final after = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      expect(
        [
          after.income,
          after.expenses,
          after.fees,
          after.borrowed,
          after.repaid,
          after.internalTransfers,
        ],
        [
          totals.income,
          totals.expenses,
          totals.fees,
          totals.borrowed,
          totals.repaid,
          totals.internalTransfers,
        ],
      );
    },
  );
}
