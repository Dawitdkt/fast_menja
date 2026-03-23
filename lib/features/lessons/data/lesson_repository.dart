import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'local_storage_service.dart';

class LessonRepository {
  final LocalStorageService _storage;

  LessonRepository(this._storage);

  /// Load all lessons metadata from assets
  Future<List<LessonMeta>> loadLessonIndex() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lessons_index.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final lessons = (jsonData['lessons'] as List)
          .map((l) => LessonMeta.fromJson(l as Map<String, dynamic>))
          .toList();

      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    } catch (e) {
      rethrow;
    }
  }

  /// Load lesson markdown by slug
  Future<String> loadMarkdown(String slug) async {
    try {
      return await rootBundle.loadString('assets/lessons/$slug.md');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark lesson as complete
  Future<void> markComplete(String slug) async {
    final progress = _storage.getLessonProgress(slug);
    final updated = LessonProgress(
      slug: slug,
      completed: true,
      bookmarked: progress?.bookmarked ?? false,
      completedAt: DateTime.now(),
    );
    await _storage.saveLessonProgress(updated);
  }

  /// Bookmark lesson
  Future<void> toggleBookmark(String slug, bool bookmarked) async {
    final progress = _storage.getLessonProgress(slug);
    final updated = LessonProgress(
      slug: slug,
      completed: progress?.completed ?? false,
      bookmarked: bookmarked,
      completedAt: progress?.completedAt,
    );
    await _storage.saveLessonProgress(updated);
  }

  /// Get lesson progress for specific slug
  LessonProgress? getProgress(String slug) {
    return _storage.getLessonProgress(slug);
  }

  /// Get all progress
  List<LessonProgress> getAllProgress() {
    return _storage.getAllProgress();
  }

  /// Get completed lessons count
  int getCompletedLessonsCount() {
    return _storage.getAllProgress().where((p) => p.completed).length;
  }

  /// Get bookmarked lessons
  List<LessonProgress> getBookmarkedLessons() {
    return _storage.getAllProgress().where((p) => p.bookmarked).toList();
  }
}
