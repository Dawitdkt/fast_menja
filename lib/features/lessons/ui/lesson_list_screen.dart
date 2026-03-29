import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/features/lessons/domain/lesson_model.dart';
import 'package:fast_menja/core/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

const _primary = Color(0xFF0058C3);
const _surface = Color(0xFFF7F9FB);
const _surfaceContainer = Color(0xFFF2F4F6);
const _outline = Color(0xFF727785);

class LessonListScreen extends ConsumerStatefulWidget {
  const LessonListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends ConsumerState<LessonListScreen> {
  String _query = '';

  void _openLesson(BuildContext context, String slug) {
    final encoded = Uri.encodeQueryComponent(slug);
    context.go('/lessons/read?slug=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonIndexProvider);
    final progress = ref.watch(lessonProgressProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: lessonsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading lessons: $err')),
          data: (lessons) {
            final filtered = _filterLessons(lessons, _query);
            final grouped = _groupByCategory(filtered);
            final feature = _pickRecommendedLesson(filtered, progress);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(lessonIndexProvider);
                ref.invalidate(lessonProgressProvider);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: _Header(
                        onBack: () => context.go('/'),
                        onProfile: () => context.go('/profile'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SearchBar(
                        value: _query,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  if (feature != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: _FeaturedCard(
                          lesson: feature,
                          progress: progress[feature.slug],
                          onTap: () => _openLesson(context, feature.slug),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    sliver: _CategoryList(
                      grouped: grouped,
                      progress: progress,
                      onTapLesson: (slug) => _openLesson(context, slug),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<LessonMeta> _filterLessons(List<LessonMeta> lessons, String query) {
    if (query.trim().isEmpty) return lessons;
    final lower = query.toLowerCase();
    return lessons
        .where((l) =>
            l.title.toLowerCase().contains(lower) ||
            l.category.toLowerCase().contains(lower) ||
            l.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();
  }

  Map<String, List<LessonMeta>> _groupByCategory(List<LessonMeta> lessons) {
    final map = <String, List<LessonMeta>>{};
    for (final lesson in lessons) {
      map.putIfAbsent(lesson.category, () => []).add(lesson);
    }
    return map;
  }

  LessonMeta? _pickRecommendedLesson(
    List<LessonMeta> lessons,
    Map<String, LessonProgress> progress,
  ) {
    if (lessons.isEmpty) return null;

    final sorted = [...lessons]..sort((a, b) => a.order.compareTo(b.order));

    for (final lesson in sorted) {
      final isCompleted = progress[lesson.slug]?.completed ?? false;
      if (!isCompleted) return lesson;
    }

    return sorted.first;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onProfile});

  final VoidCallback onBack;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButton(
          icon: Icons.arrow_back,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Text(
          'Theory Study',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        _IconButton(
          icon: Icons.person_outline,
          onTap: onProfile,
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        ),
      decoration: InputDecoration(
        hintText: 'Search specific rules or topics...',
        prefixIcon: const Icon(Icons.search, color: _outline),
        filled: true,
        fillColor: _surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  final LessonMeta lesson;
  final LessonProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = progress?.completed == true ? 1.0 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120058C3),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.traffic, color: _primary, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${lesson.readingTimeMinutes} min read',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF424754),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course progress',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                      ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: _surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Continue learning',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.grouped,
    required this.progress,
    required this.onTapLesson,
  });

  final Map<String, List<LessonMeta>> grouped;
  final Map<String, LessonProgress> progress;
  final ValueChanged<String> onTapLesson;

  @override
  Widget build(BuildContext context) {
    final lessons = grouped.values.expand((list) => list).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final lesson = lessons[index];
          final isCompleted = progress[lesson.slug]?.completed ?? false;
          final percent = isCompleted ? 100 : 0;

          return Padding(
            padding:
                EdgeInsets.only(bottom: index == lessons.length - 1 ? 0 : 12),
            child: _CategoryListTile(
              title: lesson.title,
              subtitle: '${lesson.readingTimeMinutes} min read',
              percent: percent,
              accent: _pickColor(index),
              onTap: () => onTapLesson(lesson.slug),
            ),
          );
        },
        childCount: lessons.length,
      ),
    );
  }

  Color _pickColor(int i) {
    const palette = [
      Color(0xFFFFEDD5),
      Color(0xFFE0F2FE),
      Color(0xFFE8F5E9),
      Color(0xFFFFEBEE),
      Color(0xFFE8EAF6),
    ];
    return palette[i % palette.length];
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int percent;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF424754),
                        ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0, 1).toDouble(),
                      minHeight: 7,
                      backgroundColor: _surfaceContainer,
                      valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right),
                  color: _primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: _surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _primary),
      ),
    );
  }
}
