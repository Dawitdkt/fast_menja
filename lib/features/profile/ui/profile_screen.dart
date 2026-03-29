import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final completedCount = ref.watch(completedLessonsCountProvider);
    final mockTests = ref.watch(mockTestResultsProvider);
    final lessonProgress = ref.watch(lessonProgressProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    final tests = mockTests.value ?? <MockTestResult>[];
    final totalAttempts = tests.length;

    final totalCorrect = tests.fold<int>(0, (sum, t) => sum + t.score);
    final totalAnswered =
        tests.fold<int>(0, (sum, t) => sum + t.totalQuestions);
    final accuracyPercent =
        totalAnswered == 0 ? 0 : ((totalCorrect / totalAnswered) * 100).round();

    final activityDays = <DateTime>[
      ...tests.map((t) => _toDateOnly(t.passedAt)),
      ...lessonProgress.values
          .where((p) => p.completedAt != null)
          .map((p) => _toDateOnly(p.completedAt!)),
    ];

    final streakDays = _computeStreak(activityDays);
    final xp = _computeXp(completedCount, totalAttempts, accuracyPercent);
    final level = (xp ~/ 500) + 1;
    final currentLevelBase = (level - 1) * 500;
    final currentLevelXp = xp - currentLevelBase;
    const xpPerLevel = 500;
    final progress = (currentLevelXp / xpPerLevel).clamp(0.0, 1.0);

    final profile = userProfile.value;
    final displayName = profile?.displayName ??
        currentUser?.displayName ??
        currentUser?.email?.split('@').first ??
        'Guest Driver';
    final subtitle = isPremium ? 'Road Master Aspirant' : 'Learning Driver';
    final avatarText = displayName.trim().isEmpty
        ? 'G'
        : displayName.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHero(
              avatarText: avatarText,
              displayName: displayName,
              subtitle: subtitle,
              level: level,
              currentXp: currentLevelXp,
              neededXp: xpPerLevel,
              progress: progress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.quiz_rounded,
                    iconColor: const Color(0xFF258CF4),
                    label: 'Quizzes',
                    value: '$totalAttempts',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.verified_rounded,
                    iconColor: const Color(0xFF10B981),
                    label: 'Accuracy',
                    value: '$accuracyPercent%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Streak',
                    value: '$streakDays',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _AchievementsGrid(
              items: _buildAchievements(
                completedCount: completedCount,
                attempts: totalAttempts,
                accuracyPercent: accuracyPercent,
                streakDays: streakDays,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _SettingTile(
              icon: Icons.person_rounded,
              label: 'Personal Information',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile editing coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
            _SettingToggleTile(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.security_rounded,
              label: 'Security & Privacy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Security settings coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.support_agent_rounded,
              label: 'Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support center coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
            _PremiumCard(isPremium: isPremium),
            const SizedBox(height: 8),
            if (currentUser != null)
              _LogoutTile(
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                  }
                },
              ),
            if (userProfile.isLoading || mockTests.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (userProfile.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Profile sync error: ${userProfile.error}',
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            if (mockTests.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Progress sync error: ${mockTests.error}',
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

int _computeXp(int completedLessons, int attempts, int accuracyPercent) {
  return (completedLessons * 120) + (attempts * 80) + (accuracyPercent * 6);
}

DateTime _toDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int _computeStreak(List<DateTime> activityDays) {
  if (activityDays.isEmpty) return 0;

  final unique = activityDays.toSet().toList()..sort((a, b) => b.compareTo(a));
  final today = _toDateOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  if (unique.first != today && unique.first != yesterday) return 0;

  int streak = 1;
  for (int i = 1; i < unique.length; i++) {
    final expected = unique[i - 1].subtract(const Duration(days: 1));
    if (unique[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

List<_AchievementItem> _buildAchievements({
  required int completedCount,
  required int attempts,
  required int accuracyPercent,
  required int streakDays,
}) {
  return [
    _AchievementItem(
      title: 'First Win',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFF59E0B),
      unlocked: attempts > 0,
    ),
    _AchievementItem(
      title: 'Scholar',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF3B82F6),
      unlocked: completedCount >= 3,
    ),
    _AchievementItem(
      title: 'Fastest',
      icon: Icons.speed_rounded,
      color: const Color(0xFFEF4444),
      unlocked: attempts >= 10,
    ),
    _AchievementItem(
      title: 'Pro',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFF8B5CF6),
      unlocked: accuracyPercent >= 85,
    ),
    _AchievementItem(
      title: 'Streak',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFF97316),
      unlocked: streakDays >= 5,
    ),
    _AchievementItem(
      title: 'Consistent',
      icon: Icons.timeline_rounded,
      color: const Color(0xFF14B8A6),
      unlocked: streakDays >= 10,
    ),
    _AchievementItem(
      title: 'Expert',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF6366F1),
      unlocked: attempts >= 30,
    ),
    _AchievementItem(
      title: 'More',
      icon: Icons.add_circle_outline_rounded,
      color: const Color(0xFF64748B),
      unlocked: false,
    ),
  ];
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.avatarText,
    required this.displayName,
    required this.subtitle,
    required this.level,
    required this.currentXp,
    required this.neededXp,
    required this.progress,
  });

  final String avatarText;
  final String displayName;
  final String subtitle;
  final int level;
  final int currentXp;
  final int neededXp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33258CF4), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF258CF4), width: 3),
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF258CF4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    'LVL $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROGRESS TO NEXT LEVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '$currentXp / $neededXp XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF258CF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF258CF4),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem {
  const _AchievementItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool unlocked;
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.items});

  final List<_AchievementItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final unlocked = item.unlocked;

        return Opacity(
          opacity: unlocked ? 1 : 0.45,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? item.color.withOpacity(0.15)
                      : const Color(0xFFE2E8F0),
                ),
                child: Icon(
                  unlocked ? item.icon : Icons.lock_rounded,
                  color: unlocked ? item.color : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            _SettingIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _SettingToggleTile extends StatelessWidget {
  const _SettingToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF258CF4),
          ),
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x33258CF4),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Icon(icon, color: const Color(0xFF258CF4), size: 20),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFFF7DB) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPremium ? const Color(0xFFFCD34D) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.auto_awesome_rounded,
            color:
                isPremium ? const Color(0xFFA16207) : const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPremium
                  ? 'Premium active: You have full access to all practice content.'
                  : 'Upgrade to Premium for unlimited mock tests and extra practice sets.',
              style: TextStyle(
                color: isPremium
                    ? const Color(0xFF92400E)
                    : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          children: [
            _SettingIcon(icon: Icons.logout_rounded),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
