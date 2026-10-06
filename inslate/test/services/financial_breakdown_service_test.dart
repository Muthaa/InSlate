import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/services/financial_breakdown_service.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'financial_summary_service_test.dart' show record;

void main() {
  final period = FinancialPeriod.month(DateTime(2026, 9));
  const service = FinancialBreakdownService();
  const alice = Party(
    name: 'Same name',
    type: PartyType.person,
    identifier: ' A ',
  );
  const bob = Party(name: 'Same name', type: PartyType.person, identifier: 'b');
  const fund = Party(name: 'Fund', type: PartyType.self, account: ' 123 ');
  final records = [
    record(RecordSubtype.receiveMoney, 1000, party: alice),
    record(RecordSubtype.deposit, 100),
    record(RecordSubtype.sendMoney, 200, fee: 10, party: alice),
    record(RecordSubtype.buyGoods, 300, fee: 5, party: bob),
    record(RecordSubtype.sendMoney, 50),
    record(RecordSubtype.mshwariDeposit, 80, fee: 2),
    record(RecordSubtype.mshwariWithdrawal, 30),
    record(RecordSubtype.kcbDeposit, 70),
    record(RecordSubtype.kcbWithdrawal, 20),
    record(RecordSubtype.investmentPurchase, 60, party: fund),
    record(RecordSubtype.investmentRedemption, 10, party: fund),
    record(RecordSubtype.fulizaLoan, 613, fee: 6.13),
    record(RecordSubtype.fulizaRepayment, 100),
    record(RecordSubtype.loanDisbursement, 50),
    record(RecordSubtype.loanRepayment, 20),
    record(RecordSubtype.savingsDeposit, 999, fee: 1),
  ];

  test(
    'four capital movement breakdowns separate instruments and directions',
    () {
      final summary = service.dashboard(records, period);
      for (final expected in {
        BreakdownKind.investmentPurchases: 60.0,
        BreakdownKind.investmentRedemptions: 10.0,
        BreakdownKind.savingsDeposits: 150.0,
        BreakdownKind.savingsWithdrawals: 50.0,
      }.entries) {
        final breakdown = summary.breakdown(expected.key);
        expect(breakdown.amount, expected.value);
        expect(breakdown.filter.period, period);
      }
      final deposits = summary.breakdown(BreakdownKind.savingsDeposits);
      expect(
        deposits.groups.map((group) => group.filter.endpoint!.type).toSet(),
        {AccountType.mshwariSavings, AccountType.kcbMpesa},
      );
      expect(
        deposits.groups.every(
          (group) => group.filter.direction == TransferDirection.fromCentral,
        ),
        isTrue,
      );
      expect(
        summary
            .breakdown(BreakdownKind.investmentRedemptions)
            .groups
            .single
            .filter
            .direction,
        TransferDirection.intoCentral,
      );
    },
  );

  test('Dashboard headlines use principal and each fee exactly once', () {
    final summary = service.dashboard(records, period);
    expect(summary.totals.income, 1100);
    expect(summary.totals.received, 1100);
    expect(summary.totals.expenses, 550);
    expect(summary.totals.sent, 550);
    expect(summary.totals.fees, closeTo(24.13, 0.0001));
    expect(summary.totals.netCashFlow, closeTo(525.87, 0.0001));
    expect(summary.totals.internalTransfers, 270);
    expect(summary.totals.borrowed, 663);
    expect(summary.totals.repaid, 120);
  });

  test('income category shares reconcile to income principal', () {
    final income = service
        .dashboard(records, period)
        .breakdown(BreakdownKind.incomeCategories);
    expect(income.amount, 1100);
    expect(
      income.groups.fold<double>(0, (sum, group) => sum + group.share),
      closeTo(1, 0.0001),
    );
    expect(income.groups.map((group) => group.filter.subtype).toSet(), {
      RecordSubtype.receiveMoney,
      RecordSubtype.deposit,
    });
    expect(income.groups.first.amount, 1000);
  });

  test('spending shares reconcile to expense principal, excluding fees', () {
    final spending = service
        .dashboard(records, period)
        .breakdown(BreakdownKind.spending);
    expect(spending.amount, 550);
    expect(spending.fees, 15);
    expect(spending.count, 3);
    final sent = spending.groups.singleWhere(
      (group) => group.filter.subtype == RecordSubtype.sendMoney,
    );
    expect(sent.amount, 250);
    expect(sent.share, closeTo(250 / 550, 0.0001));
    expect(
      spending.groups.fold<double>(0, (sum, group) => sum + group.share),
      closeTo(1, 0.0001),
    );
  });

  test(
    'party breakdown separates equal names and includes unidentified records truthfully',
    () {
      final expenses = service
          .dashboard(records, period)
          .breakdown(BreakdownKind.expenseParties);
      expect(expenses.amount, 550);
      expect(expenses.groups, hasLength(3));
      expect(
        expenses.groups
            .map((group) => group.filter.party)
            .whereType<PartyIdentity>()
            .toSet(),
        {PartyIdentity.fromParty(alice), PartyIdentity.fromParty(bob)},
      );
      final anonymous = expenses.groups.singleWhere(
        (group) => group.filter.partyPresence == PartyPresence.unidentified,
      );
      expect(anonymous.amount, 50);
      expect(records.where(anonymous.filter.matches).single.amount, 50);
      final income = service
          .dashboard(records, period)
          .breakdown(BreakdownKind.incomeParties);
      expect(income.amount, 1100);
    },
  );

  test(
    'internal groups include savings and investment directions, excluding unknown totals',
    () {
      final internal = service
          .dashboard(records, period)
          .breakdown(BreakdownKind.internalMovement);
      expect(internal.amount, 270);
      expect(internal.sections[0].label, 'Into M-PESA');
      expect(internal.sections[0].amount, 60);
      expect(internal.sections[1].label, 'From M-PESA');
      expect(internal.sections[1].amount, 210);
      expect(
        internal.sections[0].groups
            .map((group) => group.filter.endpoint!.type)
            .toSet(),
        {
          AccountType.mshwariSavings,
          AccountType.kcbMpesa,
          AccountType.investment,
        },
      );
      expect(internal.sections.last.includedInTotal, isFalse);
      expect(internal.sections.last.amount, 999);
      expect(
        internal.sections.last.groups.single.filter.resolution,
        SemanticResolution.unresolved,
      );
    },
  );

  test(
    'loans separate borrowed/repaid; investments retain provider identity',
    () {
      final summary = service.dashboard(records, period);
      final loans = summary.breakdown(BreakdownKind.loans);
      expect(loans.sections.map((section) => section.label), [
        'Borrowed',
        'Repaid',
      ]);
      expect(loans.sections.map((section) => section.amount), [663, 120]);
      final savings = summary.breakdown(BreakdownKind.investmentsAndSavings);
      expect(savings.sections[0].label, 'Savings');
      expect(savings.sections[0].amount, 200);
      expect(savings.sections[1].label, 'Investments');
      expect(savings.sections[1].amount, 70);
      expect(
        savings.sections[1].groups.every(
          (group) =>
              group.filter.endpoint!.identity == PartyIdentity.fromParty(fund),
        ),
        isTrue,
      );
    },
  );

  test('every group filter selects exactly its principal, fees and count', () {
    for (final kind in BreakdownKind.values) {
      final breakdown = service.dashboard(records, period).breakdown(kind);
      for (final group in breakdown.sections.expand(
        (section) => section.groups,
      )) {
        final selected = records.where(group.filter.matches).toList();
        expect(
          selected.fold<double>(0, (sum, record) => sum + record.amount),
          group.amount,
          reason: '$kind ${group.label}',
        );
        expect(
          selected.fold<double>(
            0,
            (sum, record) => sum + record.transactionCost,
          ),
          group.fees,
        );
        expect(selected.length, group.count);
        expect(group.filter.period, period);
      }
    }
  });

  test('mismatched stored investment type stays unresolved', () {
    final summary = service.dashboard([
      record(
        RecordSubtype.investmentPurchase,
        500,
        type: FinancialRecordType.expense,
      ),
    ], period);
    expect(summary.totals.expenses, 0);
    expect(summary.totals.internalTransfers, 0);
    expect(
      summary
          .breakdown(BreakdownKind.investmentsAndSavings)
          .sections
          .last
          .includedInTotal,
      isFalse,
    );
  });

  test(
    'unidentified investment provider never includes identified providers',
    () {
      final mixed = [
        record(RecordSubtype.investmentPurchase, 60, party: fund),
        record(RecordSubtype.investmentPurchase, 40),
      ];
      final breakdown = service
          .dashboard(mixed, period)
          .breakdown(BreakdownKind.investmentsAndSavings);
      final anonymous = breakdown.groups.singleWhere(
        (group) => group.filter.partyPresence == PartyPresence.unidentified,
      );
      expect(anonymous.amount, 40);
      expect(mixed.where(anonymous.filter.matches).single.amount, 40);
    },
  );
}
