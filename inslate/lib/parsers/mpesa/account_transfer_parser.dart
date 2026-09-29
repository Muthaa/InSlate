import '/builders/financial_record_builder.dart';
import '/core/constants/record_titles.dart';
import '/core/enums/party_type.dart';
import '/core/enums/record_subtype.dart';
import '/library/classifiers/message_classifier.dart';
import '/models/parse_result.dart';
import '/models/party.dart';
import '/models/raw_message.dart';
import '/parsers/common_field_parser.dart';
import '../parser.dart';

class AccountTransferParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final common = CommonFieldsParser.parse(message.body);

      late String title;
      late Party party;

      if (classification.subtype == RecordSubtype.mshwariDeposit) {
        title = RecordTitles.mshwariDeposit;

        party = const Party(name: 'M-Shwari', type: PartyType.self);
      } else if (classification.subtype == RecordSubtype.mshwariWithdrawal) {
        title = RecordTitles.mshwariWithdrawal;

        party = const Party(name: 'M-Shwari', type: PartyType.self);
      } else if (classification.subtype == RecordSubtype.kcbDeposit) {
        title = RecordTitles.kcbDeposit;

        party = const Party(name: 'KCB M-PESA', type: PartyType.self);
      } else if (classification.subtype == RecordSubtype.kcbWithdrawal) {
        title = RecordTitles.kcbWithdrawal;

        party = const Party(name: 'KCB M-PESA', type: PartyType.self);
      } else {
        return const ParseResult.failure('Unsupported transfer type.');
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
