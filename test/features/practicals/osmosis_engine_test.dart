import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/osmosis_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/osmosis_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  group('Osmosis in Potato Tissues Engine Tests', () {
    late OsmosisEngine engine;

    setUp(() {
      engine = OsmosisEngine();
    });

    test('Initial state metadata and defaults are valid', () {
      expect(engine.engineId, 'osmosis');
      expect(engine.practicalId, 'osmosis-bio');

      final state = engine.createInitialState();
      expect(state.step, OsmosisStep.inspectApparatus);
      expect(state.apparatus.length, 6);
      expect(state.allApparatusInspected, isFalse);
      expect(state.samples.length, 5);
      expect(state.allSamplesPrepared, isFalse);
      expect(state.allInitialWeighed, isFalse);
      expect(state.allImmersed, isFalse);
      expect(state.allBlottedAndFinalWeighed, isFalse);
      expect(state.isIncubating, isFalse);
      expect(state.isIncubationFinished, isFalse);
      expect(state.incubationTargetSeconds, 30);
      expect(state.scoreResult, isNull);
    });

    test('Engine is registered in PracticalEngineRegistry for osmosis and osmosis-bio', () {
      final registry = PracticalEngineRegistry();
      expect(registry.isEngineRegistered('osmosis'), isTrue);
      expect(registry.isEngineRegistered('osmosis-bio'), isTrue);

      final resolved = registry.resolveEngine('osmosis');
      expect(resolved, isNotNull);
      expect(resolved, isA<OsmosisEngine>());

      final resolvedBio = registry.resolveEngine('osmosis-bio');
      expect(resolvedBio, isNotNull);
      expect(resolvedBio, isA<OsmosisEngine>());
    });

    test('Apparatus inspection toggles inspected state for all 6 items', () {
      var state = engine.createInitialState();
      expect(state.allApparatusInspected, isFalse);

      final itemIds = [
        'potato_tuber',
        'cork_borer',
        'scalpel_ruler',
        'digital_balance',
        'boiling_tubes',
        'filter_paper'
      ];
      for (final id in itemIds) {
        state = engine.processAction(state, InspectOsmosisApparatusAction(id));
      }

      expect(state.allApparatusInspected, isTrue);
      expect(state.apparatus.where((i) => i.inspected).length, 6);
    });

    test('Prepare potato sample action prepares cylinders', () {
      var state = engine.createInitialState();
      expect(state.allSamplesPrepared, isFalse);

      state = engine.processAction(state, const PrepareAllPotatoSamplesAction());
      expect(state.allSamplesPrepared, isTrue);
      expect(state.samples.every((s) => s.isPrepared), isTrue);
    });

    test('Initial weighing on balance records initial mass', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PreparePotatoSampleAction('A'));
      state = engine.processAction(state, const PlaceSampleOnBalanceAction('A', isInitial: true));

      expect(state.balanceOccupiedBySampleId, 'A');
      expect(state.balanceDisplay, closeTo(2.00, 0.05));
      expect(state.samples.firstWhere((s) => s.id == 'A').isInitialWeighed, isTrue);

      state = engine.processAction(state, const RemoveSampleFromBalanceAction());
      expect(state.balanceOccupiedBySampleId, isNull);
      expect(state.balanceDisplay, 0.00);
    });

    test('Water flux direction and turgidity reflect sucrose concentration', () {
      var state = engine.createInitialState();

      // Prepare all, weigh initial, and immerse
      state = engine.processAction(state, const PrepareAllPotatoSamplesAction());
      for (final s in state.samples) {
        state = engine.processAction(state, PlaceSampleOnBalanceAction(s.id, isInitial: true));
      }
      state = engine.processAction(state, const RemoveSampleFromBalanceAction());
      state = engine.processAction(state, const ImmerseAllSamplesAction());
      expect(state.allImmersed, isTrue);

      // Start timer and tick 30 seconds
      state = engine.processAction(state, const StartOsmosisIncubationAction());
      expect(state.isIncubating, isTrue);

      for (int i = 0; i < 30; i++) {
        state = engine.processAction(state, const TickOsmosisIncubationAction());
      }

      expect(state.isIncubationFinished, isTrue);
      expect(state.isIncubating, isFalse);

      // Sample A (0.0 M - pure water): Hypotonic => water enters, mass increases (gain)
      final sampleA = state.samples[0];
      expect(sampleA.finalMass, greaterThan(sampleA.initialMass));
      expect(sampleA.percentChange, greaterThan(0.0));
      expect(sampleA.textureEn, contains('Turgid'));

      // Sample B (0.2 M): Hypotonic => mass increases
      final sampleB = state.samples[1];
      expect(sampleB.finalMass, greaterThan(sampleB.initialMass));
      expect(sampleB.percentChange, greaterThan(0.0));

      // Sample C (0.4 M): Near isotonic / slight loss
      final sampleC = state.samples[2];
      expect(sampleC.percentChange, closeTo(-2.0, 1.0));

      // Sample E (0.8 M): Hypertonic => water leaves, mass decreases (loss)
      final sampleE = state.samples[4];
      expect(sampleE.finalMass, lessThan(sampleE.initialMass));
      expect(sampleE.percentChange, lessThan(-15.0));
      expect(sampleE.textureEn, contains('Plasmolysed'));
    });

    test('Blotting and final weighing completes sample cycle', () {
      var state = engine.createInitialState();

      state = engine.processAction(state, const PrepareAllPotatoSamplesAction());
      for (final s in state.samples) {
        state = engine.processAction(state, PlaceSampleOnBalanceAction(s.id, isInitial: true));
      }
      state = engine.processAction(state, const RemoveSampleFromBalanceAction());
      state = engine.processAction(state, const ImmerseAllSamplesAction());
      state = engine.processAction(state, const CompleteOsmosisIncubationAction());

      // Blot all and weigh all final
      state = engine.processAction(state, const BlotAllPotatoSamplesAction());
      for (final s in state.samples) {
        state = engine.processAction(state, PlaceSampleOnBalanceAction(s.id, isInitial: false));
      }
      state = engine.processAction(state, const RemoveSampleFromBalanceAction());

      expect(state.allBlottedAndFinalWeighed, isTrue);
    });

    test('Calculates isotonic concentration accurately via linear interpolation', () {
      final state = engine.createInitialState();
      final isoConc = state.calculatedIsotonicConcentration;
      expect(isoConc, closeTo(0.36, 0.05));
    });

    test('Scoring rubric produces 100/100 Grade A+ for accurate complete submission', () {
      var state = engine.createInitialState();

      state = engine.processAction(state, const InspectAllOsmosisApparatusAction());
      state = engine.processAction(state, const PrepareAllPotatoSamplesAction());
      for (final s in state.samples) {
        state = engine.processAction(state, PlaceSampleOnBalanceAction(s.id, isInitial: true));
      }
      state = engine.processAction(state, const RemoveSampleFromBalanceAction());
      state = engine.processAction(state, const ImmerseAllSamplesAction());
      state = engine.processAction(state, const CompleteOsmosisIncubationAction());
      state = engine.processAction(state, const BlotAllPotatoSamplesAction());
      for (final s in state.samples) {
        state = engine.processAction(state, PlaceSampleOnBalanceAction(s.id, isInitial: false));
      }
      state = engine.processAction(state, const RemoveSampleFromBalanceAction());

      final evaluated = engine.evaluateSubmission(state, 0.36);
      expect(evaluated.totalScore, 100);
      expect(evaluated.grade, contains('A+'));
      expect(evaluated.competencies.length, 5);
      expect(evaluated.competencies.every((c) => c.score >= 75), isTrue);
    });

    test('Reset action resets state to fresh initial state', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PreparePotatoSampleAction('A'));
      state = engine.processAction(state, const ResetOsmosisAction(PracticalMode.guidedPractice));

      expect(state.step, OsmosisStep.inspectApparatus);
      expect(state.samples[0].isPrepared, isFalse);
      expect(state.allApparatusInspected, isFalse);
    });
  });
}
