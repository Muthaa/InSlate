import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/raw_messages_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late BalanceEvidenceRepository repo;
  late FinancialInstrumentsRepository instruments;
  late FinancialInstrument wallet;
  final date = DateTime.utc(2026, 6, 1);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceEvidenceRepository(db);
    instruments = FinancialInstrumentsRepository(db);
    wallet = await instruments.create(
      name: 'My wallet',
      type: InstrumentType.savingsProduct,
      provider: 'M-Shwari',
    );
  });
  tearDown(() => db.close());
  Future<StoredBalanceEvidence> sms(
    String id, {
    String body = 'New M-Shwari balance is Ksh0.00.',
    DateTime? asOf,
  }) async {
    await RawMessagesRepository(db).save(
      domain.RawMessage(
        id: id,
        sender: 'MPESA',
        body: body,
        receivedAt: asOf ?? date,
      ),
    );
    await repo.extractNewMpesaMessages([id]);
    return (await db.select(db.balanceEvidence).get()).singleWhere(
      (e) => e.id.endsWith(':$id'),
    );
  }

  Future<StoredBalanceEvidence> row(String id) => (db.select(
    db.balanceEvidence,
  )..where((e) => e.id.equals(id))).getSingle();
  Future<void> link(
    StoredBalanceEvidence e,
    int? target, {
    bool replace = false,
    bool uncertain = false,
  }) => repo.associateSms(
    id: e.id,
    expectedAccountId: e.accountId,
    expectedRevision: e.revision,
    accountId: target,
    confirmReplacement: replace,
    confirmUncertainCompatibility: uncertain,
  );
  test('M-PESA measured wallet cannot be attributed', () async {
    final e = await sms('measured', body: 'New M-PESA balance is Ksh5.00.');
    final target = await instruments.create(
      name: 'M-PESA',
      type: InstrumentType.mobileWallet,
      provider: 'MPESA',
    );
    await expectLater(link(e, target.id), throwsArgumentError);
    expect((await row(e.id)).accountId, isNull);
    expect((await row(e.id)).amountMinor, 500);
  });
  test(
    'explicit link stores numeric ID and provenance and preserves source content',
    () async {
      final e = await sms('one');
      final before = e.toJson()
        ..remove('accountId')
        ..remove('associationOrigin')
        ..remove('associatedMillis')
        ..remove('revision');
      await link(e, wallet.id);
      final linked = await row(e.id);
      expect(linked.accountId, wallet.id);
      expect(linked.associationOrigin, 'explicit_user');
      expect(linked.associatedMillis, isNotNull);
      expect(linked.revision, 1);
      final after = linked.toJson()
        ..remove('accountId')
        ..remove('associationOrigin')
        ..remove('associatedMillis')
        ..remove('revision');
      expect(after, before);
      expect((await repo.latest(wallet.id))!.amountMinor, 0);
      expect((await repo.latest(wallet.id))!.sourceLabel, 'SMS-reported');
    },
  );
  test(
    'missing evidence and manual observations cannot use SMS association API',
    () async {
      await expectLater(
        repo.associateSms(
          id: 'missing',
          expectedAccountId: null,
          expectedRevision: 0,
          accountId: wallet.id,
        ),
        throwsArgumentError,
      );
      final manual = await repo.createManual(
        accountId: wallet.id,
        amount: '1',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: date,
      );
      await expectLater(
        repo.associateSms(
          id: manual.id,
          expectedAccountId: wallet.id,
          expectedRevision: 0,
          accountId: null,
        ),
        throwsArgumentError,
      );
      expect((await row(manual.id)).accountId, wallet.id);
    },
  );
  test('missing archived and legacy targets rejected', () async {
    final e = await sms('targets');
    final legacy = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: 'legacy',
            name: 'Legacy',
            type: 'mobile_wallet',
          ),
        );
    await instruments.setArchived(wallet.uuid, true);
    for (final id in [99999, legacy, wallet.id]) {
      await expectLater(link(e, id), throwsArgumentError);
    }
    expect((await row(e.id)).accountId, isNull);
  });
  test('archiving preserves association and SMS history', () async {
    final e = await sms('archive');
    await link(e, wallet.id);
    await instruments.setArchived(wallet.uuid, true);
    expect((await repo.latest(wallet.id))!.id, e.id);
    final review = await repo.smsHistory(unattributedOnly: false);
    expect(review.entries.single.associationLabel, 'My wallet (Archived)');
    await link(await row(e.id), null);
    expect(await repo.latest(wallet.id), isNull);
    expect((await repo.smsHistory()).count, 1);
  });
  test(
    'replacement requires confirmation and creates exactly one association',
    () async {
      final e = await sms('replace');
      final other = await instruments.create(
        name: 'Second',
        type: InstrumentType.savingsProduct,
        provider: 'M-Shwari',
      );
      await link(e, wallet.id);
      final linked = await row(e.id);
      await expectLater(link(linked, other.id), throwsArgumentError);
      await link(linked, other.id, replace: true);
      expect(await repo.latest(wallet.id), isNull);
      expect((await repo.history(other.id)).count, 1);
      expect(await db.select(db.balanceEvidence).get(), hasLength(1));
    },
  );
  test(
    'unlink keeps evidence and permits later explicit reassociation',
    () async {
      final e = await sms('unlink');
      await link(e, wallet.id);
      await link(await row(e.id), null);
      final unlinked = await row(e.id);
      expect(unlinked.accountId, isNull);
      expect(unlinked.associationOrigin, isNull);
      expect(unlinked.associatedMillis, isNull);
      expect(unlinked.amountMinor, 0);
      await link(unlinked, wallet.id);
      expect((await repo.smsHistory()).count, 0);
    },
  );
  test(
    'expected current account and revision both required; ABA revisions guarded',
    () async {
      final e = await sms('stale');
      await link(e, wallet.id);
      await expectLater(link(e, wallet.id), throwsStateError);
      await expectLater(
        repo.associateSms(
          id: e.id,
          expectedAccountId: null,
          expectedRevision: 1,
          accountId: null,
        ),
        throwsStateError,
      );
      await link(await row(e.id), null);
      await expectLater(link(e, wallet.id), throwsStateError);
    },
  );
  test('concurrent choices cannot silently overwrite association', () async {
    final e = await sms('race');
    final other = await instruments.create(
      name: 'Other',
      type: InstrumentType.savingsProduct,
      provider: 'M-Shwari',
    );
    Future<bool> attempt(int target) async {
      try {
        await link(e, target);
        return true;
      } on StateError {
        return false;
      }
    }

    final results = await Future.wait([attempt(wallet.id), attempt(other.id)]);
    expect(results.where((v) => v), hasLength(1));
    expect((await row(e.id)).revision, 1);
  });
  test(
    'clearly incompatible instrument types cannot be confirmed through',
    () async {
      final e = await sms('types');
      for (final type in InstrumentType.values.where(
        (t) => t != InstrumentType.savingsProduct && t != InstrumentType.other,
      )) {
        final instrument = await instruments.create(
          name: type.name,
          type: type,
          provider: 'M-Shwari',
        );
        await expectLater(
          link(e, instrument.id, uncertain: true),
          throwsArgumentError,
        );
      }
    },
  );
  test(
    'exact recognized provider conflicts blocked even with confirmation',
    () async {
      final e = await sms('provider');
      final wrong = await instruments.create(
        name: 'Wrong provider',
        type: InstrumentType.savingsProduct,
        provider: 'KCB M-PESA',
      );
      await expectLater(
        link(e, wrong.id, uncertain: true),
        throwsArgumentError,
      );
    },
  );
  test(
    'missing unknown and substring provider names require explicit confirmation',
    () async {
      for (final provider in [null, 'Safaricom', 'My MPESA wallet']) {
        final e = await sms('unknown-${provider ?? 'none'}');
        final instrument = await instruments.create(
          name: 'Declared',
          type: InstrumentType.savingsProduct,
          provider: provider,
        );
        await expectLater(link(e, instrument.id), throwsArgumentError);
        await link(e, instrument.id, uncertain: true);
      }
    },
  );
  final products = {
    'mshwari': (
      'New M-Shwari saving account balance is Ksh1.25.',
      InstrumentType.savingsProduct,
      'M-Shwari',
      false,
    ),
    'kcb': (
      'KCB M-PESA Account balance is Ksh1.25.',
      InstrumentType.savingsProduct,
      'KCB M-PESA',
      false,
    ),
    'fuliza': (
      'Total Fuliza M-PESA outstanding amount is Ksh0.00.',
      InstrumentType.other,
      'Fuliza',
      true,
    ),
  };
  for (final entry in products.entries) {
    test(
      '${entry.key} uses independently typed subject compatibility',
      () async {
        final e = await sms(entry.key, body: entry.value.$1);
        final incompatible = await instruments.create(
          name: 'Insurance',
          type: InstrumentType.insurancePolicy,
        );
        await expectLater(
          link(e, incompatible.id, uncertain: true),
          throwsArgumentError,
        );
        final instrument = await instruments.create(
          name: entry.key,
          type: entry.value.$2,
          provider: entry.value.$3,
        );
        if (entry.value.$4) {
          await expectLater(link(e, instrument.id), throwsArgumentError);
        }
        await link(e, instrument.id, uncertain: entry.value.$4);
        expect((await repo.latest(instrument.id))!.amountMinor, e.amountMinor);
      },
    );
  }
  test(
    'unknown subject requires confirmation rather than invented match',
    () async {
      final e = await sms('unknown-subject');
      await (db.update(
        db.balanceEvidence,
      )..where((r) => r.id.equals(e.id))).write(
        const BalanceEvidenceCompanion(subjectFamily: Value('future_subject')),
      );
      final current = await row(e.id);
      await expectLater(link(current, wallet.id), throwsArgumentError);
      await link(current, wallet.id, uncertain: true);
    },
  );
  test(
    'same association no-op preserves revision even after archive',
    () async {
      final e = await sms('noop');
      await link(e, wallet.id);
      final linked = await row(e.id);
      await instruments.setArchived(wallet.uuid, true);
      await link(linked, wallet.id);
      expect((await row(e.id)).toJson(), linked.toJson());
    },
  );
  test('SMS content cannot be manually corrected or removed', () async {
    final e = await sms('immutable');
    await link(e, wallet.id);
    await expectLater(
      repo.deleteManual(id: e.id, accountId: wallet.id, expectedRevision: 1),
      throwsArgumentError,
    );
    await expectLater(
      repo.correctManual(
        id: e.id,
        accountId: wallet.id,
        expectedRevision: 1,
        amount: '999',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: date,
      ),
      throwsArgumentError,
    );
  });
  test(
    'latest uses as-of not association time and deterministic ties; zero vs unknown',
    () async {
      expect(await repo.latest(wallet.id), isNull);
      final manual = await repo.createManual(
        accountId: wallet.id,
        amount: '0',
        currency: 'KES',
        kind: BalanceKind.reported,
        asOf: date.add(const Duration(days: 1)),
      );
      final old = await sms('old');
      await link(old, wallet.id);
      expect((await repo.latest(wallet.id))!.id, manual.id);
      final newer = await sms('newer', asOf: date.add(const Duration(days: 2)));
      await link(newer, wallet.id);
      expect((await repo.latest(wallet.id))!.id, newer.id);
      final entries = (await repo.history(wallet.id)).entries;
      expect(entries.map((e) => e.id), [newer.id, manual.id, old.id]);
      expect(entries[1].amountMinor, 0);
      final tied = await sms('tied', asOf: date.add(const Duration(days: 2)));
      await link(tied, wallet.id);
      await (db.update(db.balanceEvidence)
            ..where((e) => e.id.isIn([newer.id, tied.id])))
          .write(const BalanceEvidenceCompanion(createdMillis: Value(1)));
      expect((await repo.latest(wallet.id))!.id, tied.id);
    },
  );
  test(
    'SQL exact counts and 20-item pages clamp after associations change',
    () async {
      for (var i = 0; i < 21; i++) {
        await sms('page-$i', asOf: date.add(Duration(minutes: i)));
      }
      final page = await repo.smsHistory(page: 1);
      expect(page.count, 21);
      expect(page.entries, hasLength(1));
      expect(page.page, 1);
      await link(await row(page.entries.single.id), wallet.id);
      final clamped = await repo.smsHistory(page: 1);
      expect(clamped.count, 20);
      expect(clamped.page, 0);
      expect(clamped.entries, hasLength(20));
      expect((await repo.smsHistory(unattributedOnly: false)).count, 21);
      expect((await repo.history(wallet.id)).count, 1);
    },
  );
  test(
    'legacy references displayed safely and can be explicitly unlinked',
    () async {
      final e = await sms('legacy-reference');
      final id = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: 'legacy-ref',
              name: 'Unconfirmed',
              type: 'mpesa',
            ),
          );
      await (db.update(db.balanceEvidence)..where((r) => r.id.equals(e.id)))
          .write(BalanceEvidenceCompanion(accountId: Value(id)));
      expect(
        (await repo.smsHistory(
          unattributedOnly: false,
        )).entries.single.associationLabel,
        'Unavailable instrument reference',
      );
      await link(await row(e.id), null);
      expect((await repo.smsHistory()).count, 1);
    },
  );
  test(
    'associations leave financial records links and semantic totals unchanged',
    () async {
      final records = FinancialRecordsRepository(db);
      await records.save(record(RecordSubtype.sendMoney, 50, fee: 3));
      final before = (await db.financialRecordsDao.getAllRecords()).single
          .toJson();
      final totals = const FinancialSemantics().calculate(
        await records.getAll(),
      );
      final e = await sms('isolation');
      await link(e, wallet.id);
      await link(await row(e.id), null);
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
