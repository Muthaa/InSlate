import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/historical_balance_extraction.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/providers/balance_evidence_provider.dart';
import 'package:inslate/providers/historical_balance_provider.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

class _GatedRepository extends BalanceEvidenceRepository {
  Completer<void>? gate;
  bool fail = false;
  _GatedRepository(super.database);
  @override
  Future<HistoricalBalanceCheckpoint> historicalExtractionBatch(
    HistoricalBalanceCheckpoint c,
  ) async {
    await gate?.future;
    if (fail) throw StateError('test failure');
    return super.historicalExtractionBatch(c);
  }
}

void main() {
  late AppDatabase db;
  late BalanceEvidenceRepository repo;
  final date = DateTime.utc(2026, 6, 1, 2, 3, 4);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceEvidenceRepository(db);
  });
  tearDown(() => db.close());
  domain.RawMessage message(
    String id, {
    String? body,
    String sender = 'MPESA',
  }) => domain.RawMessage(
    id: id,
    sender: sender,
    body: body ?? 'New M-PESA balance is Ksh1.25.',
    receivedAt: date,
  );
  Future<void> save(List<domain.RawMessage> messages) =>
      RawMessagesRepository(db).saveAll(messages);
  Future<HistoricalBalanceCheckpoint> run([
    HistoricalBalanceCheckpoint? checkpoint,
  ]) async {
    var c = checkpoint ?? await repo.beginHistoricalExtraction();
    while (!c.complete) {
      c = await repo.historicalExtractionBatch(c);
    }
    return c;
  }

  test('empty history reports actual zeros', () async {
    final c = await run();
    expect(c.complete, isTrue);
    expect([c.scanned, c.created, c.existing, c.unsupported], [0, 0, 0, 0]);
  });
  test(
    'mixed supported dual failed ambiguous and other sender messages reconcile actual counts',
    () async {
      await save([
        message('wallet'),
        message(
          'dual',
          body:
              'New M-PESA balance is Ksh0.00. KCB M-PESA Account balance is Ksh2.53.',
        ),
        message(
          'failed',
          body: 'Failed. Your M-Shwari account available balance is Ksh0.00.',
        ),
        message('unsupported', body: 'No supported balances.'),
        message(
          'ambiguous',
          body:
              'New M-PESA balance is Ksh1.00. Your M-PESA balance is Ksh2.00.',
        ),
        message('other', sender: 'BANK'),
      ]);
      final c = await run();
      expect([c.scanned, c.created, c.existing, c.unsupported], [6, 4, 0, 3]);
      final rows = await db.select(db.balanceEvidence).get();
      expect(rows, hasLength(4));
      for (final row in rows) {
        expect(row.accountId, isNull);
        expect(row.associationOrigin, isNull);
        expect(row.timeBasis, 'raw_message_received_at_proxy');
        expect(row.asOfMillis, date.millisecondsSinceEpoch);
        expect(row.currency, 'KES');
        expect(row.matchedClause, isNotNull);
      }
      final repeated = await run();
      expect(
        [
          repeated.scanned,
          repeated.created,
          repeated.existing,
          repeated.unsupported,
        ],
        [6, 0, 4, 3],
      );
      expect(await db.financialRecordsDao.getAllRecords(), isEmpty);
    },
  );
  test(
    'replay preserves associated evidence content provenance revision and manual observations',
    () async {
      await save([message('existing')]);
      await run();
      final instrument = await FinancialInstrumentsRepository(db).create(
        name: 'Wallet',
        type: InstrumentType.mobileWallet,
        provider: 'M-PESA',
      );
      await repo.associateSms(
        id: 'sms:mpesa-wallet:existing',
        expectedAccountId: null,
        expectedRevision: 0,
        accountId: instrument.id,
      );
      await repo.createManual(
        accountId: instrument.id,
        amount: '0',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: date,
      );
      await (db.update(
        db.balanceEvidence,
      )..where((e) => e.id.equals('sms:mpesa-wallet:existing'))).write(
        const BalanceEvidenceCompanion(
          amountMinor: Value(17),
          extractionVersion: Value('older_version'),
        ),
      );
      final before = (await db.select(db.balanceEvidence).get())
          .map((e) => e.toJson())
          .toList();
      final c = await run();
      expect(c.created, 0);
      expect(c.existing, 1);
      expect(
        (await db.select(db.balanceEvidence).get())
            .map((e) => e.toJson())
            .toList(),
        before,
      );
    },
  );
  test(
    '200-message keyset checkpoint resumes and excludes later inserts',
    () async {
      await save(List.generate(205, (i) => message('message-$i')));
      final start = await repo.beginHistoricalExtraction();
      final first = await repo.historicalExtractionBatch(start);
      expect(first.scanned, 200);
      expect(first.created, 200);
      expect(first.afterId, 200);
      expect(first.complete, isFalse);
      await save([message('later')]);
      final resumed = await run(first);
      expect(resumed.scanned, 205);
      expect(resumed.created, 205);
      expect(resumed.throughId, 205);
      final fresh = await run();
      expect([fresh.scanned, fresh.created, fresh.existing], [206, 1, 205]);
    },
  );
  test(
    'multiple observations exceeding 400 candidate IDs counted without N+1 lookups',
    () async {
      await save(
        List.generate(
          200,
          (i) => message(
            'multi-$i',
            body:
                'New M-PESA balance is Ksh1.00. New M-Shwari balance is Ksh2.00. '
                'KCB M-PESA Account balance is Ksh3.00. Total Fuliza M-PESA outstanding amount is Ksh4.00.',
          ),
        ),
      );
      final c = await run();
      expect([c.scanned, c.created, c.existing], [200, 800, 0]);
      final again = await run();
      expect(again.existing, 800);
      expect(again.created, 0);
    },
  );
  test(
    'sparse numeric IDs and missing tail do not skip messages or invent scanned totals',
    () async {
      for (final id in [10, 500]) {
        await db
            .into(db.rawMessages)
            .insert(
              RawMessagesCompanion.insert(
                id: Value(id),
                sourceId: 'sparse-$id',
                sender: 'MPESA',
                body: 'New M-PESA balance is Ksh1.00.',
                receivedAt: date,
              ),
            );
      }
      final c = await run();
      expect(c.scanned, 2);
      expect(c.afterId, 500);
      final emptyTail = await repo.historicalExtractionBatch(
        const HistoricalBalanceCheckpoint(
          throughId: 999,
          afterId: 500,
          scanned: 2,
        ),
      );
      expect(emptyTail.scanned, 2);
      expect(emptyTail.afterId, 999);
      expect(emptyTail.complete, isTrue);
    },
  );
  test('failed batch rolls back and checkpoint can safely retry', () async {
    await save([message('rollback')]);
    final checkpoint = await repo.beginHistoricalExtraction();
    await db.customStatement(
      "CREATE TRIGGER reject_history BEFORE INSERT ON balance_evidence BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      repo.historicalExtractionBatch(checkpoint),
      throwsA(anything),
    );
    expect(await db.select(db.balanceEvidence).get(), isEmpty);
    expect(checkpoint.afterId, 0);
    expect(checkpoint.scanned, 0);
    await db.customStatement('DROP TRIGGER reject_history');
    expect((await run(checkpoint)).created, 1);
  });
  test(
    'RawMessages and FinancialRecords remain byte-for-field identical',
    () async {
      await save([message('raw')]);
      await FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.sendMoney, 50, fee: 3));
      final rawBefore = (await db.rawMessagesDao.getAllMessages())
          .map((m) => m.toJson())
          .toList();
      final financialBefore = (await db.financialRecordsDao.getAllRecords())
          .map((r) => r.toJson())
          .toList();
      await run();
      await run();
      expect(
        (await db.rawMessagesDao.getAllMessages())
            .map((m) => m.toJson())
            .toList(),
        rawBefore,
      );
      expect(
        (await db.financialRecordsDao.getAllRecords())
            .map((r) => r.toJson())
            .toList(),
        financialBefore,
      );
    },
  );
  test(
    'fresh repository after interrupted run safely replays committed observations',
    () async {
      await save(List.generate(201, (i) => message('restart-$i')));
      await repo.historicalExtractionBatch(
        await repo.beginHistoricalExtraction(),
      );
      repo = BalanceEvidenceRepository(db);
      final c = await run();
      expect([c.scanned, c.created, c.existing], [201, 1, 200]);
    },
  );
  test(
    'controller cancels at committed batch and resumes within session',
    () async {
      await save(List.generate(201, (i) => message('cancel-$i')));
      final container = ProviderContainer(
        overrides: [balanceEvidenceRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(historicalBalanceProvider, (
        _,
        next,
      ) {
        if (next.running &&
            next.checkpoint?.scanned == 200 &&
            !next.cancelling) {
          container.read(historicalBalanceProvider.notifier).cancel();
        }
      });
      await container.read(historicalBalanceProvider.notifier).run();
      subscription.close();
      final paused = container.read(historicalBalanceProvider);
      expect(paused.running, isFalse);
      expect(paused.checkpoint!.scanned, 200);
      expect(paused.checkpoint!.complete, isFalse);
      await container.read(historicalBalanceProvider.notifier).run();
      expect(
        container.read(historicalBalanceProvider).checkpoint!.scanned,
        201,
      );
      expect(
        container.read(historicalBalanceProvider).checkpoint!.created,
        201,
      );
    },
  );
  test(
    'controller refuses overlapping runs and retains checkpoint on failure',
    () async {
      await save([message('controller')]);
      final gated = _GatedRepository(db)..gate = Completer<void>();
      final container = ProviderContainer(
        overrides: [balanceEvidenceRepositoryProvider.overrideWithValue(gated)],
      );
      addTearDown(container.dispose);
      final initialized = Completer<void>();
      container.listen(historicalBalanceProvider, (_, next) {
        if (next.checkpoint != null && !initialized.isCompleted) {
          initialized.complete();
        }
      });
      final pending = container.read(historicalBalanceProvider.notifier).run();
      await initialized.future;
      await container.read(historicalBalanceProvider.notifier).run();
      gated.fail = true;
      gated.gate!.complete();
      await pending;
      expect(container.read(historicalBalanceProvider).error, isNotNull);
      expect(container.read(historicalBalanceProvider).checkpoint!.afterId, 0);
      gated.fail = false;
      gated.gate = null;
      await container.read(historicalBalanceProvider.notifier).run();
      expect(container.read(historicalBalanceProvider).checkpoint!.created, 1);
    },
  );
}
