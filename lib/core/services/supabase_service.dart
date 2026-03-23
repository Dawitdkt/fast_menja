import 'package:fast_menja/core/models/user_model.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get user profile row
  Future<UserProfile?> getUserProfile(String uid) async {
    final data =
        await _client.from('users').select().eq('uid', uid).maybeSingle();

    if (data == null) return null;
    return _mapUserProfile(data);
  }

  /// Create or update user profile
  Future<void> createUserProfile(
      String uid, String? email, String? displayName) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('users').upsert({
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'created_at': now,
      'is_premium': false,
    });
  }

  /// Update user profile fields
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final mapped = <String, dynamic>{};
    if (data.containsKey('displayName'))
      mapped['display_name'] = data['displayName'];
    if (data.containsKey('email')) mapped['email'] = data['email'];
    if (data.containsKey('fcmToken')) mapped['fcm_token'] = data['fcmToken'];
    if (data.containsKey('isPremium')) mapped['is_premium'] = data['isPremium'];

    if (mapped.isEmpty) return;

    await _client.from('users').update(mapped).eq('uid', uid);
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    await _client.from('users').update({'fcm_token': token}).eq('uid', uid);
  }

  /// Mark lesson as complete
  Future<void> markLessonComplete(String uid, String slug) async {
    await _client.from('progress').upsert({
      'uid': uid,
      'slug': slug,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Bookmark lesson
  Future<void> bookmarkLesson(String uid, String slug, bool bookmarked) async {
    await _client.from('progress').upsert({
      'uid': uid,
      'slug': slug,
      'bookmarked': bookmarked,
    });
  }

  /// Get lesson progress for user
  Future<List<LessonProgress>> getLessonProgress(String uid) async {
    final rows = await _client.from('progress').select().eq('uid', uid);

    return rows.map<LessonProgress>((row) => _mapLessonProgress(row)).toList();
  }

  /// Record quiz attempt stats (client-side increment)
  Future<void> recordQuizAttempt(
    String uid,
    String category,
    int score,
    int totalQuestions,
  ) async {
    final current = await _client
        .from('quiz_stats')
        .select()
        .eq('uid', uid)
        .eq('category', category)
        .maybeSingle();

    final totalAttempts = (current?['total_attempts'] as int? ?? 0) + 1;
    final totalCorrect = (current?['total_correct'] as int? ?? 0) + score;

    await _client.from('quiz_stats').upsert({
      'uid': uid,
      'category': category,
      'total_attempts': totalAttempts,
      'total_correct': totalCorrect,
      'last_attempt_at': DateTime.now().toIso8601String(),
    });
  }

  /// Record mock test result
  Future<void> recordMockTest(
    String uid,
    String testId,
    int score,
    int totalQuestions,
    int durationSeconds,
  ) async {
    final result = MockTestResult(
      testId: testId,
      score: score,
      totalQuestions: totalQuestions,
      passedAt: DateTime.now(),
      durationSeconds: durationSeconds,
    );

    await _client.from('mock_tests').upsert({
      'uid': uid,
      'test_id': result.testId,
      'score': result.score,
      'total_questions': result.totalQuestions,
      'passed_at': result.passedAt.toIso8601String(),
      'duration_seconds': result.durationSeconds,
      'passed': result.passed,
    });
  }

  /// Add question to weak questions list
  Future<void> recordWeakQuestion(
    String uid,
    String questionId,
    int incorrectCount,
  ) async {
    final nextDue = _calculateNextDueDate(incorrectCount).toIso8601String();

    await _client.from('weak_questions').upsert({
      'uid': uid,
      'question_id': questionId,
      'incorrect_count': incorrectCount,
      'last_seen_at': DateTime.now().toIso8601String(),
      'next_due_at': nextDue,
    });
  }

  /// Get weak questions for user
  Future<List<WeakQuestion>> getWeakQuestions(String uid) async {
    final nowIso = DateTime.now().toIso8601String();
    final rows = await _client
        .from('weak_questions')
        .select()
        .eq('uid', uid)
        .lte('next_due_at', nowIso);

    return rows.map<WeakQuestion>((row) => _mapWeakQuestion(row)).toList();
  }

  /// Update premium status
  Future<void> updatePremiumStatus(String uid, bool isPremium) async {
    await _client
        .from('users')
        .update({'is_premium': isPremium}).eq('uid', uid);
  }

  /// Offline persistence is handled client-side by Hive; no-op here
  void enableOfflinePersistence() {}

  /// Merge local progress with remote after sign-in
  Future<void> mergeProgressAfterSignIn(
    String uid,
    List<LessonProgress> localProgress,
  ) async {
    final remote = await getLessonProgress(uid);
    final remoteMap = {for (final p in remote) p.slug: p};

    for (final progress in localProgress) {
      final remoteProg = remoteMap[progress.slug];
      final isNewer = remoteProg?.completedAt == null ||
          (progress.completedAt != null &&
              progress.completedAt!.isAfter(remoteProg!.completedAt!));

      if (remoteProg == null || isNewer) {
        await _client.from('progress').upsert({
          'uid': uid,
          'slug': progress.slug,
          'completed': progress.completed,
          'bookmarked': progress.bookmarked,
          'completed_at': progress.completedAt?.toIso8601String(),
        });
      }
    }
  }

  // ===== Helpers =====

  UserProfile _mapUserProfile(Map<String, dynamic> row) {
    return UserProfile(
      uid: row['uid'] as String,
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
      createdAt: DateTime.parse(
        (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      isPremium: row['is_premium'] as bool? ?? false,
      fcmToken: row['fcm_token'] as String?,
    );
  }

  LessonProgress _mapLessonProgress(Map<String, dynamic> row) {
    return LessonProgress(
      slug: row['slug'] as String,
      completed: row['completed'] as bool? ?? false,
      bookmarked: row['bookmarked'] as bool? ?? false,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
    );
  }

  WeakQuestion _mapWeakQuestion(Map<String, dynamic> row) {
    return WeakQuestion(
      questionId: row['question_id'] as String,
      incorrectCount: row['incorrect_count'] as int? ?? 0,
      lastSeenAt: row['last_seen_at'] != null
          ? DateTime.parse(row['last_seen_at'] as String)
          : DateTime.now(),
      nextDueAt: row['next_due_at'] != null
          ? DateTime.parse(row['next_due_at'] as String)
          : DateTime.now(),
    );
  }

  DateTime _calculateNextDueDate(int incorrectCount) {
    const intervals = [1, 2, 4, 7, 14, 30];
    final idx = incorrectCount.clamp(0, intervals.length - 1);
    return DateTime.now().add(Duration(days: intervals[idx]));
  }
}
