import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(() {
    database.close();
  });

  return database;
});

Future<void> refreshDatabase(WidgetRef ref) async {
  // Dispose the current foreground database and everything that depends on it.
  //
  // This is important after returning from the background because the
  // background SMS isolate may have committed transactions using its own
  // SQLite connection.
  ref.invalidate(databaseProvider);

  // Wait for Riverpod to rebuild the database dependency graph.
  await ref.read(databaseProvider).customSelect('SELECT 1').get();
}
