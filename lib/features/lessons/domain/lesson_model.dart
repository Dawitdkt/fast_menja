import 'package:hive/hive.dart';

part 'lesson_model.g.dart';

@HiveType(typeId: 0)
class LessonMeta extends HiveObject {
  @HiveField(0)
  final String slug;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final int order;

  @HiveField(4)
  final int readingTimeMinutes;

  @HiveField(5)
  final List<String> tags;

  LessonMeta({
    required this.slug,
    required this.title,
    required this.category,
    required this.order,
    required this.readingTimeMinutes,
    required this.tags,
  });

  factory LessonMeta.fromJson(Map<String, dynamic> json) {
    return LessonMeta(
      slug: json['slug'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      order: json['order'] as int,
      readingTimeMinutes: json['readingTimeMinutes'] as int,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'title': title,
      'category': category,
      'order': order,
      'readingTimeMinutes': readingTimeMinutes,
      'tags': tags,
    };
  }
}

@HiveType(typeId: 1)
class LessonProgress extends HiveObject {
  @HiveField(0)
  final String slug;

  @HiveField(1)
  final bool completed;

  @HiveField(2)
  final bool bookmarked;

  @HiveField(3)
  final DateTime? completedAt;

  LessonProgress({
    required this.slug,
    required this.completed,
    required this.bookmarked,
    this.completedAt,
  });

  LessonProgress copyWith({
    String? slug,
    bool? completed,
    bool? bookmarked,
    DateTime? completedAt,
  }) {
    return LessonProgress(
      slug: slug ?? this.slug,
      completed: completed ?? this.completed,
      bookmarked: bookmarked ?? this.bookmarked,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      slug: json['slug'] as String,
      completed: json['completed'] as bool? ?? false,
      bookmarked: json['bookmarked'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'completed': completed,
      'bookmarked': bookmarked,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
