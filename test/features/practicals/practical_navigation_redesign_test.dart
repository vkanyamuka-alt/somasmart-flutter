import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/repositories/practical_repository_impl.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_level_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_mode_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_subject_screen.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/practical_theory_screen.dart';

// The lab: subject cards and practical rows carry names only; a practical's
// page offers Read theory and Open practical; the mode is chosen after Open
// practical. Learning screens stay in English.
void main() {
  late SharedPreferences prefs;

  Future<void> pumpRoutes(WidgetTester tester, String location, {String lang = 'en'}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'somasmart_language': lang});
    prefs = await SharedPreferences.getInstance();
    final router = GoRouter(initialLocation: location, routes: [
      GoRoute(path: '/practical', builder: (c, s) => const PracticalLevelScreen()),
      GoRoute(path: '/practical/mode-selection/:id', builder: (c, s) => PracticalModeScreen(practicalId: s.pathParameters['id']!)),
      GoRoute(path: '/practical/theory/:id', builder: (c, s) => PracticalTheoryScreen(practicalId: s.pathParameters['id']!)),
      GoRoute(path: '/practical/simulation/:id', builder: (c, s) => Scaffold(body: Text('run ${s.pathParameters['id']} ${s.uri.queryParameters['mode']}'))),
      GoRoute(
        path: '/practical/:level/:subject',
        builder: (c, s) => PracticalSubjectScreen(
          level: PracticalLevelExtension.fromId(s.pathParameters['level']!),
          initialSubject: PracticalSubjectExtension.fromId(s.pathParameters['subject']!),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the lab home: one card per subject with its name only; A-Level says it is coming', (tester) async {
    await pumpRoutes(tester, '/practical');
    expect(find.text('SomaSmart Simulation Laboratory'), findsOneWidget);
    expect(find.text('Choose a subject'), findsOneWidget);
    for (final name in ['Chemistry', 'Physics', 'Biology']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('open'), findsNothing, reason: 'no counts on subject cards');
    expect(find.textContaining('Forms 1 to 4'), findsNothing);

    await tester.tap(find.text('A-Level'));
    await tester.pumpAndSettle();
    expect(find.text('A-Level practicals are on the way'), findsOneWidget);
    await tester.ensureVisible(find.text('Show O-Level practicals'));
    await tester.tap(find.text('Show O-Level practicals'));
    await tester.pumpAndSettle();
    expect(find.text('Chemistry'), findsOneWidget);
  });

  testWidgets('a subject lists practicals by name: ready ones open, the rest are locked', (tester) async {
    await pumpRoutes(tester, '/practical/o-level/chemistry');
    expect(find.text('Acid–Base Titration'), findsOneWidget);
    expect(find.text('Qualitative Analysis'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    expect(find.textContaining('Mins'), findsNothing, reason: 'no durations or descriptions');
    expect(find.textContaining('Practical 1'), findsNothing);

    // A locked practical does nothing.
    await tester.tap(find.text('Qualitative Analysis'));
    await tester.pumpAndSettle();
    expect(find.text('Read theory'), findsNothing);

    await tester.tap(find.text('Acid–Base Titration'));
    await tester.pumpAndSettle();
    expect(find.text('Read theory'), findsOneWidget);
    expect(find.text('Open practical'), findsOneWidget);
    expect(find.text('Guided'), findsNothing, reason: 'the mode is chosen after Open practical');
  });

  testWidgets('Open practical asks how to work and starts in that mode', (tester) async {
    await pumpRoutes(tester, '/practical/mode-selection/pendulum-phys');
    expect(find.text('Simple Pendulum'), findsOneWidget);
    expect(find.textContaining('acceleration due to gravity'), findsOneWidget, reason: 'the aim, in plain words');

    await tester.tap(find.text('Open practical'));
    await tester.pumpAndSettle();
    expect(find.text('How do you want to work?'), findsOneWidget);
    await tester.tap(find.text('Exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('run pendulum-phys examMode'), findsOneWidget);
  });

  testWidgets('every practical that opens has its theory, with its sections', (tester) async {
    final repo = PracticalRepositoryImpl();
    final open = [
      for (final level in PracticalLevel.values)
        for (final subject in PracticalSubject.values)
          ...repo.getPracticalsByLevelAndSubject(level: level, subject: subject).where((p) => p.hasSimulationEngine),
    ];
    expect(open, isNotEmpty);
    for (final p in open) {
      // Its own bundle, so the shared cache is not filled from this test.
      final text = await PracticalTheoryScreen.load(p.id, bundle: PlatformAssetBundle());
      expect(text, isNotNull, reason: '${p.id} has no theory');
      for (final h in ['## Aim', '## Theory', '## Procedure', '## Precautions']) {
        expect(text, contains(h), reason: '${p.id}: $h');
      }
    }
  });

  testWidgets('Read theory shows the theory, and it stays in English when the app is in Swahili', (tester) async {
    await pumpRoutes(tester, '/practical/mode-selection/titration', lang: 'sw');
    expect(find.text('Read theory'), findsOneWidget);
    // Start from an empty asset cache, so no earlier test's read is reused.
    rootBundle.clear();
    await tester.tap(find.text('Read theory'));
    await tester.pumpAndSettle();
    expect(find.text('Aim'), findsOneWidget);
    expect(find.text('Precautions'), findsOneWidget);
    // The page scrolls; display equations scroll sideways inside it.
    await tester.scrollUntilVisible(find.text('Open practical'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text('Open practical'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
