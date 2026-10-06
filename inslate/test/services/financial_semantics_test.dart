import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/services/financial_semantics.dart';
import 'financial_summary_service_test.dart' show record;

void main() {
  const semantics = FinancialSemantics();
  test('principal classes are exclusive and all recorded fees count once', () {
    final totals = semantics.calculate([
      record(RecordSubtype.receiveMoney, 1000),
      record(RecordSubtype.sendMoney, 200, fee: 10),
      record(RecordSubtype.mshwariDeposit, 300, fee: 3),
      record(RecordSubtype.investmentPurchase, 70, fee: 2),
      record(RecordSubtype.investmentRedemption, 80),
      record(RecordSubtype.fulizaLoan, 613, fee: 6.13),
      record(RecordSubtype.fulizaRepayment, 100),
      record(RecordSubtype.unknown, 999, fee: 1),
    ]);
    expect(totals.received, 1000);
    expect(totals.sent, 200);
    expect(totals.expenses, 200);
    expect(totals.income, 1000);
    expect(totals.fees, closeTo(22.13, 0.000001));
    expect(totals.netCashFlow, closeTo(777.87, 0.000001));
    expect(totals.transfersFromCentral, 370);
    expect(totals.transfersIntoCentral, 80);
    expect(totals.borrowed, 613);
    expect(totals.repaid, 100);
  });

  test('every subtype has an explicit outcome', () {
    const expected = {
      RecordSubtype.sendMoney: MovementClass.expense,
      RecordSubtype.receiveMoney: MovementClass.income,
      RecordSubtype.withdrawal: MovementClass.expense,
      RecordSubtype.deposit: MovementClass.income,
      RecordSubtype.buyGoods: MovementClass.expense,
      RecordSubtype.payBill: MovementClass.expense,
      RecordSubtype.mshwariDeposit: MovementClass.internalTransfer,
      RecordSubtype.mshwariWithdrawal: MovementClass.internalTransfer,
      RecordSubtype.kcbDeposit: MovementClass.internalTransfer,
      RecordSubtype.kcbWithdrawal: MovementClass.internalTransfer,
      RecordSubtype.fulizaLoan: MovementClass.loanBorrowing,
      RecordSubtype.fulizaRepayment: MovementClass.loanRepayment,
      RecordSubtype.investmentPurchase: MovementClass.internalTransfer,
      RecordSubtype.investmentRedemption: MovementClass.internalTransfer,
      RecordSubtype.airtimePurchase: MovementClass.expense,
      RecordSubtype.airtimeTopUp: MovementClass.expense,
      RecordSubtype.loanRepayment: MovementClass.loanRepayment,
      RecordSubtype.loanDisbursement: MovementClass.loanBorrowing,
      RecordSubtype.savingsDeposit: MovementClass.unresolved,
      RecordSubtype.savingsWithdrawal: MovementClass.unresolved,
      RecordSubtype.billPayment: MovementClass.unresolved,
      RecordSubtype.unknown: MovementClass.unresolved,
    };
    expect(expected.keys.toSet(), RecordSubtype.values.toSet());
    for (final entry in expected.entries) {
      final item = record(entry.key, 10, fee: 1);
      expect(semantics.classify(item), entry.value, reason: entry.key.name);
      final totals = semantics.calculate([item]);
      expect(totals.fees, 1);
      if (entry.value == MovementClass.internalTransfer) {
        expect(
          totals.received +
              totals.sent +
              totals.income +
              totals.expenses +
              totals.borrowed +
              totals.repaid,
          0,
        );
        expect(totals.internalTransfers, 10);
        expect(totals.netCashFlow, -1);
      }
    }
  });

  test('direction is relative to a supplied central account', () {
    final movement = semantics.movement(
      record(RecordSubtype.mshwariDeposit, 10),
    );
    expect(
      movement.relativeTo(const AccountEndpoint(AccountType.mpesa)),
      TransferDirection.fromCentral,
    );
    expect(
      movement.relativeTo(const AccountEndpoint(AccountType.mshwariSavings)),
      TransferDirection.intoCentral,
    );
    expect(
      movement.relativeTo(const AccountEndpoint(AccountType.kcbMpesa)),
      TransferDirection.unrelated,
    );
    expect(
      const AccountMovement().relativeTo(
        const AccountEndpoint(AccountType.mpesa),
      ),
      TransferDirection.unresolved,
    );
  });

  test('inconsistent stored type is unresolved instead of double counted', () {
    final item = record(
      RecordSubtype.investmentPurchase,
      100,
      type: FinancialRecordType.expense,
    );
    expect(semantics.classify(item), MovementClass.unresolved);
    expect(semantics.calculate([item]).expenses, 0);
    expect(semantics.movement(item).source, isNull);
  });

  test('unknown account identity stays unresolved; cash is not savings', () {
    const movement = AccountMovement(
      source: AccountEndpoint(AccountType.mpesa),
      destination: AccountEndpoint(AccountType.cash),
    );
    expect(
      movement.relativeTo(
        const AccountEndpoint(
          AccountType.mpesa,
          identity: PartyIdentity(PartyIdentityKind.account, 'specific'),
        ),
      ),
      TransferDirection.unresolved,
    );
    expect(
      const SubtypeSemantics(
        MovementClass.internalTransfer,
        FinancialRecordType.transfer,
        source: AccountType.mpesa,
        destination: AccountType.cash,
      ).isSavingsOrInvestment,
      isFalse,
    );
  });

  test('party identity preserves precedence, normalization and separation', () {
    const party = Party(
      name: 'Alice',
      type: PartyType.person,
      identifier: ' ABC ',
      phone: '123',
    );
    expect(
      PartyIdentity.fromParty(party),
      const PartyIdentity(PartyIdentityKind.identifier, 'abc'),
    );
    expect(
      PartyIdentity.fromParty(
        const Party(name: 'Alice', type: PartyType.person, phone: ' 123 '),
      ),
      const PartyIdentity(PartyIdentityKind.phone, '123'),
    );
    expect(
      PartyIdentity.fromParty(
        const Party(name: 'Alice', type: PartyType.person, account: ' XYZ '),
      ),
      const PartyIdentity(PartyIdentityKind.account, 'xyz'),
    );
    expect(
      PartyIdentity.fromParty(
        const Party(name: ' Alice ', type: PartyType.person),
      ),
      const PartyIdentity(
        PartyIdentityKind.name,
        'alice',
        type: PartyType.person,
      ),
    );
    final movement = semantics.movement(
      record(RecordSubtype.investmentPurchase, 5, party: party),
    );
    expect(movement.destination!.identity, PartyIdentity.fromParty(party));
  });
}
