import '../../data/repositories/words_repository.dart';

/// Background top-up. Triggered when learned-ratio crosses 20%.
/// Fetches the next batch from remote source; no-op if none available or
/// network unreachable.
class LoadNextBatch {
  static const triggerRatio = 0.10;
  final WordsRepository _repo;
  LoadNextBatch(this._repo);

  /// Returns true if a new batch was fetched and inserted.
  Future<bool> call() async {
    final total = await _repo.totalCount();
    if (total == 0) return false;
    final learned = await _repo.learnedCount();
    if (learned / total < triggerRatio) return false;

    final next = await _repo.nextBatchId();
    if (next == null) return false;

    return _repo.loadBatch(next);
  }
}
