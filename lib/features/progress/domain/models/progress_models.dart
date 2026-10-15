// Domain models for Progress & Learning Analytics.
// Matches React SomaSmart's progress calculations and data structures.

import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';

/// Subject performance metric model.
class SubjectProgressModel {
  final String subjectId;
  final String nameSw;
  final String nameEn;
  final int total;
  final int avg;

  const SubjectProgressModel({
    required this.subjectId,
    required this.nameSw,
    required this.nameEn,
    required this.total,
    required this.avg,
  });

  String getDisplayName(String lang) {
    if (lang == 'sw') {
      return nameSw.isNotEmpty ? nameSw : nameEn;
    }
    return nameEn.isNotEmpty ? nameEn : nameSw;
  }
}

/// Weak topic requiring review (< 60% score).
class WeakTopicModel {
  final String quizId;
  final String title;
  final double score;
  final String subjectId;
  final String? notesId;

  const WeakTopicModel({
    required this.quizId,
    required this.title,
    required this.score,
    required this.subjectId,
    this.notesId,
  });
}

/// Consolidated Progress Analytics Model.
class ProgressAnalyticsModel {
  final int avgScore;
  final int totalQuizzes;
  final String learningStatus; // 'Active' or 'New'
  final List<QuizAttemptModel> chronologicalAttempts;
  final List<SubjectProgressModel> subjectMetrics;
  final List<WeakTopicModel> weakTopics;

  const ProgressAnalyticsModel({
    required this.avgScore,
    required this.totalQuizzes,
    required this.learningStatus,
    required this.chronologicalAttempts,
    required this.subjectMetrics,
    required this.weakTopics,
  });

  factory ProgressAnalyticsModel.empty() {
    return const ProgressAnalyticsModel(
      avgScore: 0,
      totalQuizzes: 0,
      learningStatus: 'New',
      chronologicalAttempts: [],
      subjectMetrics: [],
      weakTopics: [],
    );
  }
}
