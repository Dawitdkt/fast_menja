import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fast_menja/features/lessons/ui/lesson_list_screen.dart';
import 'package:fast_menja/features/lessons/ui/lesson_reader_screen.dart';
import 'package:fast_menja/features/quiz/ui/theory_quiz_screen.dart';
import 'package:fast_menja/features/quiz/ui/mock_test_screen.dart';
import 'package:fast_menja/features/hazard/ui/hazard_perception_screen.dart';
import 'package:fast_menja/features/auth/ui/login_screen.dart';
import 'package:fast_menja/features/profile/ui/profile_screen.dart';

final goRouterProvider = GoRouter(
  initialLocation: '/',
  routes: [
    // Home / Dashboard
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        // Lessons
        GoRoute(
          path: 'lessons',
          builder: (context, state) => const LessonListScreen(),
          routes: [
            GoRoute(
              path: ':slug',
              builder: (context, state) => LessonReaderScreen(
                slug: state.pathParameters['slug']!,
              ),
            ),
          ],
        ),
        // Theory Mode
        GoRoute(
          path: 'theory',
          builder: (context, state) => const TheoryQuizScreen(),
        ),
        // Mock Test
        GoRoute(
          path: 'mock-test',
          builder: (context, state) => const MockTestScreen(),
        ),
        // Hazard Perception
        GoRoute(
          path: 'hazard',
          builder: (context, state) => const HazardPerceptionScreen(),
        ),
        // Road Signs
        GoRoute(
          path: 'signs',
          builder: (context, state) => const RoadSignsQuizScreen(),
        ),
        // Profile
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    // Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

// Dashboard screen placeholder
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Menja'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to Fast Menja',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/lessons'),
                icon: const Icon(Icons.book),
                label: const Text('Read Lessons'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/theory'),
                icon: const Icon(Icons.quiz),
                label: const Text('Theory Practice'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/mock-test'),
                icon: const Icon(Icons.timer),
                label: const Text('Mock Test'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/hazard'),
                icon: const Icon(Icons.videocam),
                label: const Text('Hazard Perception'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/signs'),
                icon: const Icon(Icons.directions),
                label: const Text('Road Signs Quiz'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.person),
                label: const Text('Profile & Progress'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Road Signs Quiz placeholder
class RoadSignsQuizScreen extends StatelessWidget {
  const RoadSignsQuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Road Signs Quiz')),
      body: const Center(child: Text('Road Signs Quiz - Coming Soon')),
    );
  }
}
