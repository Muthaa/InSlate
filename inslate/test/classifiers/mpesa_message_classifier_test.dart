import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';

import 'package:inslate/core/enums/record_subtype.dart';

import 'package:inslate/core/enums/transaction_status.dart';

import '../helpers/fixture_loader.dart';

void main() {
  final classifier = MpesaMessageClassifier();

  const cytonn =
      'TA615JJ2Y7 Confirmed.You have received Ksh15,000.00 from '
      'CYTONN MONEY MARKET FUND.788032 on 6/1/25 at 9:32 AM '
      'New M-PESA balance is Ksh15,285.06.';

  const etica =
      'TKJNYAJ5A1 Confirmed.You have received Ksh2,980.00 from  '
      'ETICA CAPITAL LTD   3036873 on 19/11/25 at 8:43 AM '
      'New M-PESA balance is Ksh3,681.30.';

  const suluhu =
      'TBI3IS5D3B Confirmed.You have received Ksh4,600.00 from '
      'SULUHU SAVINGS AND CREDIT CO-OPERATIVE SOCIETY LIMITED. '
      '718416 on 18/2/25 at 2:28 PM '
      'New M-PESA balance is Ksh4,763.06.';

  test('classifies investment purchase before generic PayBill', () {
    const body =
        'UFSNY9B1NP Confirmed. Ksh2,000.00 sent to CYTONN MONEY MARKET FUND '
        'for account ACC12345 on 28/6/26 at 11:47 AM. '
        'New M-PESA balance is Ksh3,281.24.';

    final result = classifier.classify(body);

    expect(result.subtype, RecordSubtype.investmentPurchase);
    expect(result.status, TransactionStatus.successful);
  });

  test('classifies Cytonn redemption before generic receive money', () {
    final result = classifier.classify(cytonn);

    expect(result.subtype, RecordSubtype.investmentRedemption);
    expect(result.status, TransactionStatus.successful);
  });

  test('classifies Etica redemption before generic receive money', () {
    final result = classifier.classify(etica);

    expect(result.subtype, RecordSubtype.investmentRedemption);
    expect(result.status, TransactionStatus.successful);
  });

  test('classifies Suluhu redemption before generic receive money', () {
    final result = classifier.classify(suluhu);

    expect(result.subtype, RecordSubtype.investmentRedemption);
    expect(result.status, TransactionStatus.successful);
  });

  test(
    'does not classify investment promo footer as investment redemption',
    () {
      const body =
          'UJ38B91CKT Confirmed.You have received Ksh1,000.00 from '
          'TEST USER 0700***000 on 3/10/26 at 6:25 AM '
          'New M-PESA balance is Ksh1,000.00. '
          'Invest & earn daily interest with ZIIDI on https://saf.cx/cF6ir';

      final result = classifier.classify(body);

      expect(result.subtype, RecordSubtype.receiveMoney);
      expect(result.status, TransactionStatus.successful);
    },
  );

  test('Classifies Send Money', () {
    final messages = FixtureLoader.load('send_money.txt');

    for (final sms in messages) {
      final result = classifier.classify(sms);

      expect(result.subtype, RecordSubtype.sendMoney);
    }
  });
}
