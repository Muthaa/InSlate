import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/parsing_service.dart';
import '../services/permission_service.dart';
import '../sources/sms_transaction_source.dart';
import '../library/classifiers/mpesa_message_classifier.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final smsSourceProvider = Provider<SmsTransactionSource>((ref) {
  return SmsTransactionSource();
});

final classifierProvider = Provider<MpesaMessageClassifier>((ref) {
  return MpesaMessageClassifier();
});

final parsingServiceProvider = Provider<ParsingService>((ref) {
  return ParsingService(classifier: ref.read(classifierProvider));
});
