import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/instrument_mappings_repository.dart';
import 'package:inslate/repositories/insights_repository.dart';
import 'package:inslate/repositories/budgets_repository.dart';
import 'package:inslate/core/constants/instrument_catalogue.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/party.dart';
import '../services/financial_summary_service_test.dart' show record;
import 'package:inslate/repositories/paybill_reversals_repository.dart';
import 'package:inslate/repositories/detected_providers_repository.dart';
import 'paybill_reversals_test.dart' show confirmation;

void main() {
  late AppDatabase db;
  late InstrumentMappingsRepository mappings;
  late FinancialRecordsRepository records;
  late FinancialInstrumentsRepository instruments;
  late FinancialInstrument instrument;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mappings = InstrumentMappingsRepository(db);
    records = FinancialRecordsRepository(db);
    instruments = FinancialInstrumentsRepository(db);
    instrument = await instruments.create(
      name: 'My product',
      type: InstrumentType.other,
    );
  });
  tearDown(() => db.close());
  Future<int> add({
    String provider = 'Provider',
    String? reference = 'ABC-1',
    String subtype = 'payBill',
    String type = 'expense',
    int? destination,
    int? reversal,
  }) => db
      .into(db.financialRecords)
      .insert(
        FinancialRecordsCompanion.insert(
          reference:
              'REF-$subtype-$reference-${DateTime.now().microsecondsSinceEpoch}',
          receivedAt: DateTime(2026, 9, 10),
          amount: 100,
          type: type,
          subtype: subtype,
          status: 'successful',
          title: 'Payment',
          rawMessage: 'original',
          transactionCost: const Value(5),
          partyName: Value(provider),
          partyAccount: Value(reference),
          destinationAccountId: Value(destination),
          reversesRecordId: Value(reversal),
        ),
      );
  Future<MappingResult> confirm([
    InstrumentPurpose purpose = InstrumentPurpose.investment,
  ]) => mappings.confirm(
    accountId: instrument.id,
    provider: 'Provider',
    reference: 'ABC-1',
    purpose: purpose,
  );
  test(
    'preview is read-only; exact references and provider identities isolate accounts',
    () async {
      final id = await add();
      await add(reference: 'ABC-2');
      await add(provider: 'Other');
      await add(reference: null);
      final preview = await mappings.preview(
        accountId: instrument.id,
        provider: ' provider ',
        reference: ' abc-1 ',
        purpose: InstrumentPurpose.investment,
      );
      expect(preview.matching, 1);
      expect((await records.getById(id))!.subtype, RecordSubtype.payBill);
      final result = await confirm();
      expect(result.linked, 1);
      expect(result.interpreted, 1);
      final original = await (db.select(
        db.financialRecords,
      )..where((r) => r.id.equals(id))).getSingle();
      expect(original.subtype, 'payBill');
      expect(original.type, 'expense');
      expect(original.rawMessage, 'original');
      expect(original.destinationAccountId, instrument.id);
      expect(
        (await records.getById(id))!.subtype,
        RecordSubtype.investmentPurchase,
      );
    },
  );
  test(
    'future matching and reruns are idempotent and never create registrations',
    () async {
      await confirm();
      final id = await add();
      expect((await mappings.applyNew(afterId: id - 1)).interpreted, 1);
      expect((await mappings.applyNew(afterId: id - 1)).interpreted, 0);
      expect((await instruments.list()).length, 1);
      expect(
        (await records.getById(id))!.subtype,
        RecordSubtype.investmentPurchase,
      );
    },
  );
  test(
    'incoming uses source; savings purpose is a resolved savings movement',
    () async {
      final id = await add(subtype: 'receiveMoney', type: 'income');
      await confirm(InstrumentPurpose.savings);
      final row = await (db.select(
        db.financialRecords,
      )..where((r) => r.id.equals(id))).getSingle();
      expect(row.sourceAccountId, instrument.id);
      expect(row.destinationAccountId, isNull);
      expect(
        (await records.getById(id))!.subtype,
        RecordSubtype.registeredSavingsWithdrawal,
      );
      final period = FinancialPeriod.month(DateTime(2026, 9));
      expect(
        await records.countActivity(
          ActivityFilter(
            period: period,
            scope: ActivityScope.investmentsAndSavings,
          ),
        ),
        1,
      );
      expect(
        await records.countActivity(
          ActivityFilter(period: period, scope: ActivityScope.income),
        ),
        0,
      );
    },
  );
  test(
    'explicit loan wording and reversal pairs keep parsed financial semantics',
    () async {
      final loan = await add(subtype: 'loanRepayment', type: 'loan');
      final original = await add();
      final reversal = await add(
        subtype: 'payBillReversal',
        reversal: original,
      );
      final result = await confirm();
      expect(result.protected, 3);
      expect(
        (await records.getById(loan))!.subtype,
        RecordSubtype.loanRepayment,
      );
      expect((await records.getById(original))!.subtype, RecordSubtype.payBill);
      expect(
        (await records.getById(reversal))!.subtype,
        RecordSubtype.payBillReversal,
      );
    },
  );
  test('conflicting explicit links are preserved', () async {
    final other = await instruments.create(
      name: 'Other',
      type: InstrumentType.other,
    );
    final id = await add(destination: other.id);
    expect((await confirm()).conflicts, 1);
    expect((await records.getById(id))!.subtype, RecordSubtype.payBill);
  });
  test(
    'one mapping per exact identity; removal restores interpretation and retains links',
    () async {
      final id = await add();
      await confirm();
      await expectLater(confirm(), throwsStateError);
      final mapping = (await mappings.list(instrument.id)).single;
      await expectLater(mappings.remove(mapping.id, -1), throwsStateError);
      await mappings.remove(mapping.id, instrument.id);
      expect((await records.getById(id))!.subtype, RecordSubtype.payBill);
      expect(
        (await (db.select(
          db.financialRecords,
        )..where((r) => r.id.equals(id))).getSingle()).destinationAccountId,
        instrument.id,
      );
    },
  );
  test(
    'legacy, missing and archived instruments cannot receive new mappings',
    () async {
      final legacy = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: 'legacy',
              name: 'Legacy',
              type: 'wallet',
            ),
          );
      for (final id in [-1, legacy]) {
        await expectLater(
          mappings.confirm(
            accountId: id,
            provider: 'Provider',
            reference: 'ABC-1',
            purpose: InstrumentPurpose.loan,
          ),
          throwsArgumentError,
        );
      }
      final historic = await add();
      await confirm();
      await instruments.setArchived(instrument.uuid, true);
      await expectLater(
        mappings.preview(
          accountId: instrument.id,
          provider: 'Provider',
          reference: 'ABC-2',
          purpose: InstrumentPurpose.loan,
        ),
        throwsArgumentError,
      );
      final id = await add();
      expect((await mappings.applyNew(afterId: id - 1)).matching, 0);
      expect((await mappings.list(instrument.id)).length, 1);
      expect(
        (await records.getById(historic))!.subtype,
        RecordSubtype.investmentPurchase,
      );
    },
  );
  test(
    'shared SQL totals, budget spending and Activity reconcile after confirmation',
    () async {
      await add();
      await add(reference: 'OTHER');
      await confirm(InstrumentPurpose.loan);
      final period = FinancialPeriod.month(DateTime(2026, 9));
      final insights = await InsightsRepository(db).watch(period).first;
      expect(insights.totals.expenses, 100);
      expect(insights.totals.income, 0);
      expect(insights.totals.fees, 10);
      expect(
        await records.countActivity(
          ActivityFilter(period: period, scope: ActivityScope.expenses),
        ),
        1,
      );
      expect(
        await records.countActivity(
          ActivityFilter(period: period, scope: ActivityScope.loans),
        ),
        1,
      );
      final budgets = BudgetsRepository(db);
      await budgets.create(amount: '200');
      expect(
        (await budgets.watch(period).first).single.spentMinor,
        BigInt.from(10000),
      );
    },
  );
  test(
    'unknown-purpose mapping tracks direction without claiming ordinary expenses',
    () async {
      final id = await add();
      await confirm(InstrumentPurpose.unknown);
      expect(
        (await records.getById(id))!.subtype,
        RecordSubtype.instrumentPayment,
      );
      final totals = (await InsightsRepository(
        db,
      ).watch(FinancialPeriod.month(DateTime(2026, 9))).first).totals;
      expect(totals.expenses, 0);
      expect(totals.fees, 5);
    },
  );
  test(
    'persistence applies confirmed mappings before automatic categorization',
    () async {
      await confirm(InstrumentPurpose.savings);
      await records.save(
        record(
          RecordSubtype.payBill,
          30,
          party: const Party(
            name: 'Provider',
            type: PartyType.business,
            account: 'ABC-1',
          ),
        ),
      );
      final saved = (await records.getAll()).single;
      expect(saved.subtype, RecordSubtype.registeredSavingsDeposit);
      expect(saved.parsedSubtype, RecordSubtype.payBill);
      expect(saved.interpretationMappingId, isNotNull);
    },
  );
  test(
    'catalogue exact recognition leaves ownership absent and preserves parsed investments',
    () async {
      final provider = InstrumentCatalogue.providers
          .firstWhere(
            (p) =>
                p.products.contains(InstrumentProduct.insurance) &&
                p.investmentKeywords.isEmpty,
          )
          .name;
      await records.save(
        record(
          RecordSubtype.payBill,
          30,
          party: Party(name: provider, type: PartyType.business),
        ),
      );
      final unknown = (await records.getAll()).single;
      expect(unknown.subtype, RecordSubtype.instrumentPayment);
      final detected = (await DetectedProvidersRepository(
        db,
      ).watch().first).single;
      expect(detected.unspecified, true);
      expect(detected.count, 1);
      expect(await records.countActivity(detected.filter), detected.count);
      final row = (await db.select(db.financialRecords).get()).single;
      expect(row.sourceAccountId, isNull);
      expect(row.destinationAccountId, isNull);
      await records.save(
        record(
          RecordSubtype.investmentPurchase,
          50,
          party: const Party(name: 'Cytonn', type: PartyType.business),
        ),
      );
      expect(
        (await records.getAll()).last.subtype,
        RecordSubtype.investmentPurchase,
      );
    },
  );
  test(
    'new verified reversal restores protected expense semantics without removing links',
    () async {
      final id = await add();
      await (db.update(
        db.financialRecords,
      )..where((r) => r.id.equals(id))).write(
        FinancialRecordsCompanion(
          reference: const Value('ORIGINAL01'),
          transactionDate: Value(DateTime(2026, 9, 10)),
        ),
      );
      await confirm();
      final sms = confirmation(amount: '100.00');
      await db
          .into(db.rawMessages)
          .insert(
            RawMessagesCompanion.insert(
              sourceId: sms.id,
              sender: sms.sender,
              body: sms.body,
              receivedAt: sms.receivedAt,
            ),
          );
      expect(
        (await PayBillReversalsRepository(
          db,
        ).process([sms.id])).single.imported,
        true,
      );
      expect((await records.getById(id))!.subtype, RecordSubtype.payBill);
      final row = await (db.select(
        db.financialRecords,
      )..where((r) => r.id.equals(id))).getSingle();
      expect(row.destinationAccountId, instrument.id);
      expect(row.interpretationMappingId, isNull);
      final totals = (await InsightsRepository(
        db,
      ).watch(FinancialPeriod.month(DateTime(2026, 9))).first).totals;
      expect(totals.expenses, 0);
      expect(totals.fees, 5);
    },
  );
  test(
    'history processing crosses keyset page boundaries without missing matches',
    () async {
      for (var i = 0; i < 205; i++) {
        await add();
      }
      final result = await confirm();
      expect(result.matching, 205);
      expect(result.linked, 205);
      expect(result.interpreted, 205);
      expect((await mappings.applyNew(afterId: 0)).interpreted, 0);
    },
  );
  test(
    'provider-scoped reference discovery and transaction preview stay bounded and read-only',
    () async {
      final ids = <int>[];
      for (var i = 0; i < 45; i++) {
        ids.add(await add());
      }
      await add(provider: 'Other');
      await add(reference: 'ABC-2');
      await add(subtype: 'buyGoods');
      final references = await mappings.detectedReferences(
        provider: ' Provider ',
        limit: 1,
      );
      expect(references, hasLength(1));
      expect(references.single.provider, 'Provider');
      final review = await mappings.referenceReviewPage(
        accountId: instrument.id,
        provider: 'Provider',
      );
      expect(review.first.detected, 46);
      expect(review.first.eligible, 45);
      expect(review.first.conflicts, 0);
      expect(review.first.mappedAccountId, isNull);
      expect(references.single.count, 46); // includes unsupported buyGoods
      final first = await mappings.previewTransactions(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'ABC-1',
        purpose: InstrumentPurpose.savings,
      );
      final second = await mappings.previewTransactions(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'ABC-1',
        purpose: InstrumentPurpose.savings,
        offset: 20,
      );
      final third = await mappings.previewTransactions(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'ABC-1',
        purpose: InstrumentPurpose.savings,
        offset: 40,
      );
      expect(first.length, 20);
      expect(second.length, 20);
      expect(third.length, 5);
      expect([...first, ...second, ...third].map((row) => row.id), ids);
      expect(
        first.every(
          (row) => row.treatment == 'Savings deposit' && !row.incoming,
        ),
        isTrue,
      );
      expect(await mappings.list(instrument.id), isEmpty);
      expect(
        (await db.select(db.financialRecords).get()).every(
          (row) =>
              row.destinationAccountId == null &&
              row.interpretedSubtype == null,
        ),
        isTrue,
      );
    },
  );

  test(
    'transaction previews expose conflicts and explicit loan protection exactly as confirmation',
    () async {
      final other = await instruments.create(
        name: 'Other product',
        type: InstrumentType.other,
      );
      await add(destination: other.id);
      await add(subtype: 'loanRepayment', type: 'loan');
      await add(subtype: 'receiveMoney', type: 'income');
      final preview = await mappings.previewTransactions(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'ABC-1',
        purpose: InstrumentPurpose.investment,
      );
      expect(preview.map((row) => row.treatment), [
        'Conflict - review individually; unchanged',
        'Protected - original treatment retained',
        'Investment redemption',
      ]);
      final result = await confirm();
      expect(result.conflicts, 1);
      expect(result.protected, 1);
      expect(result.linked, 2);
    },
  );
  test(
    'separate products at the same provider map separate references for history and future imports',
    () async {
      final savings = await instruments.create(
        name: 'Savings',
        type: InstrumentType.savingsProduct,
        provider: 'Provider',
      );
      await add(reference: 'SAVINGS');
      await add(reference: 'LOAN');
      await mappings.confirm(
        accountId: savings.id,
        provider: 'Provider',
        reference: 'SAVINGS',
        purpose: InstrumentPurpose.savings,
      );
      await mappings.confirm(
        accountId: instrument.id,
        provider: 'Provider',
        reference: 'LOAN',
        purpose: InstrumentPurpose.loan,
      );
      final futureSavings = record(
        RecordSubtype.payBill,
        30,
        party: const Party(
          name: 'Provider',
          type: PartyType.business,
          account: 'SAVINGS',
        ),
      );
      final futureLoan = record(
        RecordSubtype.payBill,
        40,
        party: const Party(
          name: 'Provider',
          type: PartyType.business,
          account: 'LOAN',
        ),
      );
      await records.saveAll([futureSavings, futureLoan]);
      final rows = await db.select(db.financialRecords).get();
      expect(
        rows
            .where((r) => r.partyAccount == 'SAVINGS')
            .every(
              (r) =>
                  r.destinationAccountId == savings.id &&
                  r.interpretedSubtype == 'registeredSavingsDeposit',
            ),
        isTrue,
      );
      expect(
        rows
            .where((r) => r.partyAccount == 'LOAN')
            .every(
              (r) =>
                  r.destinationAccountId == instrument.id &&
                  r.interpretedSubtype == 'loanRepayment',
            ),
        isTrue,
      );
      final review = await mappings.referenceReviewPage(
        accountId: savings.id,
        provider: 'Provider',
      );
      expect(
        review.firstWhere((r) => r.reference == 'SAVINGS').mappedAccountId,
        savings.id,
      );
      expect(
        review.firstWhere((r) => r.reference == 'LOAN').mappedAccountId,
        instrument.id,
      );
      expect(review.firstWhere((r) => r.reference == 'LOAN').conflicts, 2);
    },
  );
  test(
    'reference setup combines normalized provider and reference variants before reporting eligibility',
    () async {
      await add(provider: 'Provider', reference: 'ABC-1');
      await add(provider: ' provider ', reference: 'abc-1');
      final rows = await mappings.referenceReviewPage(
        accountId: instrument.id,
        provider: 'PROVIDER',
      );
      expect(rows, hasLength(1));
      expect(rows.single.detected, 2);
      expect(rows.single.eligible, 2);
      expect(rows.single.conflicts, 0);
    },
  );
}
