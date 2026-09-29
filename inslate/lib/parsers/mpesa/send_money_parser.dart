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

class SendMoneyParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      // Parse fields common to all M-PESA transactions
      final common = CommonFieldsParser.parse(message.body);

      /// Extract recipient name and optional phone number.
      /// M-PESA can provide.
      /// 1. A full phone number.
      /// 2. A partially masked phone number.
      /// 3. No phone number at all.
      final recipientWithPhone = MpesaPatterns.sendMoneyRecipientWithPhone
          .firstMatch(message.body);

      final Party party;

      if (recipientWithPhone != null) {
        party = Party(
          name: recipientWithPhone.group(1)!.trim(),
          phone: recipientWithPhone.group(2)!.trim(),
          type: PartyType.person,
        );
      } else {
        final recipientNameOnly = MpesaPatterns.sendMoneyRecipientNameOnly
            .firstMatch(message.body);

        if (recipientNameOnly == null) {
          return const ParseResult.failure(
            'Unable to extract recipient information.',
          );
        }

        party = Party(
          name: recipientNameOnly.group(1)!.trim(),
          phone: null,
          type: PartyType.person,
        );
      }

      final record = FinancialRecordBuilder.build(
        common: common,
        classification: classification,
        title: RecordTitles.sendMoney,
        rawMessage: message.body,
        party: party,
      );

      return ParseResult.success(record);
    } catch (e) {
      return ParseResult.failure('Failed to parse Send Money transaction: $e');
    }
  }
}
