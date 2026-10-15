import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/syllabus_topic_model.dart';

/// Mapping of subject IDs/slugs to syllabus dictionary keys.
const Map<String, String> subjectMap = {
  '1': 'mathematics',
  '8b5e28a5-d8cf-4351-a982-1df3e0cf5581': 'mathematics',
  '2': 'physics',
  'c4a631bf-9d0a-42c2-8411-9f9361ad22f0': 'physics',
  '3': 'chemistry',
  'a5e01df3-8f0a-493e-bc5d-6c1f2ea8b21c': 'chemistry',
  '4': 'biology',
  '58d0421e-1f7c-473d-bd83-aa1e8f25b290': 'biology',
  '5': 'kiswahili',
  'fb4e29c8-d1ff-4841-b0db-e3a2410a8d67': 'kiswahili',
  '6': 'english',
  '24e0b04a-4712-4c6e-821f-e8b84fb68d99': 'english',
  '7': 'history',
  'ad06c3c5-9276-47b2-a4e9-913a1a6bf961': 'history',
  '8': 'geography',
  'ef4ef667-27ea-47c1-8414-0e6ef37d16ba': 'geography',
  '9': 'civics',
  '068e1a17-b769-42b7-84fe-19a9d28c31cb': 'civics',
  '10': 'economics',
  '11': 'commerce',
  '12': 'bam',
  '13': 'general studies',
};

/// 13 Canonical Initial Subjects from React Source of Truth.
const List<SubjectModel> initialSubjects = [
  SubjectModel(
    id: '1',
    nameSw: 'Hisabati',
    nameEn: 'Mathematics',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Calculator',
  ),
  SubjectModel(
    id: '2',
    nameSw: 'Fizikia',
    nameEn: 'Physics',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Atom',
  ),
  SubjectModel(
    id: '3',
    nameSw: 'Kemia',
    nameEn: 'Chemistry',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Flask',
  ),
  SubjectModel(
    id: '4',
    nameSw: 'Biolojia',
    nameEn: 'Biology',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Dna',
  ),
  SubjectModel(
    id: '5',
    nameSw: 'Kiswahili',
    nameEn: 'Kiswahili',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'BookOpen',
  ),
  SubjectModel(
    id: '6',
    nameSw: 'Kiingereza',
    nameEn: 'English Language',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Languages',
  ),
  SubjectModel(
    id: '7',
    nameSw: 'Historia',
    nameEn: 'History',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'History',
  ),
  SubjectModel(
    id: '8',
    nameSw: 'Jiografia',
    nameEn: 'Geography',
    formLevels: [1, 2, 3, 4, 5, 6],
    iconKey: 'Globe',
  ),
  SubjectModel(
    id: '9',
    nameSw: 'Uraia',
    nameEn: 'Civics',
    formLevels: [1, 2, 3, 4],
    iconKey: 'Users',
  ),
  SubjectModel(
    id: '10',
    nameSw: 'Uchumi',
    nameEn: 'Economics',
    formLevels: [5, 6],
    iconKey: 'TrendingUp',
  ),
  SubjectModel(
    id: '11',
    nameSw: 'Biashara',
    nameEn: 'Commerce',
    formLevels: [5, 6],
    iconKey: 'ShoppingBag',
  ),
  SubjectModel(
    id: '12',
    nameSw: 'Hisabati ya Tahasusi',
    nameEn: 'Basic Applied Mathematics',
    formLevels: [5, 6],
    iconKey: 'FileSpreadsheet',
  ),
  SubjectModel(
    id: '13',
    nameSw: 'Stadi za Kazi/Maarifa',
    nameEn: 'General Studies',
    formLevels: [5, 6],
    iconKey: 'Compass',
  ),
];

/// Currently selected Form Level (1 to 6).
final selectedFormLevelProvider = StateProvider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  return userProfile?.formLevel ?? 4;
});

/// Subject search query.
final subjectSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for fetching subjects from Supabase.
final subjectsListProvider = FutureProvider<List<SubjectModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('subjects')
        .select()
        .order('id', ascending: true);

    if (response.isNotEmpty) {
      return response
          .map((row) => SubjectModel.fromMap(row))
          .toList();
    }
  } catch (e) {
    // Fallback to initial subjects if offline or query fails
  }
  return initialSubjects;
});

/// Data container for Subject Detail View.
class SubjectDetailData {
  final SubjectModel subject;
  final List<SubjectNoteItem> notes;
  final List<SubjectMaterialItem> materials;
  final List<SubjectMemorizeItem> memorizeItems;
  final List<SyllabusTopic> topics;
  final bool hasAccess;

  const SubjectDetailData({
    required this.subject,
    required this.notes,
    required this.materials,
    required this.memorizeItems,
    required this.topics,
    required this.hasAccess,
  });
}

/// Provider for fetching Subject Detail data for a specific subject ID.
final subjectDetailProvider =
    FutureProvider.family<SubjectDetailData, String>((ref, subjectId) async {
  final client = ref.watch(supabaseClientProvider);
  final subjects = await ref.watch(subjectsListProvider.future);
  final formLevel = ref.watch(selectedFormLevelProvider);
  final userProfile = ref.watch(userProfileProvider).value;

  // 1. Locate Subject
  final subject = subjects.firstWhere(
    (s) => s.id == subjectId || subjectMap[s.id] == subjectMap[subjectId],
    orElse: () => initialSubjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => initialSubjects.first,
    ),
  );

  // 2. Fetch Notes from Supabase
  List<SubjectNoteItem> notes = [];
  try {
    final notesRes = await client
        .from('notes')
        .select('*, profiles(full_name), text_content, file_type')
        .eq('status', 'approved');

    notes = notesRes
        .map((n) => SubjectNoteItem.fromMap(n))
        .where((n) =>
            (n.subjectId == subject.id ||
                subjectMap[n.subjectId] == subjectMap[subject.id]) &&
            n.formLevel == formLevel)
        .toList();
  } catch (_) {}

  // 3. Fetch Learning Materials
  List<SubjectMaterialItem> materials = [];
  try {
    final matRes = await client
        .from('learning_materials')
        .select()
        .eq('status', 'published');

    materials = matRes
        .map((m) => SubjectMaterialItem.fromMap(m))
        .where((m) =>
            (m.subjectId == subject.id ||
                subjectMap[m.subjectId] == subjectMap[subject.id]) &&
            m.formLevel == formLevel)
        .toList();
  } catch (_) {}

  // 4. Fetch Memorize Items
  List<SubjectMemorizeItem> memorizeItems = [];
  try {
    final memRes = await client
        .from('memorize_items')
        .select()
        .eq('is_published', true);

    memorizeItems = memRes
        .map((m) => SubjectMemorizeItem.fromMap(m))
        .where((m) =>
            (m.subjectId == subject.id ||
                subjectMap[m.subjectId] == subjectMap[subject.id]) &&
            m.formLevel == formLevel)
        .toList();
  } catch (_) {}

  // 5. Syllabus Topics
  final key = subjectMap[subject.id] ?? subject.nameEn.toLowerCase();
  final topics = syllabusTopicsData[key]?[formLevel] ?? [];

  // 6. Access entitlement verification (Server-aligned check)
  final hasAccess = userProfile != null && (userProfile.isPremium || userProfile.isTrialActive);

  return SubjectDetailData(
    subject: subject,
    notes: notes,
    materials: materials,
    memorizeItems: memorizeItems,
    topics: topics,
    hasAccess: hasAccess,
  );
});
