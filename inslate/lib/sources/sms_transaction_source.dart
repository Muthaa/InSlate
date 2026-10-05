import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import '../services/background_sms_handler.dart';
import '../models/raw_message.dart';
import 'transaction_source.dart';
import '../services/sms_source_id.dart';

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

    return messages.map(_toRawMessage).toList();
  }

  Future<List<RawMessage>> loadSince(DateTime since) async {
    final messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ID,
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
      filter: SmsFilter.where(SmsColumn.ADDRESS)
          .equals('MPESA')
          .and(SmsColumn.DATE)
          .greaterThan(since.millisecondsSinceEpoch.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    debugPrint(
      'NEW MPESA SMS FOUND SINCE ${since.toIso8601String()}: '
      '${messages.length}',
    );

    return messages.map(_toRawMessage).toList();
  }

  void listenForIncomingMessages({
    required void Function(RawMessage message) onMessage,
  }) {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage sms) {
        debugPrint('INCOMING SMS | sender=${sms.address} | id=${sms.id}');

        final sender = sms.address?.trim().toUpperCase();

        if (sender != 'MPESA') {
          return;
        }

        onMessage(_toRawMessage(sms));
      },
      onBackgroundMessage: backgroundSmsHandler,
      listenInBackground: true,
    );
  }

  RawMessage _toRawMessage(SmsMessage sms) {
    final sender = sms.address ?? '';
    final body = sms.body ?? '';
    final receivedAtMilliseconds =
        sms.date ?? DateTime.now().millisecondsSinceEpoch;

    return RawMessage(
      id: smsSourceId(
        smsId: sms.id,
        sender: sender,
        body: body,
        receivedAtMilliseconds: receivedAtMilliseconds,
      ),
      sender: sender,
      body: body,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMilliseconds),
    );
  }
}
