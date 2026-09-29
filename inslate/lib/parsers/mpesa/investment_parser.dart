import '/builders/financial_record_builder.dart';
import '/core/constants/mpesa_patterns.dart';
import '/core/constants/record_titles.dart';
import '/core/enums/party_type.dart';
import '/core/enums/record_subtype.dart';
import '/library/classifiers/message_classifier.dart';
import '/models/parse_result.dart';
import '/models/party.dart';
import '/models/raw_message.dart';
import '/parsers/common_field_parser.dart';
import '/parsers/parser.dart';

class InvestmentParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      late String title;
      late Party party;

      switch (classification.subtype) {
        case RecordSubtype.investmentPurchase:
          final match = MpesaPatterns.investmentPurchase.firstMatch(
            message.body,
          );

          if (match == null) {
            return const ParseResult.failure('Investment details not found.');
          }

          title = RecordTitles.investmentPurchase;

          party = Party(
            name: match.group(1)!.trim(),
            account: match.group(2)!.trim(),
            type: PartyType.self,
          );

          break;

        case RecordSubtype.investmentRedemption:
          final match = MpesaPatterns.investmentRedemption.firstMatch(
            message.body,
          );

          if (match == null) {
            return const ParseResult.failure('Investment provider not found.');
          }

          title = RecordTitles.investmentRedemption;

          party = Party(
            name: match.group(1)!.trim(),
            identifier: match.group(2),
            type: PartyType.self,
          );

          break;

        default:
          return const ParseResult.failure(
            'Unsupported investment transaction.',
          );
      }

      final record = FinancialRecordBuilder.build(
        common: common,
        classification: classification,
        title: title,
        rawMessage: message.body,
        party: party,
      );

      return ParseResult.success(record);
    } catch (e) {
      return ParseResult.failure(e.toString());
    }
  }
}
