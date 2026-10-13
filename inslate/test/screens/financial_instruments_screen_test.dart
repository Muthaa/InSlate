import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/instruments/financial_instruments_screen.dart';
import 'package:inslate/screens/instruments/instrument_detail_screen.dart';
import 'package:inslate/screens/instruments/instrument_form_screen.dart';
import 'package:inslate/screens/instruments/instrument_presentation.dart';
import '../services/financial_summary_service_test.dart' show record;

class _Repository extends FinancialInstrumentsRepository {
  bool failCreate = false,
      failEdit = false,
      failArchive = false,
      invalid = false;
  _Repository(super.database);
  @override
  Future<FinancialInstrument> create({
    required String name,
    required InstrumentType type,
    String? provider,
    InstrumentIdentifiers? identifiers,
  }) {
    if (invalid) throw ArgumentError('Instrument name must not be empty');
    if (failCreate) throw StateError('Write failed');
    return super.create(
      name: name,
      type: type,
      provider: provider,
      identifiers: identifiers,
    );
  }

  @override
  Future<FinancialInstrument> update({
    required String uuid,
    required String name,
    required InstrumentType type,
    String? provider,
    InstrumentIdentifiers? identifiers,
  }) {
    if (failEdit) throw StateError('Write failed');
    return super.update(
      uuid: uuid,
      name: name,
      type: type,
      provider: provider,
      identifiers: identifiers,
    );
  }

  @override
  Future<void> setArchived(String uuid, bool archived) {
    if (failArchive) throw StateError('Write failed');
    return super.setArchived(uuid, archived);
  }
}

void main() {
  late AppDatabase db;
  late _Repository repository;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = _Repository(db);
  });
  tearDown(() => db.close());
  Future<void> open(
    WidgetTester tester, [
    Widget screen = const FinancialInstrumentsScreen(),
  ]) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          financialInstrumentsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.2);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    final finder = find.byKey(ValueKey('instrument.$key'));
    await reveal(tester, finder);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, InstrumentType value) async {
    await tap(tester, find.byKey(const ValueKey('instrument.type')));
    final choice = find.text(instrumentTypeLabel(value)).last;
    if (choice.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        choice,
        150,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tap(tester, choice);
  }

  Future<void> create(
    WidgetTester tester,
    String name, {
    InstrumentType kind = InstrumentType.bankAccount,
    String? provider,
    String? account,
  }) async {
    await tap(tester, find.text('New instrument'));
    await enter(tester, 'name', name);
    await type(tester, kind);
    if (provider != null) await enter(tester, 'provider', provider);
    if (account != null) await enter(tester, 'account', account);
    await tap(tester, find.text('Save instrument'));
  }

  void screenTest(String description, WidgetTesterCallback body) =>
      testWidgets(description, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });

  for (final kind in InstrumentType.values) {
    screenTest(
      'creates ${kind.storageValue} through the form and registered stream',
      (tester) async {
        await open(tester);
        expect(find.text('No active instruments'), findsOneWidget);
        await create(tester, 'My instrument', kind: kind);
        final saved = (await repository.list()).single;
        expect(saved.type, kind);
        expect(saved.name, 'My instrument');
        expect(saved.identifiers, isNull);
        expect(find.text('My instrument'), findsOneWidget);
        expect(find.byType(InstrumentFormScreen), findsNothing);
        await tap(tester, find.text('My instrument'));
        expect(find.text('Instrument details'), findsOneWidget);
        expect(find.text('No identifiers provided'), findsOneWidget);
      },
    );
  }
  screenTest(
    'metadata editing preserves IDs, UUIDs, creation time and existing transaction links',
    (tester) async {
      final original = await repository.create(
        name: 'Bank',
        type: InstrumentType.bankAccount,
        provider: 'Provider',
        identifiers: const InstrumentIdentifiers(
          accountNumber: '001',
          walletNumber: '+254',
          membershipNumber: 'MEM',
          policyNumber: 'POL',
          reference: 'Ref',
        ),
      );
      final records = FinancialRecordsRepository(db);
      await records.save(record(RecordSubtype.sendMoney, 10));
      final recordId = (await db.financialRecordsDao.getAllRecords()).single.id;
      await (db.update(
        db.financialRecords,
      )..where((r) => r.id.equals(recordId))).write(
        FinancialRecordsCompanion(
          sourceAccountId: Value(original.id),
          destinationAccountId: Value(original.id),
        ),
      );
      final before = (await db.financialRecordsDao.getAllRecords()).single
          .toJson();
      await open(tester);
      await tap(tester, find.text('Bank'));
      expect(find.text('Account number'), findsOneWidget);
      expect(find.text('001'), findsOneWidget);
      expect(find.textContaining('accountNumber'), findsNothing);
      await tap(tester, find.text('Edit instrument'));
      await enter(tester, 'name', 'Renamed');
      await type(tester, InstrumentType.mobileWallet);
      await enter(tester, 'provider', '');
      await enter(tester, 'account', '');
      await enter(tester, 'policy', 'New policy');
      await tap(tester, find.text('Save instrument'));
      final edited = (await repository.getByUuid(original.uuid))!;
      expect(edited.id, original.id);
      expect(edited.uuid, original.uuid);
      expect(edited.createdAt, original.createdAt);
      expect(edited.name, 'Renamed');
      expect(edited.type, InstrumentType.mobileWallet);
      expect(edited.provider, isNull);
      expect(edited.identifiers!.accountNumber, isNull);
      expect(edited.identifiers!.walletNumber, '+254');
      expect(edited.identifiers!.membershipNumber, 'MEM');
      expect(edited.identifiers!.policyNumber, 'New policy');
      expect(edited.identifiers!.reference, 'Ref');
      expect(
        (await db.financialRecordsDao.getAllRecords()).single.toJson(),
        before,
      );
      expect(find.byType(InstrumentDetailScreen), findsOneWidget);
    },
  );
  screenTest(
    'archive and restore confirmations preserve metadata and active/archived views',
    (tester) async {
      final original = await repository.create(
        name: 'Account',
        type: InstrumentType.bankAccount,
      );
      await open(tester);
      await tap(tester, find.text('Account'));
      await tap(tester, find.text('Archive instrument'));
      await tap(tester, find.text('Cancel'));
      expect((await repository.getByUuid(original.uuid))!.isActive, isTrue);
      await tap(tester, find.text('Archive instrument'));
      await tap(tester, find.widgetWithText(FilledButton, 'Archive'));
      expect((await repository.getByUuid(original.uuid))!.isArchived, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('No active instruments'), findsOneWidget);
      await tap(tester, find.text('Archived'));
      await tap(tester, find.text('Account'));
      await tap(tester, find.text('Edit instrument'));
      await enter(tester, 'name', 'Archived edited');
      await tap(tester, find.text('Save instrument'));
      expect((await repository.getByUuid(original.uuid))!.isArchived, isTrue);
      await tap(tester, find.text('Restore instrument'));
      await tap(tester, find.text('Cancel'));
      expect((await repository.getByUuid(original.uuid))!.isArchived, isTrue);
      await tap(tester, find.text('Restore instrument'));
      await tap(tester, find.widgetWithText(FilledButton, 'Restore'));
      final restored = (await repository.getByUuid(original.uuid))!;
      expect(restored.isActive, isTrue);
      expect(restored.id, original.id);
      expect(restored.createdAt, original.createdAt);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('No archived instruments'), findsOneWidget);
      await tap(tester, find.text('Active'));
      expect(find.text('Archived edited'), findsOneWidget);
    },
  );
  screenTest('legacy rows are excluded from both lists and detail routes', (
    tester,
  ) async {
    await db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        uuid: 'old-active',
        name: 'Legacy active',
        type: 'wallet',
      ),
    );
    await db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        uuid: 'old-archived',
        name: 'Legacy archived',
        type: 'wallet',
        isActive: const Value(false),
      ),
    );
    await open(tester);
    expect(find.text('No active instruments'), findsOneWidget);
    expect(find.text('Legacy active'), findsNothing);
    await tap(tester, find.text('Archived'));
    expect(find.text('No archived instruments'), findsOneWidget);
    expect(find.text('Legacy archived'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await open(tester, const InstrumentDetailScreen(uuid: 'old-active'));
    expect(find.text('Instrument is no longer available.'), findsOneWidget);
    expect(find.text('Edit instrument'), findsNothing);
  });
  screenTest(
    'duplicates at one provider with the same name and identifier are allowed',
    (tester) async {
      await open(tester);
      await create(
        tester,
        'Same account',
        provider: 'Same provider',
        account: '0001',
      );
      await create(
        tester,
        'Same account',
        provider: 'Same provider',
        account: '0001',
      );
      final saved = await repository.list();
      expect(saved, hasLength(2));
      expect(saved.map((i) => i.uuid).toSet(), hasLength(2));
      expect(find.text('Same account'), findsNWidgets(2));
    },
  );
  screenTest(
    'required fields and repository validation preserve optional input',
    (tester) async {
      await open(tester);
      await tap(tester, find.text('New instrument'));
      await enter(tester, 'provider', 'Keep provider');
      await tap(tester, find.text('Save instrument'));
      expect(find.text('Enter an instrument name'), findsOneWidget);
      expect(find.text('Choose an instrument type'), findsOneWidget);
      await enter(tester, 'name', 'Valid');
      await type(tester, InstrumentType.other);
      repository.invalid = true;
      await tap(tester, find.text('Save instrument'));
      expect(find.text('Instrument name must not be empty'), findsOneWidget);
      expect(await repository.list(), isEmpty);
      repository.invalid = false;
      await tap(tester, find.text('Save instrument'));
      expect((await repository.list()).single.provider, 'Keep provider');
    },
  );
  screenTest('create and edit persistence failures retain inputs and can retry', (
    tester,
  ) async {
    await open(tester);
    repository.failCreate = true;
    await create(tester, 'Retained', provider: 'Provider', account: '001');
    expect(
      find.text(
        'Unable to save instrument. Your input has been kept. Please try again.',
      ),
      findsOneWidget,
    );
    expect(await repository.list(), isEmpty);
    repository.failCreate = false;
    await tap(tester, find.text('Save instrument'));
    final original = (await repository.list()).single;
    expect(original.identifiers!.accountNumber, '001');
    expect(original.provider, 'Provider');
    await tap(tester, find.text('Retained'));
    await tap(tester, find.text('Edit instrument'));
    await enter(tester, 'name', 'Edited retained');
    repository.failEdit = true;
    await tap(tester, find.text('Save instrument'));
    expect(find.byType(InstrumentFormScreen), findsOneWidget);
    repository.failEdit = false;
    await tap(tester, find.text('Save instrument'));
    expect(
      (await repository.getByUuid(original.uuid))!.name,
      'Edited retained',
    );
    expect(await repository.list(), hasLength(1));
  });
  screenTest('archive failure leaves the instrument available for retry', (
    tester,
  ) async {
    final original = await repository.create(
      name: 'Account',
      type: InstrumentType.bankAccount,
    );
    await open(tester);
    await tap(tester, find.text('Account'));
    repository.failArchive = true;
    await tap(tester, find.text('Archive instrument'));
    await tap(tester, find.widgetWithText(FilledButton, 'Archive'));
    expect(
      find.text('Unable to archive instrument. Please try again.'),
      findsOneWidget,
    );
    expect((await repository.getByUuid(original.uuid))!.isActive, isTrue);
    repository.failArchive = false;
    await tap(tester, find.text('Archive instrument'));
    await tap(tester, find.widgetWithText(FilledButton, 'Archive'));
    expect((await repository.getByUuid(original.uuid))!.isArchived, isTrue);
  });
  screenTest('all supported identifier fields save as readable references', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text('New instrument'));
    await enter(tester, 'name', 'Identifiers');
    await type(tester, InstrumentType.other);
    for (final entry in {
      'account': '000Ab',
      'wallet': '+254 700',
      'membership': 'M-01',
      'policy': 'P-01',
      'reference': 'R-01',
    }.entries) {
      await enter(tester, entry.key, ' ${entry.value} ');
    }
    await tap(tester, find.text('Save instrument'));
    final saved = (await repository.list()).single;
    expect(saved.identifiers!.toJson(), {
      'accountNumber': '000Ab',
      'walletNumber': '+254 700',
      'membershipNumber': 'M-01',
      'policyNumber': 'P-01',
      'reference': 'R-01',
    });
    await tap(tester, find.text('Identifiers'));
    expect(find.text('Policy number'), findsOneWidget);
    expect(find.textContaining('policyNumber'), findsNothing);
    expect(find.textContaining('PIN'), findsNothing);
    expect(find.textContaining('Password'), findsNothing);
  });
  screenTest(
    'unknown stored types require explicit selection before metadata edits',
    (tester) async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'future',
          name: 'Future',
          type: 'future-type',
          isUserRegistered: const Value(true),
        ),
      );
      await open(tester);
      await tap(tester, find.text('Future'));
      await tap(tester, find.text('Edit instrument'));
      await enter(tester, 'name', 'Renamed future');
      await tap(tester, find.text('Save instrument'));
      expect(
        (await db.accountsDao.getAccountByUuid('future'))!.type,
        'future-type',
      );
      await type(tester, InstrumentType.other);
      await tap(tester, find.text('Save instrument'));
      expect((await repository.getByUuid('future'))!.name, 'Renamed future');
    },
  );
}
