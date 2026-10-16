import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_cursor.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  late AppDatabase db;
  late FinancialRecordsRepository repository;
  final filter = ActivityFilter(
    period: FinancialPeriod.month(DateTime(2026, 9)),
  );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinancialRecordsRepository(db);
  });
  tearDown(() => db.close());

  test(
    'cursor crosses equal timestamps and insertions without skips or duplicates',
    () async {
      await repository.saveAll([
        for (var i = 0; i < 123; i++)
          record(
            RecordSubtype.sendMoney,
            i.toDouble(),
            date: i.isEven ? null : DateTime(2026, 9, 10),
          ),
      ]);
      final first = await repository.getActivity(filter, limit: 50);
      expect(first, hasLength(50));
      await repository.save(record(RecordSubtype.sendMoney, 999));
      final second = await repository.getActivity(
        filter,
        limit: 50,
        before: ActivityCursor.fromRecord(first.last),
      );
      final third = await repository.getActivity(
        filter,
        limit: 50,
        before: ActivityCursor.fromRecord(second.last),
      );
      final ids = [...first, ...second, ...third].map((r) => r.id!).toList();
      expect(ids, hasLength(123));
      expect(ids.toSet(), hasLength(123));
      expect(ids, orderedEquals(List.generate(123, (i) => 123 - i)));
      expect(await repository.countActivity(filter), 124);
      expect(db.schemaVersion, 11);
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT id FROM financial_records WHERE COALESCE(transaction_date, received_at) < 9999999999 ORDER BY COALESCE(transaction_date, received_at) DESC, id DESC LIMIT 50',
          )
          .get();
      expect(
        plan.map((r) => r.data.values.join(' ')).join(' '),
        contains('financial_activity_cursor_idx'),
      );
    },
  );

  test(
    'numeric search accepts currency and formatting, partial decimals and no unrelated amounts',
    () async {
      await repository.saveAll([
        for (final amount in [
          500.0,
          500.25,
          1500.0,
          1500.05,
          1500.15,
          5000.0,
          15.0,
        ])
          record(RecordSubtype.sendMoney, amount),
      ]);
      for (final term in ['1,500', 'KSh 1500', '1500']) {
        final f = filter.withSearch(term);
        expect((await repository.getActivity(f)).map((r) => r.amount).toSet(), {
          1500.0,
          1500.05,
          1500.15,
        });
        expect(await repository.countActivity(f), 3);
      }
      expect(
        (await repository.getActivity(
          filter.withSearch('500'),
        )).map((r) => r.amount).toSet(),
        {500.0, 500.25},
      );
      expect(
        (await repository.getActivity(
          filter.withSearch('1500.0'),
        )).map((r) => r.amount).toSet(),
        {1500.0, 1500.05},
      );
      expect(
        (await repository.getActivity(
          filter.withSearch('1500.00'),
        )).single.amount,
        1500,
      );
      for (final term in ['1,50', '1500.000', 'KSh', '1500 OR 1=1']) {
        expect(await repository.countActivity(filter.withSearch(term)), 0);
      }
    },
  );

  test(
    'amount filtering precedes cursor/count and composes with identity and text search',
    () async {
      const party = Party(name: 'Alice', type: PartyType.person);
      await repository.saveAll([
        for (var i = 0; i < 103; i++)
          record(RecordSubtype.sendMoney, 1500, party: party),
        record(
          RecordSubtype.sendMoney,
          9,
          party: const Party(name: 'KSh 1500 seller', type: PartyType.person),
        ),
        record(RecordSubtype.receiveMoney, 1500, party: party),
        record(
          RecordSubtype.sendMoney,
          1500,
          party: party,
          date: DateTime(2026, 8),
        ),
      ]);
      final f = ActivityFilter(
        period: filter.period,
        search: '1500.00',
        scope: ActivityScope.expenses,
        party: PartyIdentity.fromParty(party),
      );
      final first = await repository.getActivity(f, limit: 50);
      final second = await repository.getActivity(
        f,
        limit: 50,
        before: ActivityCursor.fromRecord(first.last),
      );
      final third = await repository.getActivity(
        f,
        limit: 50,
        before: ActivityCursor.fromRecord(second.last),
      );
      expect(
        [...first, ...second, ...third].map((r) => r.id).toSet(),
        hasLength(103),
      );
      expect(await repository.countActivity(f), 103);
      expect(
        await repository.countActivity(filter.withSearch('KSh 1500')),
        105,
      );
    },
  );
}
