import 'dart:convert';

/// Domain model representing a Quiz in SomaSmart.
/// Mirrors Supabase `public.quizzes` table.
class QuizModel {
  final String id;
  final String? teacherId;
  final String? notesId;
  final String subjectId;
  final String title;
  final int formLevel;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final int totalQuestions;
  final int timeLimitMinutes;
  final DateTime? createdAt;
  final String? subjectNameSw;
  final String? subjectNameEn;
  /// 'topic' | 'exam' | 'past_paper' | 'timed', set by admins in the admin panel.
  final String quizType;
  /// Year of a past paper.
  final int? examYear;
  final bool isPublished;

  const QuizModel({
    required this.id,
    this.teacherId,
    this.notesId,
    required this.subjectId,
    required this.title,
    required this.formLevel,
    this.difficulty = 'medium',
    this.totalQuestions = 0,
    this.timeLimitMinutes = 15,
    this.createdAt,
    this.subjectNameSw,
    this.subjectNameEn,
    this.quizType = 'topic',
    this.examYear,
    this.isPublished = true,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    // Check if subject was joined
    String? subSw;
    String? subEn;
    if (json['subjects'] != null && json['subjects'] is Map<String, dynamic>) {
      subSw = json['subjects']['name_sw'] as String?;
      subEn = json['subjects']['name_en'] as String?;
    }

    return QuizModel(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString(),
      notesId: json['notes_id']?.toString(),
      subjectId: json['subject_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      formLevel: (json['form_level'] is int)
          ? json['form_level'] as int
          : int.tryParse(json['form_level']?.toString() ?? '1') ?? 1,
      difficulty: json['difficulty']?.toString().toLowerCase() ?? 'medium',
      totalQuestions: (json['total_questions'] is int)
          ? json['total_questions'] as int
          : int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      timeLimitMinutes: (json['time_limit_minutes'] is int)
          ? json['time_limit_minutes'] as int
          : int.tryParse(json['time_limit_minutes']?.toString() ?? '15') ?? 15,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      subjectNameSw: subSw ?? json['subject_name_sw']?.toString(),
      subjectNameEn: subEn ?? json['subject_name_en']?.toString(),
      quizType: json['quiz_type']?.toString() ?? 'topic',
      examYear: json['exam_year'] is int ? json['exam_year'] as int : int.tryParse(json['exam_year']?.toString() ?? ''),
      isPublished: json['is_published'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (notesId != null) 'notes_id': notesId,
      'subject_id': subjectId,
      'title': title,
      'form_level': formLevel,
      'difficulty': difficulty,
      'total_questions': totalQuestions,
      'time_limit_minutes': timeLimitMinutes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  String getSubjectDisplayName(String lang) {
    if (lang == 'sw') {
      return subjectNameSw ?? subjectNameEn ?? 'Somo';
    }
    return subjectNameEn ?? subjectNameSw ?? 'Subject';
  }
}

/// Option item within a multiple choice or true/false question.
class QuizQuestionOption {
  final String text;
  final bool correct;

  const QuizQuestionOption({
    required this.text,
    required this.correct,
  });

  factory QuizQuestionOption.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return QuizQuestionOption(
        text: json['text']?.toString() ?? '',
        correct: json['correct'] == true,
      );
    } else if (json is String) {
      return QuizQuestionOption(text: json, correct: false);
    }
    return const QuizQuestionOption(text: '', correct: false);
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'correct': correct,
      };
}

/// Question model representing a single quiz question.
/// Mirrors Supabase `public.quiz_questions` table.
class QuizQuestionModel {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType; // 'mcq' | 'true_false' | 'short'
  final List<QuizQuestionOption> options;
  final String? correctAnswer;
  final String? explanation;
  final String difficulty;
  final int orderNum;

  const QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.options = const [],
    this.correctAnswer,
    this.explanation,
    this.difficulty = 'medium',
    this.orderNum = 1,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    List<QuizQuestionOption> parsedOptions = [];
    final rawOptions = json['options'];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .map((o) => QuizQuestionOption.fromJson(o))
          .toList();
    } else if (rawOptions is String && rawOptions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOptions);
        if (decoded is List) {
          parsedOptions = decoded
              .map((o) => QuizQuestionOption.fromJson(o))
              .toList();
        }
      } catch (_) {}
    }

    return QuizQuestionModel(
      id: json['id']?.toString() ?? '',
      quizId: json['quiz_id']?.toString() ?? '',
      questionText: json['question_text']?.toString() ?? '',
      questionType: json['question_type']?.toString().toLowerCase() ?? 'mcq',
      options: parsedOptions,
      correctAnswer: json['correct_answer']?.toString(),
      explanation: json['explanation']?.toString(),
      difficulty: json['difficulty']?.toString().toLowerCase() ?? 'medium',
      orderNum: (json['order_num'] is int)
          ? json['order_num'] as int
          : int.tryParse(json['order_num']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'options': options.map((o) => o.toJson()).toList(),
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      'difficulty': difficulty,
      'order_num': orderNum,
    };
  }
}

/// Quiz Attempt model representing a student's completed quiz attempt.
/// Mirrors Supabase `public.quiz_attempts` table.
class QuizAttemptModel {
  final String id;
  final String studentId;
  final String quizId;
  final double score; // Percentage e.g. 75.0
  final int timeTakenSeconds;
  final Map<String, dynamic> answers; // { question_id: submitted_text }
  final DateTime completedAt;
  final DateTime? syncedAt;
  final String? quizTitle;

  const QuizAttemptModel({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.score,
    required this.timeTakenSeconds,
    required this.answers,
    required this.completedAt,
    this.syncedAt,
    this.quizTitle,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedAnswers = {};
    final rawAnswers = json['answers'];
    if (rawAnswers is Map<String, dynamic>) {
      parsedAnswers = rawAnswers;
    } else if (rawAnswers is String && rawAnswers.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAnswers);
        if (decoded is Map<String, dynamic>) {
          parsedAnswers = decoded;
        }
      } catch (_) {}
    }

    String? qTitle;
    if (json['quizzes'] != null && json['quizzes'] is Map<String, dynamic>) {
      qTitle = json['quizzes']['title'] as String?;
    }

    return QuizAttemptModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      quizId: json['quiz_id']?.toString() ?? '',
      score: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : double.tryParse(json['score']?.toString() ?? '0.0') ?? 0.0,
      timeTakenSeconds: (json['time_taken_seconds'] is int)
          ? json['time_taken_seconds'] as int
          : int.tryParse(json['time_taken_seconds']?.toString() ?? '0') ?? 0,
      answers: parsedAnswers,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      syncedAt: json['synced_at'] != null
          ? DateTime.tryParse(json['synced_at'].toString())
          : null,
      quizTitle: qTitle ?? json['quiz_title']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'quiz_id': quizId,
      'score': score,
      'time_taken_seconds': timeTakenSeconds,
      'answers': answers,
      'completed_at': completedAt.toIso8601String(),
      if (syncedAt != null) 'synced_at': syncedAt!.toIso8601String(),
    };
  }
}
