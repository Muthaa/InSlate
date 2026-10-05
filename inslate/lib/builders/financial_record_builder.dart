import '/core/mappers/financial_record_type_mapper.dart';
import '/library/classifiers/message_classifier.dart';
import '/models/common_fields.dart';
import '/models/financial_records.dart';
import '/models/party.dart';

class FinancialRecordBuilder {
  FinancialRecordBuilder._();

  static FinancialRecord build({
    required CommonFields common,
    required ClassificationResult classification,
    required String title,
    required String rawMessage,
    required String sourceMessageId,
    Party? party,
    required DateTime receivedAt,
  }) {
    return FinancialRecord(
      reference: common.reference,
      transactionDate: common.transactionDate,
      amount: common.amount,
      balance: common.balance,
      transactionCost: common.transactionCost,
      receivedAt: receivedAt,
      type: FinancialRecordTypeMapper.fromSubtype(classification.subtype),
      subtype: classification.subtype,
      status: classification.status,
      title: title,
      rawMessage: rawMessage,
      sourceMessageId: sourceMessageId,
      party: party,
    );
  }
}
