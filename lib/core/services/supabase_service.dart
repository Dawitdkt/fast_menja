import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fast_menja/core/models/user_model.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class SupabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<UserProfile?> getUserProfile(String uid) async {
    final data = await _db.from('users').select().eq('uid', uid).maybeSingle();
    if (data == null) return null;

    return UserProfile(
      uid: uid,
      displayName: data['display_name'] as String?,
      email: data['email'] as String?,
      createdAt: _parseDate(data['created_at']) ?? DateTime.now(),
      isPremium: (data['is_premium'] as bool?) ?? false,
      fcmToken: data['fcm_token'] as String?,
    );
  }

  Future<void> createUserProfile(String uid, String? email, String? displayName) async {
    final currentUid = _db.auth.currentUser?.id;

    if (currentUid == uid) {
      try {
        await _db.functions.invoke('create-user-profile', body: {});
        return;
      } catch (_) {
        // Fall back to direct upsert when edge functions are unavailable.
      }
    }

    await _db.from('users').upsert({
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'created_at': DateTime.now().toIso8601String(),
      'is_premium': false,
    }, onConflict: 'uid');
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final mapped = {
      if (data['email'] != null) 'email': data['email'],
      if (data['displayName'] != null) 'display_name': data['displayName'],
      if (data['isPremium'] != null) 'is_premium': data['isPremium'],
      if (data['fcmToken'] != null) 'fcm_token': data['fcmToken'],
    };

    if (mapped.isEmpty) return;
    await _db.from('users').update(mapped).eq('uid', uid);
  }

  Future<void> updateFcmToken(String uid, String token) {
    return _db.from('users').update({'fcm_token': token}).eq('uid', uid);
  }

  Future<void> markLessonComplete(String uid, String slug) {
    return _db.from('lesson_progress').upsert({
      'uid': uid,
      'slug': slug,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'uid,slug');
  }

  Future<void> bookmarkLesson(String uid, String slug, bool bookmarked) {
    return _db.from('lesson_progress').upsert({
      'uid': uid,
      'slug': slug,
      'bookmarked': bookmarked,
    }, onConflict: 'uid,slug');
  }

  Future<List<LessonProgress>> getLessonProgress(String uid) async {
    final rows = await _db.from('lesson_progress').select().eq('uid', uid);

    return (rows as List<dynamic>)
        .map((row) => LessonProgress(
              slug: row['slug'] as String,
              completed: (row['completed'] as bool?) ?? false,
              bookmarked: (row['bookmarked'] as bool?) ?? false,
              completedAt: _parseDate(row['completed_at']),
            ))
        .toList();
  }

  Future<void> recordQuizAttempt(
    String uid,
    String category,
    int score,
    int totalQuestions,
  ) async {
    final existing = await _db
        .from('quiz_stats')
        .select()
        .eq('uid', uid)
        .eq('category', category)
        .maybeSingle();

    final attempts = ((existing?['total_attempts'] as int?) ?? 0) + 1;
    final totalCorrect = ((existing?['total_correct'] as int?) ?? 0) + score;

    await _db.from('quiz_stats').upsert({
      'uid': uid,
      'category': category,
      'total_attempts': attempts,
      'total_correct': totalCorrect,
      'last_attempt_at': DateTime.now().toIso8601String(),
    }, onConflict: 'uid,category');
  }

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

    await _db.from('mock_tests').upsert({
      'uid': uid,
      'test_id': testId,
      'score': score,
      'total_questions': totalQuestions,
      'passed_at': result.passedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'passed': result.passed,
    }, onConflict: 'uid,test_id');
  }

  Future<void> recordWeakQuestion(
    String uid,
    String questionId,
    int incorrectCount,
  ) async {
    final nextDue = _calculateNextDueDate(incorrectCount);

    await _db.from('weak_questions').upsert({
      'uid': uid,
      'question_id': questionId,
      'incorrect_count': incorrectCount,
      'last_seen_at': DateTime.now().toIso8601String(),
      'next_due_at': nextDue.toIso8601String(),
    }, onConflict: 'uid,question_id');
  }

  Future<List<WeakQuestion>> getWeakQuestions(String uid) async {
    final rows = await _db
        .from('weak_questions')
        .select()
        .eq('uid', uid)
        .lte('next_due_at', DateTime.now().toIso8601String());

    return (rows as List<dynamic>)
        .map((row) => WeakQuestion(
              questionId: row['question_id'] as String,
              incorrectCount: (row['incorrect_count'] as int?) ?? 0,
              lastSeenAt: _parseDate(row['last_seen_at']) ?? DateTime.now(),
              nextDueAt: _parseDate(row['next_due_at']) ?? DateTime.now(),
            ))
        .toList();
  }

  Future<void> updatePremiumStatus(String uid, bool isPremium) {
    return _db.from('users').update({'is_premium': isPremium}).eq('uid', uid);
  }

  void enableOfflinePersistence() {
    // No-op: Supabase does not provide Firestore-style local persistence.
  }

  Future<void> mergeProgressAfterSignIn(
    String uid,
    List<LessonProgress> localProgress,
  ) async {
    for (final progress in localProgress) {
      final remote = await _db
          .from('lesson_progress')
          .select()
          .eq('uid', uid)
          .eq('slug', progress.slug)
          .maybeSingle();

      final remoteCompletedAt = _parseDate(remote?['completed_at']);
      final localCompletedAt = progress.completedAt ?? DateTime.now();

      if (remote == null || (remoteCompletedAt?.isBefore(localCompletedAt) ?? true)) {
        await _db.from('lesson_progress').upsert({
          'uid': uid,
          'slug': progress.slug,
          'completed': progress.completed,
          'bookmarked': progress.bookmarked,
          'completed_at': progress.completedAt?.toIso8601String(),
        }, onConflict: 'uid,slug');
      }
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime _calculateNextDueDate(int incorrectCount) {
    const intervals = [1, 2, 4, 7, 14, 30];
    final idx = incorrectCount.clamp(0, intervals.length - 1);
    return DateTime.now().add(Duration(days: intervals[idx]));
  }
}
