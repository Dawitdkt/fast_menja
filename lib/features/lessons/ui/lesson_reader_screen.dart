import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

class LessonReaderScreen extends ConsumerWidget {
  final String slug;

  const LessonReaderScreen({
    Key? key,
    required this.slug,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markdownAsync = ref.watch(lessonBySlugProvider(slug));
    final progress = ref.watch(lessonProgressProvider);
    final lessonProgress = progress[slug];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        actions: [
          IconButton(
            icon: Icon(
              (lessonProgress?.bookmarked ?? false)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: () {
              final isBookmarked = lessonProgress?.bookmarked ?? false;
              ref
                  .read(lessonProgressProvider.notifier)
                  .toggleBookmark(slug, !isBookmarked);
            },
          ),
        ],
      ),
      body: markdownAsync.when(
        data: (markdown) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: markdown,
            styleSheet: MarkdownStyleSheet(
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              p: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              em: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
              code: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                backgroundColor: Color(0xFFF4F6F9),
              ),
              blockquote: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading lesson: $error'),
        ),
      ),
      floatingActionButton: !(lessonProgress?.completed ?? false)
          ? FloatingActionButton.extended(
              onPressed: () {
                ref
                    .read(lessonProgressProvider.notifier)
                    .markLessonComplete(slug);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson marked as complete!')),
                );
              },
              label: const Text('Mark Complete'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
