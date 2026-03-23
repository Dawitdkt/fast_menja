import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/services/auth_service.dart';
import 'package:fast_menja/core/services/firestore_service.dart';
import 'package:fast_menja/core/services/local_storage_service.dart';
import 'package:fast_menja/features/lessons/data/lesson_repository.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/features/quiz/data/quiz_repository.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';
import 'package:fast_menja/core/models/user_model.dart';

// ===== Service Providers =====

final authServiceProvider = Provider((ref) => AuthService());

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final lessonRepositoryProvider = Provider((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return LessonRepository(storage);
});

final quizRepositoryProvider = Provider((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return QuizRepository(storage);
});

// ===== Auth State =====

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user;
});

final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && !user.isAnonymous;
});

final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && user.isAnonymous;
});

// ===== User Profile =====

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getUserProfile(user.uid);
});

// ===== Lesson Data =====

final lessonIndexProvider = FutureProvider<List<LessonMeta>>((ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.loadLessonIndex();
});

final lessonBySlugProvider = FutureProvider.family<String, String>((ref, slug) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.loadMarkdown(slug);
});

final lessonProgressProvider =
    NotifierProvider<LessonProgressNotifier, Map<String, LessonProgress>>(
  LessonProgressNotifier.new,
);

class LessonProgressNotifier extends Notifier<Map<String, LessonProgress>> {
  @override
  Map<String, LessonProgress> build() {
    final storage = ref.watch(localStorageServiceProvider);
    final progress = storage.getAllProgress();
    return {for (var p in progress) p.slug: p};
  }

  Future<void> markLessonComplete(String slug) async {
    final storage = ref.watch(localStorageServiceProvider);
    final user = ref.watch(currentUserProvider);

    final progress = LessonProgress(
      slug: slug,
      completed: true,
      bookmarked: state[slug]?.bookmarked ?? false,
      completedAt: DateTime.now(),
    );

    await storage.saveLessonProgress(progress);
    state = {...state, slug: progress};

    // Sync to Firestore if signed in
    if (user != null && !user.isAnonymous) {
      final firestore = ref.watch(firestoreServiceProvider);
      await firestore.markLessonComplete(user.uid, slug);
    }
  }

  Future<void> toggleBookmark(String slug, bool bookmarked) async {
    final storage = ref.watch(localStorageServiceProvider);
    final user = ref.watch(currentUserProvider);

    final existing = state[slug];
    final progress = LessonProgress(
      slug: slug,
      completed: existing?.completed ?? false,
      bookmarked: bookmarked,
      completedAt: existing?.completedAt,
    );

    await storage.saveLessonProgress(progress);
    state = {...state, slug: progress};

    // Sync to Firestore if signed in
    if (user != null && !user.isAnonymous) {
      final firestore = ref.watch(firestoreServiceProvider);
      await firestore.bookmarkLesson(user.uid, slug, bookmarked);
    }
  }

  int getCompletedCount() {
    return state.values.where((p) => p.completed).length;
  }

  List<LessonProgress> getBookmarked() {
    return state.values.where((p) => p.bookmarked).toList();
  }
}

// ===== Quiz Data =====

final quizSessionProvider =
    NotifierProvider<QuizSessionNotifier, QuizSession?>(
  QuizSessionNotifier.new,
);

class QuizSessionNotifier extends Notifier<QuizSession?> {
  @override
  QuizSession? build() {
    return null;
  }

  void startMockTest() {
    final repository = ref.watch(quizRepositoryProvider);
    state = repository.generateMockTest();
  }

  void startTheoryMode(int questionCount) {
    final repository = ref.watch(quizRepositoryProvider);
    state = repository.generateTheorySession(questionCount);
  }

  void startCategoryQuiz(String category, int questionCount) {
    final repository = ref.watch(quizRepositoryProvider);
    state = repository.generateCategoryQuiz(category, questionCount);
  }

  void recordAnswer(int answerIndex) {
    if (state != null) {
      final repo = ref.watch(quizRepositoryProvider);
      repo.recordAnswer(state!, answerIndex);
      state = state!.copyWith();
    }
  }

  void nextQuestion() {
    if (state != null && state!.currentIndex < state!.questionIds.length - 1) {
      state = state!.copyWith(currentIndex: state!.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state != null && state!.currentIndex > 0) {
      state = state!.copyWith(currentIndex: state!.currentIndex - 1);
    }
  }

  void updateTimer(int secondsRemaining) {
    if (state != null) {
      state = state!.copyWith(timeRemainingSeconds: secondsRemaining);
    }
  }

  Future<MockTestResult?> completeQuiz() async {
    if (state == null) return null;

    final repo = ref.watch(quizRepositoryProvider);
    final questions = state!.questionIds
        .map((id) => repo._storage.getQuestion(id))
        .whereType<Question>()
        .toList();

    final result = await repo.completeQuizSession(state!, questions);
    state = null;
    return result;
  }

  void clearSession() {
    state = null;
  }
}

final questionProvider = FutureProvider.family<Question?, String>((ref, questionId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuestion(questionId);
});

final weakQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getWeakQuestionsForReview();
});

final mockTestResultsProvider = FutureProvider<List<MockTestResult>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getMockTestResults();
});

// ===== Statistics Providers =====

final completedLessonsCountProvider = Provider<int>((ref) {
  final progress = ref.watch(lessonProgressProvider);
  return progress.values.where((p) => p.completed).length;
});

final bookmarkedLessonsProvider = Provider<List<LessonProgress>>((ref) {
  final progress = ref.watch(lessonProgressProvider);
  return progress.values.where((p) => p.bookmarked).toList();
});

final quizStatsProvider = Provider<Map<String, int>>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizStats();
});

// ===== Premium Status =====

final isPremiumProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final profile = await ref.watch(userProfileProvider.future);
  return profile?.isPremium ?? false;
});
