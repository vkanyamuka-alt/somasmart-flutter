import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notes/presentation/screens/note_viewer_screen.dart';
import '../../domain/models/syllabus_topic_model.dart';
import '../controllers/subjects_controller.dart';
import '../../../../core/utils/learning_language.dart';
import '../../../../core/utils/subject_content.dart';

/// Subject Detail Screen with 3 Tabs (Notes, Understand & Master, Memorize).
/// Fully aligned with React `SubjectDetail.jsx`.
class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = learningLanguage(widget.subjectId);
    final selectedForm = ref.watch(selectedFormLevelProvider);
    final detailAsync = ref.watch(subjectDetailProvider(widget.subjectId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        title: detailAsync.when(
          data: (data) => Text(
            lang == 'sw' ? data.subject.nameSw : data.subject.nameEn,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          loading: () => const Text(''),
          error: (error, stackTrace) => const Text(''),
        ),
        actions: [
          // Form level selector popup/chip
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<int>(
              initialValue: selectedForm,
              onSelected: (val) {
                ref.read(pickedFormLevelProvider.notifier).state = val;
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? AppColors.darkBgSurface : Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Form $selectedForm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [1, 2, 3, 4, 5, 6].map((f) {
                return PopupMenuItem<int>(
                  value: f,
                  child: Text(
                    'Form $f',
                    style: TextStyle(
                      fontWeight: selectedForm == f
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedForm == f ? AppColors.primary : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  lang == 'sw'
                      ? 'Hitilafu wakati wa kupakia maudhui ya somo.'
                      : 'Failed to load subject details.',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(subjectDetailProvider(widget.subjectId)),
                  child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final notes = data.notes;
          final materials = data.materials;
          final memorize = data.memorizeItems;
          final topics = data.topics;
          final hasAccess = data.hasAccess;
          final accent = isDark ? AppColors.primaryLight : AppColors.primary;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    // Only the Premium banner sits here; no gap without it.
                    padding: hasAccess
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The app bar already names the subject and form.
                        // Subscription Paywall Banner
                        if (!hasAccess) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lang == 'sw'
                                      ? 'Maudhui Haya Yanahitaji Usajili'
                                      : 'Subscription Required for Full Access',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang == 'sw'
                                      ? 'Muda wako wa majaribio umeisha. Lipia TSh 2,500 tu kwa mwezi kufungua muhtasari wote wa masomo na video.'
                                      : 'Your trial period has ended. Subscribe for TSh 2,500/month to unlock all study notes and videos.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.push('/subscription'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    lang == 'sw'
                                        ? 'Lipia Usajili Sasa (TSh 2,500)'
                                        : 'Activate Subscription Now',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: accent,
                      unselectedLabelColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      indicatorColor: accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: [
                        // Text only, so the three views stay one short row.
                        Tab(text: lang == 'sw' ? 'Muhtasari' : 'Notes'),
                        Tab(
                          text: lang == 'sw' ? 'Elewa na Miliki' : 'Understand',
                        ),
                        Tab(text: lang == 'sw' ? 'Kumbuka' : 'Memorize'),
                      ],
                    ),
                    isDark: isDark,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                for (final tab in SubjectTab.values)
                  _ContentTab(
                    topics: topics,
                    notes: notes
                        .where((n) => tabOf(ContentKind.note, n.section) == tab)
                        .toList(),
                    materials: materials
                        .where(
                          (m) => tabOf(ContentKind.material, m.section) == tab,
                        )
                        .toList(),
                    cards: tab == SubjectTab.memorize ? memorize : const [],
                    emptyIcon: switch (tab) {
                      SubjectTab.notes => Icons.menu_book_outlined,
                      SubjectTab.understand =>
                        Icons.play_circle_outline_rounded,
                      SubjectTab.memorize => Icons.psychology_outlined,
                    },
                    emptyText: switch (tab) {
                      SubjectTab.notes =>
                        lang == 'sw'
                            ? 'Bado hakuna muhtasari wa somo hili.'
                            : 'No study notes available for this subject yet.',
                      SubjectTab.understand =>
                        lang == 'sw'
                            ? 'Video, maelezo na masomo ya somo hili yanakuja.'
                            : 'Videos, notes and lessons for this subject are coming.',
                      SubjectTab.memorize =>
                        lang == 'sw'
                            ? 'Fomula, mbinu za kukumbuka na marudio ya haraka yanakuja.'
                            : 'Formulas, memory tricks and quick revision are coming.',
                    },
                    lang: lang,
                    isDark: isDark,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkBgBase : AppColors.lightBgContainer,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

/// One tab of the subject page: the subject's syllabus topics in order, each
/// its own card (same as the web subject page). A topic lists what the admin
/// put in this tab for it — written notes, then videos and files, then memory
/// cards; a topic with nothing yet is a quiet card.
class _ContentTab extends StatelessWidget {
  final List<SyllabusTopic> topics;
  final List<SubjectNoteItem> notes;
  final List<SubjectMaterialItem> materials;
  final List<SubjectMemorizeItem> cards;
  final IconData emptyIcon;
  final String emptyText;
  final String lang;
  final bool isDark;

  const _ContentTab({
    required this.topics,
    required this.notes,
    required this.materials,
    required this.cards,
    required this.emptyIcon,
    required this.emptyText,
    required this.lang,
    required this.isDark,
  });

  static bool _mentions(String text, SyllabusTopic topic) {
    final t = text.toLowerCase();
    return t.contains(topic.en.toLowerCase()) ||
        t.contains(topic.sw.toLowerCase());
  }

  static bool _noteIn(SubjectNoteItem n, SyllabusTopic t) =>
      _mentions('${n.title} ${n.description} ${n.topic ?? ""}', t);
  static bool _materialIn(SubjectMaterialItem m, SyllabusTopic t) =>
      _mentions('${m.title} ${m.description} ${m.topic ?? ""}', t);
  static bool _cardIn(SubjectMemorizeItem c, SyllabusTopic t) =>
      _mentions('${c.title} ${c.topic}', t);

  Widget? _items(
    List<SubjectNoteItem> n,
    List<SubjectMaterialItem> m,
    List<SubjectMemorizeItem> c,
  ) {
    if (n.isEmpty && m.isEmpty && c.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (n.isNotEmpty) _NoteLinks(notes: n, lang: lang),
        if (m.isNotEmpty) _MaterialLinks(materials: m),
        if (c.isNotEmpty) _MemoryCards(cards: c),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nothing = notes.isEmpty && materials.isEmpty && cards.isEmpty;
    if (topics.isEmpty && nothing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 40,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                emptyText,
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
      );
    }

    if (topics.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_items(notes, materials, cards)!],
      );
    }

    final rows = <Widget>[];
    final placedNotes = <SubjectNoteItem>{};
    final placedMaterials = <SubjectMaterialItem>{};
    final placedCards = <SubjectMemorizeItem>{};
    for (var i = 0; i < topics.length; i++) {
      final t = topics[i];
      final n = notes.where((x) => _noteIn(x, t)).toList();
      final m = materials.where((x) => _materialIn(x, t)).toList();
      final c = cards.where((x) => _cardIn(x, t)).toList();
      placedNotes.addAll(n);
      placedMaterials.addAll(m);
      placedCards.addAll(c);
      final child = _items(n, m, c);
      rows.add(
        _TopicRow(
          number: '${i + 1}',
          name: lang == 'sw' ? t.sw : t.en,
          isEmpty: child == null,
          isDark: isDark,
          child: child,
        ),
      );
    }
    final extra = _items(
      notes.where((x) => !placedNotes.contains(x)).toList(),
      materials.where((x) => !placedMaterials.contains(x)).toList(),
      cards.where((x) => !placedCards.contains(x)).toList(),
    );
    if (extra != null) {
      rows.add(
        _TopicRow(
          number: '+',
          name: lang == 'sw' ? 'Maudhui ya ziada' : 'More resources',
          isEmpty: false,
          isDark: isDark,
          child: extra,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => rows[i],
    );
  }
}

/// One syllabus topic as a card: number and name, then its content. A topic
/// without notes yet is a quiet card with no fill.
class _TopicRow extends StatelessWidget {
  final String number;
  final String name;
  final bool isEmpty;
  final bool isDark;
  final Widget? child;

  const _TopicRow({
    required this.number,
    required this.name,
    required this.isEmpty,
    required this.isDark,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    // Navy is lifted in dark mode so it stays readable (as on the web).
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isEmpty
            ? null
            : (isDark ? AppColors.darkBgSurface : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.fromLTRB(14, 12, 14, child == null ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? muted.withValues(alpha: 0.12)
                      : accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isEmpty ? muted : accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
                    color: isEmpty ? secondary : null,
                  ),
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 10), child!],
        ],
      ),
    );
  }
}

/// A topic's notes: one row each, the whole row opens the note.
class _NoteLinks extends StatelessWidget {
  final List<SubjectNoteItem> notes;
  final String lang;

  const _NoteLinks({required this.notes, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Column(
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isDark ? AppColors.darkBgBase : AppColors.lightBgContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                // Pass the note straight to the viewer (no second fetch).
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteViewerScreen(note: note),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          lang == 'sw' ? 'Soma' : 'Read',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A topic's videos, audio and files: one row each, the row opens it.
class _MaterialLinks extends StatelessWidget {
  final List<SubjectMaterialItem> materials;

  const _MaterialLinks({required this.materials});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        for (final mat in materials)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openMaterial(context, mat),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgBase
                      : AppColors.lightBgContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          mat.materialType == 'video'
                              ? Icons.play_arrow_rounded
                              : mat.materialType == 'audio'
                              ? Icons.headphones_rounded
                              : Icons.description_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mat.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_blurb(mat).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _blurb(mat),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _blurb(SubjectMaterialItem m) =>
      m.shortDescription.isNotEmpty ? m.shortDescription : m.description;

  Future<void> _openMaterial(
    BuildContext context,
    SubjectMaterialItem mat,
  ) async {
    final uri = mat.openUri;
    final messenger = ScaffoldMessenger.of(context);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Kifaa hiki bado hakina faili. / This material has no file yet.',
          ),
        ),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kufungua. / Could not open it.'),
        ),
      );
    }
  }
}

/// A topic's memory cards: formulas, mnemonics and memory tricks.
class _MemoryCards extends StatelessWidget {
  final List<SubjectMemorizeItem> cards;

  const _MemoryCards({required this.cards});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in cards)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgBase : AppColors.lightBgContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.itemType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.content,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
