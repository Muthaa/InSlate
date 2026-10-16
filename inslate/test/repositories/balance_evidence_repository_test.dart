import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late BalanceEvidenceRepository repo;
  late FinancialInstrumentsRepository instruments;
  late FinancialInstrument instrument;
  final date = DateTime.utc(2025, 1, 2, 3, 4, 5, 678);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceEvidenceRepository(db);
    instruments = FinancialInstrumentsRepository(db);
    instrument = await instruments.create(
      name: 'Wallet',
      type: InstrumentType.mobileWallet,
    );
  });
  tearDown(() => db.close());
  Future<BalanceObservation> create(
    String amount, {
    String currency = 'KES',
    BalanceKind kind = BalanceKind.reported,
    DateTime? asOf,
    int? accountId,
  }) => repo.createManual(
    accountId: accountId ?? instrument.id,
    amount: amount,
    currency: currency,
    kind: kind,
    asOf: asOf ?? date,
  );
  test(
    'unknown is null; known zero is an explicit observation with provenance',
    () async {
      expect(await repo.latest(instrument.id), isNull);
      final zero = await create('0');
      expect((await repo.latest(instrument.id))!.amountMinor, 0);
      expect(zero.asOf, date);
      final row = (await db.select(db.balanceEvidence).get()).single;
      expect(row.origin, 'manual');
      expect(row.timeBasis, 'user_supplied');
      expect(row.associationOrigin, 'explicit_user');
      expect(row.financialRecordId, isNull);
      expect(row.rawMessageId, isNull);
      expect(row.matchedClause, isNull);
      expect(row.extractionVersion, isNull);
    },
  );
  test(
    'latest by as-of not insertion; pagination is exact and deterministic',
    () async {
      for (var i = 21; i >= 0; i--) {
        await create('$i', asOf: date.add(Duration(minutes: i)));
      }
      expect((await repo.latest(instrument.id))!.amountMinor, 2100);
      final page = await repo.history(instrument.id);
      expect(page.count, 22);
      expect(page.entries.length, 20);
      expect(page.entries.first.amountMinor, 2100);
      expect(
        (await repo.history(
          instrument.id,
          page: 1,
        )).entries.map((e) => e.amountMinor),
        [100, 0],
      );
      expect((await repo.history(instrument.id, page: 99)).page, 1);
      await expectLater(
        repo.history(instrument.id, page: -1),
        throwsArgumentError,
      );
    },
  );
  for (final entry in {
    'KES': '0.29',
    'USD': '123.45',
    'EUR': '0.01',
    'GBP': '-1.23',
    'JPY': '123',
    'KWD': '1.234',
  }.entries) {
    test('exact ${entry.key} minor units round-trip', () async {
      final e = await create(entry.value, currency: entry.key);
      expect(SnapshotMoney.decimal(e.amountMinor, e.currency), entry.value);
      expect((await repo.latest(instrument.id))!.amountMinor, e.amountMinor);
    });
  }
  test(
    'large amounts never pass through double and invalid scales/currencies fail',
    () async {
      final e = await create('90071992547409.93');
      expect(e.amountMinor, 9007199254740993);
      for (final amount in [
        '',
        '1,000.00',
        '1e3',
        'NaN',
        '1.234',
        '92233720368547758.08',
      ]) {
        await expectLater(create(amount), throwsArgumentError);
      }
      await expectLater(create('1.1', currency: 'JPY'), throwsArgumentError);
      await expectLater(create('1', currency: 'ZZZ'), throwsArgumentError);
      await expectLater(
        create('-1', kind: BalanceKind.outstandingDebt),
        throwsArgumentError,
      );
      expect(
        (await create('0', kind: BalanceKind.outstandingDebt)).amountMinor,
        0,
      );
      await expectLater(
        create('1', asOf: DateTime.now().add(const Duration(days: 1))),
        throwsArgumentError,
      );
      expect((await create('1', currency: ' usd ')).currency, 'USD');
    },
  );
  test(
    'UTC instant and millisecond precision survive local conversion and correction',
    () async {
      final e = await create('1', asOf: date.toLocal());
      expect(e.asOf.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
      await repo.correctManual(
        id: e.id,
        accountId: instrument.id,
        expectedRevision: e.revision,
        amount: '2',
        currency: 'KES',
        kind: e.kind,
        asOf: e.asOf,
      );
      expect((await repo.latest(instrument.id))!.asOf, date);
    },
  );
  test(
    'archive preserves history and permits explicit historical manual observations',
    () async {
      await create('1');
      await instruments.setArchived(instrument.uuid, true);
      await create('2');
      expect((await repo.history(instrument.id)).count, 2);
      expect(
        (await instruments.getByUuid(instrument.uuid))!.isArchived,
        isTrue,
      );
    },
  );
  test(
    'missing and legacy instruments are rejected for all operations',
    () async {
      final legacy = await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'legacy',
          name: 'Legacy',
          type: 'wallet',
        ),
      );
      for (final id in [-1, legacy]) {
        await expectLater(create('1', accountId: id), throwsArgumentError);
        await expectLater(repo.latest(id), throwsArgumentError);
        await expectLater(repo.history(id), throwsArgumentError);
      }
    },
  );
  test(
    'corrections preserve identity creation provenance and require latest revision',
    () async {
      final e = await create('1');
      await repo.correctManual(
        id: e.id,
        accountId: instrument.id,
        expectedRevision: 0,
        amount: '3.25',
        currency: 'USD',
        kind: BalanceKind.available,
        asOf: date.subtract(const Duration(days: 1)),
      );
      final updated = (await repo.latest(instrument.id))!;
      expect(updated.id, e.id);
      expect(updated.createdAt, e.createdAt);
      expect(updated.revision, 1);
      expect(updated.amountMinor, 325);
      expect(updated.currency, 'USD');
      await expectLater(
        repo.correctManual(
          id: e.id,
          accountId: instrument.id,
          expectedRevision: 0,
          amount: '9',
          currency: 'KES',
          kind: e.kind,
          asOf: date,
        ),
        throwsStateError,
      );
      await expectLater(
        repo.deleteManual(
          id: e.id,
          accountId: instrument.id,
          expectedRevision: 0,
        ),
        throwsStateError,
      );
      await repo.deleteManual(
        id: e.id,
        accountId: instrument.id,
        expectedRevision: 1,
      );
      expect(await repo.latest(instrument.id), isNull);
      await expectLater(
        repo.deleteManual(
          id: e.id,
          accountId: instrument.id,
          expectedRevision: 1,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'other instrument and SMS evidence cannot be edited through manual API',
    () async {
      final e = await create('1');
      final other = await instruments.create(
        name: 'Other',
        type: InstrumentType.other,
      );
      await expectLater(
        repo.deleteManual(id: e.id, accountId: other.id, expectedRevision: 0),
        throwsArgumentError,
      );
      await (db.update(
        db.balanceEvidence,
      )).write(const BalanceEvidenceCompanion(origin: Value('sms_reported')));
      expect((await repo.latest(instrument.id))!.origin, 'sms_reported');
      await expectLater(
        repo.deleteManual(
          id: e.id,
          accountId: instrument.id,
          expectedRevision: 0,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.correctManual(
          id: e.id,
          accountId: instrument.id,
          expectedRevision: 0,
          amount: '2',
          currency: 'KES',
          kind: e.kind,
          asOf: date,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'deleting last page clamps and known zero remains latest after deleting newer snapshot',
    () async {
      await create('0');
      final newer = await create('2', asOf: date.add(const Duration(days: 1)));
      await repo.deleteManual(
        id: newer.id,
        accountId: instrument.id,
        expectedRevision: 0,
      );
      expect((await repo.latest(instrument.id))!.amountMinor, 0);
      expect((await repo.history(instrument.id, page: 4)).page, 0);
    },
  );
  test(
    'snapshots do not touch financial records links or semantic totals',
    () async {
      final records = FinancialRecordsRepository(db);
      await records.save(record(RecordSubtype.sendMoney, 50, fee: 3));
      final before = (await db.financialRecordsDao.getAllRecords()).single
          .toJson();
      final totals = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      final e = await create('999999');
      await repo.deleteManual(
        id: e.id,
        accountId: instrument.id,
        expectedRevision: 0,
      );
      expect(
        (await db.financialRecordsDao.getAllRecords()).single.toJson(),
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
          after.internalTransfers,
          after.borrowed,
          after.repaid,
        ],
        [
          totals.income,
          totals.expenses,
          totals.fees,
          totals.internalTransfers,
          totals.borrowed,
          totals.repaid,
        ],
      );
    },
  );
}
