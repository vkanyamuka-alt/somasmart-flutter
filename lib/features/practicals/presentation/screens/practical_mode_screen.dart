import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';
import '../../../../core/utils/learning_language.dart';

class PracticalModeScreen extends ConsumerStatefulWidget {
  final String practicalId;

  const PracticalModeScreen({
    super.key,
    required this.practicalId,
  });

  @override
  ConsumerState<PracticalModeScreen> createState() => _PracticalModeScreenState();
}

class _PracticalModeScreenState extends ConsumerState<PracticalModeScreen> {
  PracticalMode _selectedMode = PracticalMode.guidedPractice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = learningLanguage();
    final isSwahili = language == 'sw';

    final repo = ref.watch(practicalRepositoryProvider);
    final practical = repo.getPracticalById(widget.practicalId);

    if (practical == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            isSwahili ? 'Jaribio halijapatikana.' : 'Practical not found.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final subjectTitle = isSwahili ? practical.subject.labelSw : practical.subject.labelEn;
    final levelTitle = practical.level == PracticalLevel.oLevel ? 'O-Level' : 'A-Level';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili ? 'Njia ya Jaribio' : 'Mode Selection',
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
            // 1. Practical Details & Concise Objective Box
            Container(
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
                  // Metadata Row
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
                          '$subjectTitle • $levelTitle',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 10),

                  // Practical Title
                  Text(
                    isSwahili ? practical.titleSw : practical.title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.heroNavyDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Concise 1-Sentence Objective
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSwahili
                              ? practical.learningObjectivesSw
                              : practical.learningObjectivesEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Mode Selection Heading
            Text(
              isSwahili ? 'Chagua Njia ya Kufanya Jaribio' : 'Select Practical Mode',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.heroNavyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSwahili
                  ? 'Chagua kiwango cha muongozo kabla ya kuanza simulizi ya maabara.'
                  : 'Select your preferred guidance level before launching the simulation workbench.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // 3. Mode Selection Cards
            _ModeCard(
              mode: PracticalMode.guidedPractice,
              titleEn: 'Guided Practice',
              titleSw: 'Mazoezi Yenye Muongozo',
              descEn: 'Step-by-step assistance, real-time feedback, and validation at each stage.',
              descSw: 'Muongozo wa hatua kwa hatua na maelezo ya kina katika kila hatua ya jaribio.',
              icon: Icons.assistant_navigation,
              isSelected: _selectedMode == PracticalMode.guidedPractice,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                setState(() => _selectedMode = PracticalMode.guidedPractice);
              },
            ),
            const SizedBox(height: 12),

            _ModeCard(
              mode: PracticalMode.examMode,
              titleEn: 'Exam Mode',
              titleSw: 'Hali ya Mtihani',
              descEn: 'Perform the practical independently under timed NECTA assessment conditions.',
              descSw: 'Fanya jaribio kwa kujitegemea chini ya masharti ya mtihani wa NECTA.',
              icon: Icons.timer_outlined,
              isSelected: _selectedMode == PracticalMode.examMode,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                setState(() => _selectedMode = PracticalMode.examMode);
              },
            ),
            const SizedBox(height: 12),

            _ModeCard(
              mode: PracticalMode.freeExploration,
              titleEn: 'Free Exploration',
              titleSw: 'Ugunduzi Huria',
              descEn: 'Explore apparatuses and observe scientific reactions without guided locks.',
              descSw: 'Chunguza vifaa na athari za kikemia/kifizikia kwa uhuru bila kufungwa hatua.',
              icon: Icons.explore_outlined,
              isSelected: _selectedMode == PracticalMode.freeExploration,
              isDark: isDark,
              isSwahili: isSwahili,
              onTap: () {
                setState(() => _selectedMode = PracticalMode.freeExploration);
              },
            ),
            const SizedBox(height: 24),

            // 4. Primary "Start Practical" Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final engineModeStr = _selectedMode == PracticalMode.examMode
                      ? 'examMode'
                      : (_selectedMode == PracticalMode.freeExploration
                          ? 'freeExploration'
                          : 'guidedPractice');
                  context.push('/practical/simulation/${widget.practicalId}?mode=$engineModeStr');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSwahili ? 'Anza Jaribio la Vitendo' : 'Start Practical',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.play_arrow_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final PracticalMode mode;
  final String titleEn;
  final String titleSw;
  final String descEn;
  final String descSw;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final bool isSwahili;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.titleEn,
    required this.titleSw,
    required this.descEn,
    required this.descSw,
    required this.icon,
    required this.isSelected,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary.withValues(alpha: 0.18) : const Color(0xFFF0F7FF))
                : (isDark ? AppColors.darkBgSurface : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.12)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? titleSw : titleEn,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.primary)
                            : (isDark ? Colors.white : AppColors.heroNavyDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSwahili ? descSw : descEn,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                    width: isSelected ? 5.5 : 1.5,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
