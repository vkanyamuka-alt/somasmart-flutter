import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/gas_preparation_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/gas_preparation_screen.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(GasPreparationEngine());
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
        home: GasPreparationScreen(mode: mode),
      ),
    );
  }

  group('Laboratory Preparation of Gases Screen Widget Tests', () {
    testWidgets('renders workbench, header, step bar, and gas selection cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GUIDED PRACTICE'), findsOneWidget);
      expect(find.text('Laboratory Preparation of Gases'), findsOneWidget);
      expect(find.text('1. Select Gas'), findsWidgets);
      expect(find.text('Oxygen Gas (O₂)'), findsOneWidget);
      expect(find.text('Carbon Dioxide Gas (CO₂)'), findsOneWidget);
      expect(find.text('Hydrogen Gas (H₂)'), findsOneWidget);
    });

    testWidgets('inspects apparatus items on tap in Step 2', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Step 2: Inspect Apparatus
      await tester.tap(find.text('2. Inspect Apparatus'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Flat-bottomed Generator Flask'), findsOneWidget);
      expect(find.text('Thistle Funnel (Safety Delivery)'), findsOneWidget);
      expect(find.text('Apparatus Inspected: 0/6'), findsOneWidget);

      await tester.tap(find.text('Flat-bottomed Generator Flask'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Apparatus Inspected: 1/6'), findsOneWidget);
    });

    testWidgets('adds solid and liquid reactants in Step 3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Step 3: Assemble & React
      await tester.tap(find.text('3. Assemble & React'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Chemical Reaction Equation:'), findsOneWidget);
      expect(find.text('1. Add Manganese(IV) Oxide (MnO₂) Powder'), findsOneWidget);

      // Tap Add
      await tester.tap(find.text('Add'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2. Pour 20-volume Hydrogen Peroxide (H₂O₂)'), findsOneWidget);
      expect(find.text('Pour'), findsOneWidget);

      // Tap Pour
      await tester.tap(find.text('Pour'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pour'), findsNothing);
    });

    testWidgets('stays in English when the app is in Swahili', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Laboratory Preparation of Gases'), findsOneWidget);
      expect(find.text('Oxygen Gas (O₂)'), findsOneWidget);
      expect(find.text('Gesi ya Oksijeni (O₂)'), findsNothing);
    });

    testWidgets('renders Dark mode properly without crash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice, isDark: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Laboratory Preparation of Gases'), findsOneWidget);
    });
  });
}
