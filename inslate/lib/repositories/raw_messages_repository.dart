import '../database/app_database.dart';
import '../models/raw_message.dart' as domain;

class RawMessagesRepository {
  final AppDatabase database;

  RawMessagesRepository(this.database);

  Future<void> save(domain.RawMessage message) async {
    await database.rawMessagesDao.insertMessage(
      RawMessagesCompanion.insert(
        sourceId: message.id,
        sender: message.sender,
        body: message.body,
        receivedAt: message.receivedAt,
      ),
    );
  }

  Future<bool> exists(String sourceId) async {
    return database.rawMessagesDao.messageExists(sourceId);
  }

  Future<domain.RawMessage?> getBySourceId(String sourceId) async {
    final row = await database.rawMessagesDao.getBySourceId(sourceId);

    if (row == null) {
      return null;
    }

    return domain.RawMessage(
      id: row.sourceId,
      sender: row.sender,
      body: row.body,
      receivedAt: row.receivedAt,
    );
  }

  Future<List<domain.RawMessage>> getAll() async {
    final rows = await database.rawMessagesDao.getAllMessages();

    return rows
        .map(
          (row) => domain.RawMessage(
            id: row.sourceId,
            sender: row.sender,
            body: row.body,
            receivedAt: row.receivedAt,
          ),
        )
        .toList();
  }

  Future<domain.RawMessage?> getLatest() async {
    final row = await database.rawMessagesDao.getLatestMessage();

    if (row == null) {
      return null;
    }

    return domain.RawMessage(
      id: row.sourceId,
      sender: row.sender,
      body: row.body,
      receivedAt: row.receivedAt,
    );
  }

  Future<List<String>> getExistingSourceIds(List<String> sourceIds) {
    return database.rawMessagesDao.getExistingSourceIds(sourceIds);
  }

  Future<List<domain.RawMessage>> getExistingBySenderAndBodies(
    List<domain.RawMessage> messages,
  ) async {
    final bodiesBySender = <String, Set<String>>{};

    for (final message in messages) {
      bodiesBySender
          .putIfAbsent(message.sender, () => <String>{})
          .add(message.body);
    }

    if (bodiesBySender.isEmpty) {
      return [];
    }

    final rows = await database.rawMessagesDao.getBySenderAndBodies(
      bodiesBySender.map((sender, bodies) => MapEntry(sender, bodies.toList())),
    );

    return rows
        .map(
          (row) => domain.RawMessage(
            id: row.sourceId,
            sender: row.sender,
            body: row.body,
            receivedAt: row.receivedAt,
          ),
        )
        .toList();
  }

  Future<void> saveAll(List<domain.RawMessage> messages) async {
    if (messages.isEmpty) {
      return;
    }

    await database.rawMessagesDao.insertMessages(
      messages
          .map(
            (message) => RawMessagesCompanion.insert(
              sourceId: message.id,
              sender: message.sender,
              body: message.body,
              receivedAt: message.receivedAt,
            ),
          )
          .toList(),
    );
  }
}
