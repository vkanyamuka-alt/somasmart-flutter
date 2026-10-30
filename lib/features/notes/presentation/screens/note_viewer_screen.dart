import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../subjects/domain/models/syllabus_topic_model.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../widgets/note_diagrams.dart';

// ---------------------------------------------------------------------------
// Provider: fetches a single note's full content by note ID.
// The note list already cached in [subjectDetailProvider] is re-used; if this
// note was opened through that path the data is already present.
// As a fallback we query Supabase directly.
// ---------------------------------------------------------------------------
final noteDetailProvider =
    FutureProvider.family<SubjectNoteItem?, String>((ref, noteId) async {
  // Try finding the note in any already-loaded subject detail provider cache.
  // We can also query Supabase directly for the full content.
  final supabase = ref.watch(supabaseClientProvider);
  try {
    final res = await supabase
        .from('notes')
        .select('*, profiles(full_name), text_content, file_type')
        .eq('id', noteId)
        .eq('status', 'approved')
        .single();
    return SubjectNoteItem.fromMap(res);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// NoteViewerScreen
// ---------------------------------------------------------------------------
class NoteViewerScreen extends ConsumerStatefulWidget {
  /// The note to display. If provided directly (from Subject Detail),
  /// the viewer uses this without a Supabase round-trip.
  final SubjectNoteItem? note;

  /// Alternative: open by note ID (deep-link / direct navigation).
  final String? noteId;

  const NoteViewerScreen({super.key, this.note, this.noteId})
      : assert(note != null || noteId != null,
            'Provide either note or noteId');

  @override
  ConsumerState<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends ConsumerState<NoteViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _flashcardIndex = 0;
  bool _showAnswer = false;
  int _memorizedCount = 0;

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);

    // If a note was passed directly, use it; otherwise fetch.
    if (widget.note != null) {
      return _buildScaffold(
          context, isDark, lang, widget.note!, isLoaded: true);
    }

    final noteAsync = ref.watch(noteDetailProvider(widget.noteId!));
    return noteAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
          leading: BackButton(
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
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
                      ? 'Hitilafu wakati wa kupakia muhtasari.'
                      : 'Failed to load note.',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                      noteDetailProvider(widget.noteId!)),
                  child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor:
                  isDark ? AppColors.darkBgSurface : Colors.white,
              leading: BackButton(
                  onPressed: () => Navigator.maybePop(context)),
            ),
            body: Center(
              child: Text(
                lang == 'sw'
                    ? 'Muhtasari haukupatikana.'
                    : 'Note not found.',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          );
        }
        return _buildScaffold(context, isDark, lang, note, isLoaded: true);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Main scaffold
  // ---------------------------------------------------------------------------
  Widget _buildScaffold(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note, {
    required bool isLoaded,
  }) {
    final bgColor = isDark ? AppColors.darkBgSurface : Colors.white;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    // Build flashcard data from note description (mirrors React)
    final flashcards = [
      _Flashcard(
        front: lang == 'sw' ? 'Kichwa cha Mada (Topic Title)' : 'Topic Title',
        back: note.title,
      ),
      _Flashcard(
        front: lang == 'sw'
            ? 'Kanuni Kuu / Wazo Mkuu'
            : 'Core Formula / Concept',
        back: note.description.length > 100
            ? '${note.description.substring(0, 100)}...'
            : note.description,
      ),
      _Flashcard(
        front: lang == 'sw' ? 'Lugha ya Notes' : 'Note Language',
        back: note.language == 'both'
            ? 'Swahili & English'
            : note.language.toUpperCase(),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBgBase : AppColors.lightBgContainer,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bgColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
            tooltip: lang == 'sw' ? 'Rudi' : 'Back',
          ),
          title: Text(
            note.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            // Where the note belongs, then the three views in one row
            // (same order as the web note page).
            _buildHeaderCard(
                context, isDark, lang, note, bgColor, borderColor),
            Container(
              color: bgColor,
              child: TabBar(
                controller: _tabController,
                labelColor: isDark ? AppColors.primaryLight : AppColors.primary,
                unselectedLabelColor: textSecondary,
                indicatorColor: isDark ? AppColors.primaryLight : AppColors.primary,
                indicatorWeight: 3,
                dividerColor: borderColor,
                labelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: lang == 'sw' ? 'Muhtasari' : 'Notes'),
                  Tab(text: lang == 'sw' ? 'Elewa na Miliki' : 'Understand'),
                  Tab(text: lang == 'sw' ? 'Kumbuka' : 'Memorize'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Notes Reader
                  _buildNotesTab(context, isDark, lang, note),
                  // Tab 2: Understand (Q&A)
                  _buildUnderstandTab(
                      context, isDark, lang, note, bgColor, borderColor),
                  // Tab 3: Memorize (Flashcards)
                  _buildMemorizeTab(
                    context,
                    isDark,
                    lang,
                    note,
                    flashcards,
                    bgColor,
                    borderColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header Card
  // ---------------------------------------------------------------------------
  Widget _buildHeaderCard(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note,
    Color bgColor,
    Color borderColor,
  ) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final subjectName = _subjectName(note.subjectId, lang);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (subjectName != null)
                _Badge(
                  text: subjectName,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              _Badge(
                text: lang == 'sw'
                    ? 'Kidato cha ${note.formLevel}'
                    : 'Form ${note.formLevel}',
                color: textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${lang == 'sw' ? 'Mwandishi' : 'Author'}: ${note.authorName}',
            style: TextStyle(fontSize: 12.5, color: textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// The note's subject in the chosen language, from the app's catalogue.
  String? _subjectName(String subjectId, String lang) {
    final key = subjectMap[subjectId];
    for (final s in initialSubjects) {
      if (s.id == subjectId || (key != null && subjectMap[s.id] == key)) {
        return lang == 'sw' ? s.nameSw : s.nameEn;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Notes Reader (Markdown + LaTeX)
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note,
  ) {
    final content = note.textContent;

    if (note.fileType == 'pdf') {
      return _buildPdfPlaceholder(context, isDark, lang, note);
    }

    if (content == null || content.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 40,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                note.description.isNotEmpty
                    ? note.description
                    : (lang == 'sw'
                        ? 'Maudhui ya muhtasari huu bado hayajawekwa.'
                        : 'The content of this note is not yet available.'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Markdown with inline LaTeX; diagram blocks are drawn in place
    // (never shown as raw data).
    final segments = splitNoteContent(content);
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final seg in segments)
              switch (seg) {
                NoteMarkdown(:final text) =>
                  _SomaNoteMarkdown(data: text, isDark: isDark),
                NoteDiagramBlock() => NoteDiagram(block: seg, lang: lang),
              },
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF placeholder (React shows a placeholder too; no native PDF viewer added
  // without confirmed PDF content in the backend — REQUIRES VERIFICATION)
  // ---------------------------------------------------------------------------
  Widget _buildPdfPlaceholder(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'sw' ? 'Hati ya PDF' : 'PDF Document',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'sw'
                  ? 'Hati hii ipo katika muundo wa PDF. Msaada wa PDF utaongezwa hivi karibuni.'
                  : 'This note is in PDF format. PDF viewing support is coming soon.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Understand (Q&A explorer — mirrors React understandData)
  // ---------------------------------------------------------------------------
  Widget _buildUnderstandTab(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note,
    Color bgColor,
    Color borderColor,
  ) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final qaItems = [
      _QaItem(
        q: lang == 'sw'
            ? 'Dhana kuu ya mada hii ni ipi?'
            : 'What is the core concept of this topic?',
        a: note.description.isNotEmpty
            ? note.description
            : (lang == 'sw'
                ? 'Tazama muhtasari kamili kwenye kichupo cha Notes.'
                : 'See the full note in the Notes tab.'),
      ),
      _QaItem(
        q: lang == 'sw'
            ? 'Tofauti kuu za kutofautisha ni zipi?'
            : 'What are the key distinctions to remember?',
        a: lang == 'sw'
            ? 'Ni muhimu kuelewa kanuni, muundo, na tofauti za msingi zilizopo kwenye muhtasari (notes).'
            : 'Make sure to focus on the formulas, structure, and differences detailed in the notes.',
      ),
      _QaItem(
        q: lang == 'sw'
            ? 'Taja makosa ya kawaida ya kuepuka kwenye mtihani.'
            : 'What are common mistakes to avoid in exams?',
        a: lang == 'sw'
            ? 'Kutochora michoro sahihi, kutoweka vipimo (units) kwenye hesabu, na kuruka hatua za njiamgando.'
            : 'Not drawing diagrams correctly, forgetting scientific units, and skipping steps in calculations.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          lang == 'sw'
              ? 'Maswali na Majibu ya Kujifunza'
              : 'Q&A Study Explorer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ...qaItems.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q: ${item.q}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A: ${item.a}',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Memorize (Flashcards — mirrors React memorizeData)
  // ---------------------------------------------------------------------------
  Widget _buildMemorizeTab(
    BuildContext context,
    bool isDark,
    String lang,
    SubjectNoteItem note,
    List<_Flashcard> flashcards,
    Color bgColor,
    Color borderColor,
  ) {
    final current = flashcards[_flashcardIndex];
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          lang == 'sw'
              ? 'Flashcards za Kukariri'
              : 'Active Recall Flashcards',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),

        // Flashcard
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Card counter
              Text(
                lang == 'sw'
                    ? 'Kadi ya ${_flashcardIndex + 1} kati ya ${flashcards.length}'
                    : 'Card ${_flashcardIndex + 1} of ${flashcards.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Card content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showAnswer
                    ? Text(
                        current.back,
                        key: const ValueKey('back'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        current.front,
                        key: const ValueKey('front'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (!_showAnswer)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showAnswer = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      lang == 'sw' ? 'Onyesha Jibu' : 'Show Answer',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                            _flashcardIndex =
                                (_flashcardIndex + 1) % flashcards.length;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: borderColor),
                        ),
                        child: Text(
                          lang == 'sw' ? 'Jaribu Tena' : 'Try Again',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                            _memorizedCount++;
                            _flashcardIndex =
                                (_flashcardIndex + 1) % flashcards.length;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          lang == 'sw' ? 'Nimekariri' : 'Memorized',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Score
        const SizedBox(height: 20),
        Center(
          child: Text(
            lang == 'sw'
                ? 'Kadi zilizokaririwa: $_memorizedCount'
                : 'Cards memorized: $_memorizedCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Markdown + LaTeX renderer
// Mirrors React: ReactMarkdown + remarkGfm + remarkMath + rehypeKatex
// Also handles IMPORTANT:/NOTE:/TIP: callout paragraphs from React
// ---------------------------------------------------------------------------
class _SomaNoteMarkdown extends StatelessWidget {
  final String data;
  final bool isDark;

  const _SomaNoteMarkdown({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final codeBackground =
        isDark ? AppColors.darkBgBase : const Color(0xFFF3F4F6);

    return MarkdownBody(
      data: data,
      selectable: false,
      extensionSet: md.ExtensionSet(
        [
          ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      styleSheet: MarkdownStyleSheet(
        // Paragraphs
        p: TextStyle(
          fontSize: 15.5,
          height: 1.75,
          color: textColor,
        ),
        // Headings
        h1: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.3,
        ),
        h2: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.3,
        ),
        h3: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.3,
        ),
        h4: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.3,
        ),
        h5: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        h6: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        // H2/H3 divider
        h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
        h3Padding: const EdgeInsets.only(top: 20, bottom: 6),
        // Lists
        listBullet: TextStyle(fontSize: 15.5, color: textColor),
        // Blockquote
        blockquote: TextStyle(fontSize: 14.5, color: textSecondary),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
          color: AppColors.primary.withValues(alpha: 0.06),
        ),
        blockquotePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Code (inline)
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          color: isDark ? const Color(0xFFE879F9) : const Color(0xFF9333EA),
          backgroundColor: codeBackground,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        // Tables
        tableBorder: TableBorder.all(color: borderColor, width: 1),
        tableHead: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: textColor,
        ),
        tableBody: TextStyle(fontSize: 13, color: textColor),
        tableCellsPadding: const EdgeInsets.all(8),
        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        // Strong / em
        strong: TextStyle(fontWeight: FontWeight.w800, color: textColor),
        em: TextStyle(
            fontStyle: FontStyle.italic, color: textSecondary),
      ),
      builders: {
        // Custom inline math builder: handles $...$ via flutter_math_fork
        'math': _MathElementBuilder(isDark: isDark, display: false),
        'mathBlock': _MathElementBuilder(isDark: isDark, display: true),
      },
      // Handle $...$ inline and $$...$$ display math
      inlineSyntaxes: [_DollarInlineMathSyntax()],
      blockSyntaxes: [_DollarDisplayMathSyntax()],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Markdown Builder for LaTeX math via flutter_math_fork
// ---------------------------------------------------------------------------
class _MathElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final bool display;

  _MathElementBuilder({required this.isDark, required this.display});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    if (display) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            tex,
            mathStyle: MathStyle.display,
            textStyle: TextStyle(fontSize: 16, color: textColor),
            onErrorFallback: (err) => Text(
              tex,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isDark ? Colors.amber : Colors.deepOrange,
              ),
            ),
          ),
        ),
      );
    } else {
      return Math.tex(
        tex,
        mathStyle: MathStyle.text,
        textStyle: TextStyle(fontSize: 15, color: textColor),
        onErrorFallback: (err) => Text(
          tex,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: isDark ? Colors.amber : Colors.deepOrange,
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Custom Markdown syntax for $...$ inline math
// ---------------------------------------------------------------------------
class _DollarInlineMathSyntax extends md.InlineSyntax {
  _DollarInlineMathSyntax() : super(r'\$([^\$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tex = match.group(1)!;
    final el = md.Element.text('math', tex);
    parser.addNode(el);
    return true;
  }
}

// ---------------------------------------------------------------------------
// Custom Markdown syntax for $$...$$ display math
// ---------------------------------------------------------------------------
class _DollarDisplayMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$\s*$');

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance();
    final lines = <String>[];
    while (!parser.isDone && !parser.matches(pattern)) {
      lines.add(parser.current.content);
      parser.advance();
    }
    if (!parser.isDone) parser.advance(); // consume closing $$
    final tex = lines.join('\n');
    return md.Element('mathBlock', [md.Text(tex)]);
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------
class _Flashcard {
  final String front;
  final String back;
  const _Flashcard({required this.front, required this.back});
}

class _QaItem {
  final String q;
  final String a;
  const _QaItem({required this.q, required this.a});
}

// ---------------------------------------------------------------------------
// Reusable badge widget
// ---------------------------------------------------------------------------
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
