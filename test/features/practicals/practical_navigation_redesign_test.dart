import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_level_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_subject_select_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_subject_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_mode_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/practical_thumbnail_widget.dart';

void main() {
  group('P19 Practicals Organization and UX Redesign Tests', () {
    testWidgets('1. PracticalLevelScreen renders Simulation Laboratory Hub with O-Level & A-Level cards in English', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalLevelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to the'), findsOneWidget);
      expect(find.text('SomaSmart Simulation Laboratory'), findsOneWidget);
      expect(find.text('O-Level'), findsOneWidget);
      expect(find.text('A-Level'), findsOneWidget);
      expect(find.text('Choose a bench'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('3 open, 6 coming soon'), findsOneWidget);
      expect(find.text('3 open'), findsOneWidget);
      expect(find.text('2 open'), findsOneWidget);

      // A-Level shows that its practicals are still being built.
      await tester.tap(find.text('A-Level'));
      await tester.pumpAndSettle();
      expect(find.text('A-Level practicals are on the way'), findsOneWidget);
      expect(find.text('Chemistry'), findsNothing);

      await tester.tap(find.text('Show O-Level practicals'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a bench'), findsOneWidget);
    });

    testWidgets('2. PracticalSubjectSelectScreen renders Chemistry, Physics, Biology subject cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalSubjectSelectScreen(level: PracticalLevel.oLevel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('O-Level Laboratory'), findsOneWidget);
      expect(find.text('Select Science Discipline'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
    });

    testWidgets('3. PracticalSubjectScreen renders horizontal cards with thumbnails and Open Practical button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalSubjectScreen(
              level: PracticalLevel.oLevel,
              initialSubject: PracticalSubject.chemistry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Student-facing numbering
      expect(find.text('Practical 1'), findsOneWidget);
      expect(find.text('Practical 2'), findsOneWidget);
      expect(find.text('Practical 3'), findsOneWidget);

      // Titles
      expect(find.text('Acid–Base Titration (HCl vs NaOH)'), findsOneWidget);
      expect(find.text('Open Practical'), findsWidgets);
      expect(find.byType(PracticalThumbnailWidget), findsWidgets);
    });

    testWidgets('4. PracticalModeScreen renders clean details, 1-sentence objective, and Guided/Exam/Free mode cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalModeScreen(practicalId: 'titration'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acid–Base Titration (HCl vs NaOH)'), findsOneWidget);
      expect(find.text('Guided Practice'), findsOneWidget);
      expect(find.text('Exam Mode'), findsOneWidget);
      expect(find.text('Free Exploration'), findsOneWidget);
      expect(find.text('Start Practical'), findsOneWidget);
    });

    testWidgets('5. The lab stays in English when the app is in Swahili', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      // Level Hub in Swahili
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalLevelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SomaSmart Simulation Laboratory'), findsOneWidget);
      expect(find.text('Choose a bench'), findsOneWidget);

      // Subject Select in Swahili
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalSubjectSelectScreen(level: PracticalLevel.oLevel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('O-Level Laboratory'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('Kemia'), findsNothing);

      // Mode Screen in Swahili
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PracticalModeScreen(practicalId: 'titration'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guided Practice'), findsOneWidget);
      expect(find.text('Start Practical'), findsOneWidget);
      expect(find.text('Anza Jaribio la Vitendo'), findsNothing);
    });
  });
}
