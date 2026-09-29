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
import '../parser.dart';

class CashTransactionParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      if (classification.subtype == RecordSubtype.deposit) {
        final match = MpesaPatterns.cashDeposit.firstMatch(message.body);

        if (match == null) {
          return const ParseResult.failure('Unable to extract agent.');
        }

        final party = Party(
          name: match.group(1)!.trim(),
          type: PartyType.agent,
        );

        final record = FinancialRecordBuilder.build(
          common: common,
          classification: classification,
          title: RecordTitles.cashDeposit,
          rawMessage: message.body,
          party: party,
        );

        return ParseResult.success(record);
      }

      if (classification.subtype == RecordSubtype.withdrawal) {
        final match = MpesaPatterns.cashWithdrawal.firstMatch(message.body);

        if (match == null) {
          return const ParseResult.failure('Unable to extract agent.');
        }

        final party = Party(
          identifier: match.group(1),
          name: match.group(2)!.trim(),
          type: PartyType.agent,
        );

        final record = FinancialRecordBuilder.build(
          common: common,
          classification: classification,
          title: RecordTitles.cashWithdrawal,
          rawMessage: message.body,
          party: party,
        );

        return ParseResult.success(record);
      }

      return const ParseResult.failure('Unsupported cash transaction.');
    } catch (e) {
      return ParseResult.failure(e.toString());
    }
  }
}
