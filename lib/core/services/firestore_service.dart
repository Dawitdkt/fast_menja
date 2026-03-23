import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_menja/core/models/user_model.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get user profile document
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson({...doc.data()!, 'uid': uid});
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create user profile on first sign-in
  Future<void> createUserProfile(String uid, String? email, String? displayName) async {
    final userProfile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      isPremium: false,
    );

    await _db.collection('users').doc(uid).set(
          userProfile.toJson(),
          SetOptions(merge: true),
        );
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Mark lesson as complete
  Future<void> markLessonComplete(String uid, String slug) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(slug)
        .set({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Bookmark lesson
  Future<void> bookmarkLesson(String uid, String slug, bool bookmarked) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(slug)
        .set({
      'bookmarked': bookmarked,
    }, SetOptions(merge: true));
  }

  /// Get lesson progress for user
  Future<List<LessonProgress>> getLessonProgress(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();

      return snapshot.docs
          .map((doc) => LessonProgress.fromJson({...doc.data(), 'slug': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Record quiz attempt
  Future<void> recordQuizAttempt(
    String uid,
    String category,
    int score,
    int totalQuestions,
  ) async {
    await _db.collection('users').doc(uid).collection('quizStats').doc(category).set({
      'totalAttempts': FieldValue.increment(1),
      'totalCorrect': FieldValue.increment(score),
      'lastAttemptAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

    await _db
        .collection('users')
        .doc(uid)
        .collection('mockTests')
        .doc(testId)
        .set(result.toJson());
  }

  /// Add question to weak questions list
  Future<void> recordWeakQuestion(
    String uid,
    String questionId,
    int incorrectCount,
  ) async {
    final nextDue = _calculateNextDueDate(incorrectCount);

    await _db
        .collection('users')
        .doc(uid)
        .collection('weakQuestions')
        .doc(questionId)
        .set({
      'questionId': questionId,
      'incorrectCount': incorrectCount,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'nextDueAt': nextDue,
    }, SetOptions(merge: true));
  }

  /// Get weak questions for user
  Future<List<WeakQuestion>> getWeakQuestions(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('weakQuestions')
          .where('nextDueAt', isLessThanOrEqualTo: FieldValue.serverTimestamp())
          .get();

      return snapshot.docs
          .map((doc) => WeakQuestion.fromJson({...doc.data(), 'questionId': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update premium status
  Future<void> updatePremiumStatus(String uid, bool isPremium) async {
    await _db.collection('users').doc(uid).update({'isPremium': isPremium});
  }

  /// Enable offline persistence
  void enableOfflinePersistence() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 41943040, // 40 MB
    );
  }

  /// Merge local progress with remote after sign-in
  Future<void> mergeProgressAfterSignIn(
    String uid,
    List<LessonProgress> localProgress,
  ) async {
    for (final progress in localProgress) {
      final remoteDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(progress.slug)
          .get();

      if (!remoteDoc.exists || (remoteDoc['completedAt'] as Timestamp?)?.toDate().isBefore(progress.completedAt ?? DateTime.now()) ?? true) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(progress.slug)
            .set(progress.toJson(), SetOptions(merge: true));
      }
    }
  }

  DateTime _calculateNextDueDate(int incorrectCount) {
    const intervals = [1, 2, 4, 7, 14, 30];
    final idx = incorrectCount.clamp(0, intervals.length - 1);
    return DateTime.now().add(Duration(days: intervals[idx]));
  }
}
