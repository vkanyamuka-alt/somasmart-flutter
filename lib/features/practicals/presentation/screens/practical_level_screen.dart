import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';

class PracticalLevelScreen extends ConsumerWidget {
  const PracticalLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(languageProvider);
    final isSwahili = language == 'sw';
    final repo = ref.watch(practicalRepositoryProvider);

    final allPracticals = repo.getAllPracticals();
    final oLevelPracticals = allPracticals.where((p) => p.level == PracticalLevel.oLevel).toList();
    final aLevelPracticals = allPracticals.where((p) => p.level == PracticalLevel.aLevel).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili ? 'Maabara ya Vitendo ya SomaSmart' : 'SomaSmart Simulation Laboratory',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            // Lab Hero Intro Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [AppColors.heroNavyDark, const Color(0xFF0058BE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.science_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                isSwahili ? 'SIMULIZI ZA MAABARA' : 'VIRTUAL SIMULATIONS',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isSwahili ? 'Jifunze Sayansi kwa Vitendo' : 'Master Practical Science',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSwahili
                              ? 'Fanya majaribio halisi ya Kemia, Fizikia na Biolojia kwa kiwango cha NECTA.'
                              : 'Interactive simulations aligned with NECTA O-Level & A-Level syllabi.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.biotech_rounded,
                      color: Color(0xFF38BDF8),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Select Level Heading
            Text(
              isSwahili ? 'Chagua Ngazi ya Masomo' : 'Select Academic Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.heroNavyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSwahili
                  ? 'Chagua darasa lako ili kuona majaribio yanayolingana na silabasi yako.'
                  : 'Choose your academic tier to explore subject-specific laboratory practicals.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // O-Level Level Card
            _LevelCard(
              level: PracticalLevel.oLevel,
              titleEn: 'O-Level Secondary',
              titleSw: 'Kidato cha 1–4 (O-Level)',
              subtitleEn: 'Standard Secondary Science Curriculum (Form 1–4)',
              subtitleSw: 'Mtaala wa Sayansi wa Sekondari (Kidato cha 1–4)',
              icon: Icons.school_rounded,
              isAvailable: true,
              availableCount: oLevelPracticals.length,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () => context.push('/practical/o-level'),
            ),
            const SizedBox(height: 14),

            // A-Level Level Card
            _LevelCard(
              level: PracticalLevel.aLevel,
              titleEn: 'A-Level Advanced',
              titleSw: 'Kidato cha 5–6 (A-Level)',
              subtitleEn: 'Advanced High School Science (Form 5–6)',
              subtitleSw: 'Sayansi ya Ngazi ya Juu (Kidato cha 5–6)',
              icon: Icons.workspace_premium_rounded,
              isAvailable: false,
              availableCount: aLevelPracticals.length,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                _showALevelNoticeDialog(context, isDark, isSwahili);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showALevelNoticeDialog(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSwahili ? 'A-Level Inatengenezwa' : 'A-Level in Development',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.heroNavyDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isSwahili
              ? 'Simulizi za maabara za A-Level (Kidato cha 5 na 6) bado zipo katika hatua ya utengenezaji na zitapatikana hivi karibuni.'
              : 'Advanced Level practical simulations (Form 5 & 6) are currently in active development and will be released in an upcoming update.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final PracticalLevel level;
  final String titleEn;
  final String titleSw;
  final String subtitleEn;
  final String subtitleSw;
  final IconData icon;
  final bool isAvailable;
  final int availableCount;
  final bool isDark;
  final bool isSwahili;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.titleEn,
    required this.titleSw,
    required this.subtitleEn,
    required this.subtitleSw,
    required this.icon,
    required this.isAvailable,
    required this.availableCount,
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
              color: isAvailable
                  ? (isDark ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3))
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isAvailable ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isAvailable
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
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
                            color: isAvailable
                                ? (isDark ? const Color(0xFF065F46).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isAvailable
                                  ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            isAvailable
                                ? (isSwahili ? '$availableCount Majaribio' : '$availableCount Practicals')
                                : (isSwahili ? 'Inatengenezwa' : 'In Development'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
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
