import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';
import 'package:somasmart_flutter/features/practice/presentation/controllers/quiz_controllers.dart';
import 'package:somasmart_flutter/features/practice/presentation/screens/quiz_exams_screen.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  test('reads the quiz type, past-paper year and published flag set in the admin panel', () {
    final q = QuizModel.fromJson({
      'id': 'q1',
      'subject_id': 's',
      'title': 'Biology Paper 1',
      'form_level': 4,
      'quiz_type': 'past_paper',
      'exam_year': 2023,
      'is_published': true,
    });
    expect(q.quizType, 'past_paper');
    expect(q.examYear, 2023);
    expect(q.isPublished, isTrue);

    final old = QuizModel.fromJson({'id': 'q2', 'subject_id': 's', 'title': 'Old', 'form_level': 1});
    expect(old.quizType, 'topic', reason: 'quizzes made before quiz types are topic quizzes');
  });

  testWidgets('each tab shows only published quizzes of its type; Past papers follows the link', (tester) async {
    SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    const quizzes = [
      QuizModel(id: 't', subjectId: 's', title: 'Cell biology quiz', formLevel: 1, quizType: 'topic'),
      QuizModel(id: 'p', subjectId: 's', title: 'Biology Paper 1', formLevel: 4, quizType: 'past_paper', examYear: 2023),
      QuizModel(id: 'd', subjectId: 's', title: 'Draft paper', formLevel: 4, quizType: 'past_paper', isPublished: false),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        languageProvider.overrideWith((ref) => _Lang('en')),
        quizListProvider.overrideWith((ref) async => quizzes),
        userProfileProvider.overrideWith(() => _Profile()),
      ],
      child: const MaterialApp(home: QuizExamsScreen(initialTab: 'practice')),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Biology Paper 1'), findsOneWidget);
    expect(find.text('Cell biology quiz'), findsNothing);
    expect(find.text('Draft paper'), findsNothing);
  });
}

class _Lang extends StateNotifier<String> implements LanguageNotifier {
  _Lang(super.state);
  @override
  Future<void> setLanguage(String lang) async => state = lang;
}

class _Profile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
        id: 'u',
        email: 'u@x.tz',
        fullName: 'Student',
        phone: '',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc(),
      );
}
