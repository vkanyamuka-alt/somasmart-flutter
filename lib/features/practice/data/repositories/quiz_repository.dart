import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/quiz_models.dart';

/// Repository for querying quizzes, quiz questions, and submitting quiz attempts.
class QuizRepository {
  final SupabaseClient _client;

  QuizRepository(this._client);

  // Canonical React SomaSmart initial quizzes
  static const List<QuizModel> _canonicalQuizzes = [
    QuizModel(
      id: 'q1',
      notesId: 'n1',
      subjectId: '3',
      title: 'Jaribio la Hydrocarbons - Form 4',
      formLevel: 4,
      difficulty: 'medium',
      totalQuestions: 4,
      timeLimitMinutes: 10,
      subjectNameSw: 'Kemia',
      subjectNameEn: 'Chemistry',
    ),
    QuizModel(
      id: 'q2',
      notesId: 'n2',
      subjectId: '1',
      title: 'Quadratic Equations Mastery Quiz',
      formLevel: 3,
      difficulty: 'medium',
      totalQuestions: 3,
      timeLimitMinutes: 8,
      subjectNameSw: 'Hisabati',
      subjectNameEn: 'Mathematics',
    ),
  ];

  // Canonical React SomaSmart initial questions
  static const List<QuizQuestionModel> _canonicalQuestions = [
    QuizQuestionModel(
      id: 'q1_1',
      quizId: 'q1',
      questionText: 'Ni ipi fomula ya jumla ya Alkanes?',
      questionType: 'mcq',
      options: [
        QuizQuestionOption(text: 'CnH2n', correct: false),
        QuizQuestionOption(text: 'CnH2n+2', correct: true),
        QuizQuestionOption(text: 'CnH2n-2', correct: false),
        QuizQuestionOption(text: 'CnHn', correct: false),
      ],
      correctAnswer: 'CnH2n+2',
      explanation: 'Alkanes ni saturated hydrocarbons zenye fomula kuu ya CnH2n+2.',
      difficulty: 'easy',
      orderNum: 1,
    ),
    QuizQuestionModel(
      id: 'q1_2',
      quizId: 'q1',
      questionText: 'Ethene (C2H4) ni mfano wa hydrocarbon gani?',
      questionType: 'mcq',
      options: [
        QuizQuestionOption(text: 'Alkane', correct: false),
        QuizQuestionOption(text: 'Alkene', correct: true),
        QuizQuestionOption(text: 'Alkyne', correct: false),
        QuizQuestionOption(text: 'Aromatic', correct: false),
      ],
      correctAnswer: 'Alkene',
      explanation: 'Ethene ina double bond (kifungo cha upande mbili) hivyo ni Alkene (fomula CnH2n).',
      difficulty: 'medium',
      orderNum: 2,
    ),
    QuizQuestionModel(
      id: 'q1_3',
      quizId: 'q1',
      questionText: 'Hydrocarbon isiyo na uwezo wa kujibu kirahisi na kemikali nyingine (saturated) huitwa Alkane. Kweli au Si Kweli?',
      questionType: 'true_false',
      options: [
        QuizQuestionOption(text: 'Kweli (True)', correct: true),
        QuizQuestionOption(text: 'Si Kweli (False)', correct: false),
      ],
      correctAnswer: 'Kweli (True)',
      explanation: 'Alkanes zina vifungo vya single bond tu na ziko thabiti (saturated), hivyo huwa hazifanyi react kirahisi.',
      difficulty: 'easy',
      orderNum: 3,
    ),
    QuizQuestionModel(
      id: 'q1_4',
      quizId: 'q1',
      questionText: 'Taja jina la hydrocarbon ya Alkyne yenye atomi mbili za kaboni (carbon atoms).',
      questionType: 'short',
      correctAnswer: 'ethyne',
      explanation: 'Ethyne (au Acetylene) ndio alkyne rahisi zaidi yenye formula ya C2H2.',
      difficulty: 'hard',
      orderNum: 4,
    ),
    QuizQuestionModel(
      id: 'q2_1',
      quizId: 'q2',
      questionText: 'What is the discriminant formula for a quadratic equation ax^2 + bx + c = 0?',
      questionType: 'mcq',
      options: [
        QuizQuestionOption(text: 'b^2 - 4ac', correct: true),
        QuizQuestionOption(text: 'sqrt(b^2 - 4ac)', correct: false),
        QuizQuestionOption(text: '-b / 2a', correct: false),
        QuizQuestionOption(text: '4ac - b^2', correct: false),
      ],
      correctAnswer: 'b^2 - 4ac',
      explanation: 'The discriminant is D = b^2 - 4ac, which determines the nature of the roots.',
      difficulty: 'easy',
      orderNum: 1,
    ),
    QuizQuestionModel(
      id: 'q2_2',
      quizId: 'q2',
      questionText: 'If the discriminant of a quadratic equation is negative (D < 0), what does it imply about the roots?',
      questionType: 'mcq',
      options: [
        QuizQuestionOption(text: 'Two real and equal roots', correct: false),
        QuizQuestionOption(text: 'Two real and distinct roots', correct: false),
        QuizQuestionOption(text: 'No real roots (Complex roots)', correct: true),
        QuizQuestionOption(text: 'No roots at all', correct: false),
      ],
      correctAnswer: 'No real roots (Complex roots)',
      explanation: 'A negative discriminant means we take the square root of a negative number, resulting in complex/imaginary roots.',
      difficulty: 'medium',
      orderNum: 2,
    ),
    QuizQuestionModel(
      id: 'q2_3',
      quizId: 'q2',
      questionText: 'Find the roots of x^2 - 5x + 6 = 0.',
      questionType: 'short',
      correctAnswer: '2,3',
      explanation: 'Factorizing x^2 - 5x + 6 gives (x - 2)(x - 3) = 0. Thus, x = 2 or x = 3.',
      difficulty: 'hard',
      orderNum: 3,
    ),
  ];

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
      final result = list.map((json) => QuizModel.fromJson(json as Map<String, dynamic>)).toList();

      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}

    // Fallback to canonical dataset when Supabase table has no rows
    var filtered = List<QuizModel>.from(_canonicalQuizzes);
    if (formLevel != null && formLevel > 0) {
      filtered = filtered.where((q) => q.formLevel == formLevel).toList();
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') {
      filtered = filtered.where((q) => q.difficulty == difficulty).toList();
    }
    return filtered;
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

    return _canonicalQuizzes.where((q) => q.id == quizId).firstOrNull;
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
      final result = list
          .map((json) => QuizQuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}

    return _canonicalQuestions.where((q) => q.quizId == quizId).toList();
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
