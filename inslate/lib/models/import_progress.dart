enum ImportStatus {
  idle,
  requestingPermission,
  loadingMessages,
  processing,
  saving,
  completed,
  failed,
}

class ImportProgress {
  final ImportStatus status;
  final int total;
  final int processed;
  final int imported;
  final int skipped;
  final int failed;
  final String? error;

  const ImportProgress({
    required this.status,
    this.total = 0,
    this.processed = 0,
    this.imported = 0,
    this.skipped = 0,
    this.failed = 0,
    this.error,
  });

  double get percentage {
    if (total == 0) {
      return 0;
    }

    return processed / total;
  }

  bool get isComplete => status == ImportStatus.completed;

  bool get hasFailed => status == ImportStatus.failed;
}
