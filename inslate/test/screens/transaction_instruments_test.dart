import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/screens/activity/transaction_detail_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialInstrumentsRepository instruments;
  late InstrumentLinksRepository links;
  late FinancialInstrument wallet, savings;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    instruments = FinancialInstrumentsRepository(db);
    links = InstrumentLinksRepository(db);
    wallet = await instruments.create(
      name: 'Wallet',
      type: InstrumentType.mobileWallet,
    );
    savings = await instruments.create(
      name: 'Savings',
      type: InstrumentType.savingsProduct,
    );
  });
  tearDown(() => db.close());
  Future<int> open(WidgetTester tester, RecordSubtype subtype) async {
    final records = FinancialRecordsRepository(db);
    await records.save(record(subtype, 10));
    final id = (await records.getAll()).single.id!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TransactionDetailScreen(recordId: id)),
      ),
    );
    await tester.pumpAndSettle();
    return id;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<FinancialRecord> stored(int id) => (db.select(
    db.financialRecords,
  )..where((r) => r.id.equals(id))).getSingle();

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'transfer links both endpoints, explicitly replaces and removes with cancellation',
    (tester) async {
      try {
        final id = await open(tester, RecordSubtype.mshwariDeposit);
        await tap(tester, find.byKey(const ValueKey('link.source.choose')));
        await tap(tester, find.byKey(ValueKey('link.choose.${wallet.id}')));
        await tap(
          tester,
          find.byKey(const ValueKey('link.destination.choose')),
        );
        await tap(tester, find.byKey(ValueKey('link.choose.${savings.id}')));
        expect((await stored(id)).sourceAccountId, wallet.id);
        expect((await stored(id)).destinationAccountId, savings.id);
        await tap(tester, find.byKey(const ValueKey('link.source.choose')));
        await tap(tester, find.byKey(ValueKey('link.choose.${savings.id}')));
        await tap(tester, find.text('Cancel'));
        expect((await stored(id)).sourceAccountId, wallet.id);
        await tap(tester, find.byKey(const ValueKey('link.source.choose')));
        await tap(tester, find.byKey(ValueKey('link.choose.${savings.id}')));
        await tap(tester, find.text('Replace'));
        expect((await stored(id)).sourceAccountId, savings.id);
        await tap(tester, find.byKey(const ValueKey('link.source.remove')));
        await tap(tester, find.text('Cancel'));
        expect((await stored(id)).sourceAccountId, savings.id);
        await tap(tester, find.byKey(const ValueKey('link.source.remove')));
        await tap(tester, find.text('Remove'));
        expect((await stored(id)).sourceAccountId, isNull);
        expect((await stored(id)).destinationAccountId, savings.id);
      } finally {
        await dispose(tester);
      }
    },
  );
  testWidgets(
    'income offers both explicit endpoints and picker excludes archived and legacy',
    (tester) async {
      try {
        await instruments.setArchived(wallet.uuid, true);
        await db.accountsDao.insertAccount(
          AccountsCompanion.insert(
            uuid: 'legacy',
            name: 'Legacy',
            type: 'wallet',
          ),
        );
        final id = await open(tester, RecordSubtype.receiveMoney);
        expect(
          find.byKey(const ValueKey('link.source.choose')),
          findsOneWidget,
        );
        await tap(
          tester,
          find.byKey(const ValueKey('link.destination.choose')),
        );
        expect(find.text('Wallet'), findsNothing);
        expect(find.text('Legacy'), findsNothing);
        await tap(tester, find.byKey(ValueKey('link.choose.${savings.id}')));
        expect((await stored(id)).destinationAccountId, savings.id);
      } finally {
        await dispose(tester);
      }
    },
  );
  testWidgets(
    'expense shows archived historical link and supports explicit removal',
    (tester) async {
      try {
        final id = await open(tester, RecordSubtype.sendMoney);
        await links.setLink(
          recordId: id,
          endpoint: InstrumentEndpoint.source,
          instrumentId: wallet.id,
          expectedCurrentId: null,
        );
        await instruments.setArchived(wallet.uuid, true);
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('link.source.choose')));
        expect(find.text('Wallet'), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Wallet (archived)'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('link.destination.choose')),
          findsOneWidget,
        );
        await tap(tester, find.byKey(const ValueKey('link.source.remove')));
        await tap(tester, find.text('Remove'));
        expect((await stored(id)).sourceAccountId, isNull);
      } finally {
        await dispose(tester);
      }
    },
  );
  testWidgets(
    'unresolved endpoints are never offered; legacy link remains removable',
    (tester) async {
      try {
        final id = await open(tester, RecordSubtype.unknown);
        expect(
          find.text('No supported instrument endpoints for this transaction.'),
          findsOneWidget,
        );
        await (db.update(
          db.financialRecords,
        )..where((r) => r.id.equals(id))).write(
          const FinancialRecordsCompanion(sourceAccountId: Value(900)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Existing account association (unconfirmed or unavailable)',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('link.source.choose')), findsNothing);
        await tap(tester, find.byKey(const ValueKey('link.source.remove')));
        await tap(tester, find.text('Remove'));
        expect((await stored(id)).sourceAccountId, isNull);
      } finally {
        await dispose(tester);
      }
    },
  );
  testWidgets(
    'stale picker selection reports failure without overwriting newer link',
    (tester) async {
      try {
        final id = await open(tester, RecordSubtype.sendMoney);
        await tap(tester, find.byKey(const ValueKey('link.source.choose')));
        await links.setLink(
          recordId: id,
          endpoint: InstrumentEndpoint.source,
          instrumentId: wallet.id,
          expectedCurrentId: null,
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(ValueKey('link.choose.${savings.id}')));
        expect(
          find.text('This association changed. Review it and try again.'),
          findsOneWidget,
        );
        expect((await stored(id)).sourceAccountId, wallet.id);
      } finally {
        await dispose(tester);
      }
    },
  );
}
