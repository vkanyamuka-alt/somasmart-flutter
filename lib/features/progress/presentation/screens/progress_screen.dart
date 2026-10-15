import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:somasmart_flutter/core/theme/app_colors.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/progress/presentation/controllers/progress_controller.dart';
import 'package:somasmart_flutter/features/progress/domain/models/progress_models.dart';
import 'package:somasmart_flutter/features/progress/presentation/widgets/score_trend_chart.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';

/// Progress & Learning Analytics Screen.
/// Faithfully reproduces React `Progress.jsx` features, layout, and calculations.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final analyticsAsync = ref.watch(progressAnalyticsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgBase,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(progressAnalyticsProvider);
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Screen Header
                _HeaderSection(lang: lang, isDark: isDark),
                const SizedBox(height: 16),

                // 2. Unauthenticated / Guest Note Banner if applicable
                if (userProfileAsync.value == null ||
                    userProfileAsync.value?.id == 'guest')
                  _GuestNoticeBanner(lang: lang, isDark: isDark),

                // 3. Analytics Content
                analyticsAsync.when(
                  loading: () => const _LoadingSkeleton(),
                  error: (err, _) => _ErrorState(
                    error: err.toString(),
                    lang: lang,
                    onRetry: () => ref.invalidate(progressAnalyticsProvider),
                  ),
                  data: (analytics) => _AnalyticsBody(
                    analytics: analytics,
                    lang: lang,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String lang;
  final bool isDark;

  const _HeaderSection({required this.lang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == 'sw' ? 'Maendeleo Yako' : 'Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lang == 'sw'
                    ? 'Chunguza maendeleo yako ya kimasomo na majaribio uliyofanya.'
                    : 'Track your overall academic performance and quiz completions.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuestNoticeBanner extends StatelessWidget {
  final String lang;
  final bool isDark;

  const _GuestNoticeBanner({required this.lang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang == 'sw'
                  ? 'Ingia kwenye akaunti yako ili kuhifadhi na kufuatilia matokeo yako yote ya majaribio mtandaoni.'
                  : 'Log in to your account to record and track all your quiz test history online.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final ProgressAnalyticsModel analytics;
  final String lang;
  final bool isDark;

  const _AnalyticsBody({
    required this.analytics,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top 3 Summary Cards
        _TopStatsRow(
          avgScore: analytics.avgScore,
          totalQuizzes: analytics.totalQuizzes,
          learningStatus: analytics.learningStatus,
          lang: lang,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // 2. Score Trend Chart Card
        _ScoreTrendSection(
          attempts: analytics.chronologicalAttempts,
          lang: lang,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // 3. Subject-wise Performance Card
        _SubjectPerformanceSection(
          subjectMetrics: analytics.subjectMetrics,
          lang: lang,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // 4. Weak Topics Requiring Review Card
        _WeakTopicsSection(
          weakTopics: analytics.weakTopics,
          lang: lang,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _TopStatsRow extends StatelessWidget {
  final int avgScore;
  final int totalQuizzes;
  final String learningStatus;
  final String lang;
  final bool isDark;

  const _TopStatsRow({
    required this.avgScore,
    required this.totalQuizzes,
    required this.learningStatus,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stat 1: Avg Score
        Expanded(
          child: _StatCard(
            title: lang == 'sw' ? 'Wastani wa Alama' : 'Average Score',
            value: '$avgScore%',
            icon: Icons.military_tech_rounded,
            iconColor: AppColors.warning,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Stat 2: Quizzes Done
        Expanded(
          child: _StatCard(
            title: lang == 'sw' ? 'Majaribio (Done)' : 'Quizzes Done',
            value: '$totalQuizzes',
            icon: Icons.assignment_turned_in_rounded,
            iconColor: AppColors.primaryLight,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Stat 3: Learning Status
        Expanded(
          child: _StatCard(
            title: lang == 'sw' ? 'Hali ya Masomo' : 'Learning Status',
            value: learningStatus,
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.success,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScoreTrendSection extends StatelessWidget {
  final List<dynamic> attempts;
  final String lang;
  final bool isDark;

  const _ScoreTrendSection({
    required this.attempts,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                lang == 'sw'
                    ? 'Mwelekeo wa Alama Yako'
                    : 'Your Scoring Trend',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScoreTrendChart(
            attempts: attempts.cast(),
            lang: lang,
          ),
        ],
      ),
    );
  }
}

class _SubjectPerformanceSection extends StatelessWidget {
  final List<SubjectProgressModel> subjectMetrics;
  final String lang;
  final bool isDark;

  const _SubjectPerformanceSection({
    required this.subjectMetrics,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                lang == 'sw' ? 'Wastani kwa Somo' : 'Average by Subject',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (subjectMetrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  lang == 'sw'
                      ? 'Hakuna data ya kutosha ya masomo.'
                      : 'No subject data available.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjectMetrics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final sm = subjectMetrics[index];
                final isPassed = sm.avg >= 50;
                final statusColor =
                    isPassed ? AppColors.success : AppColors.error;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sm.getDisplayName(lang),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${sm.avg}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (sm.avg / 100.0).clamp(0.0, 1.0),
                          child: Container(color: statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        lang == 'sw'
                            ? '${sm.total} majaribio'
                            : '${sm.total} quizzes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WeakTopicsSection extends StatelessWidget {
  final List<WeakTopicModel> weakTopics;
  final String lang;
  final bool isDark;

  const _WeakTopicsSection({
    required this.weakTopics,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang == 'sw'
                      ? 'Masomo Yanayohitaji Nguvu (<60%)'
                      : 'Topics Requiring Review (<60%)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (weakTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.military_tech_rounded,
                      size: 36,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang == 'sw'
                          ? 'Kazi nzuri! Huna mada dhaifu (< 60%) kwa sasa.'
                          : 'Great job! You have no weak topics (< 60%) at the moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weakTopics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final topic = weakTopics[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.3)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang == 'sw'
                                  ? 'Alama: ${topic.score.round()}%'
                                  : 'Score: ${topic.score.round()}%',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (topic.notesId != null && topic.notesId!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            context.push('/notes/${topic.notesId}');
                          },
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: Text(
                            lang == 'sw' ? 'Soma Notes' : 'Read Notes',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final String lang;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.lang,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              lang == 'sw'
                  ? 'Imeshindwa kupakia maendeleo. Jaribu tena.'
                  : 'Failed to load progress analytics. Try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
