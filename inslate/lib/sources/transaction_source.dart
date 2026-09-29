import '../models/raw_message.dart';

abstract class TransactionSource {
  Future<List<RawMessage>> load();
}
