class SpacedRepetition {
  // Simplified SM-2 algorithm
  static const List<int> _intervals = [1, 2, 4, 7, 14, 30];

  /// Calculate next due date based on incorrect count
  static DateTime calculateNextDueDate(int incorrectCount) {
    final idx = incorrectCount.clamp(0, _intervals.length - 1);
    return DateTime.now().add(Duration(days: _intervals[idx]));
  }

  /// Get interval in days for incorrect count
  static int getIntervalDays(int incorrectCount) {
    final idx = incorrectCount.clamp(0, _intervals.length - 1);
    return _intervals[idx];
  }

  /// Check if a question is due for review
  static bool isDueForReview(DateTime nextDueDate) {
    return nextDueDate.isBefore(DateTime.now()) ||
        nextDueDate.isAtSameMomentAs(DateTime.now());
  }

  /// Calculate days until review
  static int daysUntilReview(DateTime nextDueDate) {
    final now = DateTime.now();
    if (isDueForReview(nextDueDate)) {
      return 0;
    }
    return nextDueDate.difference(now).inDays;
  }
}
