import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/quiz_models.dart';

/// Repository for querying quizzes, quiz questions, and submitting quiz attempts.
class QuizRepository {
  final SupabaseClient _client;

  QuizRepository(this._client);

  /// Fetch all quizzes with optional subject, form level, or difficulty filters.
  Future<List<QuizModel>> getQuizzes({
    String? subjectId,
    int? formLevel,
    String? difficulty,
  }) async {
    try {
      var query = _client.from('quizzes').select('*, subjects(name_sw, name_en)');

      if (subjectId != null && subjectId.isNotEmpty) {
        query = query.eq('subject_id', subjectId);
      }
      if (formLevel != null && formLevel > 0) {
        query = query.eq('form_level', formLevel);
      }
      if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') {
        query = query.eq('difficulty', difficulty);
      }

      final response = await query.order('created_at', ascending: false);
      final list = response as List<dynamic>;
      return list.map((json) => QuizModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      // No made-up quizzes: an empty list shows the "no quizzes yet" state.
      return const [];
    }
  }

  /// Fetch a single quiz by ID.
  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      final response = await _client
          .from('quizzes')
          .select('*, subjects(name_sw, name_en)')
          .eq('id', quizId)
          .maybeSingle();

      if (response != null) {
        return QuizModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  /// Fetch all questions for a specific quiz.
  Future<List<QuizQuestionModel>> getQuizQuestions(String quizId) async {
    try {
      final response = await _client
          .from('quiz_questions')
          .select('*')
          .eq('quiz_id', quizId)
          .order('order_num', ascending: true);

      final list = response as List<dynamic>;
      return list
          .map((json) => QuizQuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<QuizAttemptModel?> submitAttempt({
    required String quizId,
    required String studentId,
    required double score,
    required int timeTakenSeconds,
    required Map<String, dynamic> answers,
  }) async {
    // Unauthenticated or guest sessions cannot be persisted to Supabase foreign key
    if (studentId.isEmpty || studentId == 'guest') {
      return null;
    }

    try {
      final completedAt = DateTime.now().toUtc();
      final response = await _client
          .from('quiz_attempts')
          .insert({
            'quiz_id': quizId,
            'student_id': studentId,
            'score': score,
            'time_taken_seconds': timeTakenSeconds,
            'answers': answers,
            'completed_at': completedAt.toIso8601String(),
            'synced_at': completedAt.toIso8601String(),
          })
          .select('*, quizzes(title)')
          .single();

      return QuizAttemptModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Fetch a specific attempt by attemptId with associated quiz information.
  Future<QuizAttemptModel?> getAttemptById(String attemptId) async {
    try {
      final response = await _client
          .from('quiz_attempts')
          .select('*, quizzes(title)')
          .eq('id', attemptId)
          .maybeSingle();

      if (response != null) {
        return QuizAttemptModel.fromJson(response);
      }
    } catch (_) {}

    return null;
  }

  /// Fetch all attempts for a student.
  Future<List<QuizAttemptModel>> getStudentAttempts(String studentId) async {
    try {
      final response = await _client
          .from('quiz_attempts')
          .select('*, quizzes(title)')
          .eq('student_id', studentId)
          .order('completed_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((json) => QuizAttemptModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Provider for QuizRepository.
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return QuizRepository(client);
});
