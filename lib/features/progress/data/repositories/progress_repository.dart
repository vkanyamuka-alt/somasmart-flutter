import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:somasmart_flutter/core/services/supabase_service.dart';
import 'package:somasmart_flutter/features/practice/data/repositories/quiz_repository.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';

/// Repository for querying student learning progress and quiz attempt history.
class ProgressRepository {
  final SupabaseClient _client;
  final QuizRepository _quizRepo;

  ProgressRepository(this._client, this._quizRepo);

  /// Fetch full attempt history for a student with associated quiz and subject details.
  Future<List<ProgressAttemptDetail>> getStudentAttemptsWithMetadata(String studentId) async {
    if (studentId.isEmpty || studentId == 'guest') {
      return [];
    }

    try {
      // Query attempts ordered chronologically (oldest to newest) matching React
      final response = await _client
          .from('quiz_attempts')
          .select('*, quizzes(*, subjects(*))')
          .eq('student_id', studentId)
          .order('completed_at', ascending: true);

      final list = response as List<dynamic>;
      final results = <ProgressAttemptDetail>[];

      for (final item in list) {
        final json = item as Map<String, dynamic>;
        final attempt = QuizAttemptModel.fromJson(json);

        String title = attempt.quizTitle ?? 'Quiz';
        String subjectId = '';
        String? notesId;
        String nameSw = '';
        String nameEn = '';

        if (json['quizzes'] != null && json['quizzes'] is Map<String, dynamic>) {
          final qJson = json['quizzes'] as Map<String, dynamic>;
          title = qJson['title']?.toString() ?? title;
          subjectId = qJson['subject_id']?.toString() ?? '';
          notesId = qJson['notes_id']?.toString();

          if (qJson['subjects'] != null && qJson['subjects'] is Map<String, dynamic>) {
            final sJson = qJson['subjects'] as Map<String, dynamic>;
            nameSw = sJson['name_sw']?.toString() ?? '';
            nameEn = sJson['name_en']?.toString() ?? '';
          }
        }

        // If joined data was missing, attempt resolving via QuizRepository
        if (subjectId.isEmpty || nameSw.isEmpty) {
          final quiz = await _quizRepo.getQuizById(attempt.quizId);
          if (quiz != null) {
            title = quiz.title;
            subjectId = quiz.subjectId;
            notesId = quiz.notesId;
            nameSw = quiz.subjectNameSw ?? '';
            nameEn = quiz.subjectNameEn ?? '';
          }
        }

        results.add(ProgressAttemptDetail(
          attempt: attempt,
          quizTitle: title,
          subjectId: subjectId,
          notesId: notesId,
          subjectNameSw: nameSw,
          subjectNameEn: nameEn,
        ));
      }

      return results;
    } catch (_) {
      // If error occurs, fallback to basic attempts query
      final basicAttempts = await _quizRepo.getStudentAttempts(studentId);
      final results = <ProgressAttemptDetail>[];

      for (final attempt in basicAttempts) {
        final quiz = await _quizRepo.getQuizById(attempt.quizId);
        results.add(ProgressAttemptDetail(
          attempt: attempt,
          quizTitle: quiz?.title ?? attempt.quizTitle ?? 'Quiz',
          subjectId: quiz?.subjectId ?? '',
          notesId: quiz?.notesId,
          subjectNameSw: quiz?.subjectNameSw ?? '',
          subjectNameEn: quiz?.subjectNameEn ?? '',
        ));
      }

      // Ensure chronological sort
      results.sort((a, b) => a.attempt.completedAt.compareTo(b.attempt.completedAt));
      return results;
    }
  }
}

/// Helper container holding attempt + joined metadata for analytics processing.
class ProgressAttemptDetail {
  final QuizAttemptModel attempt;
  final String quizTitle;
  final String subjectId;
  final String? notesId;
  final String subjectNameSw;
  final String subjectNameEn;

  const ProgressAttemptDetail({
    required this.attempt,
    required this.quizTitle,
    required this.subjectId,
    this.notesId,
    required this.subjectNameSw,
    required this.subjectNameEn,
  });
}

/// Provider for ProgressRepository.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final quizRepo = ref.watch(quizRepositoryProvider);
  return ProgressRepository(client, quizRepo);
});
