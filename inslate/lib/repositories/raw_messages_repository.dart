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

  Future<List<String>> getExistingSourceIds(List<String> sourceIds) {
    return database.rawMessagesDao.getExistingSourceIds(sourceIds);
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
