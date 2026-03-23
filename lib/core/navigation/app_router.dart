import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fast_menja/features/lessons/ui/lesson_list_screen.dart';
import 'package:fast_menja/features/lessons/ui/lesson_reader_screen.dart';
import 'package:fast_menja/features/quiz/ui/theory_quiz_screen.dart';
import 'package:fast_menja/features/quiz/ui/mock_test_screen.dart';
import 'package:fast_menja/features/hazard/ui/hazard_perception_screen.dart';
import 'package:fast_menja/features/auth/ui/login_screen.dart';
import 'package:fast_menja/features/profile/ui/profile_screen.dart';
import 'package:fast_menja/features/dashboard/ui/dashboard_screen.dart';

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
