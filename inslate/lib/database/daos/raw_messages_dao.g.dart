// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_messages_dao.dart';

// ignore_for_file: type=lint
mixin _$RawMessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RawMessagesTable get rawMessages => attachedDatabase.rawMessages;
  RawMessagesDaoManager get managers => RawMessagesDaoManager(this);
}

class RawMessagesDaoManager {
  final _$RawMessagesDaoMixin _db;
  RawMessagesDaoManager(this._db);
  $$RawMessagesTableTableManager get rawMessages =>
      $$RawMessagesTableTableManager(_db.attachedDatabase, _db.rawMessages);
}
