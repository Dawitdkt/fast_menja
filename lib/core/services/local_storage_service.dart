import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  static const String _progressBoxName = 'lesson_progress';
  static const String _questionsBoxName = 'questions';
  static const String _weakQuestionsBoxName = 'weak_questions';
  static const String _mockTestsBoxName = 'mock_tests';

  late Box<LessonProgress> _progressBox;
  late Box<Question> _questionsBox;
  late Box<WeakQuestion> _weakQuestionsBox;
  late Box<MockTestResult> _mockTestsBox;

  bool _initialized = false;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LessonProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WeakQuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(MockTestResultAdapter());
    }

    // Open boxes
    _progressBox = await Hive.openBox<LessonProgress>(_progressBoxName);
    _questionsBox = await Hive.openBox<Question>(_questionsBoxName);
    _weakQuestionsBox = await Hive.openBox<WeakQuestion>(_weakQuestionsBoxName);
    _mockTestsBox = await Hive.openBox<MockTestResult>(_mockTestsBoxName);

    _initialized = true;
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
  }

  /// Clear all data
  Future<void> clearAll() async {
    await Future.wait([
      _progressBox.clear(),
      _questionsBox.clear(),
      _weakQuestionsBox.clear(),
      _mockTestsBox.clear(),
    ]);
  }

  // ===== Lesson Progress =====

  /// Save lesson progress
  Future<void> saveLessonProgress(LessonProgress progress) async {
    await _progressBox.put(progress.slug, progress);
  }

  /// Get lesson progress by slug
  LessonProgress? getLessonProgress(String slug) {
    return _progressBox.get(slug);
  }

  /// Get all lesson progress
  List<LessonProgress> getAllProgress() {
    return _progressBox.values.toList();
  }

  /// Delete lesson progress
  Future<void> deleteLessonProgress(String slug) async {
    await _progressBox.delete(slug);
  }

  // ===== Questions =====

  /// Load quest questions from bundled JSON
  Future<void> loadQuestionsFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/questions.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final questions = (jsonData['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      await _questionsBox.clear();
      await _questionsBox.addAll(questions);
    } catch (e) {
      rethrow;
    }
  }

  /// Get question by ID
  Question? getQuestion(String id) {
    return _questionsBox.values.cast<Question?>().firstWhere(
          (q) => q?.id == id,
          orElse: () => null,
        );
  }

  /// Get all questions
  List<Question> getAllQuestions() {
    return _questionsBox.values.toList();
  }

  /// Get questions by category
  List<Question> getQuestionsByCategory(String category) {
    return _questionsBox.values.where((q) => q.category == category).toList();
  }

  /// Get random questions
  List<Question> getRandomQuestions(int count) {
    final questions = _questionsBox.values.toList();
    questions.shuffle();
    return questions.take(count).toList();
  }

  /// Get random questions from category
  List<Question> getRandomQuestionsFromCategory(String category, int count) {
    final questions = getQuestionsByCategory(category);
    questions.shuffle();
    return questions.take(count).toList();
  }

  /// Save or update questions
  Future<void> saveQuestions(List<Question> questions) async {
    await _questionsBox.clear();
    await _questionsBox.addAll(questions);
  }

  // ===== Weak Questions (Spaced Repetition) =====

  /// Add or update weak question
  Future<void> saveWeakQuestion(WeakQuestion weakQuestion) async {
    await _weakQuestionsBox.put(weakQuestion.questionId, weakQuestion);
  }

  /// Get weak question by ID
  WeakQuestion? getWeakQuestion(String questionId) {
    return _weakQuestionsBox.get(questionId);
  }

  /// Get all weak questions due today
  List<WeakQuestion> getWeakQuestionsDue() {
    final now = DateTime.now();
    return _weakQuestionsBox.values
        .where((wq) =>
            wq.nextDueAt.isBefore(now) || wq.nextDueAt.isAtSameMomentAs(now))
        .toList();
  }

  /// Get all weak questions
  List<WeakQuestion> getAllWeakQuestions() {
    return _weakQuestionsBox.values.toList();
  }

  /// Delete weak question
  Future<void> deleteWeakQuestion(String questionId) async {
    await _weakQuestionsBox.delete(questionId);
  }

  /// Clear weak questions
  Future<void> clearWeakQuestions() async {
    await _weakQuestionsBox.clear();
  }

  // ===== Mock Tests =====

  /// Save mock test result
  Future<void> saveMockTestResult(MockTestResult result) async {
    await _mockTestsBox.put(result.testId, result);
  }

  /// Get mock test result
  MockTestResult? getMockTestResult(String testId) {
    return _mockTestsBox.get(testId);
  }

  /// Get all mock test results
  List<MockTestResult> getAllMockTestResults() {
    return _mockTestsBox.values.toList();
  }

  /// Get mock test results sorted by date
  List<MockTestResult> getMockTestResultsSorted() {
    final results = _mockTestsBox.values.toList();
    results.sort((a, b) => b.passedAt.compareTo(a.passedAt));
    return results;
  }

  /// Delete mock test result
  Future<void> deleteMockTestResult(String testId) async {
    await _mockTestsBox.delete(testId);
  }
}

// Hive Adapters (auto-generated, but stubbed here)
class LessonProgressAdapter extends TypeAdapter<LessonProgress> {
  @override
  final typeId = 1;

  @override
  LessonProgress read(BinaryReader reader) {
    return LessonProgress(
      slug: reader.read(),
      completed: reader.read(),
      bookmarked: reader.read(),
      completedAt: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, LessonProgress obj) {
    writer.write(obj.slug);
    writer.write(obj.completed);
    writer.write(obj.bookmarked);
    writer.write(obj.completedAt);
  }
}

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final typeId = 2;

  @override
  Question read(BinaryReader reader) {
    return Question(
      id: reader.read(),
      text: reader.read(),
      options: (reader.read() as List).cast<String>(),
      correctIndex: reader.read(),
      explanation: reader.read(),
      category: reader.read(),
      imageAsset: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer.write(obj.id);
    writer.write(obj.text);
    writer.write(obj.options);
    writer.write(obj.correctIndex);
    writer.write(obj.explanation);
    writer.write(obj.category);
    writer.write(obj.imageAsset);
  }
}

class WeakQuestionAdapter extends TypeAdapter<WeakQuestion> {
  @override
  final typeId = 4;

  @override
  WeakQuestion read(BinaryReader reader) {
    return WeakQuestion(
      questionId: reader.read(),
      incorrectCount: reader.read(),
      lastSeenAt: reader.read(),
      nextDueAt: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, WeakQuestion obj) {
    writer.write(obj.questionId);
    writer.write(obj.incorrectCount);
    writer.write(obj.lastSeenAt);
    writer.write(obj.nextDueAt);
  }
}

class MockTestResultAdapter extends TypeAdapter<MockTestResult> {
  @override
  final typeId = 5;

  @override
  MockTestResult read(BinaryReader reader) {
    return MockTestResult(
      testId: reader.read(),
      score: reader.read(),
      totalQuestions: reader.read(),
      passedAt: reader.read(),
      durationSeconds: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MockTestResult obj) {
    writer.write(obj.testId);
    writer.write(obj.score);
    writer.write(obj.totalQuestions);
    writer.write(obj.passedAt);
    writer.write(obj.durationSeconds);
  }
}
