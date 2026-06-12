import '../../data/repositories/words_repository.dart';

/// Background top-up. Triggered when learned ratio within the user's active
/// CEFR levels crosses 50%. Picks the next batch belonging to an active level
/// that isn't already in the DB. No-op when network is unreachable or no
/// matching batch is left.
class LoadNextBatch {
  static const triggerRatio = 0.50;
  final WordsRepository _repo;
  LoadNextBatch(this._repo);

  /// [force] bypasses the 50% threshold (used by manual "Load more words"
  /// button in Settings).
  Future<bool> call(List<String> activeLevels, {bool force = false}) async {
    if (activeLevels.isEmpty) return false;
    if (!force) {
      final total = await _repo.totalCount(levels: activeLevels);
      if (total == 0) return false;
      final learned = await _repo.learnedCount(levels: activeLevels);
      if (learned / total < triggerRatio) return false;
    }

    final next = await _repo.nextBatchForLevels(activeLevels);
    if (next == null) return false;

    return _repo.loadBatch(next);
  }
}
