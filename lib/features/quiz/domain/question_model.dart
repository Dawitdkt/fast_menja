import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Question extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final int correctIndex;

  @HiveField(4)
  final String explanation;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String? imageAsset;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    this.imageAsset,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      category: json['category'] as String,
      imageAsset: json['imageAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'category': category,
      'imageAsset': imageAsset,
    };
  }
}

@HiveType(typeId: 3)
class QuizSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String> questionIds;

  @HiveField(2)
  final int currentIndex;

  @HiveField(3)
  final List<int?> userAnswers;

  @HiveField(4)
  final int timeRemainingSeconds;

  @HiveField(5)
  final DateTime startedAt;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final String sessionType; // 'theory', 'mock', 'signs', etc.

  QuizSession({
    required this.id,
    required this.questionIds,
    required this.currentIndex,
    required this.userAnswers,
    required this.timeRemainingSeconds,
    required this.startedAt,
    required this.isCompleted,
    required this.sessionType,
  });

  int get score {
    if (!isCompleted) return 0;
    // This would need questions to calculate properly
    return userAnswers.where((answer) => answer != null).length;
  }

  QuizSession copyWith({
    String? id,
    List<String>? questionIds,
    int? currentIndex,
    List<int?>? userAnswers,
    int? timeRemainingSeconds,
    DateTime? startedAt,
    bool? isCompleted,
    String? sessionType,
  }) {
    return QuizSession(
      id: id ?? this.id,
      questionIds: questionIds ?? this.questionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      startedAt: startedAt ?? this.startedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      sessionType: sessionType ?? this.sessionType,
    );
  }
}

@HiveType(typeId: 4)
class WeakQuestion extends HiveObject {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  final int incorrectCount;

  @HiveField(2)
  final DateTime lastSeenAt;

  @HiveField(3)
  final DateTime nextDueAt;

  WeakQuestion({
    required this.questionId,
    required this.incorrectCount,
    required this.lastSeenAt,
    required this.nextDueAt,
  });

  WeakQuestion copyWith({
    String? questionId,
    int? incorrectCount,
    DateTime? lastSeenAt,
    DateTime? nextDueAt,
  }) {
    return WeakQuestion(
      questionId: questionId ?? this.questionId,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
    );
  }

  factory WeakQuestion.fromJson(Map<String, dynamic> json) {
    return WeakQuestion(
      questionId: json['questionId'] as String,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : DateTime.now(),
      nextDueAt: json['nextDueAt'] != null
          ? DateTime.parse(json['nextDueAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'incorrectCount': incorrectCount,
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'nextDueAt': nextDueAt.toIso8601String(),
    };
  }
}

@HiveType(typeId: 5)
class MockTestResult extends HiveObject {
  @HiveField(0)
  final String testId;

  @HiveField(1)
  final int score;

  @HiveField(2)
  final int totalQuestions;

  @HiveField(3)
  final DateTime passedAt;

  @HiveField(4)
  final int durationSeconds;

  @HiveField(5)
  final bool passed;

  MockTestResult({
    required this.testId,
    required this.score,
    required this.totalQuestions,
    required this.passedAt,
    required this.durationSeconds,
  }) : passed = score >= (totalQuestions * 0.86).ceil();

  factory MockTestResult.fromJson(Map<String, dynamic> json) {
    return MockTestResult(
      testId: json['testId'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      passedAt: DateTime.parse(json['passedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'score': score,
      'totalQuestions': totalQuestions,
      'passedAt': passedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'passed': passed,
    };
  }
}
