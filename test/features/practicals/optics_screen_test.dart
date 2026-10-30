import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/optics_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/optics_screen.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(OpticsEngine());
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
        home: OpticsScreen(mode: mode),
      ),
    );
  }

  group('Optics Screen Widget Tests', () {
    testWidgets('renders workbench, header, step bar, and apparatus cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GUIDED PRACTICE'), findsOneWidget);
      expect(find.text('Refraction & Prism'), findsOneWidget);
      expect(find.text('1. Inspect Apparatus'), findsWidgets);
      expect(find.text('Equilateral Glass Prism'), findsOneWidget);
      expect(find.text('Optical Target Pins (P1–P4)'), findsOneWidget);
      expect(find.text('360°/180° Optical Protractor'), findsOneWidget);
    });

    testWidgets('inspects apparatus items on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0/5'), findsOneWidget);

      await tester.tap(find.text('Equilateral Glass Prism'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1/5'), findsOneWidget);
    });

    testWidgets('navigates through step tabs and adjusts incident angle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Step 3 (Set Incident Angle)
      await tester.tap(find.text('3. Set Incident Angle'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Adjust Angle of Incidence (i)'), findsOneWidget);
      expect(find.text('30°'), findsOneWidget);
      expect(find.text('60°'), findsOneWidget);

      // Tap 30° preset
      await tester.tap(find.text('30°'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('i = 30.0°'), findsOneWidget);
    });

    testWidgets('stays in English when the app is in Swahili', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Refraction & Prism'), findsOneWidget);
      expect(find.text('1. Inspect Apparatus'), findsWidgets);
      expect(find.text('1. Kagua Vifaa'), findsNothing);
    });

    testWidgets('opens Lab Notebook bottom sheet with event logs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      final notebookButton = find.byIcon(Icons.menu_book_outlined);
      expect(notebookButton, findsOneWidget);

      await tester.tap(notebookButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Optics Laboratory Notebook'), findsOneWidget);
      expect(find.textContaining('Principle: n₁ · sin(i) = n₂ · sin(r)'), findsOneWidget);
    });
  });
}
