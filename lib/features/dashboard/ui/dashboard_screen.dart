import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

const _primaryColor = Color(0xFF1C74E9);
const _backgroundLight = Color(0xFFF6F7F8);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonIndex = ref.watch(lessonIndexProvider);
    final lessonProgress = ref.watch(lessonProgressProvider);
    final profile = ref.watch(userProfileProvider);
    final weakQuestions = ref.watch(weakQuestionsProvider);
    final mockResults = ref.watch(mockTestResultsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final quizRepo = ref.watch(quizRepositoryProvider);

    final totalLessons = lessonIndex.maybeWhen(
      data: (lessons) => lessons.length,
      orElse: () => 0,
    );
    final completedLessons =
        lessonProgress.values.where((p) => p.completed).length;
    final readinessPercent = totalLessons == 0
        ? 0
        : ((completedLessons / totalLessons) * 100).clamp(0, 100).round();

    final totalQuestions = quizRepo.loadAllQuestions().length;
    final dueWeakCount = weakQuestions.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final practicePercent = totalQuestions == 0
        ? 0
        : (((totalQuestions - dueWeakCount) / totalQuestions) * 100)
            .clamp(0, 100)
            .round();

    final mockTestCount = mockResults.maybeWhen(
      data: (results) => results.length,
      orElse: () => 0,
    );
    final bestMockScore = mockResults.maybeWhen<int?>(
      data: (results) {
        if (results.isEmpty) return null;
        final latest = results.first;
        return ((latest.score / latest.totalQuestions) * 100).round();
      },
      orElse: () => null,
    );

    final greetingName = profile.maybeWhen(
      data: (p) =>
          (p?.displayName ?? '').trim().isEmpty ? 'Driver' : p!.displayName!,
      orElse: () => 'Driver',
    );

    final premiumUnlocked = isPremium.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(name: greetingName),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(lessonIndexProvider);
                  ref.invalidate(weakQuestionsProvider);
                  ref.invalidate(mockTestResultsProvider);
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(isPremiumProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadinessCard(
                        readinessPercent: readinessPercent,
                        completedLessons: completedLessons,
                        totalLessons: totalLessons,
                      ),
                      const SizedBox(height: 16),
                      _ModulesSection(
                        readinessPercent: readinessPercent,
                        practicePercent: practicePercent,
                        mockTestCount: mockTestCount,
                        bestMockScore: bestMockScore,
                        hazardPercent: 60,
                      ),
                      const SizedBox(height: 18),
                      _PremiumCard(isPremium: premiumUnlocked),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0D1B2A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theory Test Kit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hi $name, let\'s drive forward',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readinessPercent,
    required this.completedLessons,
    required this.totalLessons,
  });

  final int readinessPercent;
  final int completedLessons;
  final int totalLessons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RadialProgress(percent: readinessPercent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep it up!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$readinessPercent% ready for exam',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completed $completedLessons of $totalLessons lessons',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9CA3AF),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall readiness',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Goal: 90%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _primaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: readinessPercent / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            readinessPercent >= 70
                ? 'Strong on road signs, keep revising rules of the road.'
                : 'Focus on core rules to boost your score quickly.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

class _RadialProgress extends StatelessWidget {
  const _RadialProgress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 96,
            width: 96,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 8,
              backgroundColor: _primaryColor.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _ModulesSection extends StatelessWidget {
  const _ModulesSection({
    required this.readinessPercent,
    required this.practicePercent,
    required this.mockTestCount,
    required this.bestMockScore,
    required this.hazardPercent,
  });

  final int readinessPercent;
  final int practicePercent;
  final int mockTestCount;
  final int? bestMockScore;
  final int hazardPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Study modules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            TextButton(
              onPressed: () => context.go('/lessons'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.98,
          children: [
            _ModuleCard(
              title: 'Theory Study',
              subtitle: 'Road signs & rules',
              icon: Icons.menu_book_rounded,
              iconBg: const Color(0xFFE0ECFF),
              iconColor: const Color(0xFF2563EB),
              progressLabel: '$readinessPercent%',
              progressValue: readinessPercent / 100,
              onTap: () => context.go('/lessons'),
            ),
            _ModuleCard(
              title: 'Practice',
              subtitle: 'Questions by category',
              icon: Icons.quiz_rounded,
              iconBg: const Color(0xFFE4F5EE),
              iconColor: const Color(0xFF10B981),
              progressLabel: '$practicePercent%',
              progressValue: practicePercent / 100,
              onTap: () => context.go('/practice'),
            ),
            _ModuleCard(
              title: 'Mock exam',
              subtitle: 'Timed simulation',
              icon: Icons.timer_rounded,
              iconBg: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF7C3AED),
              progressLabel: '${mockTestCount.clamp(0, 10)}/10',
              progressValue: (mockTestCount.clamp(0, 10)) / 10,
              trailingChip:
                  bestMockScore != null ? 'Best ${bestMockScore!}%' : null,
              onTap: () => context.go('/mock-test'),
            ),
            _ModuleCard(
              title: 'Hazard clips',
              subtitle: 'Perception training',
              icon: Icons.videocam_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFF59E0B),
              progressLabel: '$hazardPercent%',
              progressValue: hazardPercent / 100,
              onTap: () => context.go('/hazard'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.progressLabel,
    required this.progressValue,
    required this.onTap,
    this.trailingChip,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String progressLabel;
  final double progressValue;
  final VoidCallback onTap;
  final String? trailingChip;

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
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                if (trailingChip != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailingChip!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue.clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progressLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremium ? 'You\'re Pro!' : 'Unlock all premium content',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isPremium
                ? 'Enjoy unlimited questions, hazard clips, and sync across devices.'
                : 'Get access to 700+ official questions and extra hazard clips.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE5E7EB),
                ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go('/profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              isPremium ? 'Manage subscription' : 'Go Pro',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomNavItem(
                label: 'Home',
                icon: Icons.home_rounded,
                active: location == '/',
                onTap: () => context.go('/'),
              ),
              _BottomNavItem(
                label: 'Progress',
                icon: Icons.bar_chart_rounded,
                active: location.startsWith('/profile'),
                onTap: () => context.go('/profile'),
              ),
              _BottomNavItem(
                label: 'Saved',
                icon: Icons.bookmark_rounded,
                active: location.contains('/lessons'),
                onTap: () => context.go('/lessons'),
              ),
              _BottomNavItem(
                label: 'Settings',
                icon: Icons.settings_rounded,
                active: location.startsWith('/login'),
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _primaryColor : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
