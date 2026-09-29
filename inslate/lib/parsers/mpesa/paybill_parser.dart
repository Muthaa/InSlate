import '/builders/financial_record_builder.dart';
import '/core/constants/mpesa_patterns.dart';
import '/core/constants/record_titles.dart';
import '/core/enums/party_type.dart';
import '/library/classifiers/message_classifier.dart';
import '/models/parse_result.dart';
import '/models/party.dart';
import '/models/raw_message.dart';
import '/parsers/common_field_parser.dart';
import '../parser.dart';

class PayBillParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      final match = MpesaPatterns.payBill.firstMatch(message.body);

      if (match == null) {
        return const ParseResult.failure('Unable to extract Pay Bill details.');
      }

      final party = Party(
        name: match.group(1)!.trim(),
        account: match.group(2)!.trim(),
        type: PartyType.business,
      );

      final record = FinancialRecordBuilder.build(
        common: common,
        classification: classification,
        title: RecordTitles.payBill,
        rawMessage: message.body,
        party: party,
      );

      return ParseResult.success(record);
    } catch (e) {
      return ParseResult.failure('Failed to parse Pay Bill transaction: $e');
    }
  }
}
