import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/rates_of_reaction_state.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';
import 'package:somasmart_flutter/features/practicals/domain/rates_of_reaction_engine.dart';

void main() {
  group('Rates of Chemical Reactions Engine Tests', () {
    late RatesOfReactionEngine engine;

    setUp(() {
      engine = RatesOfReactionEngine();
    });

    test('Initial state metadata and defaults are valid', () {
      expect(engine.engineId, 'rates_of_reaction');
      expect(engine.practicalId, 'reaction-rates');

      final state = engine.createInitialState();
      expect(state.step, RatesOfReactionStep.inspectApparatus);
      expect(state.apparatus.length, 6);
      expect(state.allApparatusInspected, isFalse);
      expect(state.trials.length, 5);
      expect(state.allTrialsPrepared, isFalse);
      expect(state.allTrialsCompleted, isFalse);
      expect(state.isStopwatchRunning, isFalse);
      expect(state.currentStopwatchSeconds, 0.0);
      expect(state.turbidityOpacity, 0.0);
      expect(state.scoreResult, isNull);
    });

    test('Engine is registered in PracticalEngineRegistry for rates_of_reaction and reaction-rates', () {
      final registry = PracticalEngineRegistry();
      expect(registry.isEngineRegistered('rates_of_reaction'), isTrue);
      expect(registry.isEngineRegistered('reaction-rates'), isTrue);
      expect(registry.isEngineRegistered('rates-of-reaction'), isTrue);

      final resolved = registry.resolveEngine('rates_of_reaction');
      expect(resolved, isNotNull);
      expect(resolved, isA<RatesOfReactionEngine>());

      final resolvedAlias = registry.resolveEngine('reaction-rates');
      expect(resolvedAlias, isNotNull);
      expect(resolvedAlias, isA<RatesOfReactionEngine>());
    });

    test('Apparatus inspection toggles inspected state for all 6 items', () {
      var state = engine.createInitialState();
      expect(state.allApparatusInspected, isFalse);

      final itemIds = [
        'conical_flasks',
        'cross_tile',
        'stopwatch',
        'measuring_cylinders',
        'thiosulfate_stock',
        'hydrochloric_acid'
      ];
      for (final id in itemIds) {
        state = engine.processAction(state, InspectRatesApparatusAction(id));
      }

      expect(state.allApparatusInspected, isTrue);
      expect(state.apparatus.where((i) => i.inspected).length, 6);
    });

    test('Preparing solutions sets isPrepared for trials', () {
      var state = engine.createInitialState();
      expect(state.allTrialsPrepared, isFalse);

      state = engine.processAction(state, const PrepareSolutionAction(1));
      expect(state.trials.firstWhere((t) => t.flaskNumber == 1).isPrepared, isTrue);
      expect(state.allTrialsPrepared, isFalse);

      state = engine.processAction(state, const PrepareAllSolutionsAction());
      expect(state.allTrialsPrepared, isTrue);
      expect(state.trials.every((t) => t.isPrepared), isTrue);
    });

    test('Starting reaction adds acid, sets timer running, and ticks turbidity opacity', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PrepareAllSolutionsAction());
      state = engine.processAction(state, const SelectTrialAction(0)); // Flask 1: 0.20 M (expected 20.0s)

      state = engine.processAction(state, const AddAcidAction(1));
      expect(state.isStopwatchRunning, isTrue);
      expect(state.isFlaskOnCross, isTrue);

      // Tick 10 seconds (50% of expected time 20.0s)
      for (int i = 0; i < 100; i++) {
        state = engine.processAction(state, const TickStopwatchAction(deltaSeconds: 0.1));
      }

      expect(state.currentStopwatchSeconds, closeTo(10.0, 0.2));
      expect(state.turbidityOpacity, closeTo(0.50, 0.05));

      // Tick another 10 seconds to reach 20.0s
      for (int i = 0; i < 100; i++) {
        state = engine.processAction(state, const TickStopwatchAction(deltaSeconds: 0.1));
      }

      expect(state.currentStopwatchSeconds, closeTo(20.0, 0.2));
      expect(state.turbidityOpacity, 1.0);

      // Record cross disappearance endpoint
      state = engine.processAction(state, const RecordDisappearanceAction(1));
      expect(state.isStopwatchRunning, isFalse);
      expect(state.trials[0].isCompleted, isTrue);
      expect(state.trials[0].recordedTimeSeconds, closeTo(20.0, 0.2));
      expect(state.trials[0].calculatedRate, closeTo(0.050, 0.005));
    });

    test('Completing all 5 trials computes linear rate slope k = 0.25 s^-1 M^-1', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PrepareAllSolutionsAction());

      final times = [20.0, 25.0, 33.3, 50.0, 100.0];
      for (int i = 0; i < 5; i++) {
        state = engine.processAction(state, SelectTrialAction(i));
        state = engine.processAction(state, AddAcidAction(i + 1));
        // Simulate timer reaching expected time
        final ticks = (times[i] * 10).toInt();
        for (int t = 0; t < ticks; t++) {
          state = engine.processAction(state, const TickStopwatchAction(deltaSeconds: 0.1));
        }
        state = engine.processAction(state, RecordDisappearanceAction(i + 1));
      }

      expect(state.allTrialsCompleted, isTrue);
      expect(state.calculatedSlope, closeTo(0.250, 0.015));
    });

    test('Scoring rubric produces 100/100 Grade A+ for accurate submission', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const InspectAllRatesApparatusAction());
      state = engine.processAction(state, const PrepareAllSolutionsAction());

      for (int i = 0; i < 5; i++) {
        state = engine.processAction(state, RecordDisappearanceAction(i + 1));
      }

      final evaluated = engine.evaluateSubmission(state, 0.250);
      expect(evaluated.totalScore, 100);
      expect(evaluated.grade, contains('A+'));
      expect(evaluated.competencies.length, 5);
      expect(evaluated.competencies.every((c) => c.score >= 75), isTrue);
    });

    test('Reset action restores initial fresh state', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PrepareSolutionAction(1));
      state = engine.processAction(state, const ResetRatesAction(PracticalMode.guidedPractice));

      expect(state.step, RatesOfReactionStep.inspectApparatus);
      expect(state.trials[0].isPrepared, isFalse);
      expect(state.allApparatusInspected, isFalse);
    });
  });
}
