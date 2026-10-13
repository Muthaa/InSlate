import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late InstrumentLinksRepository links;
  late FinancialRecordsRepository records;
  late FinancialInstrumentsRepository instruments;
  late FinancialInstrument first, second;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    links = InstrumentLinksRepository(db);
    records = FinancialRecordsRepository(db);
    instruments = FinancialInstrumentsRepository(db);
    first = await instruments.create(
      name: 'Same',
      type: InstrumentType.mobileWallet,
    );
    second = await instruments.create(name: 'Same', type: InstrumentType.other);
  });
  tearDown(() => db.close());
  Future<int> save(RecordSubtype subtype, {FinancialRecordType? type}) async {
    await records.save(record(subtype, 50, type: type));
    return (await records.getAll()).last.id!;
  }

  Future<void> set(
    int id,
    InstrumentEndpoint endpoint,
    int? target, [
    int? expected,
  ]) => links.setLink(
    recordId: id,
    endpoint: endpoint,
    instrumentId: target,
    expectedCurrentId: expected,
  );

  for (final subtype in RecordSubtype.values.where(
    (s) => s != RecordSubtype.payBillReversal,
  )) {
    test('endpoint policy for ${subtype.name}', () async {
      final id = await save(subtype);
      final normalized = (await records.getById(id))!;
      final movement = const FinancialSemantics().classify(normalized);
      for (final endpoint in InstrumentEndpoint.values) {
        final supported =
            movement != MovementClass.unresolved ||
            subtype == RecordSubtype.instrumentPayment ||
            subtype == RecordSubtype.instrumentReceipt;
        expect(
          InstrumentLinksRepository.supports(normalized, endpoint),
          supported,
        );
        if (supported) {
          await set(id, endpoint, first.id);
          expect((await links.watch(id).first)!.at(endpoint), first.id);
        } else {
          await expectLater(set(id, endpoint, first.id), throwsArgumentError);
        }
      }
    });
  }
  test(
    'missing transactions, missing instruments and unconfirmed rows fail without writes',
    () async {
      final id = await save(RecordSubtype.sendMoney);
      final legacy = await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'legacy',
          name: 'Legacy',
          type: 'wallet',
        ),
      );
      await expectLater(
        set(-1, InstrumentEndpoint.source, first.id),
        throwsArgumentError,
      );
      await expectLater(
        set(id, InstrumentEndpoint.source, -1),
        throwsArgumentError,
      );
      await expectLater(
        set(id, InstrumentEndpoint.source, legacy),
        throwsArgumentError,
      );
      expect((await links.watch(id).first)!.sourceId, isNull);
    },
  );
  test(
    'replacement and unlinking require current numeric ID; endpoints stay independent',
    () async {
      final id = await save(RecordSubtype.mshwariDeposit);
      await set(id, InstrumentEndpoint.source, first.id);
      await set(id, InstrumentEndpoint.destination, second.id);
      await expectLater(
        set(id, InstrumentEndpoint.source, second.id),
        throwsStateError,
      );
      await expectLater(
        set(id, InstrumentEndpoint.source, null, second.id),
        throwsStateError,
      );
      await set(id, InstrumentEndpoint.source, second.id, first.id);
      await set(id, InstrumentEndpoint.source, second.id, second.id);
      await set(id, InstrumentEndpoint.source, null, second.id);
      final result = (await links.watch(id).first)!;
      expect(result.sourceId, isNull);
      expect(result.destinationId, second.id);
    },
  );
  test(
    'archiving retains historical links; rejects new links; permits unlinking',
    () async {
      final id = await save(RecordSubtype.mshwariDeposit);
      await set(id, InstrumentEndpoint.source, first.id);
      await instruments.setArchived(first.uuid, true);
      expect((await links.watch(id).first)!.sourceId, first.id);
      await expectLater(
        set(id, InstrumentEndpoint.destination, first.id),
        throwsArgumentError,
      );
      await expectLater(
        set(id, InstrumentEndpoint.source, first.id, first.id),
        throwsArgumentError,
      );
      await set(id, InstrumentEndpoint.source, null, first.id);
      await instruments.setArchived(first.uuid, false);
      await set(id, InstrumentEndpoint.destination, first.id);
    },
  );
  test(
    'unsupported and legacy historical endpoints are retained and can be removed',
    () async {
      final id = await save(RecordSubtype.unknown);
      await (db.update(
        db.financialRecords,
      )..where((r) => r.id.equals(id))).write(
        const FinancialRecordsCompanion(
          sourceAccountId: Value(987),
          destinationAccountId: Value(988),
        ),
      );
      expect((await links.watch(id).first)!.sourceId, 987);
      await expectLater(
        set(id, InstrumentEndpoint.source, first.id, 987),
        throwsArgumentError,
      );
      await set(id, InstrumentEndpoint.source, null, 987);
      expect((await links.watch(id).first)!.destinationId, 988);
    },
  );
  test('type-subtype mismatch rejects new associations', () async {
    final id = await save(
      RecordSubtype.receiveMoney,
      type: FinancialRecordType.expense,
    );
    for (final endpoint in InstrumentEndpoint.values) {
      await expectLater(set(id, endpoint, first.id), throwsArgumentError);
    }
  });
  test(
    'only link columns change; categories, semantics, Activity count and order stay identical',
    () async {
      final id = await save(RecordSubtype.sendMoney);
      final categories = CategoriesRepository(db);
      await categories.assign(recordId: id, categoryId: 'builtin.expense.food');
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        search: 'send',
      );
      final count = await records.countActivity(filter);
      final before = (await db.financialRecordsDao.getAllRecords()).single
          .toJson();
      final totals = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      final assignment = await categories.watchAssignment(id).first;
      await set(id, InstrumentEndpoint.source, first.id);
      await set(id, InstrumentEndpoint.source, second.id, first.id);
      final after = (await db.financialRecordsDao.getAllRecords()).single
          .toJson();
      after['sourceAccountId'] = before['sourceAccountId'];
      expect(after, before);
      final afterAssignment = await categories.watchAssignment(id).first;
      expect(afterAssignment!.categoryId, assignment!.categoryId);
      expect(afterAssignment.origin, assignment.origin);
      expect(await records.countActivity(filter), count);
      expect((await records.getActivity(filter, limit: 50)).map((r) => r.id), [
        id,
      ]);
      final updated = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      expect(
        [
          updated.income,
          updated.expenses,
          updated.fees,
          updated.borrowed,
          updated.repaid,
          updated.internalTransfers,
          updated.netCashFlow,
        ],
        [
          totals.income,
          totals.expenses,
          totals.fees,
          totals.borrowed,
          totals.repaid,
          totals.internalTransfers,
          totals.netCashFlow,
        ],
      );
    },
  );
}
