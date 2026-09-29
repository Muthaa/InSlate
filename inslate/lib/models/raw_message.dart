class RawMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;

  const RawMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
  });
}
