import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        centerTitle: true,
      ),
      body: lessonsAsync.when(
        data: (lessons) => _buildLessonsList(context, ref, lessons),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading lessons: $error'),
        ),
      ),
    );
  }

  Widget _buildLessonsList(
    BuildContext context,
    WidgetRef ref,
    List<LessonMeta> lessons,
  ) {
    final progress = ref.watch(lessonProgressProvider);

    // Group lessons by category
    final grouped = <String, List<LessonMeta>>{};
    for (var lesson in lessons) {
      grouped.putIfAbsent(lesson.category, () => []).add(lesson);
    }

    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final categoryLessons = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...categoryLessons.map((lesson) {
              final lessonProgress = progress[lesson.slug];
              final isCompleted = lessonProgress?.completed ?? false;
              final isBookmarked = lessonProgress?.bookmarked ?? false;

              return ListTile(
                leading: isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.circle_outlined),
                title: Text(lesson.title),
                subtitle: Text(
                  '${lesson.readingTimeMinutes} min read',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : null,
                  ),
                  onPressed: () {
                    ref
                        .read(lessonProgressProvider.notifier)
                        .toggleBookmark(lesson.slug, !isBookmarked);
                  },
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/lessons/${lesson.slug}',
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
