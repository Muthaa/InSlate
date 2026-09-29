import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/permission_service.dart';
import '../sources/sms_transaction_source.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final smsTransactionSourceProvider = Provider<SmsTransactionSource>((ref) {
  return SmsTransactionSource();
});
