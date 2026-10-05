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

  Future<RawMessage?> getLatestMessage() {
    return (select(rawMessages)
          ..orderBy([(message) => OrderingTerm.desc(message.receivedAt)])
          ..limit(1))
        .getSingleOrNull();
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

  Future<List<RawMessage>> getBySenderAndBodies(
    Map<String, List<String>> bodiesBySender,
  ) async {
    final matches = <RawMessage>[];

    for (final entry in bodiesBySender.entries) {
      final bodies = entry.value;

      for (var start = 0; start < bodies.length; start += 500) {
        final bodyChunk = bodies.skip(start).take(500).toList();
        final rows =
            await (select(rawMessages)..where(
                  (message) =>
                      message.sender.equals(entry.key) &
                      message.body.isIn(bodyChunk),
                ))
                .get();

        matches.addAll(rows);
      }
    }

    return matches;
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
