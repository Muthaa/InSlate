import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/parsers/mpesa/fuliza_parser.dart';

void main() {
  final classifier = MpesaMessageClassifier();
  final parser = FulizaParser();

  test('parses real Fuliza loan message', () {
    const body =
        'UFQNY935Z8 Confirmed. Fuliza M-PESA amount is Ksh 613.00. '
        'Access Fee charged Ksh 6.13. Total Fuliza M-PESA outstanding '
        'amount is Ksh889.36 due on 26/07/26. To check daily charges, '
        'Dial *334#OK Select Query Charges';

    final message = RawMessage(
      id: 'test-fuliza-loan',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 7, 26),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFQNY935Z8');
    expect(result.record!.amount, 613.00);
    expect(result.record!.transactionCost, 6.13);
  });

  test('parses real Fuliza repayment message', () {
    const body =
        'UFSNY9AMDQ Confirmed. Ksh 1030.76 from your M-PESA has been '
        'used to fully pay your outstanding Fuliza M-PESA. Available '
        'Fuliza M-PESA limit is Ksh 2800.00. Your M-PESA balance is 13969.24.';

    final message = RawMessage(
      id: 'test-fuliza-repayment',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 6, 28),
    );

    final classification = classifier.classify(body);
    final result = parser.parse(message, classification);

    expect(result.success, isTrue);
    expect(result.record, isNotNull);
    expect(result.record!.reference, 'UFSNY9AMDQ');
    expect(result.record!.amount, 1030.76);
  });
}
