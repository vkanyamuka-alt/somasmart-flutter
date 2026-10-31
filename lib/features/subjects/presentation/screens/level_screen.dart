import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/subject_model.dart';
import '../controllers/subjects_controller.dart';
import '../../../../core/utils/learning_language.dart';

/// O-Level / A-Level screen: a card per form (or stream). Choosing one opens
/// that form's own screen with its subjects. Cards carry a name only. Same
/// layout as the web app's LevelBrowser (docs/DESIGN_SYSTEM.md, "Level screens").
class LevelScreen extends ConsumerWidget {
  /// 'o-level' or 'a-level'.
  final String level;

  /// The chosen form ('1'–'4') or stream ('science', 'arts'); null shows the
  /// choices.
  final String? choice;
  const LevelScreen({super.key, required this.level, this.choice});

  bool get _isO => level != 'a-level';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = learningLanguage() == 'sw';
    final levelName = _isO ? 'O-Level' : 'A-Level';
    final choices = levelChoices(level, sw);
    final current = choices.where((c) => c.key == choice).firstOrNull;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(current?.title ?? levelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: sw ? 'Rudi' : 'Back',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(current == null ? '/home' : '/subjects?level=$level'),
        ),
      ),
      body: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final columns = current == null
            ? (_isO && width >= 720 ? 4 : 2)
            : (width >= 1240 ? 5 : width >= 960 ? 4 : width >= 600 ? 3 : 2);
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xxl),
          children: [
            Text(
              current != null
                  ? levelName
                  : _isO
                      ? (sw ? 'Chagua kidato chako.' : 'Choose your form.')
                      : (sw ? 'Chagua mkondo wako.' : 'Choose your stream.'),
              style: TextStyle(fontSize: 13.5, color: muted),
            ),
            const SizedBox(height: AppSpacing.m),
            _CardRows(
              columns: columns,
              children: current == null
                  ? [
                      for (final c in choices)
                        _NameCard(
                          leading: c.icon != null ? Icon(c.icon, size: 19) : Text(c.badge ?? ''),
                          title: c.title,
                          onTap: () => context.push('/subjects/$level/${c.key}'),
                        ),
                    ]
                  : [
                      for (final id in current.subjectIds)
                        _NameCard(
                          leading: Icon(_subject(id).iconData, size: 19),
                          title: sw ? _subject(id).nameSw : _subject(id).nameEn,
                          onTap: () {
                            // The subject screen reads the form from here.
                            ref.read(pickedFormLevelProvider.notifier).state = current.form;
                            context.push('/subjects/$id');
                          },
                        ),
                    ],
            ),
          ],
        );
      }),
    );
  }

  SubjectModel _subject(String id) => initialSubjects.firstWhere((s) => s.id == id);
}

/// The subjects of each choice, in the same order as the web.
const oLevelSubjectIds = ['1', '2', '3', '4', '6', '5', '7', '8', '9'];
const aLevelScienceIds = ['1', '2', '3', '4', '12', '13'];
const aLevelArtsIds = ['7', '10', '11', '6', '5', '8'];
const aLevelForm = 5;

class LevelChoice {
  final String key;
  final String title;
  final String? badge;
  final IconData? icon;
  final List<String> subjectIds;
  final int form;
  const LevelChoice({required this.key, required this.title, this.badge, this.icon, required this.subjectIds, required this.form});
}

/// The forms of O-Level, or the streams of A-Level.
List<LevelChoice> levelChoices(String level, bool sw) => level != 'a-level'
    ? [
        for (final f in [1, 2, 3, 4])
          LevelChoice(key: '$f', badge: '$f', title: sw ? 'Kidato cha $f' : 'Form $f', subjectIds: oLevelSubjectIds, form: f),
      ]
    : [
        LevelChoice(key: 'science', icon: Icons.science_outlined, title: sw ? 'Sayansi' : 'Science', subjectIds: aLevelScienceIds, form: aLevelForm),
        LevelChoice(key: 'arts', icon: Icons.account_balance_outlined, title: sw ? 'Sanaa na Biashara' : 'Arts & Business', subjectIds: aLevelArtsIds, form: aLevelForm),
      ];

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

/// A form, stream or subject: a small square mark and the name.
class _NameCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final VoidCallback onTap;
  const _NameCard({required this.leading, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Semantics(
      button: true,
      child: Material(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: IconTheme(
                    data: IconThemeData(color: accent),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: accent),
                      child: leading,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
