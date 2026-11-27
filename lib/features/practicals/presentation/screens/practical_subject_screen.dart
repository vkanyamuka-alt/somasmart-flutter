import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';

/// One lab subject's practicals by name, in syllabus order. Ready ones open
/// their page; the rest are dimmed with a lock. In English: the lab is a
/// learning screen. Same as the web's PracticalSubjectPage.
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
    final subject = initialSubject ?? PracticalSubject.chemistry;
    final practicals = ref.watch(practicalRepositoryProvider).getPracticalsByLevelAndSubject(level: level, subject: subject);
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.labelEn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/practical'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(level == PracticalLevel.oLevel ? 'O-Level' : 'A-Level', style: TextStyle(fontSize: 13.5, color: secondary)),
          const SizedBox(height: 12),
          for (final p in practicals) ...[
            _PracticalRow(
              practical: p,
              isDark: isDark,
              onTap: p.hasSimulationEngine ? () => context.push('/practical/mode-selection/${p.id}') : null,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// A practical's name; a chevron when it opens, a lock when it is not ready.
class _PracticalRow extends StatelessWidget {
  final PracticalModel practical;
  final bool isDark;
  final VoidCallback? onTap;

  const _PracticalRow({required this.practical, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ready = onTap != null;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Semantics(
      button: ready,
      enabled: ready,
      label: ready ? null : '${practical.title}, not available yet',
      excludeSemantics: !ready,
      child: Material(
        color: ready ? (isDark ? AppColors.darkBgSurface : Colors.white) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Expanded(
                  child: Text(
                    practical.title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: ready ? FontWeight.w700 : FontWeight.w600,
                      color: ready ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(ready ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                    size: ready ? 22 : 18, color: ready ? accent : muted),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
