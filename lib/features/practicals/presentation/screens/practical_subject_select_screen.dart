import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';
import '../controllers/practical_catalog_controller.dart';

class PracticalSubjectSelectScreen extends ConsumerWidget {
  final PracticalLevel level;

  const PracticalSubjectSelectScreen({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(languageProvider);
    final isSwahili = language == 'sw';
    final repo = ref.watch(practicalRepositoryProvider);

    final chemPracticals = repo.getPracticalsByLevelAndSubject(
      level: level,
      subject: PracticalSubject.chemistry,
    );
    final physPracticals = repo.getPracticalsByLevelAndSubject(
      level: level,
      subject: PracticalSubject.physics,
    );
    final bioPracticals = repo.getPracticalsByLevelAndSubject(
      level: level,
      subject: PracticalSubject.biology,
    );

    final isOLevel = level == PracticalLevel.oLevel;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili
              ? (isOLevel ? 'Masomo ya O-Level' : 'Masomo ya A-Level')
              : (isOLevel ? 'O-Level Laboratory' : 'A-Level Laboratory'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Academic Intro Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili ? 'Chagua Somo la Sayansi' : 'Select Science Discipline',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.heroNavyDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSwahili
                              ? 'Chagua somo ili kuona majaribio ya vitendo yaliyopo.'
                              : 'Select a subject to view available curriculum practicals.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Subject Cards List
            _SubjectCard(
              titleEn: 'Chemistry',
              titleSw: 'Kemia',
              subtitleEn: 'Volumetric analysis, reaction kinetics & gas preparation',
              subtitleSw: 'Uchambuzi wa ujazo, kasi ya athari na utengenezaji wa gesi',
              icon: Icons.science_outlined,
              practicalsCount: chemPracticals.length,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                ref.read(selectedPracticalSubjectProvider.notifier).state = PracticalSubject.chemistry;
                context.push('/practical/${level.id}/chemistry');
              },
            ),
            const SizedBox(height: 12),

            _SubjectCard(
              titleEn: 'Physics',
              titleSw: 'Fizikia',
              subtitleEn: 'Electricity, optics, mechanics & wave dynamics',
              subtitleSw: 'Umeme, optiki, mekaniki na nguvu ya mawimbi',
              icon: Icons.bolt_outlined,
              practicalsCount: physPracticals.length,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                ref.read(selectedPracticalSubjectProvider.notifier).state = PracticalSubject.physics;
                context.push('/practical/${level.id}/physics');
              },
            ),
            const SizedBox(height: 12),

            _SubjectCard(
              titleEn: 'Biology',
              titleSw: 'Biolojia',
              subtitleEn: 'Cytology, plant tissue physiology & osmosis',
              subtitleSw: 'Seli za viumbe, fisiojia ya mimea na osmosisi',
              icon: Icons.biotech_outlined,
              practicalsCount: bioPracticals.length,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                ref.read(selectedPracticalSubjectProvider.notifier).state = PracticalSubject.biology;
                context.push('/practical/${level.id}/biology');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String titleEn;
  final String titleSw;
  final String subtitleEn;
  final String subtitleSw;
  final IconData icon;
  final int practicalsCount;
  final bool isDark;
  final bool isSwahili;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.titleEn,
    required this.titleSw,
    required this.subtitleEn,
    required this.subtitleSw,
    required this.icon,
    required this.practicalsCount,
    required this.isDark,
    required this.isSwahili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSwahili ? titleSw : titleEn,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.heroNavyDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSwahili
                                ? '$practicalsCount Majaribio'
                                : '$practicalsCount Practicals',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSwahili ? subtitleSw : subtitleEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
