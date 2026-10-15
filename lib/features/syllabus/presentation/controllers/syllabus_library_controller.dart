import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/syllabus_document_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

/// Active education level tab.
final syllabusLevelProvider = StateProvider<String>((ref) => 'o-level');

/// Search query string.
final syllabusSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Data fetching ────────────────────────────────────────────────────────────

/// Fetches ALL published syllabus documents from Supabase.
final syllabusDocumentsProvider =
    FutureProvider<List<SyllabusDocument>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('syllabus_documents')
        .select()
        .eq('is_published', true)
        .order('subject_name', ascending: true);

    return (response as List)
        .map((row) => SyllabusDocument.fromMap(row as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Derived providers ────────────────────────────────────────────────────────

/// Filtered list by level + search.
final filteredSyllabusDocsProvider =
    Provider<AsyncValue<List<SyllabusDocument>>>((ref) {
  final docsAsync = ref.watch(syllabusDocumentsProvider);
  final level = ref.watch(syllabusLevelProvider);
  final query = ref.watch(syllabusSearchQueryProvider).trim().toLowerCase();

  return docsAsync.whenData((docs) {
    final byLevel = docs.where((d) => d.educationLevel == level).toList();

    if (query.isEmpty) return byLevel;

    return byLevel.where((d) {
      return (d.subjectName.toLowerCase().contains(query)) ||
          (d.title.toLowerCase().contains(query)) ||
          (d.academicYear?.toLowerCase().contains(query) ?? false) ||
          (d.coverage?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});

/// Deduplicates by subject: keeps 'Current' or latest-year doc per subject.
final currentSyllabusDocsProvider =
    Provider<AsyncValue<List<SyllabusDocument>>>((ref) {
  final filteredAsync = ref.watch(filteredSyllabusDocsProvider);

  return filteredAsync.whenData((docs) {
    final Map<String, SyllabusDocument> map = {};
    for (final doc in docs) {
      final key = doc.subjectName.toLowerCase();
      if (!map.containsKey(key)) {
        map[key] = doc;
      } else {
        final existing = map[key]!;
        final isCurrent = doc.version == 'Current';
        final isNewerYear =
            (int.tryParse(doc.academicYear ?? '0') ?? 0) >
                (int.tryParse(existing.academicYear ?? '0') ?? 0);
        if (isCurrent || isNewerYear) {
          map[key] = doc;
        }
      }
    }
    return map.values.toList();
  });
});

/// Previous versions for a given selected document.
final previousVersionsProvider =
    Provider.family<AsyncValue<List<SyllabusDocument>>, SyllabusDocument>(
        (ref, selectedDoc) {
  final docsAsync = ref.watch(syllabusDocumentsProvider);
  return docsAsync.whenData((docs) {
    return docs.where((d) {
      return d.id != selectedDoc.id &&
          d.educationLevel == selectedDoc.educationLevel &&
          d.subjectName.toLowerCase() ==
              selectedDoc.subjectName.toLowerCase();
    }).toList();
  });
});
