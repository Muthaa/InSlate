import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/models/balance_observation.dart';
import 'package:inslate/core/enums/account_type.dart';
import 'package:inslate/services/mpesa_provider_balance_extractor.dart';
import 'package:inslate/services/mpesa_balance_evidence_extractor.dart';
import '../fixtures/mshwari_loan_messages.dart';

void main() {
  final extractor = MpesaProviderBalanceExtractor();
  RawMessage sms(String body, {String sender = 'MPESA'}) => RawMessage(
    id: 'source',
    sender: sender,
    body: body,
    receivedAt: DateTime.utc(2026, 6, 28),
  );
  String fixture(String name) =>
      File('test/fixtures/$name.txt').readAsStringSync();
  final cases = {
    'mshwari_deposit': (
      'mshwari-savings',
      AccountType.mshwariSavings,
      BalanceKind.reported,
      200024,
    ),
    'mshwari_withdrawal': (
      'mshwari-savings',
      AccountType.mshwariSavings,
      BalanceKind.reported,
      24,
    ),
    'kcb_deposit': (
      'kcb-mpesa-savings',
      AccountType.kcbMpesa,
      BalanceKind.reported,
      200053,
    ),
    'kcb_withdrawal': (
      'kcb-mpesa-savings',
      AccountType.kcbMpesa,
      BalanceKind.reported,
      100053,
    ),
    'failed_transaction': (
      'mshwari-savings',
      AccountType.mshwariSavings,
      BalanceKind.available,
      50024,
    ),
    'fuliza_loan': (
      'fuliza-debt',
      AccountType.fuliza,
      BalanceKind.outstandingDebt,
      88936,
    ),
  };
  for (final entry in cases.entries) {
    test('verified ${entry.key} provider evidence', () {
      final body = fixture(entry.key);
      final e = extractor.extract(sms(body)).single;
      expect((
        e.subjectKey,
        e.subjectFamily,
        e.kind,
        e.amountMinor,
      ), entry.value);
      expect(body, contains(e.matchedClause));
    });
  }
  test('verified M-Shwari repayment has savings and zero outstanding debt', () {
    final entries = extractor.extract(sms(mshwariRepaidLoan));
    expect(entries.map((e) => (e.subjectKey, e.amountMinor, e.kind)), [
      ('mshwari-savings', 10734, BalanceKind.reported),
      ('mshwari-loan', 0, BalanceKind.outstandingDebt),
    ]);
    expect(entries.last.matchedClause, 'Loan balance is Ksh0.00');
  });
  test(
    'positive debt uses the reported loan balance, never repayment amount',
    () {
      // Amount-only variant of the verified repayment format.
      final body = mshwariRepaidLoan.replaceFirst(
        'Loan balance is Ksh0.00',
        'Loan balance is Ksh700.25',
      );
      expect(extractor.extract(sms(body)).last.amountMinor, 70025);
    },
  );
  test('zero provider balances are observations', () {
    for (final clause in [
      'New M-Shwari saving account balance is Ksh0.00.',
      'KCB M-PESA Account balance is Ksh0.00.',
      'Total Fuliza M-PESA outstanding amount is Ksh0.00 due on 26/07/26.',
    ]) {
      expect(extractor.extract(sms(clause)).single.amountMinor, 0);
    }
  });
  test(
    'dual wallet and savings extraction independently preserve both subjects',
    () {
      for (final name in [
        'mshwari_deposit',
        'mshwari_withdrawal',
        'kcb_deposit',
        'kcb_withdrawal',
      ]) {
        final message = sms(fixture(name));
        expect(extractor.extract(message), hasLength(1));
        expect(MpesaBalanceEvidenceExtractor().extract(message), isNotNull);
      }
    },
  );
  test('all distinct subjects can coexist without arbitrary selection', () {
    final body =
        '$mshwariRepaidLoan ${fixture('kcb_deposit')} ${fixture('fuliza_loan')}';
    expect(extractor.extract(sms(body)).map((e) => e.subjectKey).toSet(), {
      'mshwari-savings',
      'mshwari-loan',
      'kcb-mpesa-savings',
      'fuliza-debt',
    });
  });
  test('M-Shwari loan disbursement is not outstanding debt evidence', () {
    expect(extractor.extract(sms(mshwariApprovedLoan)), isEmpty);
    expect(
      MpesaBalanceEvidenceExtractor()
          .extract(sms(mshwariApprovedLoan))!
          .amountMinor,
      394000,
    );
  });
  test('Fuliza fully paid and available limit do not imply zero debt', () {
    expect(extractor.extract(sms(fixture('fuliza_repayment'))), isEmpty);
  });
  test(
    'generic loan balance requires verified local M-Shwari repayment context',
    () {
      for (final body in [
        'Loan balance is Ksh0.00.',
        'M-Shwari loan approved. Loan balance is Ksh0.00.',
        'M-Shwari loan repaid. Loan balance is Ksh0.00.',
        'Loan of Ksh4,300.00 repaid from M-Shwari on 6/10/26. KCB M-PESA Account balance is Ksh107.34. Loan balance is Ksh0.00.',
        'New M-Shwari balance is Ksh107.34. Loan balance is Ksh0.00.',
      ]) {
        expect(
          extractor
              .extract(sms(body))
              .where((e) => e.subjectKey == 'mshwari-loan'),
          isEmpty,
        );
      }
    },
  );
  test(
    'malformed provider amounts and ambiguous amount alternatives rejected',
    () {
      for (final amount in [
        '1,23.45',
        '1.234',
        '-1.00',
        '1.00abc',
        '1',
        '1.00 or Ksh2.00',
        '92233720368547758.08',
      ]) {
        for (final head in [
          'New M-Shwari saving account balance is',
          'KCB M-PESA Account balance is',
          'Total Fuliza M-PESA outstanding amount is',
        ]) {
          expect(
            extractor.extract(sms('$head Ksh$amount.')),
            isEmpty,
            reason: '$head $amount',
          );
        }
      }
    },
  );
  test('requires Ksh marker and exact integer conversion', () {
    expect(
      extractor.extract(sms('KCB M-PESA Account balance is 1.00.')),
      isEmpty,
    );
    expect(
      extractor
          .extract(sms('KCB M-PESA Account balance is Ksh90071992547409.93.'))
          .single
          .amountMinor,
      9007199254740993,
    );
  });
  test('same subject repeated even identical or malformed is rejected', () {
    for (final suffix in ['Ksh1.00.', 'Ksh2.00.', 'unknown.']) {
      for (final head in [
        'New M-Shwari saving account balance is',
        'KCB M-PESA Account balance is',
        'Total Fuliza M-PESA outstanding amount is',
      ]) {
        expect(extractor.extract(sms('$head Ksh1.00. $head $suffix')), isEmpty);
      }
    }
  });
  test('reported and available M-Shwari clauses compete for same subject', () {
    expect(
      extractor.extract(
        sms(
          'New M-Shwari balance is Ksh1.00. Your M-Shwari account available balance is Ksh2.00.',
        ),
      ),
      isEmpty,
    );
  });
  test(
    'ambiguous generic debt does not discard independently identified savings',
    () {
      final entries = extractor.extract(
        sms('$mshwariRepaidLoan Loan balance is Ksh0.00.'),
      );
      expect(entries.map((e) => e.subjectKey), ['mshwari-savings']);
    },
  );
  test('ambiguous savings does not discard wallet or Fuliza debt', () {
    final message = sms(
      'New M-Shwari balance is Ksh1.00. M-Shwari balance is Ksh2.00. New M-PESA balance is Ksh3.00. ${fixture('fuliza_loan')}',
    );
    expect(extractor.extract(message).single.subjectKey, 'fuliza-debt');
    expect(MpesaBalanceEvidenceExtractor().extract(message)!.amountMinor, 300);
  });
  test('sender normalization policy remains MPESA only', () {
    final body = fixture('kcb_deposit');
    expect(extractor.extract(sms(body, sender: ' mpesa ')), hasLength(1));
    expect(extractor.extract(sms(body, sender: 'KCB')), isEmpty);
  });
  test(
    'unsupported debt or qualified context cannot become savings evidence',
    () {
      for (final body in [
        'Outstanding M-Shwari balance is Ksh500.00.',
        'Your loan KCB M-PESA Account balance is Ksh500.00.',
        'Old M-Shwari balance is Ksh100.00.',
      ]) {
        expect(extractor.extract(sms(body)), isEmpty);
      }
    },
  );
}
