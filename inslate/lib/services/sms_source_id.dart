String smsSourceId({
  required int? smsId,
  required String sender,
  required String body,
  required int receivedAtMilliseconds,
}) {
  if (smsId != null) {
    return smsId.toString();
  }

  // Background SMS broadcasts do not reliably include the inbox database ID.
  //
  // This fallback is deterministic so repeated callbacks for the same
  // broadcast resolve to the same source ID. Once the SMS is visible through
  // the inbox API, the importer can reconcile its real numeric ID using the
  // existing identical sender/body duplicate protection.
  final normalizedSender = sender.trim().toUpperCase();

  return 'broadcast:$normalizedSender:$receivedAtMilliseconds:${body.hashCode}';
}
