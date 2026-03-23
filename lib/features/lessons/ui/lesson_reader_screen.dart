import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

class LessonReaderScreen extends ConsumerStatefulWidget {
  final String slug;

  const LessonReaderScreen({
    Key? key,
    required this.slug,
  }) : super(key: key);

  @override
  ConsumerState<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends ConsumerState<LessonReaderScreen> {
  final ScrollController _controller = ScrollController();
  bool _completionTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final maxExtent = position.maxScrollExtent;

    if (maxExtent <= 0) {
      _markCompleteIfNeeded();
      return;
    }

    final progress = (position.pixels / maxExtent).clamp(0.0, 1.0);
    if (progress >= 0.95) {
      _markCompleteIfNeeded();
    }
  }

  void _markCompleteIfNeeded() {
    if (_completionTriggered) return;

    final current = ref.read(lessonProgressProvider)[widget.slug];
    if (current?.completed == true) {
      _completionTriggered = true;
      return;
    }

    _completionTriggered = true;
    ref.read(lessonProgressProvider.notifier).markLessonComplete(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final markdownAsync = ref.watch(lessonBySlugProvider(widget.slug));
    final progress = ref.watch(lessonProgressProvider);
    final lessonProgress = progress[widget.slug];

    if ((lessonProgress?.completed ?? false) && !_completionTriggered) {
      _completionTriggered = true;
    }

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
                  .toggleBookmark(widget.slug, !isBookmarked);
            },
          ),
        ],
      ),
      body: markdownAsync.when(
        data: (markdown) => SingleChildScrollView(
          controller: _controller,
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
    );
  }
}
