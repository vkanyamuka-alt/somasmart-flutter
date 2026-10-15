import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/ohms_law_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/presentation/screens/ohms_law_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';

void main() {
  setUp(() {
    PracticalEngineRegistry().registerEngine(OhmsLawEngine());
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
        home: OhmsLawScreen(mode: mode),
      ),
    );
  }

  group("Ohm's Law Screen Widget Tests", () {
    testWidgets('Renders all initial UI components for Guided Practice in English', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Title & Status
      expect(find.text("Ohm's Law Verification"), findsOneWidget);
      expect(find.text('Guided Practice'), findsOneWidget);

      // Workflow step bar
      expect(find.text('Inspect'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);

      // Inspection chips in Step 0
      expect(find.text('DC Power Supply'), findsOneWidget);
      expect(find.text('Resistor (10Ω)'), findsOneWidget);
      expect(find.text('Ammeter'), findsOneWidget);
      expect(find.text('Voltmeter'), findsOneWidget);
      expect(find.text('Knife Switch'), findsOneWidget);

      // Initial circuit disconnected state
      expect(find.text('DE-ENERGIZED'), findsOneWidget);
    });

    testWidgets('Renders initial UI components in Kiswahili', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Title & Status in Swahili
      expect(find.text("Uhakiki wa Sheria ya Ohm"), findsOneWidget);
      expect(find.text('Mazoezi Yaliyoongozwa'), findsOneWidget);
      expect(find.text('Vifaa'), findsOneWidget);
      expect(find.text('Unganisha'), findsOneWidget);
    });

    testWidgets('Inspecting apparatus unlocks step advancement', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.guidedPractice));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 4 inspection chips
      await tester.tap(find.text('DC Power Supply'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Resistor (10Ω)'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Ammeter'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Voltmeter'));
      await tester.pump(const Duration(milliseconds: 100));

      // Advance button should now be enabled
      final advanceBtn = find.text('Next Step (Assemble Circuit)');
      expect(advanceBtn, findsOneWidget);
      await tester.ensureVisible(advanceBtn);
      await tester.tap(advanceBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Now in Step 1: Connect Circuit
      expect(find.text('Connect Laboratory Circuit'), findsOneWidget);
    });

    testWidgets('Full workflow: inspect -> connect -> close switch -> record readings -> calculate -> scorecard', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs, mode: PracticalMode.freeExploration));
      await tester.pump(const Duration(milliseconds: 100));

      // In Free Exploration, circuit is auto-connected
      expect(find.text('Free Exploration'), findsOneWidget);
      expect(find.text('CLOSE (ON)'), findsOneWidget);

      // Toggle switch to CLOSED (ON)
      await tester.tap(find.text('CLOSE (ON)'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('OPEN (OFF)'), findsOneWidget);
      expect(find.text('ACTIVE / ENERGIZED'), findsOneWidget);

      // Tap voltage preset 2V
      await tester.tap(find.text('2V'));
      await tester.pump(const Duration(milliseconds: 100));

      // Record reading
      final recordBtn = find.byIcon(Icons.playlist_add_rounded);
      expect(recordBtn, findsOneWidget);
      await tester.tap(recordBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify trial in data table
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('2.00 V'), findsOneWidget);
      expect(find.text('0.200 A'), findsOneWidget);
      expect(find.text('10.00 Ω'), findsOneWidget);

      // Enter calculation and submit
      final rField = find.widgetWithText(TextField, 'Final Calculated Resistance R (Ω)');
      expect(rField, findsOneWidget);
      await tester.ensureVisible(rField);
      await tester.enterText(rField, '10.0');
      await tester.pump(const Duration(milliseconds: 100));

      final submitBtn = find.text('Submit Calculations & Complete Practical');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify completion scorecard
      expect(find.text("Ohm's Law Verification (V = IR)"), findsOneWidget);
      expect(find.text('A+ (Distinction)'), findsOneWidget);
      expect(find.text('100 / 100'), findsOneWidget);
    });

    testWidgets('Lab Notebook modal opens and shows experiment logs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestableWidget(prefs: prefs));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap notebook icon in AppBar
      final notebookBtn = find.byIcon(Icons.menu_book_rounded);
      expect(notebookBtn, findsOneWidget);
      await tester.tap(notebookBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Physics Lab Notebook'), findsOneWidget);
      expect(find.text('• Virtual Laboratory initialized for Ohm’s Law Verification.'), findsOneWidget);
    });
  });
}
