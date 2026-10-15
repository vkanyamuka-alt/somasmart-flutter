import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/microscope_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/microscope_screen.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(MicroscopeEngine());
  });

  Widget buildTestableWidget({
    required SharedPreferences prefs,
    PracticalMode mode = PracticalMode.guidedPractice,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: MicroscopeScreen(mode: mode),
      ),
    );
  }

  group('Microscope Screen Widget Tests', () {
    testWidgets('Renders all initial UI components for Guided Practice in English', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Title & Badge
      expect(find.text('Light Microscope Cell Staining'), findsOneWidget);
      expect(find.text('GUIDED'), findsOneWidget);

      // Workflow step bar
      expect(find.text('Inspect Apparatus'), findsOneWidget);
      expect(find.text('Mount Specimen'), findsOneWidget);

      // Workbench
      expect(find.text('Slide Preparation Workbench'), findsOneWidget);
      expect(find.text('1. Inspect Apparatus'), findsOneWidget);
      expect(find.text('2. Mount Specimen'), findsOneWidget);
      expect(find.text('3. Apply Iodine'), findsOneWidget);
    });

    testWidgets('Renders initial UI components in Kiswahili', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Darubini ya Mwanga & Seli'), findsOneWidget);
      expect(find.text('MAZOEZI'), findsOneWidget);
      expect(find.text('Kagua Vifaa'), findsOneWidget);
      expect(find.text('Meza ya Kutayarisha Kiolezo'), findsOneWidget);
    });

    testWidgets('Apparatus inspection opens modal and checks off items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 1. Inspect Apparatus
      await tester.tap(find.text('1. Inspect Apparatus'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Apparatus & Reagent Inspection'), findsOneWidget);
      expect(find.text('Compound Light Microscope'), findsOneWidget);
      expect(find.text('Glass Slides & Coverslips'), findsOneWidget);

      // Inspect 4 items
      await tester.tap(find.text('Compound Light Microscope'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Glass Slides & Coverslips'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Mounted Needle (45°)'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Fresh Onion Bulb (Allium cepa)'));
      await tester.pump(const Duration(milliseconds: 100));

      // Close modal
      await tester.tap(find.text('Done Inspecting'));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2 is now unlocked
      expect(find.text('2. Mount Specimen'), findsOneWidget);
    });

    testWidgets('Free Exploration mode starts with active microscope canvas', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Coarse Focus:'), findsOneWidget);
      expect(find.text('Fine Focus:'), findsOneWidget);
      expect(find.text('Light:'), findsOneWidget);
    });

    testWidgets('Lab notebook opens and displays theory', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Laboratory Notebook & Theory'), findsOneWidget);
      expect(find.text('1. Biological Theory'), findsOneWidget);
      expect(find.text('2. Magnification Calculations'), findsOneWidget);
    });
  });
}
