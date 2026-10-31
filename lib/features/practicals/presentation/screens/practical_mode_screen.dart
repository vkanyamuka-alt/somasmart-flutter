import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';
import '../../data/repositories/practical_repository_impl.dart';

/// A practical's page: its name and aim, then Read theory and Open practical.
/// Open practical asks how to work (guided, exam or free) and starts it. In
/// English: the lab is a learning screen. Same as the web practical page.
class PracticalModeScreen extends ConsumerWidget {
  final String practicalId;

  const PracticalModeScreen({super.key, required this.practicalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final practical = ref.watch(practicalRepositoryProvider).getPracticalById(practicalId);
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    void back() => context.canPop() ? context.pop() : context.go('/practical');

    if (practical == null || !practical.hasSimulationEngine) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back', onPressed: back)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              practical == null ? 'Practical not found.' : 'This practical is not available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(practical.subject.labelEn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back', onPressed: back),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(practical.title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 8),
          Text(practical.learningObjectivesEn, style: TextStyle(fontSize: 15, height: 1.5, color: secondary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/practical/theory/${practical.id}'),
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: const Text('Read theory', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => showPracticalModeSheet(context, practical.id),
              icon: const Icon(Icons.science_outlined, size: 20),
              label: const Text('Open practical', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks how to work, then opens the simulation in that mode.
Future<void> showPracticalModeSheet(BuildContext context, String practicalId) async {
  final mode = await showModalBottomSheet<PracticalMode>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _ModeSheet(),
  );
  if (mode != null && context.mounted) {
    context.push('/practical/simulation/$practicalId?mode=${mode.name}');
  }
}

class _ModeSheet extends StatefulWidget {
  const _ModeSheet();

  @override
  State<_ModeSheet> createState() => _ModeSheetState();
}

class _ModeSheetState extends State<_ModeSheet> {
  PracticalMode _mode = PracticalMode.guidedPractice;

  static const _modes = [
    (PracticalMode.guidedPractice, Icons.explore_outlined, 'Guided', 'Each step tells you what to do and is checked before you go on.'),
    (PracticalMode.examMode, Icons.timer_outlined, 'Exam', 'Work through it yourself, as in a NECTA practical.'),
    (PracticalMode.freeExploration, Icons.psychology_outlined, 'Free', 'Any order, any setting. Nothing is locked.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How do you want to work?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final (mode, icon, title, text) in _modes) ...[
              Semantics(
                selected: _mode == mode,
                button: true,
                child: Material(
                  color: _mode == mode ? accent.withValues(alpha: 0.10) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _mode == mode ? accent : border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _mode = mode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(icon, size: 20, color: _mode == mode ? accent : secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: secondary)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_mode),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
