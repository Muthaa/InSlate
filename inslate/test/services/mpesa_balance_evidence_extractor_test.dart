import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/services/mpesa_balance_evidence_extractor.dart';

void main() {
  final extractor = MpesaBalanceEvidenceExtractor();
  final receipt = DateTime.utc(2026, 6, 28, 9, 1, 2, 345);
  RawMessage message(String body, {String sender = 'MPESA'}) =>
      RawMessage(id: 'sms-1', sender: sender, body: body, receivedAt: receipt);
  final fixtures = {
    'send_money': 328124,
    'receive_money': 100000,
    'buy_goods': 0,
    'paybill': 18487,
    'withdraw_agent': 36916,
    'deposit_agent': 923360,
    'mshwari_deposit': 1396924,
    'mshwari_withdrawal': 207966,
    'kcb_deposit': 128124,
    'kcb_withdrawal': 288124,
    'investment_purchase': 279130,
    'investment_redemption': 150000,
    'fuliza_repayment': 1396924,
  };
  for (final entry in fixtures.entries) {
    test('extracts only wallet evidence from ${entry.key} fixture', () {
      final body = File('test/fixtures/${entry.key}.txt').readAsStringSync();
      final evidence = extractor.extract(message(body))!;
      expect(evidence.amountMinor, entry.value);
      expect(body, contains(evidence.matchedClause));
      expect(evidence.asOf, receipt);
    });
  }
  test('explicit wallet wording, exact money and known zero', () {
    for (final clause in [
      'M-PESA balance is Ksh0.00',
      'New M-PESA balance is Ksh 1,234.56.',
      'Your M-PESA balance is 1234.56.',
      'new m-pesa balance is ksh1234.56.',
    ]) {
      expect(extractor.extract(message(clause)), isNotNull);
    }
    expect(
      extractor.extract(message('M-PESA balance is Ksh0.00'))!.amountMinor,
      0,
    );
    expect(
      extractor
          .extract(message('New M-PESA balance is Ksh90071992547409.93'))!
          .amountMinor,
      9007199254740993,
    );
  });
  test('rejects missing, other-product and malformed balance clauses', () {
    for (final body in [
      'M-Shwari balance is Ksh500.24.',
      'KCB M-PESA balance is Ksh500.24.',
      'Fuliza M-PESA balance is Ksh500.24.',
      'Available Fuliza M-PESA limit is Ksh500.24.',
      'Your account available balance is Ksh500.24.',
      'New M-PESA balance is Ksh1,23.45.',
      'New M-PESA balance is Ksh1.234.',
      'New M-PESA balance is Ksh1.23abc',
      'New M-PESA balance is USD1.23.',
      'New M-PESA balance is Ksh-1.23.',
      'New M-PESA balance is Ksh1.',
      'New M-PESA balance is Ksh92233720368547758.08.',
      'No balance here.',
    ]) {
      expect(extractor.extract(message(body)), isNull, reason: body);
    }
  });
  test('multiple wallet clauses rejected even identical or malformed', () {
    for (final suffix in ['Ksh1.00.', 'Ksh2.00.', 'unavailable.']) {
      expect(
        extractor.extract(
          message(
            'New M-PESA balance is Ksh1.00. Your M-PESA balance is $suffix',
          ),
        ),
        isNull,
      );
    }
  });
  test('second wallet clause with unsupported prefix is still ambiguous', () {
    expect(
      extractor.extract(
        message('New M-PESA balance is Ksh1.00 and M-PESA balance is Ksh2.00.'),
      ),
      isNull,
    );
  });
  test('requires existing MPESA sender policy', () {
    expect(
      extractor.extract(message('M-PESA balance is Ksh1.00', sender: 'BANK')),
      isNull,
    );
    expect(
      extractor.extract(
        message('M-PESA balance is Ksh1.00', sender: ' mpesa '),
      ),
      isNotNull,
    );
  });
  test(
    'absent, invalid or multiple body timestamps never override receipt proxy',
    () {
      for (final body in [
        'New M-PESA balance is Ksh1.00.',
        'on 99/99/26 at 25:00 PM. New M-PESA balance is Ksh1.00.',
        'on 1/1/20 at 1:00 PM and on 2/2/21 at 2:00 PM. New M-PESA balance is Ksh1.00.',
      ]) {
        expect(extractor.extract(message(body))!.asOf, receipt);
      }
      expect(
        MpesaBalanceEvidenceExtractor.timeBasis,
        'raw_message_received_at_proxy',
      );
    },
  );
}
