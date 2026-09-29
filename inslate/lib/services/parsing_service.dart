import '/library/classifiers/mpesa_message_classifier.dart';
import '/models/parse_result.dart';
import '/models/raw_message.dart';
import '/parsers/parser_factory.dart';

class ParsingService {
  final MpesaMessageClassifier classifier;

  const ParsingService({required this.classifier});

  ParseResult parse(RawMessage message) {
    final classification = classifier.classify(message.body);

    final parser = ParserFactory.getParser(classification.subtype);

    if (parser == null) {
      return const ParseResult.failure('Unsupported transaction type.');
    }

    return parser.parse(message, classification);
  }
}
