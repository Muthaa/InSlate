import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/repositories/your_data_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late YourDataRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = YourDataRepository(db);
  });
  tearDown(() => db.close());
  test(
    'empty storage counts seeded categories rather than hardcoded defaults',
    () async {
      final s = await repo.watchSummary().first;
      expect(s.records, 0);
      expect(s.messages, 0);
      expect(s.rules, 0);
      expect(
        s.categories,
        (await db.select(db.transactionCategories).get()).length,
      );
      expect(s.activeInstruments, 0);
      expect(s.balances, 0);
    },
  );
  test(
    'counts registered archives, hidden categories, rules, records and independent SMS evidence',
    () async {
      final instruments = FinancialInstrumentsRepository(db);
      final active = await instruments.create(
        name: 'Private',
        type: InstrumentType.mobileWallet,
      );
      final archived = await instruments.create(
        name: 'Private',
        type: InstrumentType.mobileWallet,
      );
      await instruments.setArchived(archived.uuid, true);
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: 'legacy',
              name: 'Legacy',
              type: 'bank',
            ),
          );
      final category = (await db.select(db.transactionCategories).get()).first;
      await (db.update(db.transactionCategories)
            ..where((t) => t.id.equals(category.id)))
          .write(const TransactionCategoriesCompanion(isHidden: Value(true)));
      await db
          .into(db.categoryRules)
          .insert(
            CategoryRulesCompanion.insert(
              identityKey: 'test',
              kind: category.kind,
              categoryId: category.id,
            ),
          );
      await FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.sendMoney, 10));
      await RawMessagesRepository(db).saveAll([
        domain.RawMessage(
          id: 'balance',
          sender: 'MPESA',
          body: 'New M-PESA balance is Ksh0.00.',
          receivedAt: DateTime.utc(2026),
        ),
        domain.RawMessage(
          id: 'failed',
          sender: 'MPESA',
          body: 'Failed financial attempt.',
          receivedAt: DateTime.utc(2026),
        ),
      ]);
      final balances = BalanceEvidenceRepository(db);
      await balances.extractNewMpesaMessages(['balance', 'failed']);
      await balances.createManual(
        accountId: active.id,
        amount: '0',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: DateTime.utc(2026),
      );
      final s = await repo.watchSummary().first;
      expect(s.records, 1);
      expect(s.successfulRecords, 1);
      expect(s.messages, 2);
      expect(s.activeInstruments, 1);
      expect(s.archivedInstruments, 1);
      expect(s.hiddenCategories, 1);
      expect(s.rules, 1);
      expect(s.balances, 2);
      expect(s.manualBalances, 1);
      expect(s.smsBalances, 1);
      expect(s.unattributedSmsBalances, 1);
    },
  );
  test(
    'live summaries update after writes without reading complete history',
    () async {
      final updates = <YourDataSummary>[];
      final ready = Completer<void>();
      final changed = Completer<void>();
      final subscription = repo.watchSummary().listen((s) {
        updates.add(s);
        if (!ready.isCompleted) ready.complete();
        if (s.messages == 1 && !changed.isCompleted) changed.complete();
      });
      try {
        await ready.future;
        await RawMessagesRepository(db).save(
          domain.RawMessage(
            id: 'one',
            sender: 'MPESA',
            body: 'Sensitive body',
            receivedAt: DateTime.utc(2026),
          ),
        );
        await changed.future;
        expect(updates.last.messages, 1);
        expect(updates.last.records, 0);
      } finally {
        await subscription.cancel();
      }
    },
  );
  test(
    'stored failed records are never counted as successful imports',
    () async {
      await FinancialRecordsRepository(
        db,
      ).save(record(RecordSubtype.sendMoney, 10));
      await db
          .update(db.financialRecords)
          .write(const FinancialRecordsCompanion(status: Value('failed')));
      final s = await repo.watchSummary().first;
      expect(s.records, 1);
      expect(s.successfulRecords, 0);
    },
  );
  test(
    'SMS receipt metadata uses bounded pages and deterministic newest-first order',
    () async {
      await RawMessagesRepository(db).saveAll(
        List.generate(
          51,
          (i) => domain.RawMessage(
            id: 'sms-$i',
            sender: 'Private sender',
            body: 'Private body',
            receivedAt: DateTime.utc(2026).add(Duration(minutes: i)),
          ),
        ),
      );
      final first = await repo.watchSmsReceiptDates(0).first;
      final second = await repo.watchSmsReceiptDates(1).first;
      expect(first, hasLength(50));
      expect(second.map((date) => date.toUtc()).toList(), [DateTime.utc(2026)]);
      expect(
        first.first.toUtc(),
        DateTime.utc(2026).add(const Duration(minutes: 50)),
      );
      expect(await repo.watchSmsReceiptDates(2).first, isEmpty);
      expect(() => repo.watchSmsReceiptDates(-1), throwsArgumentError);
    },
  );
}
