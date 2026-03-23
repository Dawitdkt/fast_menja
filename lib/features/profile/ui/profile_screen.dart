import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final completedCount = ref.watch(completedLessonsCountProvider);
    final mockTests = ref.watch(mockTestResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Sign out logic
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User section
            userProfile.when(
              data: (profile) {
                if (profile == null) {
                  return _buildGuestCard();
                }
                return _buildUserCard(profile);
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 24),
            // Progress section
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildProgressCard('Lessons Completed', '$completedCount lessons'),
            const SizedBox(height: 12),
            mockTests.when(
              data: (tests) => _buildProgressCard(
                'Mock Tests',
                '${tests.length} attempts',
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            // Premium section
            _buildPremiumSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Guest User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to sync your progress across devices',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.displayName ?? profile.email ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (profile.isPremium)
              const Chip(
                label: Text('Premium Member'),
                backgroundColor: Color(0xFFFFD700),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSection(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return isPremium.when(
      data: (premium) {
        if (premium) {
          return Card(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('You have Premium access!'),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlimited access to mock tests, hazard perception, and spaced repetition',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Show pricing
                  },
                  child: const Text('Upgrade Now'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
