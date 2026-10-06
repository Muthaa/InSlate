import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/financial_record_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/enums/transaction_status.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/financial_records.dart';
import 'package:inslate/parsers/parser_factory.dart';
import 'package:inslate/services/financial_breakdown_service.dart';
import '../fixtures/mshwari_loan_messages.dart';

FinancialRecord parse(String body) {
  final classification = MpesaMessageClassifier().classify(body);
  final parser = ParserFactory.getParser(classification.subtype);
  expect(parser, isNotNull);
  final result = parser!.parse(
    RawMessage(
      id: 'mshwari-fixture',
      sender: 'MPESA',
      body: body,
      receivedAt: DateTime(2026, 10, 4),
    ),
    classification,
  );
  expect(result.success, isTrue, reason: result.toString());
  return result.record!;
}

void main() {
  final period = FinancialPeriod.month(DateTime(2026, 10));
  test(
    'real approved loan parses principal, date, balance and provider without inferred duty',
    () {
      final record = parse(mshwariApprovedLoan);
      expect(record.reference, 'UJ3NY8KRG4');
      expect(record.amount, 3940);
      expect(record.balance, 3940);
      expect(record.transactionDate, DateTime(2026, 10, 3, 0, 42));
      expect(record.transactionCost, 0);
      expect(record.type, FinancialRecordType.loan);
      expect(record.subtype, RecordSubtype.loanDisbursement);
      expect(record.status, TransactionStatus.successful);
      expect(record.party!.name, 'M-Shwari');
      expect(record.party!.type, PartyType.self);
      expect(record.sourceMessageId, 'mshwari-fixture');
      expect(record.rawMessage, mshwariApprovedLoan);
    },
  );

  test(
    'production loan enters Borrowed and exact provider Activity, excluding all non-loan metrics',
    () {
      final record = parse(mshwariApprovedLoan);
      final summary = const FinancialBreakdownService().dashboard([
        record,
      ], period);
      final totals = summary.totals;
      expect(totals.borrowed, 3940);
      expect(totals.repaid, 0);
      expect([
        totals.income,
        totals.expenses,
        totals.received,
        totals.sent,
        totals.internalTransfers,
        totals.netCashFlow,
        totals.fees,
      ], everyElement(0));
      final borrowed = summary
          .breakdown(BreakdownKind.loans)
          .sections
          .singleWhere((section) => section.label == 'Borrowed');
      expect(borrowed.amount, 3940);
      expect(borrowed.groups.single.label, contains('M-Shwari'));
      expect(borrowed.groups.single.filter.matches(record), isTrue);
      expect(borrowed.groups.single.filter.party!.value, 'm-shwari');
      for (final scope in [
        ActivityScope.income,
        ActivityScope.expenses,
        ActivityScope.internalTransfers,
        ActivityScope.investmentsAndSavings,
      ]) {
        expect(
          ActivityFilter(period: period, scope: scope).matches(record),
          isFalse,
        );
      }
      for (final kind in BreakdownKind.values.where(
        (kind) => kind != BreakdownKind.loans,
      )) {
        expect(summary.breakdown(kind).groups, isEmpty, reason: kind.name);
      }
    },
  );

  test(
    'top-up marketing does not change or create an additional borrowing',
    () {
      final withoutMarketing = mshwariApprovedLoan.split('Did you know').first;
      expect(parse(withoutMarketing).amount, parse(mshwariApprovedLoan).amount);
      expect(
        parse(mshwariApprovedLoan).subtype,
        RecordSubtype.loanDisbursement,
      );
      expect(
        const FinancialBreakdownService()
            .dashboard([parse(mshwariApprovedLoan)], period)
            .breakdown(BreakdownKind.loans)
            .count,
        1,
      );
    },
  );

  test(
    'synthetic transactional top-up using verified disbursement grammar is borrowing',
    () {
      final body = mshwariApprovedLoan.replaceFirst(
        'loan has been approved',
        'loan top-up has been approved',
      );
      expect(parse(body).subtype, RecordSubtype.loanDisbursement);
      expect(parse(body).amount, 3940);
    },
  );

  // Synthetic conservative payment grammar; replace/extend with a real SMS when available.
  for (final source in ['M-PESA', 'M-Shwari savings', 'M-Shwari']) {
    test(
      'conservative repayment from $source is Repaid, never savings or expenses',
      () {
        final record = parse(
          'UJ3NY8KRG5 Confirmed. Ksh500.00 from your $source account '
          'has been used to fully pay your outstanding M-Shwari loan on 3/10/26 12:42 AM.',
        );
        expect(record.subtype, RecordSubtype.loanRepayment);
        expect(record.party!.name, 'M-Shwari');
        expect(record.amount, 500);
        final summary = const FinancialBreakdownService().dashboard([
          record,
        ], period);
        expect(summary.totals.repaid, 500);
        expect(summary.totals.expenses, 0);
        expect(summary.totals.sent, 0);
        expect(summary.totals.internalTransfers, 0);
        expect(summary.totals.netCashFlow, 0);
        expect(
          summary.breakdown(BreakdownKind.investmentsAndSavings).groups,
          isEmpty,
        );
        expect(
          summary
              .breakdown(BreakdownKind.loans)
              .sections
              .singleWhere((section) => section.label == 'Repaid')
              .groups
              .single
              .filter
              .matches(record),
          isTrue,
        );
        expect(record.transactionDate, DateTime(2026, 10, 3, 0, 42));
      },
    );
  }
  test('repayment with no source or date does not invent them', () {
    final record = parse(
      'UJ3NY8KRG5 Confirmed. Ksh500.00 has been used to pay your M-Shwari loan.',
    );
    expect(record.transactionDate, isNull);
    expect(record.balance, isNull);
    expect(record.rawMessage, isNot(contains('M-PESA')));
  });
  for (final body in [
    'Did you know you can top up your M-Shwari loan once within the first 20 days?',
    'UJ3NY8KRG5 Confirmed. Your M-Shwari loan of Ksh500.00 is due tomorrow.',
    'UJ3NY8KRG5 Confirmed. Transfer to M-Shwari loan Ksh500.00 to repay today.',
    'UJ3NY8KRG5 Confirmed. Your M-Shwari loan top-up application is pending. Ksh500.00.',
    'UJ3NY8KRG5 Confirmed. Your M-Shwari loan repayment failed. Ksh500.00.',
  ]) {
    test('reminder/marketing/incomplete action is not parsed: $body', () {
      expect(
        MpesaMessageClassifier().classify(body).subtype,
        RecordSubtype.unknown,
      );
    });
  }
}
