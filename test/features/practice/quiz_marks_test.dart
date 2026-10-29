import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';
import 'package:somasmart_flutter/features/practice/presentation/screens/quiz_results_screen.dart';

void main() {
  const mcq = QuizQuestionModel(
    id: 'a',
    quizId: 'q',
    questionText: 'Which organelle releases energy from food?',
    questionType: 'mcq',
    options: [
      QuizQuestionOption(text: 'Nucleus', correct: false),
      QuizQuestionOption(text: 'Mitochondrion', correct: true),
    ],
  );
  const short = QuizQuestionModel(
    id: 'b',
    quizId: 'q',
    questionText: 'Process plants use to make food?',
    questionType: 'short',
    correctAnswer: 'Photosynthesis',
  );

  test('marks answers the same way as the web app', () {
    expect(isQuizAnswerCorrect(mcq, 'Mitochondrion'), isTrue);
    expect(isQuizAnswerCorrect(mcq, 'Nucleus'), isFalse);
    expect(isQuizAnswerCorrect(short, ' photosynthesis '), isTrue);
    expect(isQuizAnswerCorrect(short, null), isFalse, reason: 'unanswered counts as wrong');
    expect(isQuizAnswerCorrect(short, ''), isFalse);
  });
}
