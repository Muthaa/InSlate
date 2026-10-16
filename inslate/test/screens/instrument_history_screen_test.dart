import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/financial_instrument.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/instrument_history.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/repository_providers.dart';
import 'package:inslate/repositories/financial_instruments_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/repositories/instrument_links_repository.dart';
import 'package:inslate/screens/instruments/instrument_detail_screen.dart';
import 'package:inslate/widgets/transaction_row.dart';
import '../services/financial_summary_service_test.dart' show record;

class _Instruments extends FinancialInstrumentsRepository {
  int historyReads = 0;
  _Instruments(super.database);
  @override
  Future<InstrumentHistoryPage> history({
    required int accountId,
    required FinancialPeriod period,
    int page = 0,
  }) {
    historyReads++;
    return super.history(accountId: accountId, period: period, page: page);
  }
}

void main() {
  late AppDatabase db;
  late _Instruments instruments;
  late FinancialInstrument instrument, other;
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final previous = DateTime(now.year, now.month - 1);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    instruments = _Instruments(db);
    instrument = await instruments.create(
      name: 'My instrument',
      type: InstrumentType.mobileWallet,
    );
    other = await instruments.create(
      name: 'Other instrument',
      type: InstrumentType.mobileWallet,
    );
  });
  tearDown(() => db.close());
  Future<void> seed(int count, DateTime date, {bool selfLinked = false}) async {
    final records = FinancialRecordsRepository(db);
    await records.saveAll(
      List.generate(
        count,
        (_) => record(
          selfLinked ? RecordSubtype.mshwariDeposit : RecordSubtype.sendMoney,
          10,
          receivedAt: date,
        ),
      ),
    );
    await (db.update(db.financialRecords)..where(
          (r) => r.sourceAccountId.isNull() & r.destinationAccountId.isNull(),
        ))
        .write(
          FinancialRecordsCompanion(
            sourceAccountId: Value(instrument.id),
            destinationAccountId: Value(selfLinked ? instrument.id : null),
          ),
        );
  }

  Future<void> open(WidgetTester tester, {String? uuid}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          financialInstrumentsRepositoryProvider.overrideWithValue(instruments),
        ],
        child: MaterialApp(
          home: InstrumentDetailScreen(uuid: uuid ?? instrument.uuid),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (uuid == null) {
      final section = find.byKey(const ValueKey('instrument.history.period'));
      if (section.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          section,
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await Scrollable.ensureVisible(tester.element(section));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
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

  Future<void> selectPrevious(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('instrument.history.period')));
    await tap(tester, find.text(DateFormat.yMMMM().format(previous)).last);
  }

  void screenTest(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      });
  screenTest(
    'archived history displays distinct source destination self roles and opens persisted transaction',
    (tester) async {
      await seed(3, month, selfLinked: true);
      final rows = await db.financialRecordsDao.getAllRecords();
      await (db.update(
        db.financialRecords,
      )..where((r) => r.id.equals(rows[0].id))).write(
        const FinancialRecordsCompanion(destinationAccountId: Value(null)),
      );
      await (db.update(db.financialRecords)
            ..where((r) => r.id.equals(rows[1].id)))
          .write(const FinancialRecordsCompanion(sourceAccountId: Value(null)));
      await instruments.setArchived(instrument.uuid, true);
      await open(tester);
      expect(find.text('3 linked transactions'), findsOneWidget);
      expect(find.textContaining('Outgoing (source)'), findsOneWidget);
      expect(find.textContaining('Incoming (destination)'), findsOneWidget);
      expect(
        find.textContaining('Self-linked (source and destination)'),
        findsOneWidget,
      );
      await tap(tester, find.byType(TransactionRow).first);
      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.text('My instrument (archived)'), findsNWidgets(2));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('3 linked transactions'), findsOneWidget);
    },
  );
  screenTest(
    'period selection resets page and exact counts bound rendered rows to fifty',
    (tester) async {
      await seed(51, month);
      await seed(2, previous);
      await open(tester);
      expect(find.text('51 linked transactions'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(50));
      await tap(tester, find.text('Next'));
      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(find.byType(TransactionRow), findsOneWidget);
      await selectPrevious(tester);
      expect(find.text('2 linked transactions'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNWidgets(2));
    },
  );
  screenTest(
    'return preserves period and valid page then clamps after last link removal',
    (tester) async {
      await seed(1, month);
      await seed(52, previous);
      await open(tester);
      await selectPrevious(tester);
      await tap(tester, find.text('Next'));
      expect(find.text('Page 2 of 2'), findsOneWidget);
      for (var removal = 0; removal < 2; removal++) {
        await tap(tester, find.byType(TransactionRow).first);
        await tap(tester, find.byKey(const ValueKey('link.source.remove')));
        await tap(tester, find.text('Remove'));
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text(DateFormat.yMMMM().format(previous)), findsOneWidget);
        expect(
          find.text('${51 - removal} linked transactions'),
          findsOneWidget,
        );
        expect(
          find.text(removal == 0 ? 'Page 2 of 2' : 'Page 1 of 1'),
          findsOneWidget,
        );
      }
      expect(find.byType(TransactionRow), findsNWidgets(50));
      // The corrected page remains selected even if another link is added
      // while a subsequent transaction detail route is open.
      await tap(tester, find.byType(TransactionRow).first);
      final removed = (await db.financialRecordsDao.getAllRecords()).firstWhere(
        (r) => r.sourceAccountId == null,
      );
      await InstrumentLinksRepository(db).setLink(
        recordId: removed.id,
        endpoint: InstrumentEndpoint.source,
        instrumentId: instrument.id,
        expectedCurrentId: null,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('51 linked transactions'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);
    },
  );
  screenTest(
    'explicit replacement removes row and retains selected empty period',
    (tester) async {
      await seed(1, previous);
      await open(tester);
      expect(
        find.text('No linked transactions in this period.'),
        findsOneWidget,
      );
      await selectPrevious(tester);
      await tap(tester, find.byType(TransactionRow).first);
      await tap(tester, find.byKey(const ValueKey('link.source.choose')));
      await tap(tester, find.byKey(ValueKey('link.choose.${other.id}')));
      await tap(tester, find.text('Replace'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.yMMMM().format(previous)), findsOneWidget);
      expect(find.text('0 linked transactions'), findsOneWidget);
      expect(find.byType(TransactionRow), findsNothing);
      expect(
        find.text('No linked transactions in this period.'),
        findsOneWidget,
      );
    },
  );
  screenTest(
    'unconfirmed or missing instrument has no history section or queries',
    (tester) async {
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          uuid: 'legacy',
          name: 'Legacy',
          type: 'wallet',
        ),
      );
      await open(tester, uuid: 'legacy');
      expect(find.text('Instrument is no longer available.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('instrument.history.period')),
        findsNothing,
      );
      expect(instruments.historyReads, 0);
    },
  );
}
