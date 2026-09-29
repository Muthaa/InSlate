import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/parsers/mpesa/account_transfer_parser.dart';

void main() {
  final classifier = MpesaMessageClassifier();
  final parser = AccountTransferParser();

  test('parses M-Shwari withdrawal', () {
    const body =
        'UFSNY9BQ1Z Confirmed.Ksh500.00 transferred from M-Shwari account '
        'on 28/6/26 at 2:48 PM. M-Shwari balance is Ksh1,500.24 .'
        'M-PESA balance is Ksh508.24 .Transaction cost Ksh.0.00';

    final message = RawMessage(
      id: 'test-mshwari-withdrawal',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 14, 48),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFSNY9BQ1Z');
  });

  test('parses M-Shwari deposit', () {
    const body =
        'UFSNY9AMQ5 Confirmed.Ksh2,000.00 transferred to M-Shwari account '
        'on 28/6/26 at 8:35 AM. M-PESA balance is Ksh13,969.24 .'
        'New M-Shwari saving account balance is Ksh2,000.24. '
        'Transaction cost Ksh.0.00';

    final message = RawMessage(
      id: 'test-mshwari-deposit',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 8, 35),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFSNY9AMQ5');
  });

  test('parses KCB M-PESA deposit', () {
    const body =
        'UFSNY9B1O3 Confirmed. Ksh2,000.00 transfered to KCB M-PESA account '
        'on 28/6/26 at 11:48 AM. New M-PESA balance is Ksh1,281.24, '
        'new KCB M-PESA Saving account balance is Ksh2,000.53.';

    final message = RawMessage(
      id: 'test-kcb-deposit',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 11, 48),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFSNY9B1O3');
  });

  test('parses KCB M-PESA withdrawal', () {
    const body =
        'UFSNY9BORW Confirmed. You have transfered Ksh500.00 from your '
        'KCB M-PESA account on 28/6/26 at 2:46 PM. KCB M-PESA Account '
        'balance is Ksh1,000.53. New M-PESA balance is Ksh2,881.24.';

    final message = RawMessage(
      id: 'test-kcb-withdrawal',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28, 14, 46),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFSNY9BORW');
  });
}
