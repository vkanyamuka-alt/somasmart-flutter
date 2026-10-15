import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../subjects/domain/models/syllabus_topic_model.dart';
import '../../presentation/screens/note_viewer_screen.dart';

// ---------------------------------------------------------------------------
// Provider: global notes search across all subjects
// ---------------------------------------------------------------------------
final _allNotesProvider = FutureProvider<List<SubjectNoteItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final res = await client
        .from('notes')
        .select(
            '*, profiles(full_name), text_content, file_type, subject:subjects(name_en, name_sw)')
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .limit(200);
    return res.map((row) => SubjectNoteItem.fromMap(row)).toList();
  } catch (_) {
    return [];
  }
});

// ---------------------------------------------------------------------------
// NotesScreen — global notes browser with search + form filter
// ---------------------------------------------------------------------------
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  int _selectedFormIndex = 3; // Form 4 default
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final forms = ['Form 1', 'Form 2', 'Form 3', 'Form 4', 'Form 5', 'Form 6'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubjectNoteItem> _filter(List<SubjectNoteItem> notes) {
    final formLevel = _selectedFormIndex + 1;
    var result = notes.where((n) => n.formLevel == formLevel).toList();

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.description.toLowerCase().contains(q) ||
            (n.topic?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final notesAsync = ref.watch(_allNotesProvider);

    return Scaffold(
      body: Column(
        children: [
          // --- Search & Filter Header ---
          Container(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: lang == 'sw'
                        ? 'Tafuta muhtasari, mada au kanuni...'
                        : 'Search notes, topics or formulas...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBgBase
                        : AppColors.lightBgContainer,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Form filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(forms.length, (index) {
                      final isSelected = _selectedFormIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(forms[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFormIndex = index);
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkBgBase
                              : AppColors.lightBgContainer,
                          side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // --- Content Area ---
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => _ErrorState(
                lang: lang,
                onRetry: () => ref.invalidate(_allNotesProvider),
              ),
              data: (allNotes) {
                final filtered = _filter(allNotes);

                if (allNotes.isEmpty) {
                  return _EmptyState(
                    lang: lang,
                    isDark: isDark,
                    message: lang == 'sw'
                        ? 'Muhtasari wa masomo bado haujaongezwa.'
                        : 'Study notes have not been added yet.',
                  );
                }

                if (filtered.isEmpty) {
                  return _EmptyState(
                    lang: lang,
                    isDark: isDark,
                    message: _searchQuery.isNotEmpty
                        ? (lang == 'sw'
                            ? 'Hakuna matokeo ya utafutaji: "$_searchQuery"'
                            : 'No results for "$_searchQuery"')
                        : (lang == 'sw'
                            ? 'Hakuna muhtasari wa ${forms[_selectedFormIndex]}.'
                            : 'No notes for ${forms[_selectedFormIndex]}.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) => _NoteListItem(
                    note: filtered[index],
                    lang: lang,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note list item card
// ---------------------------------------------------------------------------
class _NoteListItem extends StatelessWidget {
  final SubjectNoteItem note;
  final String lang;
  final bool isDark;

  const _NoteListItem({
    required this.note,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkBgSurface : Colors.white;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteViewerScreen(note: note),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language badge + view count
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.language == 'both'
                        ? 'SW + EN'
                        : note.language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (note.fileType == 'pdf')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.visibility_outlined, size: 13, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  '${note.downloads}',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 9),
            // Note title
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            // Description
            if (note.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            // Author + chevron
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 13, color: textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note.authorName,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String lang;
  final bool isDark;
  final String message;

  const _EmptyState({
    required this.lang,
    required this.isDark,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 44,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 14),
            Text(
              message,
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
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final String lang;
  final VoidCallback onRetry;

  const _ErrorState({required this.lang, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              lang == 'sw'
                  ? 'Hitilafu wakati wa kupakia muhtasari.'
                  : 'Failed to load notes. Check your connection.',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
