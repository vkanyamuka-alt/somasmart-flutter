import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/card_surface.dart';
import '../../../../core/widgets/status_badge.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Practice Overview Stat Card
          CardSurface(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(context, label: 'Quizzes Taken', value: '14'),
                Container(height: 36, width: 1, color: AppColors.darkBorderSubtle),
                _buildStatColumn(context, label: 'Accuracy', value: '82%'),
                Container(height: 36, width: 1, color: AppColors.darkBorderSubtle),
                _buildStatColumn(context, label: 'Streak', value: '5 Days'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories
          Text(
            'Practice Modes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),

          _buildPracticeModeCard(
            context,
            title: 'NECTA Past Papers Drill',
            description: 'Timed questions from official NECTA CSEE & ACSEE national exams.',
            icon: Icons.timer_outlined,
            color: AppColors.primaryLight,
            tag: 'Exam Mode',
          ),
          const SizedBox(height: 12),
          _buildPracticeModeCard(
            context,
            title: 'Topic-by-Topic Mastery',
            description: 'Target specific weak areas with step-by-step explanations.',
            icon: Icons.auto_stories_rounded,
            color: AppColors.secondary,
            tag: 'Topic Drill',
          ),
          const SizedBox(height: 12),
          _buildPracticeModeCard(
            context,
            title: 'Speed Challenge Quiz',
            description: '60 seconds per question to test your formula recall and speed.',
            icon: Icons.bolt_rounded,
            color: AppColors.accentGold,
            tag: 'Rapid Fire',
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPracticeModeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String tag,
  }) {
    return CardSurface(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    StatusBadge(label: tag, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
