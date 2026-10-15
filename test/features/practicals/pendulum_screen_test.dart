import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/pendulum_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/pendulum_screen.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(PendulumEngine());
  });

  Widget buildTestableWidget({
    required SharedPreferences prefs,
    PracticalMode mode = PracticalMode.guidedPractice,
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: PendulumScreen(mode: mode),
      ),
    );
  }

  group('Pendulum Screen Widget Tests', () {
    testWidgets('renders workbench, header, step bar, and apparatus cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GUIDEDPRACTICE'), findsOneWidget);
      expect(find.text('Simple Pendulum (g)'), findsOneWidget);
      expect(find.text('1. Inspect Apparatus'), findsWidgets);
      expect(find.text('Laboratory Apparatus'), findsOneWidget);
      expect(find.text('Retort Stand & Clamp'), findsOneWidget);
      expect(find.text('Heavy Metallic Bob'), findsOneWidget);
    });

    testWidgets('inspects apparatus items on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0 / 5 Inspected'), findsOneWidget);

      await tester.tap(find.text('Retort Stand & Clamp'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 / 5 Inspected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    testWidgets('navigates through step tabs and adjusts string length', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Jump to step 1 (Set String Length)
      await tester.tap(find.text('2. Set String Length'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Set String Length (L)'), findsOneWidget);
      expect(find.text('60 cm'), findsOneWidget);

      // Tap 60cm preset
      await tester.tap(find.text('60 cm'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('L = 60.0 cm (0.60 m)'), findsWidgets);
    });

    testWidgets('renders stopwatch controls and starts timing in step 3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Jump to step 3 (Time Oscillations)
      await tester.tap(find.text('4. Time Oscillations'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Digital Stopwatch & Timing'), findsOneWidget);
      expect(find.text('Start Oscillations'), findsOneWidget);
      expect(find.text('Record Trial'), findsOneWidget);

      // Tap Start
      await tester.tap(find.text('Start Oscillations'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Stop Timing'), findsOneWidget);

      // Tap Stop
      await tester.tap(find.text('Stop Timing'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Start Oscillations'), findsOneWidget);
    });

    testWidgets('renders Swahili bilingual UI properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Penduli Rahisi (g)'), findsOneWidget);
      expect(find.text('1. Kagua Vifaa'), findsWidgets);
      expect(find.text('Vifaa vya Maabara'), findsOneWidget);
      expect(find.text('Standi na Kishikio cha Chuma'), findsOneWidget);
    });

    testWidgets('opens Lab Notebook bottom sheet with event logs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Lab Notebook icon in app bar
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Physics Laboratory Notebook'), findsOneWidget);
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
