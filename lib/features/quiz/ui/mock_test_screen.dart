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
    if (_timer?.isActive ?? false) return;
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
        appBar: AppBar(title: const Text('Mock Exam')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _startTimer();

    final minutes = session.timeRemainingSeconds ~/ 60;
    final seconds = session.timeRemainingSeconds % 60;

    final isLowTime = session.timeRemainingSeconds <= 300;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Mock Exam'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isLowTime
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isLowTime
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isLowTime
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
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
    final isLastQuestion =
        session.currentIndex == session.questionIds.length - 1;
    final hasImage =
        question.imageAsset != null && question.imageAsset!.trim().isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${session.currentIndex + 1} of ${session.questionIds.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 14),
                if (hasImage) ...[
                  _QuestionImageCard(question: question),
                  const SizedBox(height: 14),
                ],
                ...List.generate(question.options.length, (index) {
                  final isSelected = selectedAnswer == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref
                            .read(quizSessionProvider.notifier)
                            .recordAnswer(index);
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedAnswer,
                              activeColor: const Color(0xFF1C74E9),
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                      .read(quizSessionProvider.notifier)
                                      .recordAnswer(value);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              if (session.currentIndex > 0)
                SizedBox(
                  width: 54,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      ref.read(quizSessionProvider.notifier).previousQuestion();
                    },
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              if (session.currentIndex > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFF1C74E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () async {
                    if (!isLastQuestion) {
                      ref.read(quizSessionProvider.notifier).nextQuestion();
                      return;
                    }

                    _timer?.cancel();
                    final result = await ref
                        .read(quizSessionProvider.notifier)
                        .completeQuiz();
                    if (result != null && mounted) {
                      _showResults(context, result);
                    }
                  },
                  child: Text(isLastQuestion ? 'Finish Exam' : 'Next Question'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResults(BuildContext context, MockTestResult result) {
    final passed = result.passed;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          passed ? 'Test Passed!' : 'Test Failed',
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

class _QuestionImageCard extends StatelessWidget {
  const _QuestionImageCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          question.imageAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.traffic_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
