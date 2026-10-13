import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/detected_providers_repository.dart';
import 'database_provider.dart';

final detectedProvidersProvider =
    StreamProvider.autoDispose<List<DetectedProvider>>(
      (ref) => DetectedProvidersRepository(ref.watch(databaseProvider)).watch(),
    );

final detectedProvidersPageProvider = StreamProvider.autoDispose
    .family<List<DetectedProvider>, int>(
      (ref, page) => DetectedProvidersRepository(
        ref.watch(databaseProvider),
      ).watch(page: page),
    );
