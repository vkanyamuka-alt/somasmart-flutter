import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/progress/data/repositories/progress_repository.dart';
import 'package:somasmart_flutter/features/progress/domain/models/progress_models.dart';

/// Provider that calculates real student progress and learning analytics.
/// Adheres 1:1 to React SomaSmart calculations in `Progress.jsx`.
final progressAnalyticsProvider =
    FutureProvider.autoDispose<ProgressAnalyticsModel>((ref) async {
  final userProfile = ref.watch(userProfileProvider).value;
  final studentId = userProfile?.id ?? '';

  if (studentId.isEmpty || studentId == 'guest') {
    return ProgressAnalyticsModel.empty();
  }

  final repository = ref.watch(progressRepositoryProvider);
  final details = await repository.getStudentAttemptsWithMetadata(studentId);

  if (details.isEmpty) {
    return ProgressAnalyticsModel.empty();
  }

  // 1. Total Quizzes and Avg Score
  final totalQuizzes = details.length;
  final totalScoreSum = details.fold<double>(
    0.0,
    (sum, d) => sum + d.attempt.score,
  );
  final avgScore = (totalScoreSum / totalQuizzes).round();
  final learningStatus = totalQuizzes > 0 ? 'Active' : 'New';

  // 2. Group performance by subject
  // Matches React `getSubjectMetrics`:
  // groups attempts by subject, calculating total attempts and average score.
  final Map<String, _SubjectAccumulator> subjectMap = {};

  for (final item in details) {
    if (item.subjectId.isEmpty) continue;

    final key = item.subjectId;
    if (!subjectMap.containsKey(key)) {
      subjectMap[key] = _SubjectAccumulator(
        subjectId: item.subjectId,
        nameSw: item.subjectNameSw,
        nameEn: item.subjectNameEn,
      );
    }
    subjectMap[key]!.total += 1;
    subjectMap[key]!.scoreSum += item.attempt.score;
  }

  final subjectMetrics = subjectMap.values.map((s) {
    return SubjectProgressModel(
      subjectId: s.subjectId,
      nameSw: s.nameSw,
      nameEn: s.nameEn,
      total: s.total,
      avg: (s.scoreSum / s.total).round(),
    );
  }).toList();

  // 3. Identify weak areas (score < 60%)
  // Matches React `getWeakTopics`:
  // Lists unique quizzes where score < 60%, with links to review notes.
  final List<WeakTopicModel> weakTopics = [];
  final Set<String> seenQuizIds = {};

  for (final item in details) {
    if (item.attempt.score < 60) {
      if (!seenQuizIds.contains(item.attempt.quizId)) {
        seenQuizIds.add(item.attempt.quizId);
        weakTopics.add(WeakTopicModel(
          quizId: item.attempt.quizId,
          title: item.quizTitle,
          score: item.attempt.score,
          subjectId: item.subjectId,
          notesId: item.notesId,
        ));
      }
    }
  }

  return ProgressAnalyticsModel(
    avgScore: avgScore,
    totalQuizzes: totalQuizzes,
    learningStatus: learningStatus,
    chronologicalAttempts: details.map((d) => d.attempt).toList(),
    subjectMetrics: subjectMetrics,
    weakTopics: weakTopics,
  );
});

class _SubjectAccumulator {
  final String subjectId;
  final String nameSw;
  final String nameEn;
  int total = 0;
  double scoreSum = 0.0;

  _SubjectAccumulator({
    required this.subjectId,
    required this.nameSw,
    required this.nameEn,
  });
}
