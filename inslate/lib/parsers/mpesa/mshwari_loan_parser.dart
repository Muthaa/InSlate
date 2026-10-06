import '../../builders/financial_record_builder.dart';
import '../../core/constants/mshwari_loan_patterns.dart';
import '../../core/enums/party_type.dart';
import '../../core/enums/record_subtype.dart';
import '../../core/extensions/string_extensions.dart';
import '../../library/classifiers/message_classifier.dart';
import '../../models/common_fields.dart';
import '../../models/parse_result.dart';
import '../../models/party.dart';
import '../../models/raw_message.dart';
import '../common_field_parser.dart';
import '../parser.dart';
import '../parser_utils.dart';

class MshwariLoanParser implements Parser {
  @override
  ParseResult parse(RawMessage message, ClassificationResult classification) {
    try {
      final borrowed = classification.subtype == RecordSubtype.loanDisbursement;
      if (!borrowed && classification.subtype != RecordSubtype.loanRepayment) {
        return const ParseResult.failure(
          'Unsupported M-Shwari loan transaction.',
        );
      }
      final match = borrowed
          ? MshwariLoanPatterns.disbursement.firstMatch(message.body)
          : MshwariLoanPatterns.repaymentMatch(message.body);
      if (match == null) {
        return const ParseResult.failure('Unrecognized M-Shwari loan clause.');
      }
      final common = CommonFieldsParser.parse(message.body);
      final date = match.group(borrowed ? 1 : 2);
      final time = match.group(borrowed ? 2 : 3);
      return ParseResult.success(
        FinancialRecordBuilder.build(
          common: CommonFields(
            reference: common.reference,
            amount: match.group(borrowed ? 3 : 1)!.toMoney(),
            transactionDate: date == null || time == null
                ? null
                : ParserUtils.parseMpesaDate(
                    date,
                    time.replaceAllMapped(
                      RegExp(r'\s*(AM|PM)$', caseSensitive: false),
                      (match) => ' ${match.group(1)}',
                    ),
                  ),
            balance: common.balance,
            // "less excise duty" alone supplies no fee amount.
            transactionCost:
                MshwariLoanPatterns.explicitCost
                    .firstMatch(message.body)
                    ?.group(1)
                    ?.toMoney() ??
                common.transactionCost,
          ),
          classification: classification,
          title: borrowed
              ? 'M-Shwari loan disbursement'
              : 'M-Shwari loan repayment',
          rawMessage: message.body,
          sourceMessageId: message.id,
          receivedAt: message.receivedAt,
          party: const Party(name: 'M-Shwari', type: PartyType.self),
        ),
      );
    } catch (error) {
      return ParseResult.failure(error.toString());
    }
  }
}
