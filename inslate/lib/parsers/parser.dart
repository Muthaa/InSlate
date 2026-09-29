import '../library/classifiers/message_classifier.dart';
import '../models/raw_message.dart';
import '../models/parse_result.dart';

abstract class Parser {
  ParseResult parse(RawMessage message, ClassificationResult classification);
}
