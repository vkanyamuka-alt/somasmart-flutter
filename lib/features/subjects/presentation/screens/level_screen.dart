import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_widgets.dart';
import '../../domain/models/subject_model.dart';
import '../controllers/subjects_controller.dart';
import '../../../../core/utils/learning_language.dart';

/// O-Level / A-Level screen: first a card per form (or stream), then the
/// chosen form's subjects as medium cards, several to a row. Same layout as
/// the web app's LevelBrowser (docs/DESIGN_SYSTEM.md, "Level screens").
class LevelScreen extends ConsumerStatefulWidget {
  /// 'o-level' or 'a-level'.
  final String level;
  const LevelScreen({super.key, required this.level});

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

/// The subjects of each choice, in the same order as the web.
const oLevelSubjectIds = ['1', '2', '3', '4', '6', '5', '7', '8', '9'];
const aLevelScienceIds = ['1', '2', '3', '4', '12', '13'];
const aLevelArtsIds = ['7', '10', '11', '6', '5', '8'];
const aLevelForm = 5;

class _Choice {
  final String key;
  final String title;
  final String? badge;
  final IconData? icon;
  final List<String> subjectIds;
  final int form;
  const _Choice({required this.key, required this.title, this.badge, this.icon, required this.subjectIds, required this.form});
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  // Nothing chosen yet: the screen opens on the form (or stream) cards.
  String? _selected;

  bool get _isO => widget.level != 'a-level';

  List<_Choice> _choices(bool sw) => _isO
      ? [
          for (final f in [1, 2, 3, 4])
            _Choice(key: '$f', badge: '$f', title: sw ? 'Kidato cha $f' : 'Form $f', subjectIds: oLevelSubjectIds, form: f),
        ]
      : [
          _Choice(key: 'science', icon: Icons.science_outlined, title: sw ? 'Sayansi' : 'Science', subjectIds: aLevelScienceIds, form: aLevelForm),
          _Choice(key: 'arts', icon: Icons.account_balance_outlined, title: sw ? 'Sanaa na Biashara' : 'Arts & Business', subjectIds: aLevelArtsIds, form: aLevelForm),
        ];

  SubjectModel _subject(String id) => initialSubjects.firstWhere((s) => s.id == id);

  @override
  Widget build(BuildContext context) {
    final sw = learningLanguage() == 'sw';
    final counts = ref.watch(lessonCountsProvider).value ?? const <String, int>{};
    final choices = _choices(sw);
    final current = choices.where((c) => c.key == _selected).firstOrNull;
    String lessons(int n) => sw ? 'Maudhui $n' : '$n ${n == 1 ? 'lesson' : 'lessons'}';
    int lessonsIn(_Choice c) => c.subjectIds.fold(0, (sum, id) => sum + lessonCountFor(counts, id, c.form));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isO ? 'O-Level' : 'A-Level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: sw ? 'Rudi' : 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final choiceColumns = _isO && width >= 720 ? 4 : 2;
        final subjectColumns = width >= 1240 ? 5 : width >= 960 ? 4 : width >= 600 ? 3 : 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xxl),
          children: [
            Text(
              _isO
                  ? (sw ? 'Kidato cha 1 hadi 4. Chagua kidato chako.' : 'Forms 1 to 4. Choose your form.')
                  : (sw ? 'Kidato cha 5 na 6. Chagua mkondo wako.' : 'Forms 5 and 6. Choose your stream.'),
              style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.l),
            SectionLabel(_isO ? (sw ? 'Chagua kidato' : 'Choose a form') : (sw ? 'Chagua mkondo' : 'Choose a stream')),
            _CardRows(
              columns: choiceColumns,
              children: [
                for (final c in choices)
                  _ChoiceCard(
                    choice: c,
                    selected: c.key == _selected,
                    meta: [sw ? 'Masomo ${c.subjectIds.length}' : '${c.subjectIds.length} subjects', lessons(lessonsIn(c))],
                    onTap: () {
                      setState(() => _selected = c.key);
                      // The subject screen reads the form from here.
                      ref.read(pickedFormLevelProvider.notifier).state = c.form;
                    },
                  ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionLabel(sw ? 'Masomo · ${current.title}' : 'Subjects · ${current.title}'),
              _CardRows(
                columns: subjectColumns,
                children: [
                  for (final id in current.subjectIds)
                    _SubjectCard(
                      subject: _subject(id),
                      sw: sw,
                      lessons: lessonCountFor(counts, id, current.form),
                      lessonsLabel: lessons,
                      onTap: () {
                        ref.read(pickedFormLevelProvider.notifier).state = current.form;
                        context.push('/subjects/$id');
                      },
                    ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

/// Cards in rows of [columns]; every card in a row is as tall as the tallest,
/// so wrapped titles never overflow and rows stay even.
class _CardRows extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  const _CardRows({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) cells.add(const SizedBox(width: gap));
        final k = i + j;
        cells.add(Expanded(child: k < children.length ? children[k] : const SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _ChoiceCard extends StatelessWidget {
  final _Choice choice;
  final bool selected;
  final List<String> meta;
  final VoidCallback onTap;
  const _ChoiceCard({required this.choice, required this.selected, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.08) : (isDark ? AppColors.darkBgSurface : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? accent : border, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: choice.icon != null
                    ? Icon(choice.icon, size: 20, color: selected ? Colors.white : accent)
                    : Text(choice.badge ?? '',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? Colors.white : accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(choice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 2),
                    Wrap(spacing: 10, children: [
                      for (final m in meta)
                        Text(m, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final bool sw;
  final int lessons;
  final String Function(int) lessonsLabel;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.sw, required this.lessons, required this.lessonsLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Material(
      color: isDark ? AppColors.darkBgSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(subject.iconData, size: 19, color: accent),
            ),
            const SizedBox(height: 8),
            Text(sw ? subject.nameSw : subject.nameEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25)),
            const Spacer(),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Text(
                  lessons > 0 ? lessonsLabel(lessons) : (sw ? 'Inakuja' : 'Coming soon'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: lessons > 0 ? FontWeight.w600 : FontWeight.w500, color: lessons > 0 ? accent : muted),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: muted),
            ]),
          ]),
        ),
      ),
    );
  }
}
