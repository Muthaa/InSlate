/// Checkpoint after a committed batch. IDs refer to this database's RawMessages.
/// Session resume is bounded by the initial high-water ID; after process loss,
/// replay from zero is safe because evidence inserts never overwrite rows.
class HistoricalBalanceCheckpoint {
  final int throughId, afterId, scanned, created, existing, unsupported;
  final bool complete;
  const HistoricalBalanceCheckpoint({
    required this.throughId,
    this.afterId = 0,
    this.scanned = 0,
    this.created = 0,
    this.existing = 0,
    this.unsupported = 0,
    this.complete = false,
  });
}

class HistoricalBalanceState {
  final HistoricalBalanceCheckpoint? checkpoint;
  final bool running, cancelling;
  final String? error;
  const HistoricalBalanceState({
    this.checkpoint,
    this.running = false,
    this.cancelling = false,
    this.error,
  });
}
