import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';

void main() {
  test('answers saved as {text, correct} keep their marking', () {
    final q = QuizQuestionModel.fromJson({
      'id': 'a',
      'question_type': 'mcq',
      'options': [
        {'text': 'Nucleus', 'correct': false},
        {'text': 'Mitochondrion', 'correct': true},
      ],
    });
    expect(q.options.map((o) => o.correct), [false, true]);
  });

  test('plain-text answers show, and correct_answer marks the right one', () {
    final q = QuizQuestionModel.fromJson({
      'id': 'b',
      'question_type': 'mcq',
      'options': ['Nucleus', 'Mitochondrion'],
      'correct_answer': 'mitochondrion',
    });
    expect(q.options.map((o) => o.text), ['Nucleus', 'Mitochondrion']);
    expect(q.options.map((o) => o.correct), [false, true]);
  });

  test('plain-text answers saved as a JSON string are read too', () {
    final q = QuizQuestionModel.fromJson({
      'id': 'c',
      'question_type': 'mcq',
      'options': '["a", "b"]',
      'correct_answer': 'b',
    });
    expect(q.options.map((o) => o.correct), [false, true]);
  });
}
