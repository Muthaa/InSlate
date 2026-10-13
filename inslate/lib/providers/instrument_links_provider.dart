import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/instrument_links_repository.dart';
import 'repository_providers.dart';

final instrumentLinksProvider = StreamProvider.autoDispose
    .family<InstrumentLinks?, int>(
      (ref, id) => ref.watch(instrumentLinksRepositoryProvider).watch(id),
    );
