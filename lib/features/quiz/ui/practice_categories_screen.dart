import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

class PracticeCategoriesScreen extends ConsumerStatefulWidget {
  const PracticeCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PracticeCategoriesScreen> createState() =>
      _PracticeCategoriesScreenState();
}

class _PracticeCategoriesScreenState
    extends ConsumerState<PracticeCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizStats = ref.watch(quizStatsProvider);
    final entries = quizStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final filtered = entries
        .where(
          (entry) => entry.key.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    final totalQuestions =
        entries.fold<int>(0, (sum, item) => sum + item.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Practice Module',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F8FF), Color(0xFFF7FAFC)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeroCard(
                totalQuestions: totalQuestions, categoryCount: entries.length),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              _EmptySearchState(query: _query)
            else
              ...filtered.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(
                    title: entry.key,
                    questionCount: entry.value,
                    totalQuestions: totalQuestions,
                    icon: _iconForCategory(entry.key),
                    color: _colorForCategory(entry.key),
                    onTap: () {
                      final count = entry.value.clamp(1, 20);
                      ref
                          .read(quizSessionProvider.notifier)
                          .startCategoryQuiz(entry.key, count);
                      context.go('/theory');
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _MotivationCard(categoryCount: entries.length),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.totalQuestions, required this.categoryCount});

  final int totalQuestions;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C81), Color(0xFF1C74E9)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A1C74E9),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Category',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a topic and launch a focused quiz session.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.grid_view_rounded,
                label: '$categoryCount categories',
              ),
              _StatChip(
                icon: Icons.fact_check_rounded,
                label: '$totalQuestions questions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.questionCount,
    required this.totalQuestions,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int questionCount;
  final int totalQuestions;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = totalQuestions == 0 ? 0.0 : questionCount / totalQuestions;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$questionCount Questions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: share.clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFF7E8),
        border: Border.all(color: const Color(0xFFFFE2B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep it up. Complete $categoryCount focused category sessions this week and your theory confidence will climb quickly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7C2D12),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 32, color: Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(
            'No categories found for "$query"',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('sign')) return Icons.traffic_rounded;
  if (normalized.contains('motor')) return Icons.directions_car_filled_rounded;
  if (normalized.contains('hazard')) return Icons.warning_amber_rounded;
  if (normalized.contains('rule')) return Icons.gavel_rounded;
  return Icons.quiz_rounded;
}

Color _colorForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('sign')) return const Color(0xFF2563EB);
  if (normalized.contains('motor')) return const Color(0xFF10B981);
  if (normalized.contains('hazard')) return const Color(0xFFF59E0B);
  if (normalized.contains('rule')) return const Color(0xFF7C3AED);
  return const Color(0xFF1C74E9);
}
