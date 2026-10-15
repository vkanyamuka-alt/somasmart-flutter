import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/card_surface.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controllers.dart';

/// Results and Answer Review screen.
/// Faithfully reproduces React `QuizResults.jsx` scoring, metrics, trophy display, and question-by-question review.
class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  final double? fallbackScore;
  final int? fallbackTime;
  final int? fallbackTotal;
  final String? fallbackQuizId;

  const QuizResultsScreen({
    super.key,
    required this.attemptId,
    this.fallbackScore,
    this.fallbackTime,
    this.fallbackTotal,
    this.fallbackQuizId,
  });

  String _formatSeconds(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);

    final isOffline = attemptId == 'offline';

    // If online, fetch attempt from repository
    final attemptAsync = isOffline
        ? null
        : ref.watch(quizAttemptDetailProvider(attemptId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'sw' ? 'Matokeo ya Mtihani' : 'Quiz Results',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: isOffline
          ? _buildResultsBody(
              context,
              ref: ref,
              title: lang == 'sw' ? 'Jaribio la Somo' : 'Subject Quiz',
              score: fallbackScore ?? 0.0,
              timeTaken: fallbackTime ?? 0,
              quizId: fallbackQuizId,
              answersMap: (fallbackQuizId != null && fallbackQuizId!.isNotEmpty)
                  ? ref.watch(quizSessionProvider).answersMap
                  : {},
              questionsList: (fallbackQuizId != null && fallbackQuizId!.isNotEmpty)
                  ? (ref.watch(quizQuestionsProvider(fallbackQuizId!)).value ?? <QuizQuestionModel>[])
                  : <QuizQuestionModel>[],
              isOffline: true,
              lang: lang,
              isDark: isDark,
            )
          : attemptAsync!.when(
              data: (attempt) {
                if (attempt == null) {
                  final List<QuizQuestionModel> questions = (fallbackQuizId != null && fallbackQuizId!.isNotEmpty)
                      ? (ref.watch(quizQuestionsProvider(fallbackQuizId!)).value ?? <QuizQuestionModel>[])
                      : <QuizQuestionModel>[];
                  return _buildResultsBody(
                    context,
                    ref: ref,
                    title: lang == 'sw' ? 'Jaribio' : 'Quiz',
                    score: fallbackScore ?? 0.0,
                    timeTaken: fallbackTime ?? 0,
                    quizId: fallbackQuizId,
                    answersMap: (fallbackQuizId != null && fallbackQuizId!.isNotEmpty)
                        ? ref.watch(quizSessionProvider).answersMap
                        : {},
                    questionsList: questions,
                    isOffline: false,
                    lang: lang,
                    isDark: isDark,
                  );
                }

                // Also load the questions for answer review
                final questionsAsync =
                    ref.watch(quizQuestionsProvider(attempt.quizId));
                final questions = questionsAsync.value ?? [];

                return _buildResultsBody(
                  context,
                  ref: ref,
                  title: attempt.quizTitle ??
                      (lang == 'sw' ? 'Jaribio la Somo' : 'Subject Quiz'),
                  score: attempt.score,
                  timeTaken: attempt.timeTakenSeconds,
                  quizId: attempt.quizId,
                  answersMap: attempt.answers,
                  questionsList: questions,
                  isOffline: false,
                  lang: lang,
                  isDark: isDark,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang == 'sw'
                            ? 'Imeshindwa kupakia matokeo'
                            : 'Failed to load results',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          lang == 'sw' ? 'Rudi Nyumbani' : 'Back to Home',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildResultsBody(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required double score,
    required int timeTaken,
    required String? quizId,
    required Map<String, dynamic> answersMap,
    required List<QuizQuestionModel> questionsList,
    required bool isOffline,
    required String lang,
    required bool isDark,
  }) {
    final isPassed = score >= 50.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main Result Card Panel
          CardSurface(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Trophy Icon Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPassed
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 38,
                    color: isPassed ? AppColors.warning : AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),

                // Score and Time metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Score percentage
                    Column(
                      children: [
                        Text(
                          '${score.round()}%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: isPassed ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        Text(
                          lang == 'sw' ? 'Alama Yako' : 'Your Score',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      height: 48,
                      width: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),

                    // Time spent
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatSeconds(timeTaken),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang == 'sw' ? 'Muda Uliotumika' : 'Time Spent',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description message
                Text(
                  isPassed
                      ? (lang == 'sw'
                          ? 'Hongera! Umefaulu mtihani huu vizuri.'
                          : 'Congratulations! You passed this assessment.')
                      : (lang == 'sw'
                          ? 'Endelea kujaribu! Fanya mazoezi na soma muhtasari ili kuboresha matokeo yako.'
                          : 'Keep trying! Review the study notes and practice again to improve your score.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Persistence status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOffline
                        ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOffline
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                        size: 14,
                        color: isOffline
                            ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                            : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOffline
                            ? (lang == 'sw'
                                ? 'Matokeo ya kikao hiki tu (Hayajahifadhiwa mtandaoni)'
                                : 'Session results only (Not saved to cloud)')
                            : (lang == 'sw'
                                ? 'Yamehifadhiwa kwenye akaunti yako'
                                : 'Saved to your account'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isOffline
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions row
                Row(
                  children: [
                    if (quizId != null && quizId.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.pushReplacement('/quiz/$quizId');
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            lang == 'sw' ? 'Fanya Tena' : 'Retake',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: Text(
                          lang == 'sw' ? 'Dashibodi' : 'Dashboard',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        label: const Icon(Icons.arrow_forward_rounded, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Question-by-Question Review Section
          if (questionsList.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lang == 'sw'
                    ? 'Mapitio ya Majibu (Answer Review)'
                    : 'Answer Review & Explanations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            ...questionsList.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              final userAnswer = answersMap[q.id]?.toString();

              bool isUserCorrect = false;
              String correctAnswerText = '';

              if (q.questionType == 'mcq' || q.questionType == 'true_false') {
                final selectedOpt = q.options.where((o) => o.text == userAnswer).firstOrNull;
                isUserCorrect = selectedOpt?.correct ?? false;
                correctAnswerText = q.options.where((o) => o.correct).firstOrNull?.text ?? '';
              } else if (q.questionType == 'short') {
                isUserCorrect = userAnswer != null &&
                    userAnswer.trim().toLowerCase() ==
                        (q.correctAnswer ?? '').trim().toLowerCase();
                correctAnswerText = q.correctAnswer ?? '';
              }

              return CardSurface(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Question number & Correct / Incorrect Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lang == 'sw' ? 'Swali' : 'Question'} ${idx + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isUserCorrect
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUserCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 14,
                                color: isUserCorrect
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUserCorrect
                                    ? (lang == 'sw' ? 'Sahihi' : 'Correct')
                                    : (lang == 'sw' ? 'Sio Sahihi' : 'Incorrect'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isUserCorrect
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Question text
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Answer vs Correct Answer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lang == 'sw' ? 'Jibu Lako' : 'Your Answer'}: ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  userAnswer ??
                                      (lang == 'sw'
                                          ? '(Hukujibu)'
                                          : '(No Answer)'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isUserCorrect
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isUserCorrect && correctAnswerText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${lang == 'sw' ? 'Jibu Sahihi' : 'Correct Answer'}: ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    correctAnswerText,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Explanation
                    if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${lang == 'sw' ? 'Maelezo' : 'Explanation'}: ${q.explanation}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
