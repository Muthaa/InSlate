import 'package:flutter_test/flutter_test.dart';

import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/library/classifiers/mpesa_message_classifier.dart';

import 'fixture_loader.dart';

class ClassifierTestRunner {
  ClassifierTestRunner._();

  static void run({
    required String fixture,
    required RecordSubtype expectedSubtype,
  }) {
    test(fixture, () {
      final classifier = MpesaMessageClassifier();

      final messages = FixtureLoader.load(fixture);

      expect(messages.isNotEmpty, true);

      for (final sms in messages) {
        final result = classifier.classify(sms);

        expect(result.subtype, expectedSubtype, reason: sms);
      }
    });
  }
}
