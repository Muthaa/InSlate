import 'package:inslate/core/enums/record_subtype.dart';
import '../helpers/classifier_test_runner.dart';

void main() {
  ClassifierTestRunner.run(
    fixture: 'send_money.txt',
    expectedSubtype: RecordSubtype.sendMoney,
  );

  ClassifierTestRunner.run(
    fixture: 'receive_money.txt',
    expectedSubtype: RecordSubtype.receiveMoney,
  );

  ClassifierTestRunner.run(
    fixture: 'buy_goods.txt',
    expectedSubtype: RecordSubtype.buyGoods,
  );

  ClassifierTestRunner.run(
    fixture: 'paybill.txt',
    expectedSubtype: RecordSubtype.payBill,
  );

  ClassifierTestRunner.run(
    fixture: 'withdraw_agent.txt',
    expectedSubtype: RecordSubtype.withdrawal,
  );

  ClassifierTestRunner.run(
    fixture: 'deposit_agent.txt',
    expectedSubtype: RecordSubtype.deposit,
  );

  ClassifierTestRunner.run(
    fixture: 'mshwari_deposit.txt',
    expectedSubtype: RecordSubtype.mshwariDeposit,
  );

  ClassifierTestRunner.run(
    fixture: 'mshwari_withdrawal.txt',
    expectedSubtype: RecordSubtype.mshwariWithdrawal,
  );

  ClassifierTestRunner.run(
    fixture: 'kcb_deposit.txt',
    expectedSubtype: RecordSubtype.kcbDeposit,
  );

  ClassifierTestRunner.run(
    fixture: 'kcb_withdrawal.txt',
    expectedSubtype: RecordSubtype.kcbWithdrawal,
  );

  // We'll expand this as we split fixtures by subtype.
  ClassifierTestRunner.run(
    fixture: 'fuliza_loan.txt',
    expectedSubtype: RecordSubtype.fulizaLoan,
  );

  ClassifierTestRunner.run(
    fixture: 'fuliza_repayment.txt',
    expectedSubtype: RecordSubtype.fulizaRepayment,
  );
}
