import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/import_logger.dart';

final importLogProvider = FutureProvider<String>((ref) async {
  return ImportLogger.read();
});
