import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/raw_message.dart' as domain;
import 'package:inslate/parsers/parser_factory.dart';
import 'package:inslate/repositories/financial_records_repository.dart';

void main() {
  late AppDatabase database;
  late FinancialRecordsRepository repository;
  late MpesaMessageClassifier classifier;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinancialRecordsRepository(database);
    classifier = MpesaMessageClassifier();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'persists Fuliza loan with null balance and null transaction date',
    () async {
      const body =
          'UFQNY935Z8 Confirmed. Fuliza M-PESA amount is Ksh 613.00. '
          'Access Fee charged Ksh 6.13. '
          'Total Fuliza M-PESA outstanding amount is Ksh889.36 '
          'due on 26/07/26. '
          'To check daily charges, Dial *334#OK Select Query Charges';

      final message = domain.RawMessage(
        id: 'FULIZA-LOAN-001',
        sender: 'MPESA',
        body: body,
        receivedAt: DateTime(2026, 7, 26),
      );

      final classification = classifier.classify(body);

      final parser = ParserFactory.getParser(classification.subtype);

      expect(parser, isNotNull);

      final result = parser!.parse(message, classification);

      expect(result.success, isTrue);
      expect(result.record, isNotNull);

      final record = result.record!;

      expect(record.reference, 'UFQNY935Z8');
      expect(record.amount, 613.00);
      expect(record.transactionCost, 6.13);
      expect(record.balance, isNull);
      expect(record.transactionDate, isNull);

      await repository.save(record);

      final savedRecords = await repository.getAllByReference('UFQNY935Z8');
      final saved = savedRecords.single;

      expect(saved.reference, 'UFQNY935Z8');
      expect(saved.amount, 613.00);
      expect(saved.transactionCost, 6.13);
      expect(saved.balance, isNull);
      expect(saved.transactionDate, isNull);
    },
  );
}
