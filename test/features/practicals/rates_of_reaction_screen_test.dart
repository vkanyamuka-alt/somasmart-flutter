import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/domain/rates_of_reaction_engine.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/rates_of_reaction_screen.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(RatesOfReactionEngine());
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
        home: RatesOfReactionScreen(mode: mode),
      ),
    );
  }

  group('Rates of Chemical Reactions Screen Widget Tests', () {
    testWidgets('renders workbench, header, step bar, and apparatus cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GUIDED PRACTICE'), findsOneWidget);
      expect(find.text('Rates of Chemical Reactions'), findsOneWidget);
      expect(find.text('1. Inspect Apparatus'), findsWidgets);
      expect(find.text('5 × 250 mL Conical Flasks (Pyrex)'), findsOneWidget);
      expect(find.text('White Ceramic Tile with Bold Black Cross (X)'), findsOneWidget);
      expect(find.text('Digital Electronic Stopwatch (0.01 s)'), findsOneWidget);
    });

    testWidgets('inspects apparatus items on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0/6'), findsOneWidget);

      await tester.tap(find.text('5 × 250 mL Conical Flasks (Pyrex)'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1/6'), findsOneWidget);
    });

    testWidgets('navigates through step tabs and prepares dilutions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Step 2 (Prepare Solutions)
      await tester.tap(find.text('2. Prepare Solutions'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dilution Preparation (Flasks 1–5)'), findsOneWidget);
      expect(find.text('Dilute All'), findsOneWidget);

      // Tap Dilute All
      await tester.tap(find.text('Dilute All'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Prepared'), findsWidgets);
    });

    testWidgets('renders Swahili bilingual UI properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Kasi ya Miitikio ya Kikemia'), findsOneWidget);
      expect(find.text('1. Kagua Vifaa'), findsWidgets);
      expect(find.text('Chupa 5 za Koni za 250 mL (Pyrex)'), findsOneWidget);
    });

    testWidgets('renders in Dark Theme without crashing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration, isDark: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FREE EXPLORATION'), findsOneWidget);
      expect(find.text('Rates of Chemical Reactions'), findsOneWidget);
    });
  });
}
