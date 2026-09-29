import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';
import 'package:inslate/models/raw_message.dart';
import 'package:inslate/parsers/parser_factory.dart';

import 'fixture_loader.dart';

class PipelineTestRunner {
  PipelineTestRunner._();

  static void run(String fixture) {
    test(fixture, () {
      final classifier = MpesaMessageClassifier();

      final messages = FixtureLoader.load(fixture);

      expect(messages.isNotEmpty, true);

      for (final sms in messages) {
        final classification = classifier.classify(sms);

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
      }
    });
  }
}
