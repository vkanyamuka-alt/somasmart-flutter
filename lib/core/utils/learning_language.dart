import '../../features/subjects/presentation/controllers/subjects_controller.dart';

/// Swahili is for the app itself (sign in, home, menus, settings, account,
/// payment, messages). Learning screens (subjects, topics, notes, quizzes and
/// exams, past papers, the lab) are in English, except the Kiswahili subject,
/// which is always in Swahili. Pass the subject id when the screen has one.
String learningLanguage([String? subjectId]) => isKiswahiliSubject(subjectId) ? 'sw' : 'en';

bool isKiswahiliSubject(String? subjectId) => subjectId != null && subjectMap[subjectId] == 'kiswahili';
