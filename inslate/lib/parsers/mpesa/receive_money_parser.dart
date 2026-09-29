import '/core/constants/mpesa_patterns.dart';
import '/core/constants/record_titles.dart';
import '/core/enums/party_type.dart';
import '/library/classifiers/message_classifier.dart';
import '/models/parse_result.dart';
import '/models/party.dart';
import '/models/raw_message.dart';
import '/parsers/common_field_parser.dart';
import '../parser.dart';
import '/builders/financial_record_builder.dart';

class ReceiveMoneyParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      final senderWithPhone = MpesaPatterns.receiveMoneySenderWithPhone
          .firstMatch(message.body);

      final Party party;

      if (senderWithPhone != null) {
        party = Party(
          name: senderWithPhone.group(1)!.trim(),
          phone: senderWithPhone.group(2)!.trim(),
          type: PartyType.person,
        );
      } else {
        final senderNameOnly = MpesaPatterns.receiveMoneySenderNameOnly
            .firstMatch(message.body);

        if (senderNameOnly == null) {
          return const ParseResult.failure('Unable to extract sender.');
        }

        party = Party(
          name: senderNameOnly.group(1)!.trim(),
          phone: null,
          type: PartyType.person,
        );
      }

      final record = FinancialRecordBuilder.build(
        common: common,
        classification: classification,
        title: RecordTitles.receiveMoney,
        rawMessage: message.body,
        party: party,
      );

      return ParseResult.success(record);
    } catch (e) {
      return ParseResult.failure(
        'Failed to parse Receive Money transaction: $e',
      );
    }
  }
}
