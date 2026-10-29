import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/models/quiz_models.dart';

/// Filter provider for the active Quiz discovery tab.
/// Values: 'topic' | 'exam' | 'past_paper' | 'timed' (the quiz's quiz_type)
final quizTabFilterProvider = StateProvider<String>((ref) => 'topic');

/// Filter provider for selected subject ID in quiz discovery (null means all).
final quizSubjectFilterProvider = StateProvider<String?>((ref) => null);

/// Filter provider for selected Form Level (1..6 or null for all).
final quizFormFilterProvider = StateProvider<int?>((ref) => null);

/// Future provider fetching quizzes based on current filters.
final quizListProvider = FutureProvider<List<QuizModel>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  final subjectId = ref.watch(quizSubjectFilterProvider);
  final formLevel = ref.watch(quizFormFilterProvider);

  return repo.getQuizzes(
    subjectId: subjectId,
    formLevel: formLevel,
  );
});

/// Future provider fetching questions for a specific quiz ID.
final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestionModel>, String>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizQuestions(quizId);
});

/// Future provider fetching a single quiz by ID.
final quizDetailProvider =
    FutureProvider.family<QuizModel?, String>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizById(quizId);
});

/// Future provider fetching an attempt by ID for the results screen.
final quizAttemptDetailProvider =
    FutureProvider.family<QuizAttemptModel?, String>((ref, attemptId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getAttemptById(attemptId);
});

/// State representation for an active interactive quiz session.
class QuizSessionState {
  final QuizModel? quiz;
  final List<QuizQuestionModel> questions;
  final int currentIndex;
  final QuizQuestionOption? selectedOption;
  final String shortAnswerText;
  final bool isAnswered;
  final bool isCorrect;
  final Map<String, dynamic> answersMap;
  final int scoreCount;
  final int timeLeft; // in seconds
  final bool isFinished;
  final String currentDifficulty;
  final int consecutiveCorrect;
  final int consecutiveWrong;
  final String? adaptiveMessage;
  final bool isSubmitting;
  final QuizAttemptModel? submittedAttempt;
  final String? errorMessage;

  const QuizSessionState({
    this.quiz,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOption,
    this.shortAnswerText = '',
    this.isAnswered = false,
    this.isCorrect = false,
    this.answersMap = const {},
    this.scoreCount = 0,
    this.timeLeft = 600,
    this.isFinished = false,
    this.currentDifficulty = 'medium',
    this.consecutiveCorrect = 0,
    this.consecutiveWrong = 0,
    this.adaptiveMessage,
    this.isSubmitting = false,
    this.submittedAttempt,
    this.errorMessage,
  });

  QuizQuestionModel? get currentQuestion {
    if (questions.isEmpty || currentIndex < 0 || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  QuizSessionState copyWith({
    QuizModel? quiz,
    List<QuizQuestionModel>? questions,
    int? currentIndex,
    QuizQuestionOption? selectedOption,
    bool clearSelectedOption = false,
    String? shortAnswerText,
    bool? isAnswered,
    bool? isCorrect,
    Map<String, dynamic>? answersMap,
    int? scoreCount,
    int? timeLeft,
    bool? isFinished,
    String? currentDifficulty,
    int? consecutiveCorrect,
    int? consecutiveWrong,
    String? adaptiveMessage,
    bool clearAdaptiveMessage = false,
    bool? isSubmitting,
    QuizAttemptModel? submittedAttempt,
    String? errorMessage,
  }) {
    return QuizSessionState(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      shortAnswerText: shortAnswerText ?? this.shortAnswerText,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      answersMap: answersMap ?? this.answersMap,
      scoreCount: scoreCount ?? this.scoreCount,
      timeLeft: timeLeft ?? this.timeLeft,
      isFinished: isFinished ?? this.isFinished,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      adaptiveMessage: clearAdaptiveMessage ? null : (adaptiveMessage ?? this.adaptiveMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedAttempt: submittedAttempt ?? this.submittedAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller managing active quiz session state, timer, option selection, adaptive scoring, and submission.
class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  final QuizRepository _repository;
  Timer? _timer;

  QuizSessionNotifier(this._repository) : super(const QuizSessionState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initialize the quiz session with the loaded quiz and questions.
  void initialize(QuizModel quiz, List<QuizQuestionModel> questions) {
    _timer?.cancel();

    final timeInSeconds = quiz.timeLimitMinutes > 0
        ? quiz.timeLimitMinutes * 60
        : 600;

    state = QuizSessionState(
      quiz: quiz,
      questions: questions,
      currentIndex: 0,
      timeLeft: timeInSeconds,
      currentDifficulty: quiz.difficulty,
      isFinished: false,
      scoreCount: 0,
      answersMap: {},
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isFinished) {
        timer.cancel();
        return;
      }

      if (state.timeLeft <= 1) {
        timer.cancel();
        state = state.copyWith(timeLeft: 0);
        // Force complete on timeout
        forceSubmit();
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  /// Check answer for multiple choice / true-false questions (matches React handleCheckAnswer).
  void checkAnswer(QuizQuestionOption option) {
    if (state.isAnswered || state.isFinished) return;

    final currentQ = state.currentQuestion;
    if (currentQ == null) return;

    bool isAnsCorrect = false;
    if (currentQ.questionType == 'mcq' || currentQ.questionType == 'true_false') {
      isAnsCorrect = option.correct;
    }

    final newAnswersMap = Map<String, dynamic>.from(state.answersMap);
    newAnswersMap[currentQ.id] = option.text;

    int newScore = state.scoreCount;
    int newConsecutiveCorrect = state.consecutiveCorrect;
    int newConsecutiveWrong = state.consecutiveWrong;

    if (isAnsCorrect) {
      newScore += 1;
      newConsecutiveCorrect += 1;
      newConsecutiveWrong = 0;
    } else {
      newConsecutiveWrong += 1;
      newConsecutiveCorrect = 0;
    }

    state = state.copyWith(
      selectedOption: option,
      isAnswered: true,
      isCorrect: isAnsCorrect,
      answersMap: newAnswersMap,
      scoreCount: newScore,
      consecutiveCorrect: newConsecutiveCorrect,
      consecutiveWrong: newConsecutiveWrong,
    );
  }

  /// Check short answer question (matches React handleCheckShortAnswer).
  void checkShortAnswer(String text) {
    if (state.isAnswered || state.isFinished || text.trim().isEmpty) return;

    final currentQ = state.currentQuestion;
    if (currentQ == null) return;

    final userAns = text.trim().toLowerCase();
    final correctAns = (currentQ.correctAnswer ?? '').trim().toLowerCase();
    final isAnsCorrect = userAns.isNotEmpty && userAns == correctAns;

    final newAnswersMap = Map<String, dynamic>.from(state.answersMap);
    newAnswersMap[currentQ.id] = text.trim();

    int newScore = state.scoreCount;
    int newConsecutiveCorrect = state.consecutiveCorrect;
    int newConsecutiveWrong = state.consecutiveWrong;

    if (isAnsCorrect) {
      newScore += 1;
      newConsecutiveCorrect += 1;
      newConsecutiveWrong = 0;
    } else {
      newConsecutiveWrong += 1;
      newConsecutiveCorrect = 0;
    }

    state = state.copyWith(
      shortAnswerText: text,
      isAnswered: true,
      isCorrect: isAnsCorrect,
      answersMap: newAnswersMap,
      scoreCount: newScore,
      consecutiveCorrect: newConsecutiveCorrect,
      consecutiveWrong: newConsecutiveWrong,
    );
  }

  /// Advance to the next question with adaptive difficulty scaling matching React handleNext.
  void nextQuestion() {
    if (state.currentIndex + 1 < state.questions.length) {
      // Adaptive difficulty scaling
      String nextDifficulty = state.currentDifficulty;
      String? adaptiveMsg;
      int nextConsecutiveCorrect = state.consecutiveCorrect;
      int nextConsecutiveWrong = state.consecutiveWrong;

      if (state.consecutiveCorrect >= 2) {
        if (state.currentDifficulty == 'easy') {
          nextDifficulty = 'medium';
          adaptiveMsg = 'Ugumu Umeongezeka!';
        } else if (state.currentDifficulty == 'medium') {
          nextDifficulty = 'hard';
          adaptiveMsg = 'Ugumu Umeongezeka!';
        }
        nextConsecutiveCorrect = 0;
      } else if (state.consecutiveWrong >= 1) {
        if (state.currentDifficulty == 'hard') {
          nextDifficulty = 'medium';
          adaptiveMsg = 'Ugumu Umepunguzwa!';
        } else if (state.currentDifficulty == 'medium') {
          nextDifficulty = 'easy';
          adaptiveMsg = 'Ugumu Umepunguzwa!';
        }
        nextConsecutiveWrong = 0;
      }

      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedOption: true,
        shortAnswerText: '',
        isAnswered: false,
        isCorrect: false,
        currentDifficulty: nextDifficulty,
        consecutiveCorrect: nextConsecutiveCorrect,
        consecutiveWrong: nextConsecutiveWrong,
        adaptiveMessage: adaptiveMsg,
      );
    }
  }

  /// Jump directly to a question index (if student wants to review).
  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      final targetQ = state.questions[index];
      final existingAnswer = state.answersMap[targetQ.id];

      QuizQuestionOption? selOpt;
      if (existingAnswer != null && targetQ.options.isNotEmpty) {
        for (final opt in targetQ.options) {
          if (opt.text == existingAnswer) {
            selOpt = opt;
            break;
          }
        }
      }

      state = state.copyWith(
        currentIndex: index,
        selectedOption: selOpt,
        shortAnswerText: existingAnswer?.toString() ?? '',
        isAnswered: existingAnswer != null,
        isCorrect: selOpt?.correct ?? false,
      );
    }
  }

  /// Complete and submit quiz attempt to Supabase backend (matches React handleCompleteQuiz).
  Future<QuizAttemptModel?> submitQuiz(String studentId) async {
    _timer?.cancel();

    // Prevent duplicate submissions
    if (state.isSubmitting || state.submittedAttempt != null) {
      return state.submittedAttempt;
    }

    if (state.quiz == null || state.questions.isEmpty) return null;

    state = state.copyWith(isSubmitting: true, isFinished: true);

    final totalQ = state.questions.length;
    final finalScorePercent = totalQ > 0
        ? ((state.scoreCount / totalQ) * 100).roundToDouble()
        : 0.0;

    final timeLimit = state.quiz!.timeLimitMinutes * 60;
    final timeTaken = (timeLimit - state.timeLeft).clamp(0, timeLimit);

    final attempt = await _repository.submitAttempt(
      quizId: state.quiz!.id,
      studentId: studentId,
      score: finalScorePercent,
      timeTakenSeconds: timeTaken,
      answers: state.answersMap,
    );

    state = state.copyWith(
      isSubmitting: false,
      submittedAttempt: attempt,
    );

    return attempt;
  }

  /// Force submission on timeout or manual force exit.
  Future<QuizAttemptModel?> forceSubmit({String studentId = ''}) async {
    return submitQuiz(studentId);
  }
}

/// Provider exposing the active QuizSessionNotifier.
final quizSessionProvider =
    StateNotifierProvider.autoDispose<QuizSessionNotifier, QuizSessionState>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return QuizSessionNotifier(repo);
});
