import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';
import '../widgets/practical_thumbnail_widget.dart';

class PracticalSubjectScreen extends ConsumerWidget {
  final PracticalLevel level;
  final PracticalSubject? initialSubject;

  const PracticalSubjectScreen({
    super.key,
    required this.level,
    this.initialSubject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(languageProvider);
    final isSwahili = language == 'sw';
    final repo = ref.watch(practicalRepositoryProvider);

    final subject = initialSubject ?? PracticalSubject.chemistry;
    final practicals = repo.getPracticalsByLevelAndSubject(
      level: level,
      subject: subject,
    );

    final subjectTitle = isSwahili ? subject.labelSw : subject.labelEn;
    final levelTitle = isSwahili
        ? (level == PracticalLevel.oLevel ? 'O-Level' : 'A-Level')
        : (level == PracticalLevel.oLevel ? 'O-Level' : 'A-Level');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili
              ? 'Majaribio ya $subjectTitle ($levelTitle)'
              : '$subjectTitle Practicals — $levelTitle',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: practicals.isEmpty
          ? Center(
              child: Text(
                isSwahili ? 'Hakuna majaribio yaliyopatikana.' : 'No practicals found.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: practicals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final practical = practicals[index];
                // Student-facing practical number: 1, 2, 3...
                final practicalNumberText = isSwahili
                    ? 'Jaribio la ${index + 1}'
                    : 'Practical ${index + 1}';

                return _HorizontalPracticalCard(
                  practical: practical,
                  practicalNumberText: practicalNumberText,
                  isDark: isDark,
                  isSwahili: isSwahili,
                  onOpen: () {
                    if (practical.hasSimulationEngine) {
                      context.push('/practical/mode-selection/${practical.id}');
                    } else {
                      _showComingSoonDialog(context, practical, isDark, isSwahili);
                    }
                  },
                );
              },
            ),
    );
  }

  void _showComingSoonDialog(
    BuildContext context,
    PracticalModel practical,
    bool isDark,
    bool isSwahili,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSwahili ? 'Simulizi Inatengenezwa' : 'Simulation in Development',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.heroNavyDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isSwahili
                ? 'Simulizi ya ${practical.titleSw} bado inatengenezwa na itapatikana katika toleo lijalo.'
                : 'The interactive simulation for "${practical.title}" is currently in development and will be available soon.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isSwahili ? 'Sawa, Nimeelewa' : 'Got It',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HorizontalPracticalCard extends StatelessWidget {
  final PracticalModel practical;
  final String practicalNumberText;
  final bool isDark;
  final bool isSwahili;
  final VoidCallback onOpen;

  const _HorizontalPracticalCard({
    required this.practical,
    required this.practicalNumberText,
    required this.isDark,
    required this.isSwahili,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Unified Apparatus Thumbnail Widget
          PracticalThumbnailWidget(
            thumbnailType: practical.thumbnailType,
            size: 84,
            isDark: isDark,
          ),
          const SizedBox(width: 14),

          // Right: Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Number chip & Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        practicalNumberText,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          practical.duration,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Practical Title
                Text(
                  isSwahili ? practical.titleSw : practical.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.heroNavyDark,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Concise Description (1 line/sentence)
                Text(
                  isSwahili ? practical.descriptionSw : practical.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Real Progress Bar (Only shown if real progress > 0%)
                if (practical.progressPercent > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: practical.progressPercent / 100,
                            minHeight: 4,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${practical.progressPercent}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Action: "Open Practical" Button
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onOpen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSwahili ? 'Fungua Jaribio' : 'Open Practical',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
