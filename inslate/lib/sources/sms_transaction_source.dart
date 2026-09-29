import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import '../models/raw_message.dart';
import 'transaction_source.dart';

class SmsTransactionSource implements TransactionSource {
  final Telephony _telephony = Telephony.instance;

  @override
  Future<List<RawMessage>> load() async {
    final messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ID,
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
      filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA'),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    debugPrint('MPESA SMS FOUND: ${messages.length}');

    return messages.map((sms) {
      return RawMessage(
        id: sms.id?.toString() ?? '',
        sender: sms.address ?? '',
        body: sms.body ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0),
      );
    }).toList();
  }
}
