import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/parsers/parser_factory.dart';

import 'fixture_loader.dart';

class ParserTestRunner {
  ParserTestRunner._();

  static void run({
    required String fixture,
    required RecordSubtype expectedSubtype,
  }) {
    test(fixture, () {
      final classifier = MpesaMessageClassifier();

      final messages = FixtureLoader.load(fixture);

      expect(messages.isNotEmpty, true);

      for (final sms in messages) {
        final classification = classifier.classify(sms);

        expect(classification.subtype, expectedSubtype);

        final parser = ParserFactory.getParser(classification.subtype);

        final result = parser?.parse(
          RawMessage(
            id: '1',
            sender: 'MPESA',
            body: sms,
            receivedAt: DateTime.now(),
          ),
          classification,
        );

        expect(result?.success ?? false, true, reason: sms);

        final record = result?.record;

        expect(record?.reference.isNotEmpty, true);
        expect((record?.amount ?? 0) > 0, true);
        expect(record?.transactionDate, isNotNull);
        expect(record?.title.isNotEmpty, true);
        expect(record?.type, isNotNull);
        expect(record?.subtype, expectedSubtype);
        expect(record?.rawMessage.isNotEmpty, true);
      }
    });
  }
}
