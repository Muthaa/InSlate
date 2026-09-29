import '/core/enums/message_type.dart';
import '/core/enums/record_subtype.dart';
import '/core/enums/transaction_status.dart';

class ClassificationResult {
  final MessageType messageType;
  final RecordSubtype subtype;
  final TransactionStatus status;

  const ClassificationResult({
    required this.messageType,
    required this.subtype,
    required this.status,
  });
}

abstract class MessageClassifier {
  ClassificationResult classify(String message);
}
