import 'package:uuid/uuid.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';
import 'package:fast_menja/core/services/local_storage_service.dart';
import 'package:fast_menja/core/utils/spaced_repetition.dart';

class QuizRepository {
  final LocalStorageService _storage;

  QuizRepository(this._storage);

  /// Load all questions from local storage
  List<Question> loadAllQuestions() {
    return _storage.getAllQuestions();
  }

  /// Get questions by category
  List<Question> getQuestionsByCategory(String category) {
    return _storage.getQuestionsByCategory(category);
  }

  /// Get random questions (theory mode)
  List<Question> getRandomQuestions(int count) {
    return _storage.getRandomQuestions(count);
  }

  /// Generate mock test (50 questions, 57 minutes)
  QuizSession generateMockTest() {
    const questionCount = 50;
    const timeMinutes = 57;

    final questions = _storage.getRandomQuestions(questionCount);
    final session = QuizSession(
      id: const Uuid().v4(),
      questionIds: questions.map((q) => q.id).toList(),
      currentIndex: 0,
      userAnswers: List<int?>.filled(questionCount, null),
      timeRemainingSeconds: timeMinutes * 60,
      startedAt: DateTime.now(),
      isCompleted: false,
      sessionType: 'mock',
    );

    return session;
  }

  /// Generate theory mode session
  QuizSession generateTheorySession(int questionCount) {
    final questions = _storage.getRandomQuestions(questionCount);
    final session = QuizSession(
      id: const Uuid().v4(),
      questionIds: questions.map((q) => q.id).toList(),
      currentIndex: 0,
      userAnswers: List<int?>.filled(questionCount, null),
      timeRemainingSeconds: 0, // No time limit for theory
      startedAt: DateTime.now(),
      isCompleted: false,
      sessionType: 'theory',
    );

    return session;
  }

  /// Generate category quiz
  QuizSession generateCategoryQuiz(String category, int questionCount) {
    final questions =
        _storage.getRandomQuestionsFromCategory(category, questionCount);
    final session = QuizSession(
      id: const Uuid().v4(),
      questionIds: questions.map((q) => q.id).toList(),
      currentIndex: 0,
      userAnswers: List<int?>.filled(questionCount, null),
      timeRemainingSeconds: 0,
      startedAt: DateTime.now(),
      isCompleted: false,
      sessionType: 'category-$category',
    );

    return session;
  }

  /// Record answer
  void recordAnswer(QuizSession session, int answerIndex) {
    session.userAnswers[session.currentIndex] = answerIndex;
  }

  /// Get question for current index
  Question? getQuestion(String questionId) {
    return _storage.getQuestion(questionId);
  }

  /// Calculate score for a session
  int calculateScore(QuizSession session, List<Question> questions) {
    int score = 0;
    for (int i = 0; i < session.userAnswers.length; i++) {
      if (session.userAnswers[i] != null && i < questions.length) {
        if (session.userAnswers[i] == questions[i].correctIndex) {
          score++;
        }
      }
    }
    return score;
  }

  /// Complete quiz session
  Future<MockTestResult?> completeQuizSession(
    QuizSession session,
    List<Question> questions,
  ) async {
    final score = calculateScore(session, questions);
    final result = MockTestResult(
      testId: session.id,
      score: score,
      totalQuestions: questions.length,
      passedAt: DateTime.now(),
      durationSeconds: DateTime.now().difference(session.startedAt).inSeconds,
    );

    // Record weak questions
    for (int i = 0; i < session.userAnswers.length; i++) {
      if (session.userAnswers[i] != questions[i].correctIndex) {
        final weakQ = _storage.getWeakQuestion(questions[i].id);
        await _storage.saveWeakQuestion(
          WeakQuestion(
            questionId: questions[i].id,
            incorrectCount: (weakQ?.incorrectCount ?? 0) + 1,
            lastSeenAt: DateTime.now(),
            nextDueAt: SpacedRepetition.calculateNextDueDate(
              (weakQ?.incorrectCount ?? 0) + 1,
            ),
          ),
        );
      }
    }

    // Save result
    await _storage.saveMockTestResult(result);
    return result;
  }

  /// Get weak questions for review
  List<Question> getWeakQuestionsForReview() {
    final weakQuestions = _storage.getWeakQuestionsDue();
    return weakQuestions
        .map((wq) => _storage.getQuestion(wq.questionId))
        .whereType<Question>()
        .toList();
  }

  /// Update weak question after review
  Future<void> updateWeakQuestionAfterReview(
    String questionId,
    bool answeredCorrectly,
  ) async {
    final weakQ = _storage.getWeakQuestion(questionId);
    if (weakQ != null) {
      int newIncorrectCount = weakQ.incorrectCount;
      if (!answeredCorrectly) {
        newIncorrectCount++;
      }

      await _storage.saveWeakQuestion(
        WeakQuestion(
          questionId: questionId,
          incorrectCount: newIncorrectCount,
          lastSeenAt: DateTime.now(),
          nextDueAt: SpacedRepetition.calculateNextDueDate(newIncorrectCount),
        ),
      );
    }
  }

  /// Get quiz stats
  Map<String, int> getQuizStats() {
    final allQuestions = _storage.getAllQuestions();
    final categories = <String>{};
    for (var q in allQuestions) {
      categories.add(q.category);
    }

    final stats = <String, int>{};
    for (var category in categories) {
      stats[category] = allQuestions
          .where((q) => q.category == category)
          .length;
    }
    return stats;
  }

  /// Get all mock test results
  List<MockTestResult> getMockTestResults() {
    return _storage.getMockTestResultsSorted();
  }

  /// Clear all weak questions
  Future<void> clearWeakQuestions() async {
    await _storage.clearWeakQuestions();
  }
}
