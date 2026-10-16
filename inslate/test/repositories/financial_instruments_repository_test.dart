import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/categories_repository.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/financial_instruments_provider.dart';
import 'package:inslate/services/financial_summary_service.dart';
import 'package:inslate/services/financial_semantics.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialInstrumentsRepository instruments;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    instruments = FinancialInstrumentsRepository(db);
  });
  tearDown(() => db.close());

  test(
    'all supported types persist with permanent codes independently of transactions',
    () async {
      expect(InstrumentType.values.map((t) => t.storageValue).toList(), [
        'bank_account',
        'mobile_wallet',
        'savings_product',
        'investment_account',
        'sacco_membership',
        'insurance_policy',
        'pension',
        'other',
      ]);
      for (final type in InstrumentType.values) {
        final instrument = await instruments.create(
          name: '  My ${type.name}  ',
          type: type,
        );
        expect(instrument.id, greaterThan(0));
        expect(instrument.uuid, isNotEmpty);
        expect(instrument.type, type);
        expect(instrument.storedType, type.storageValue);
        expect(instrument.name, 'My ${type.name}');
        expect(instrument.isActive, isTrue);
        expect(instrument.provider, isNull);
        expect(instrument.identifiers, isNull);
        expect(
          (await instruments.getById(instrument.id))!.uuid,
          instrument.uuid,
        );
        expect(
          (await instruments.getByUuid(instrument.uuid))!.id,
          instrument.id,
        );
      }
      final all = await instruments.list();
      expect(all, hasLength(8));
      expect(all.map((a) => a.uuid).toSet(), hasLength(8));
      expect(await db.financialRecordsDao.getAllRecords(), isEmpty);
      expect(await db.rawMessagesDao.getAllMessages(), isEmpty);
    },
  );
  test(
    'update replaces metadata and clears optional fields while keeping identity and timestamps',
    () async {
      final first = await instruments.create(
        name: 'Personal',
        type: InstrumentType.bankAccount,
        provider: '  Bank  ',
        identifiers: const InstrumentIdentifiers(
          accountNumber: ' 001-002 ',
          reference: ' Ref ',
        ),
      );
      expect(first.provider, 'Bank');
      expect(first.identifiers!.accountNumber, '001-002');
      final edited = await instruments.update(
        uuid: first.uuid,
        name: '  Pension  ',
        type: InstrumentType.pension,
        provider: '  Fund ',
        identifiers: const InstrumentIdentifiers(membershipNumber: '  00045 '),
      );
      expect(edited.id, first.id);
      expect(edited.uuid, first.uuid);
      expect(edited.createdAt, first.createdAt);
      expect(edited.type, InstrumentType.pension);
      expect(edited.name, 'Pension');
      expect(edited.identifiers!.accountNumber, isNull);
      expect(edited.identifiers!.membershipNumber, '00045');
      final cleared = await instruments.update(
        uuid: first.uuid,
        name: edited.name,
        type: edited.type,
      );
      expect(cleared.provider, isNull);
      expect(cleared.identifiers, isNull);
      expect(await instruments.list(), hasLength(1));
    },
  );
  test(
    'optional identifiers trim blanks without changing numbers or inferring identities',
    () async {
      final empty = await instruments.create(
        name: 'Other',
        type: InstrumentType.other,
        provider: ' ',
        identifiers: const InstrumentIdentifiers(
          accountNumber: ' ',
          reference: '',
        ),
      );
      expect(empty.identifiers, isNull);
      expect(empty.provider, isNull);
      final all = await instruments.create(
        name: 'Numbers',
        type: InstrumentType.other,
        identifiers: const InstrumentIdentifiers(
          accountNumber: ' 000Ab ',
          walletNumber: ' +254 700 ',
          membershipNumber: ' SAC-01 ',
          policyNumber: ' POL-01 ',
          reference: ' Ref-X ',
        ),
      );
      expect(all.identifiers!.toJson(), {
        'accountNumber': '000Ab',
        'walletNumber': '+254 700',
        'membershipNumber': 'SAC-01',
        'policyNumber': 'POL-01',
        'reference': 'Ref-X',
      });
    },
  );
  test(
    'blank names and missing or legacy IDs reject writes without partial changes',
    () async {
      await expectLater(
        instruments.create(name: ' \n ', type: InstrumentType.bankAccount),
        throwsArgumentError,
      );
      final valid = await instruments.create(
        name: 'Valid',
        type: InstrumentType.bankAccount,
      );
      await expectLater(
        instruments.update(
          uuid: valid.uuid,
          name: ' ',
          type: InstrumentType.pension,
        ),
        throwsArgumentError,
      );
      expect((await instruments.getByUuid(valid.uuid))!.name, 'Valid');
      await expectLater(
        instruments.update(
          uuid: 'missing',
          name: 'Name',
          type: InstrumentType.other,
        ),
        throwsArgumentError,
      );
      await expectLater(
        instruments.setArchived('missing', true),
        throwsArgumentError,
      );
      expect(await instruments.getByUuid('missing'), isNull);
      expect(await instruments.getById(-1), isNull);
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'legacy',
          name: 'Legacy',
          type: 'wallet',
        ),
      );
      await expectLater(
        instruments.update(
          uuid: 'legacy',
          name: 'Claim',
          type: InstrumentType.mobileWallet,
        ),
        throwsArgumentError,
      );
      await expectLater(
        instruments.setArchived('legacy', true),
        throwsArgumentError,
      );
      expect(await instruments.getByUuid('legacy'), isNull);
      expect(
        (await db.accountsDao.getAccountByUuid('legacy'))!.isUserRegistered,
        isFalse,
      );
      expect(await instruments.list(includeArchived: true), hasLength(1));
    },
  );
  test(
    'multiple accounts at one provider can share names and optional identifiers',
    () async {
      for (var i = 0; i < 3; i++) {
        await instruments.create(
          name: 'Account',
          type: InstrumentType.bankAccount,
          provider: 'Same Bank',
          identifiers: const InstrumentIdentifiers(accountNumber: '001'),
        );
      }
      final rows = await instruments.list();
      expect(rows, hasLength(3));
      expect(rows.map((r) => r.id).toSet(), hasLength(3));
      await expectLater(
        db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            uuid: rows.first.uuid,
            name: 'Duplicate UUID',
            type: 'bank_account',
          ),
        ),
        throwsException,
      );
    },
  );
  test(
    'archive and restore are idempotent and archived metadata remains editable',
    () async {
      final first = await instruments.create(
        name: 'Account',
        type: InstrumentType.bankAccount,
      );
      await instruments.setArchived(first.uuid, true);
      await instruments.setArchived(first.uuid, true);
      expect(await instruments.list(), isEmpty);
      expect(await instruments.list(includeArchived: true), hasLength(1));
      expect((await instruments.getByUuid(first.uuid))!.isArchived, isTrue);
      final edited = await instruments.update(
        uuid: first.uuid,
        name: 'Archived account',
        type: first.type,
      );
      expect(edited.isArchived, isTrue);
      expect(edited.id, first.id);
      await instruments.setArchived(first.uuid, false);
      await instruments.setArchived(first.uuid, false);
      expect((await instruments.list()).single.id, first.id);
      expect((await instruments.list()).single.createdAt, first.createdAt);
    },
  );
  test(
    'listing and reactive queries exclude legacy rows and order stably',
    () async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'old',
          name: 'A legacy',
          type: 'unknown',
        ),
      );
      final iterator = StreamIterator(instruments.watch());
      try {
        await iterator.moveNext();
        expect(iterator.current, isEmpty);
        final b = await instruments.create(
          name: 'B',
          type: InstrumentType.other,
        );
        await iterator.moveNext();
        expect(iterator.current.single.uuid, b.uuid);
        await instruments.setArchived(b.uuid, true);
        await iterator.moveNext();
        expect(iterator.current, isEmpty);
      } finally {
        await iterator.cancel();
      }
      await instruments.create(name: 'A', type: InstrumentType.other);
      await instruments.create(name: 'A', type: InstrumentType.other);
      final rows = await instruments.list(includeArchived: true);
      expect(rows.map((r) => r.name), ['A', 'A', 'B']);
      expect(rows[0].id, lessThan(rows[1].id));
    },
  );
  test(
    'unknown free-text types have a safe projection without rewriting stored types',
    () async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'future',
          name: 'Future',
          type: 'future_type',
          isUserRegistered: const Value(true),
        ),
      );
      final value = (await instruments.getByUuid('future'))!;
      expect(value.type, InstrumentType.other);
      expect(value.storedType, 'future_type');
      await instruments.setArchived(value.uuid, true);
      expect(
        (await db.accountsDao.getAccountByUuid('future'))!.type,
        'future_type',
      );
      expect(InstrumentType.fromStorage('wallet'), InstrumentType.other);
    },
  );
  test(
    'providers expose active and all registered instruments from the same database',
    () async {
      final value = await instruments.create(
        name: 'Account',
        type: InstrumentType.other,
      );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final activeSub = container.listen(
        financialInstrumentsProvider,
        (_, _) {},
      );
      final allSub = container.listen(
        allFinancialInstrumentsProvider,
        (_, _) {},
      );
      try {
        expect(
          (await container.read(
            financialInstrumentsProvider.future,
          )).single.uuid,
          value.uuid,
        );
        expect(
          (await container.read(
            allFinancialInstrumentsProvider.future,
          )).single.uuid,
          value.uuid,
        );
        final updated = Completer<void>();
        final sub = container.listen(financialInstrumentsProvider, (_, next) {
          if (next.asData?.value.isEmpty == true && !updated.isCompleted) {
            updated.complete();
          }
        });
        await instruments.setArchived(value.uuid, true);
        await updated.future;
        expect(container.read(financialInstrumentsProvider).value, isEmpty);
        expect(
          container.read(allFinancialInstrumentsProvider).value,
          hasLength(1),
        );
        sub.close();
      } finally {
        activeSub.close();
        allSub.close();
        container.dispose();
      }
    },
  );
  test(
    'registration is isolated from ingestion, categorization, Activity and financial semantics',
    () async {
      final records = FinancialRecordsRepository(db);
      final categories = CategoriesRepository(db);
      const party = Party(
        name: 'Recognized bank',
        type: PartyType.business,
        identifier: ' BANK ',
      );
      await records.saveAll([
        record(RecordSubtype.sendMoney, 100, party: party),
        record(RecordSubtype.mshwariDeposit, 20),
        record(RecordSubtype.receiveMoney, 300),
      ]);
      expect(await db.accountsDao.getAllAccounts(), isEmpty);
      final id = (await db.financialRecordsDao.getAllRecords()).first.id;
      await categories.assignSimilar(
        recordId: id,
        categoryId: 'builtin.expense.food',
      );
      final before = (await db.financialRecordsDao.getAllRecords())
          .map((r) => r.toJson())
          .toList();
      final assignment = (await db.select(db.recordCategoryAssignments).get())
          .map((r) => r.toJson())
          .toList();
      final rules = (await db.select(db.categoryRules).get())
          .map((r) => r.toJson())
          .toList();
      final summary = FinancialSummaryService().calculate(
        await records.getAll(),
        period: DateTime(2026, 9),
      );
      final identity = PartyIdentity.fromParty(party);
      final instrument = await instruments.create(
        name: 'My Bank',
        type: InstrumentType.bankAccount,
        provider: 'Recognized bank',
        identifiers: const InstrumentIdentifiers(accountNumber: 'BANK'),
      );
      await instruments.setArchived(instrument.uuid, true);
      expect(
        (await db.financialRecordsDao.getAllRecords())
            .map((r) => r.toJson())
            .toList(),
        before,
      );
      expect(
        (await db.select(db.recordCategoryAssignments).get())
            .map((r) => r.toJson())
            .toList(),
        assignment,
      );
      expect(
        (await db.select(db.categoryRules).get())
            .map((r) => r.toJson())
            .toList(),
        rules,
      );
      expect(PartyIdentity.fromParty(party), identity);
      final after = FinancialSummaryService().calculate(
        await records.getAll(),
        period: DateTime(2026, 9),
      );
      expect(after.totalIncome, summary.totalIncome);
      expect(after.totalExpenses, summary.totalExpenses);
      expect(after.netMovement, summary.netMovement);
      final filter = ActivityFilter(
        period: FinancialPeriod.month(DateTime(2026, 9)),
        category: const ActivityCategoryFilter.category('builtin.expense.food'),
      );
      expect(await records.countActivity(filter), 1);
      expect((await records.getActivity(filter)).single.id, id);
      await records.save(record(RecordSubtype.kcbDeposit, 10, party: party));
      expect(await instruments.list(includeArchived: true), hasLength(1));
      expect(
        (await db.financialRecordsDao.getAllRecords()).every(
          (r) => r.sourceAccountId == null && r.destinationAccountId == null,
        ),
        isTrue,
      );
    },
  );
}
