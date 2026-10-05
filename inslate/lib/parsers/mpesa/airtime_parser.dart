import '/models/parse_result.dart';
import '/models/raw_message.dart';
import '/library/classifiers/message_classifier.dart';
import '/parsers/common_field_parser.dart';
import '/parsers/parser.dart';
import '/builders/financial_record_builder.dart';

class AirtimeParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      final record = FinancialRecordBuilder.build(
        common: common,
        classification: classification,
        title: 'Airtime',
        rawMessage: message.body,
        sourceMessageId: message.id,
        receivedAt: message.receivedAt,
      );

      return ParseResult.success(record);
    } catch (e) {
      return ParseResult.failure(e.toString());
    }
  }
}
