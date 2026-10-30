import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/card_surface.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controllers.dart';
import '../../../../core/utils/learning_language.dart';

/// Active interactive Quiz Session screen.
/// Directly mirrors React `Quiz.jsx` state machine, instant feedback, timer, and attempt submission.
class QuizSessionScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizSessionScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  final TextEditingController _shortAnswerController = TextEditingController();

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  String _formatTime(int secs) {
    final mins = secs ~/ 60;
    final s = secs % 60;
    return '${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit(BuildContext context, String lang) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'sw' ? 'Ondoka Kwenye Jaribio?' : 'Exit Quiz?'),
        content: Text(
          lang == 'sw'
              ? 'Je, una uhakika unataka kuondoka? Majibu uliyoweka yatapotea ikiwa hujaweka mtihani huu.'
              : 'Are you sure you want to exit? Your answers will not be saved if you leave before submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang == 'sw' ? 'Endelea' : 'Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang == 'sw' ? 'Ondoka' : 'Exit'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _handleComplete(BuildContext context, String studentId) async {
    final notifier = ref.read(quizSessionProvider.notifier);
    final attempt = await notifier.submitQuiz(studentId);

    if (!context.mounted) return;

    if (attempt != null && attempt.id.isNotEmpty) {
      context.pushReplacement('/quiz/results/${attempt.id}');
    } else {
      // Fallback navigation with local score metrics if network offline
      final sessionState = ref.read(quizSessionProvider);
      final scorePct = sessionState.questions.isNotEmpty
          ? ((sessionState.scoreCount / sessionState.questions.length) * 100).round()
          : 0;
      final timeTaken = (sessionState.quiz?.timeLimitMinutes ?? 10) * 60 - sessionState.timeLeft;
      context.pushReplacement(
        '/quiz/results/offline?score=$scorePct&time=$timeTaken&total=${sessionState.questions.length}&quiz_id=${widget.quizId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfileAsync = ref.watch(userProfileProvider);
    final studentId = userProfileAsync.value?.id ?? '';

    // Fetch quiz & questions
    final quizAsync = ref.watch(quizDetailProvider(widget.quizId));
    final lang = learningLanguage(quizAsync.value?.subjectId);
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quizId));

    // Handle initial state setup once data is loaded
    ref.listen<AsyncValue<List<QuizQuestionModel>>>(
      quizQuestionsProvider(widget.quizId),
      (previous, next) {
        if (next.hasValue && quizAsync.hasValue) {
          final quiz = quizAsync.value;
          final questions = next.value ?? [];
          if (quiz != null && questions.isNotEmpty && ref.read(quizSessionProvider).quiz == null) {
            ref.read(quizSessionProvider.notifier).initialize(quiz, questions);
          }
        }
      },
    );

    if (quizAsync.isLoading || questionsAsync.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                lang == 'sw' ? 'Inapakia mtihani...' : 'Loading quiz...',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (quizAsync.hasError || questionsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  lang == 'sw'
                      ? 'Imeshindwa kupakia mtihani'
                      : 'Failed to load quiz questions',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(quizDetailProvider(widget.quizId));
                    ref.invalidate(quizQuestionsProvider(widget.quizId));
                  },
                  child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quiz = quizAsync.value;
    final questions = questionsAsync.value ?? [];

    if (quiz != null && questions.isNotEmpty) {
      final currentSession = ref.watch(quizSessionProvider);
      if (currentSession.quiz == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(quizSessionProvider).quiz == null) {
            ref.read(quizSessionProvider.notifier).initialize(quiz, questions);
          }
        });
      }
    }

    if (quiz == null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  lang == 'sw'
                      ? 'Mtihani huu hauna maswali bado.'
                      : 'This quiz has no questions yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(lang == 'sw' ? 'Rudi Nyuma' : 'Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final session = ref.watch(quizSessionProvider);
    final currentQ = session.currentQuestion ?? questions.first;
    final totalQ = session.questions.isNotEmpty ? session.questions.length : questions.length;
    final currentIndex = session.currentIndex;
    final isLastQuestion = currentIndex + 1 == totalQ;
    final isLowTime = session.timeLeft <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context, lang);
        if (shouldExit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldExit = await _confirmExit(context, lang);
              if (shouldExit && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            quiz.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLowTime ? AppColors.danger : AppColors.primary,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: isLowTime ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(session.timeLeft),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isLowTime ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: session.isSubmitting
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      lang == 'sw'
                          ? 'Inawasilisha matokeo...'
                          : 'Submitting your results...',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar & Question Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lang == 'sw' ? 'Swali' : 'Question'} ${currentIndex + 1} / $totalQ',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${((currentIndex + 1) / totalQ * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / totalQ,
                        backgroundColor: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.lightBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Question Card
                    CardSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.help_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentQ.questionText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Answers Section
                          if (currentQ.questionType == 'mcq' ||
                              currentQ.questionType == 'true_false') ...[
                            ...currentQ.options.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final option = entry.value;
                              final isSelected = session.selectedOption?.text == option.text;

                              Color borderColor = isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder;
                              Color bgColor = isDark
                                  ? AppColors.darkBgSurface
                                  : Colors.white;

                              if (session.isAnswered) {
                                if (option.correct) {
                                  borderColor = AppColors.success;
                                  bgColor = AppColors.success.withValues(alpha: 0.12);
                                } else if (isSelected && !option.correct) {
                                  borderColor = AppColors.danger;
                                  bgColor = AppColors.danger.withValues(alpha: 0.12);
                                }
                              } else if (isSelected) {
                                borderColor = AppColors.primary;
                                bgColor = AppColors.primary.withValues(alpha: 0.08);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: session.isAnswered
                                      ? null
                                      : () {
                                          ref
                                              .read(quizSessionProvider.notifier)
                                              .checkAnswer(option);
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: borderColor,
                                        width: (isSelected || (session.isAnswered && option.correct))
                                            ? 1.8
                                            : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: (session.isAnswered && option.correct)
                                                ? AppColors.success
                                                : (isSelected && !option.correct && session.isAnswered)
                                                    ? AppColors.danger
                                                    : (isDark
                                                        ? Colors.white10
                                                        : Colors.black.withValues(alpha: 0.05)),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + idx),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                color: (session.isAnswered &&
                                                        (option.correct || isSelected))
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white70
                                                        : Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (session.isAnswered && option.correct)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.success,
                                            size: 20,
                                          )
                                        else if (session.isAnswered && isSelected && !option.correct)
                                          const Icon(
                                            Icons.cancel_rounded,
                                            color: AppColors.danger,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ] else if (currentQ.questionType == 'short') ...[
                            TextField(
                              controller: _shortAnswerController,
                              enabled: !session.isAnswered,
                              decoration: InputDecoration(
                                hintText: lang == 'sw'
                                    ? 'Andika jibu lako hapa...'
                                    : 'Type your answer here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!session.isAnswered)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(quizSessionProvider.notifier)
                                        .checkShortAnswer(_shortAnswerController.text);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    lang == 'sw' ? 'Thibitisha' : 'Confirm Answer',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],

                          // Explanation block if answered
                          if (session.isAnswered) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: session.isCorrect
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: session.isCorrect
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        session.isCorrect
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        color: session.isCorrect
                                            ? AppColors.success
                                            : AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        session.isCorrect
                                            ? (lang == 'sw' ? 'Sahihi!' : 'Correct!')
                                            : (lang == 'sw' ? 'Sio Sahihi!' : 'Incorrect!'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: session.isCorrect
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (currentQ.explanation != null &&
                                      currentQ.explanation!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${lang == 'sw' ? 'Maelezo Sahihi:' : 'Explanation:'} ${currentQ.explanation}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Next / Submit Button
                    if (session.isAnswered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastQuestion) {
                              _handleComplete(context, studentId);
                            } else {
                              _shortAnswerController.clear();
                              ref.read(quizSessionProvider.notifier).nextQuestion();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastQuestion
                                    ? (lang == 'sw'
                                        ? 'Wasilisha Mtihani'
                                        : 'Submit Quiz')
                                    : (lang == 'sw'
                                        ? 'Swali Linalofuata'
                                        : 'Next Question'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastQuestion
                                    ? Icons.task_alt_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
