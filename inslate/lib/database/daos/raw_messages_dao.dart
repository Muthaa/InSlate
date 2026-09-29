import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/raw_messages.dart';

part 'raw_messages_dao.g.dart';

@DriftAccessor(tables: [RawMessages])
class RawMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$RawMessagesDaoMixin {
  RawMessagesDao(super.db);

  Future<RawMessage?> getBySourceId(String sourceId) {
    return (select(
      rawMessages,
    )..where((message) => message.sourceId.equals(sourceId))).getSingleOrNull();
  }

  Future<List<RawMessage>> getAllMessages() {
    return select(rawMessages).get();
  }

  Future<int> insertMessage(RawMessagesCompanion message) {
    return into(rawMessages).insert(message);
  }

  Future<bool> messageExists(String sourceId) async {
    final message = await getBySourceId(sourceId);
    return message != null;
  }

  Future<List<String>> getExistingSourceIds(List<String> sourceIds) async {
    if (sourceIds.isEmpty) {
      return [];
    }

    final rows = await (select(
      rawMessages,
    )..where((message) => message.sourceId.isIn(sourceIds))).get();

    return rows.map((row) => row.sourceId).toList();
  }

  Future<void> insertMessages(List<RawMessagesCompanion> messages) async {
    if (messages.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(rawMessages, messages);
    });
  }
}
