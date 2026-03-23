import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  const MockTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(quizSessionProvider.notifier).startMockTest(),
    );
  }

  @override
  void didUpdateWidget(MockTestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = ref.read(quizSessionProvider);
      if (session != null && session.timeRemainingSeconds > 0) {
        ref
            .read(quizSessionProvider.notifier)
            .updateTimer(session.timeRemainingSeconds - 1);
      } else if (session != null && session.timeRemainingSeconds == 0) {
        _autoCompleteTest();
      }
    });
  }

  Future<void> _autoCompleteTest() async {
    _timer?.cancel();
    final result = await ref.read(quizSessionProvider.notifier).completeQuiz();
    if (result != null && mounted) {
      _showResults(context, result);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Test')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _startTimer();

    final minutes = session.timeRemainingSeconds ~/ 60;
    final seconds = session.timeRemainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${session.currentIndex + 1}/50'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _buildQuizContent(context, ref, session),
    );
  }

  Widget _buildQuizContent(
    BuildContext context,
    WidgetRef ref,
    QuizSession session,
  ) {
    final questionId = session.questionIds[session.currentIndex];
    final questionAsync = ref.watch(questionProvider(questionId));

    return questionAsync.when(
      data: (question) {
        if (question == null) {
          return const Center(child: Text('Question not found'));
        }
        return _buildQuestionContent(context, ref, session, question);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildQuestionContent(
    BuildContext context,
    WidgetRef ref,
    QuizSession session,
    Question question,
  ) {
    final selectedAnswer = session.userAnswers[session.currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ...List.generate(question.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: selectedAnswer == index
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : null,
                  side: BorderSide(
                    color: selectedAnswer == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
                onPressed: () {
                  ref.read(quizSessionProvider.notifier).recordAnswer(index);
                },
                child: Text(
                  question.options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedAnswer == index
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (session.currentIndex > 0)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).previousQuestion();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              if (session.currentIndex < session.questionIds.length - 1)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).nextQuestion();
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    _timer?.cancel();
                    final result = await ref
                        .read(quizSessionProvider.notifier)
                        .completeQuiz();
                    if (result != null && mounted) {
                      _showResults(context, result);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Finish'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResults(BuildContext context, MockTestResult result) {
    final passed = result.passed;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          passed ? 'Test Passed! 🎉' : 'Test Failed',
          style: TextStyle(
            color: passed ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: ${result.score}/${result.totalQuestions}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${((result.score / result.totalQuestions) * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 8),
            Text(
              'Pass mark: 43/50 (86%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
