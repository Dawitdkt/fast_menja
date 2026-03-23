import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_menja/core/providers/app_providers.dart';
import 'package:fast_menja/features/quiz/domain/question_model.dart';

class TheoryQuizScreen extends ConsumerStatefulWidget {
  const TheoryQuizScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TheoryQuizScreen> createState() => _TheoryQuizScreenState();
}

class _TheoryQuizScreenState extends ConsumerState<TheoryQuizScreen> {
  @override
  void initState() {
    super.initState();
    // Start theory session with 10 random questions
    Future.microtask(
      () => ref.read(quizSessionProvider.notifier).startTheoryMode(10),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theory Practice')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${session.currentIndex + 1}/${session.questionIds.length}'),
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
          if (selectedAnswer != null && selectedAnswer == question.correctIndex)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Correct!',
                style: TextStyle(color: Colors.green[700]),
              ),
            ),
          if (selectedAnswer != null && selectedAnswer != question.correctIndex)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Incorrect. Correct answer: ${question.options[question.correctIndex]}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          if (selectedAnswer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Explanation: ${question.explanation}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
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
                  onPressed: selectedAnswer != null
                      ? () {
                          ref
                              .read(quizSessionProvider.notifier)
                              .nextQuestion();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                )
              else
                ElevatedButton.icon(
                  onPressed: selectedAnswer != null
                      ? () async {
                          final result = await ref
                              .read(quizSessionProvider.notifier)
                              .completeQuiz();
                          if (result != null && mounted) {
                            _showResults(context, result);
                          }
                        }
                      : null,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
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
