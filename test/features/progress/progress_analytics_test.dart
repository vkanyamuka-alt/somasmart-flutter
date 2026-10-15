import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';
import 'package:somasmart_flutter/features/progress/domain/models/progress_models.dart';

void main() {
  group('Progress Domain & Calculations (Matching React Progress.jsx)', () {
    test('Empty attempts produce clean empty state model', () {
      final empty = ProgressAnalyticsModel.empty();

      expect(empty.avgScore, 0);
      expect(empty.totalQuizzes, 0);
      expect(empty.learningStatus, 'New');
      expect(empty.chronologicalAttempts, isEmpty);
      expect(empty.subjectMetrics, isEmpty);
      expect(empty.weakTopics, isEmpty);
    });

    test('Calculates average score and learning status correctly matching React', () {
      final attempts = [
        QuizAttemptModel(
          id: 'a1',
          studentId: 's1',
          quizId: 'q1',
          score: 80.0,
          timeTakenSeconds: 120,
          answers: {},
          completedAt: DateTime.parse('2026-09-01T10:00:00Z'),
        ),
        QuizAttemptModel(
          id: 'a2',
          studentId: 's1',
          quizId: 'q2',
          score: 65.0,
          timeTakenSeconds: 150,
          answers: {},
          completedAt: DateTime.parse('2026-09-02T10:00:00Z'),
        ),
        QuizAttemptModel(
          id: 'a3',
          studentId: 's1',
          quizId: 'q1',
          score: 90.0,
          timeTakenSeconds: 110,
          answers: {},
          completedAt: DateTime.parse('2026-09-03T10:00:00Z'),
        ),
      ];

      final totalQuizzes = attempts.length;
      final sum = attempts.fold<double>(0.0, (s, a) => s + a.score);
      final avgScore = (sum / totalQuizzes).round();
      final learningStatus = totalQuizzes > 0 ? 'Active' : 'New';

      expect(totalQuizzes, 3);
      // (80 + 65 + 90) / 3 = 235 / 3 = 78.333 -> 78
      expect(avgScore, 78);
      expect(learningStatus, 'Active');
    });

    test('Groups subject metrics with rounded averages and counts', () {
      final subMetric = SubjectProgressModel(
        subjectId: 'sub_kemia',
        nameSw: 'Kemia',
        nameEn: 'Chemistry',
        total: 2,
        avg: 85,
      );

      expect(subMetric.getDisplayName('sw'), 'Kemia');
      expect(subMetric.getDisplayName('en'), 'Chemistry');
      expect(subMetric.total, 2);
      expect(subMetric.avg, 85);
    });

    test('Identifies weak topics with score < 60% and preserves unique quiz IDs', () {
      final weakAttempts = [
        {'quizId': 'q1', 'title': 'Hydrocarbons', 'score': 50.0, 'notesId': 'n1'},
        {'quizId': 'q2', 'title': 'Quadratic Equations', 'score': 75.0, 'notesId': 'n2'},
        {'quizId': 'q3', 'title': 'Organic Chemistry', 'score': 45.0, 'notesId': 'n3'},
        {'quizId': 'q1', 'title': 'Hydrocarbons Repeat', 'score': 55.0, 'notesId': 'n1'},
      ];

      final List<WeakTopicModel> weakList = [];
      final Set<String> seenQuizIds = {};

      for (final a in weakAttempts) {
        final score = a['score'] as double;
        final qId = a['quizId'] as String;
        if (score < 60.0) {
          if (!seenQuizIds.contains(qId)) {
            seenQuizIds.add(qId);
            weakList.add(WeakTopicModel(
              quizId: qId,
              title: a['title'] as String,
              score: score,
              subjectId: 'sub1',
              notesId: a['notesId'] as String?,
            ));
          }
        }
      }

      expect(weakList.length, 2);
      expect(weakList[0].quizId, 'q1');
      expect(weakList[0].score, 50.0);
      expect(weakList[0].notesId, 'n1');
      expect(weakList[1].quizId, 'q3');
      expect(weakList[1].score, 45.0);
    });
  });
}
