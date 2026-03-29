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
  final Set<int> _revealedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final session = ref.read(quizSessionProvider);
      if (session == null) {
        ref.read(quizSessionProvider.notifier).startTheoryMode(10);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice Module')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Practice Module'),
        actions: [
          IconButton(
            tooltip: 'Bookmark',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark feature coming soon')),
              );
            },
            icon: const Icon(Icons.bookmark_border_rounded),
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
    final currentIndex = session.currentIndex;
    final selectedAnswer = session.userAnswers[session.currentIndex];
    final isRevealed = _revealedIndexes.contains(currentIndex);
    final isLastQuestion =
        session.currentIndex == session.questionIds.length - 1;
    final canCheck = selectedAnswer != null && !isRevealed;
    final canAdvance = selectedAnswer != null && isRevealed;
    final hasImage =
        question.imageAsset != null && question.imageAsset!.trim().isNotEmpty;

    final primaryLabel = selectedAnswer == null
        ? 'Select an answer'
        : !isRevealed
            ? 'Check Answer'
            : isLastQuestion
                ? 'Finish'
                : 'Next Question';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  final isCorrectOption = index == question.correctIndex;
                  final isWrongSelected =
                      isRevealed && isSelected && !isCorrectOption;

                  Color borderColor = const Color(0xFFE2E8F0);
                  Color backgroundColor = Colors.white;
                  Widget? trailing;

                  if (!isRevealed && isSelected) {
                    borderColor = const Color(0xFF60A5FA);
                    backgroundColor = const Color(0xFFEFF6FF);
                  }

                  if (isRevealed && isCorrectOption) {
                    borderColor = const Color(0xFF10B981);
                    backgroundColor = const Color(0xFFECFDF5);
                    trailing = const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                    );
                  } else if (isWrongSelected) {
                    borderColor = const Color(0xFFEF4444);
                    backgroundColor = const Color(0xFFFEF2F2);
                    trailing = const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFEF4444),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isRevealed
                          ? null
                          : () {
                              ref
                                  .read(quizSessionProvider.notifier)
                                  .recordAnswer(index);
                            },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedAnswer,
                              activeColor: const Color(0xFF1C74E9),
                              onChanged: isRevealed
                                  ? null
                                  : (value) {
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
                            if (trailing != null) trailing,
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (isRevealed && selectedAnswer != null)
                  _AnswerFeedbackCard(
                    isCorrect: selectedAnswer == question.correctIndex,
                    explanation: question.explanation,
                  ),
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
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFF1C74E9),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: selectedAnswer == null
                      ? null
                      : () async {
                          if (canCheck) {
                            setState(() {
                              _revealedIndexes.add(currentIndex);
                            });
                            return;
                          }

                          if (canAdvance && !isLastQuestion) {
                            ref
                                .read(quizSessionProvider.notifier)
                                .nextQuestion();
                            return;
                          }

                          if (canAdvance && isLastQuestion) {
                            final result = await ref
                                .read(quizSessionProvider.notifier)
                                .completeQuiz();
                            if (result != null && mounted) {
                              _showResults(context, result);
                            }
                          }
                        },
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 10),
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
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Hint'),
                        content: Text(question.explanation),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      child: question.imageAsset != null && question.imageAsset!.isNotEmpty
          ? ClipRRect(
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
            )
          : const Center(
              child: Icon(
                Icons.traffic_rounded,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
            ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard(
      {required this.isCorrect, required this.explanation});

  final bool isCorrect;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final background =
        isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final border =
        isCorrect ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
    final accent =
        isCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final title = isCorrect ? 'Correct Answer' : 'Review This Answer';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
