import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notes/presentation/screens/note_viewer_screen.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/syllabus_topic_model.dart';
import '../controllers/subjects_controller.dart';

/// Subject Detail Screen with 3 Tabs (Notes, Understand & Master, Memorize).
/// Fully aligned with React `SubjectDetail.jsx`.
class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
  });

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
    final lang = ref.watch(languageProvider);
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
                ref.read(selectedFormLevelProvider.notifier).state = val;
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? AppColors.darkBgSurface : Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.primary),
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
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
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
          final subject = data.subject;
          final notes = data.notes;
          final materials = data.materials;
          final memorize = data.memorizeItems;
          final topics = data.topics;
          final hasAccess = data.hasAccess;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Header Info Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.darkBgSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  subject.iconData,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang == 'sw'
                                          ? subject.nameSw
                                          : subject.nameEn,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      lang == 'sw'
                                          ? 'Kidato cha $selectedForm • Maudhui yako ya kujifunza'
                                          : 'Form $selectedForm • Your learning resources',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 32, color: AppColors.primary),
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
                                  onPressed: () => context.push('/subscription'),
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
                      labelColor: AppColors.primary,
                      unselectedLabelColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.description_outlined, size: 18),
                          text: lang == 'sw' ? 'Muhtasari' : 'Notes',
                        ),
                        Tab(
                          icon: const Icon(Icons.play_circle_outline_rounded,
                              size: 18),
                          text: lang == 'sw' ? 'Elewa na Miliki' : 'Understand',
                        ),
                        Tab(
                          icon: const Icon(Icons.psychology_outlined, size: 18),
                          text: lang == 'sw' ? 'Kumbuka' : 'Memorize',
                        ),
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
                // 1. NOTES TAB
                _NotesTabContent(
                  topics: topics,
                  notes: notes,
                  lang: lang,
                  isDark: isDark,
                ),

                // 2. UNDERSTAND & MASTER TAB
                _UnderstandTabContent(
                  topics: topics,
                  materials: materials,
                  lang: lang,
                  isDark: isDark,
                ),

                // 3. MEMORIZE TAB
                _MemorizeTabContent(
                  topics: topics,
                  memorizeItems: memorize,
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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

/// 1. Notes Tab Content
class _NotesTabContent extends StatelessWidget {
  final List<SyllabusTopic> topics;
  final List<SubjectNoteItem> notes;
  final String lang;
  final bool isDark;

  const _NotesTabContent({
    required this.topics,
    required this.notes,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty && notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                lang == 'sw'
                    ? 'Bado hakuna muhtasari wa somo hili.'
                    : 'No study notes available for this subject yet.',
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
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) => _NoteCard(note: notes[index], lang: lang),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (ctx, index) {
        final topic = topics[index];
        final topicNotes = notes.where((n) {
          final tEn = topic.en.toLowerCase();
          final tSw = topic.sw.toLowerCase();
          final text = '${n.title} ${n.description} ${n.topic ?? ""}'.toLowerCase();
          return text.contains(tEn) || text.contains(tSw);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. ${lang == 'sw' ? topic.sw : topic.en}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (topicNotes.isEmpty)
                Text(
                  lang == 'sw'
                      ? 'Bado hakuna muhtasari (Study Notes) wa mada hii.'
                      : 'No study notes available for this topic yet.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                )
              else
                ...topicNotes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NoteCard(note: note, lang: lang),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final SubjectNoteItem note;
  final String lang;

  const _NoteCard({required this.note, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.language == 'both'
                      ? 'SW + EN'
                      : note.language.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${note.downloads} ${lang == 'sw' ? 'wamesoma' : 'views'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (note.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the Note Viewer, passing the note directly
                // to avoid a redundant Supabase round-trip.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteViewerScreen(note: note),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded, size: 14),
              label: Text(
                lang == 'sw' ? 'Soma Muhtasari' : 'Read Notes',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Understand & Master Tab Content
class _UnderstandTabContent extends StatelessWidget {
  final List<SyllabusTopic> topics;
  final List<SubjectMaterialItem> materials;
  final String lang;
  final bool isDark;

  const _UnderstandTabContent({
    required this.topics,
    required this.materials,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 40,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                lang == 'sw'
                    ? 'Bado hakuna video au sauti za somo hili.'
                    : 'No video or audio lessons for this subject yet.',
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final mat = materials[index];
        final isVideo = mat.materialType == 'video';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Thumbnail container
              Container(
                width: 90,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgBase : Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isVideo
                        ? Icons.play_arrow_rounded
                        : Icons.headphones_rounded,
                    color: Colors.white,
                    size: 24,
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
                    const SizedBox(height: 4),
                    Text(
                      mat.shortDescription.isNotEmpty
                          ? mat.shortDescription
                          : mat.description,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 3. Memorize Tab Content
class _MemorizeTabContent extends StatelessWidget {
  final List<SyllabusTopic> topics;
  final List<SubjectMemorizeItem> memorizeItems;
  final String lang;
  final bool isDark;

  const _MemorizeTabContent({
    required this.topics,
    required this.memorizeItems,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (memorizeItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 40,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                lang == 'sw'
                    ? 'Bado hakuna kanuni au mnemonics za somo hili.'
                    : 'No formulas or memory tricks for this subject yet.',
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memorizeItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = memorizeItems[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.itemType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                  if (item.topic.isNotEmpty)
                    Text(
                      item.topic,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgBase
                      : AppColors.lightBgContainer,
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
        );
      },
    );
  }
}
