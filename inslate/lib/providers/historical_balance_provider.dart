import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/historical_balance_extraction.dart';
import 'balance_evidence_provider.dart';

final historicalBalanceProvider =
    NotifierProvider<HistoricalBalanceController, HistoricalBalanceState>(
      HistoricalBalanceController.new,
    );

class HistoricalBalanceController extends Notifier<HistoricalBalanceState> {
  bool _cancel = false, _disposed = false;
  @override
  HistoricalBalanceState build() {
    ref.onDispose(() {
      _cancel = true;
      _disposed = true;
    });
    return const HistoricalBalanceState();
  }

  void cancel() {
    if (!state.running) return;
    _cancel = true;
    state = HistoricalBalanceState(
      checkpoint: state.checkpoint,
      running: true,
      cancelling: true,
    );
  }

  Future<void> run() async {
    if (state.running) return;
    _cancel = false;
    var checkpoint = state.checkpoint;
    final repo = ref.read(balanceEvidenceRepositoryProvider);
    state = HistoricalBalanceState(checkpoint: checkpoint, running: true);
    try {
      if (checkpoint == null || checkpoint.complete) {
        checkpoint = await repo.beginHistoricalExtraction();
      }
      if (_disposed) return;
      state = HistoricalBalanceState(
        checkpoint: checkpoint,
        running: true,
        cancelling: _cancel,
      );
      while (!checkpoint!.complete && !_cancel) {
        checkpoint = await repo.historicalExtractionBatch(checkpoint);
        if (_disposed) return;
        state = HistoricalBalanceState(
          checkpoint: checkpoint,
          running: true,
          cancelling: _cancel,
        );
        // Yield between committed batches so cancellation and rendering can run.
        await Future<void>.delayed(Duration.zero);
      }
      if (!_disposed) state = HistoricalBalanceState(checkpoint: checkpoint);
    } catch (_) {
      if (!_disposed) {
        state = HistoricalBalanceState(
          checkpoint: checkpoint,
          error:
              'Extraction stopped. Retry resumes after the last committed batch.',
        );
      }
    }
  }
}
