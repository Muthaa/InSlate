import 'package:drift/drift.dart' show Value;
import 'package:inslate/core/enums/account_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/repositories/balance_evidence_repository.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';

void main() {
  late AppDatabase db;
  late BalanceEvidenceRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BalanceEvidenceRepository(db);
  });
  tearDown(() => db.close());
  Future<void> seed(
    String id, {
    String family = 'mpesa',
    String currency = 'KES',
    int asOf = 1,
    int created = 1,
    int amount = 0,
    String kind = 'reported',
    String origin = 'sms_reported',
  }) => db
      .into(db.balanceEvidence)
      .insert(
        BalanceEvidenceCompanion.insert(
          id: id,
          amountMinor: amount,
          currency: currency,
          kind: kind,
          subjectFamily: Value(family),
          origin: origin,
          asOfMillis: asOf,
          timeBasis: 'raw_message_received_at_proxy',
          createdMillis: created,
        ),
      );

  test(
    'more than one history page becomes one wallet; late older SMS does not replace latest',
    () async {
      for (var i = 0; i < 45; i++) {
        await seed('sms-$i', asOf: i + 1, amount: i * 100);
      }
      await seed('late-old', asOf: 2, created: 999, amount: 999999);
      final wallets = await repo.smsWallets();
      expect(wallets, hasLength(1));
      expect(wallets.single.latest.id, 'sms-44');
      expect(wallets.single.latest.amountMinor, 4400);
      expect(wallets.single.observationCount, 46);
      expect((await repo.smsHistory(unattributedOnly: false)).count, 46);
      expect(
        (await repo.smsHistory(unattributedOnly: false)).entries,
        hasLength(20),
      );
    },
  );
  test(
    'products, debt and currencies remain distinct; reported/available are not duplicate wallets',
    () async {
      await seed('wallet');
      await seed('savings-old', family: 'mshwariSavings');
      await seed(
        'savings-new',
        family: 'mshwariSavings',
        kind: 'available',
        asOf: 2,
      );
      await seed('kcb', family: 'kcbMpesa');
      await seed('loan', family: 'mshwariLoan', kind: 'outstanding_debt');
      await seed('usd', currency: 'USD');
      await seed('manual', origin: 'manual', asOf: 999);
      final wallets = await repo.smsWallets();
      expect(wallets, hasLength(5));
      expect(wallets.first.isMeasuredWallet, isTrue);
      final savings = wallets.singleWhere((e) => e.latest.id == 'savings-new');
      expect(savings.observationCount, 2);
      expect(savings.latest.kind, BalanceKind.available);
      expect(wallets.map((e) => e.latest.id), isNot(contains('manual')));
    },
  );
  test(
    'deterministic ties use created time then ID; linked old data never replaces latest',
    () async {
      await seed('old', family: 'mshwariSavings');
      final target = await FinancialInstrumentsRepository(db).create(
        name: 'Savings',
        type: InstrumentType.savingsProduct,
        provider: 'M-Shwari',
      );
      await repo.associateSms(
        id: 'old',
        expectedAccountId: null,
        expectedRevision: 0,
        accountId: target.id,
      );
      await seed('latest-a', family: 'mshwariSavings', asOf: 2, created: 3);
      await seed('latest-z', family: 'mshwariSavings', asOf: 2, created: 3);
      final wallet = (await repo.smsWallets()).single;
      expect(wallet.latest.id, 'latest-z');
      expect(wallet.latest.accountId, isNull);
      expect(wallet.observationCount, 3);
      final history = await repo.smsHistory(
        unattributedOnly: false,
        subjectFamily: AccountType.mshwariSavings,
        currency: 'KES',
      );
      expect(history.entries.map((e) => e.id), ['latest-z', 'latest-a', 'old']);
      expect(history.entries.last.associationName, 'Savings');
    },
  );
}
