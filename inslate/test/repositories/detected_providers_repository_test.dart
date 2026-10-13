import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:inslate/core/constants/instrument_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/repositories/detected_providers_repository.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  test(
    'provider recognition reuses identity, reconciles Activity and never registers or links accounts',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final records = FinancialRecordsRepository(db);
        await records.saveAll([
          record(
            RecordSubtype.investmentPurchase,
            100,
            party: const Party(
              name: 'Fund',
              type: PartyType.business,
              identifier: 'FUND',
              account: 'one',
            ),
          ),
          record(
            RecordSubtype.investmentRedemption,
            20,
            party: const Party(
              name: 'Renamed Fund',
              type: PartyType.business,
              identifier: 'fund',
              account: 'two',
            ),
          ),
          record(
            RecordSubtype.investmentPurchase,
            30,
            party: const Party(
              name: 'Fund',
              type: PartyType.business,
              identifier: 'other',
            ),
          ),
          record(RecordSubtype.investmentPurchase, 40),
          record(
            RecordSubtype.investmentPurchase,
            50,
            type: FinancialRecordType.expense,
            party: const Party(name: 'Wrong type', type: PartyType.business),
          ),
          record(RecordSubtype.mshwariDeposit, 60),
          record(RecordSubtype.mshwariWithdrawal, 10),
          record(RecordSubtype.kcbDeposit, 70),
          record(
            RecordSubtype.receiveMoney,
            80,
            party: const Party(name: 'Not a provider', type: PartyType.person),
          ),
        ]);
        final providers = await DetectedProvidersRepository(db).watch().first;
        expect(providers.length, 5);
        expect(providers.map((p) => p.count).toList()..sort(), [1, 1, 1, 1, 2]);
        for (final provider in providers) {
          final matching = await records.getActivity(
            provider.filter,
            limit: 50,
          );
          expect(matching.length, provider.count);
        }
        expect(await db.select(db.accounts).get(), isEmpty);
        final persisted = await db.select(db.financialRecords).get();
        expect(persisted.length, 9);
        expect(
          persisted.every(
            (r) => r.sourceAccountId == null && r.destinationAccountId == null,
          ),
          isTrue,
        );
      } finally {
        await db.close();
      }
    },
  );
  test(
    'SQL provider pages keep all references and aliases of one provider together',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final records = FinancialRecordsRepository(db);
        for (var i = 0; i < 25; i++) {
          await records.save(
            record(
              RecordSubtype.investmentPurchase,
              10,
              party: Party(
                name: 'Fund ${i.toString().padLeft(2, '0')}',
                type: PartyType.business,
                account: 'one',
              ),
            ),
          );
        }
        await records.save(
          record(
            RecordSubtype.investmentPurchase,
            20,
            party: const Party(
              name: 'FUND 00',
              type: PartyType.business,
              account: 'two',
            ),
          ),
        );
        final repository = DetectedProvidersRepository(db);
        final first = await repository.watch(page: 0).first;
        final second = await repository.watch(page: 1).first;
        expect(
          first.map((p) => p.name.toLowerCase()).toSet(),
          hasLength(21),
        ); // one look-ahead provider
        expect(
          first
              .where((p) => p.name.toLowerCase() == 'fund 00')
              .map((p) => p.providerReference!.reference)
              .toSet(),
          {'one', 'two'},
        );
        expect(second.map((p) => p.name.toLowerCase()).toSet(), {
          'fund 20',
          'fund 21',
          'fund 22',
          'fund 23',
          'fund 24',
        });
      } finally {
        await db.close();
      }
    },
  );
  test(
    'paged discovery retains named savings families without a reported party',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.mshwariDeposit, 10),
          record(RecordSubtype.kcbWithdrawal, 20),
        ]);
        final providers = await DetectedProvidersRepository(
          db,
        ).watch(page: 0).first;
        expect(providers.map((p) => p.name).toSet(), {
          'M-Shwari',
          'KCB M-PESA',
        });
      } finally {
        await db.close();
      }
    },
  );
  test(
    'catalogue recognition of old payments creates review tasks without financial reclassification',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final provider = InstrumentCatalogue.providers.first.name;
        await db
            .into(db.financialRecords)
            .insert(
              FinancialRecordsCompanion.insert(
                reference: 'old-payment',
                receivedAt: DateTime(2026, 1, 1),
                amount: 75,
                type: 'expense',
                subtype: 'payBill',
                status: 'successful',
                title: 'Payment',
                rawMessage: 'fixture',
                partyName: Value(provider),
                partyAccount: const Value('one'),
              ),
            );
        final groups = await DetectedProvidersRepository(
          db,
        ).watch(page: 0).first;
        expect(groups, hasLength(1));
        expect(groups.single.unspecified, isFalse);
        expect(groups.single.reviewSubtype, RecordSubtype.payBill);
        expect(groups.single.count, 1);
        expect(
          await FinancialRecordsRepository(
            db,
          ).countActivity(groups.single.filter),
          1,
        );
        final stored = await db.select(db.financialRecords).getSingle();
        expect(stored.type, 'expense');
        expect(stored.subtype, 'payBill');
        expect(stored.interpretedType, isNull);
        expect(stored.destinationAccountId, isNull);
        expect(await db.select(db.accounts).get(), isEmpty);
      } finally {
        await db.close();
      }
    },
  );
}
