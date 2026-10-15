import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/pendulum_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  late PendulumEngine engine;

  setUp(() {
    engine = PendulumEngine();
  });

  group('PendulumEngine Domain Tests', () {
    test('initializes default state correctly for Guided Practice', () {
      final state = engine.createInitialState(PracticalMode.guidedPractice);

      expect(state.mode, PracticalMode.guidedPractice);
      expect(state.currentStepIndex, 0);
      expect(state.pendulumLengthCm, 40.0);
      expect(state.deflectionAngleDeg, 6.0);
      expect(state.isOscillating, isFalse);
      expect(state.targetOscillations, 20);
      expect(state.recordedTrials, isEmpty);
      expect(state.isCompleted, isFalse);
      expect(state.inspectedItems, isEmpty);
    });

    test('calculates accurate theoretical periods and values', () {
      final state = engine.createInitialState(PracticalMode.guidedPractice);

      // L = 40.0 cm = 0.40 m. T = 2π * sqrt(0.40 / 9.80) ≈ 1.269s
      expect(state.theoreticalPeriod, closeTo(1.269, 0.01));

      // t = 20 * T ≈ 25.38s
      expect(state.theoreticalTotalTime, closeTo(25.38, 0.2));

      // T² ≈ 1.61 s²
      expect(state.theoreticalPeriodSquared, closeTo(1.61, 0.05));
    });

    test('inspects apparatus items and records into notebook logs', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      state = engine.processAction(state, const InspectPendulumItemAction('stand'));
      state = engine.processAction(state, const InspectPendulumItemAction('bob'));
      state = engine.processAction(state, const InspectPendulumItemAction('thread'));
      state = engine.processAction(state, const InspectPendulumItemAction('ruler'));

      expect(state.inspectedItems.length, 4);
      expect(state.inspectedItems, containsAll(['stand', 'bob', 'thread', 'ruler']));
      expect(state.canAdvanceStep(), isTrue);
    });

    test('adjusts pendulum length within scientific bounds (20 to 100 cm)', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      state = engine.processAction(state, const SetPendulumLengthAction(60.0));
      expect(state.pendulumLengthCm, 60.0);

      // Clamps under 20cm
      state = engine.processAction(state, const SetPendulumLengthAction(5.0));
      expect(state.pendulumLengthCm, 20.0);

      // Clamps over 100cm
      state = engine.processAction(state, const SetPendulumLengthAction(150.0));
      expect(state.pendulumLengthCm, 100.0);
    });

    test('starts and runs simulation oscillation ticks to completion', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      state = engine.processAction(state, const StartPendulumOscillationAction());
      expect(state.isOscillating, isTrue);
      expect(state.stopwatchRunning, isTrue);

      // Tick for 10 seconds
      for (int i = 0; i < 100; i++) {
        state = engine.processAction(state, const TickPendulumSimulationAction(0.1));
      }

      expect(state.stopwatchElapsedSec, closeTo(10.0, 0.2));
      expect(state.currentOscillations, greaterThan(0));

      // Stop oscillation
      state = engine.processAction(state, const StopPendulumOscillationAction());
      expect(state.isOscillating, isFalse);
      expect(state.stopwatchRunning, isFalse);
    });

    test('records multiple trials and calculates linear regression slope and experimental gravity', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      // Trial 1: L = 20 cm
      state = engine.processAction(state, const SetPendulumLengthAction(20.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());

      // Trial 2: L = 40 cm
      state = engine.processAction(state, const SetPendulumLengthAction(40.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());

      // Trial 3: L = 60 cm
      state = engine.processAction(state, const SetPendulumLengthAction(60.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());

      // Trial 4: L = 80 cm
      state = engine.processAction(state, const SetPendulumLengthAction(80.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());

      expect(state.recordedTrials.length, 4);

      // Regression slope m = 4π²/g ≈ 4.028 s²/m
      final slope = state.calculatedRegressionSlope;
      expect(slope, isNotNull);
      expect(slope!, closeTo(4.028, 0.1));

      // Experimental gravity g = 4π²/m ≈ 9.80 m/s²
      final expG = state.calculatedExperimentalGravity;
      expect(expG, isNotNull);
      expect(expG!, closeTo(9.80, 0.2));

      // Percentage error should be under 2%
      final error = state.percentageError;
      expect(error, isNotNull);
      expect(error!, lessThan(2.0));
    });

    test('evaluates practical simulation and produces a valid scorecard', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      // Inspect apparatus
      state = engine.processAction(state, const InspectPendulumItemAction('stand'));
      state = engine.processAction(state, const InspectPendulumItemAction('bob'));
      state = engine.processAction(state, const InspectPendulumItemAction('thread'));
      state = engine.processAction(state, const InspectPendulumItemAction('ruler'));
      state = engine.processAction(state, const InspectPendulumItemAction('stopwatch'));

      // 4 Trials
      state = engine.processAction(state, const SetPendulumLengthAction(20.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());
      state = engine.processAction(state, const SetPendulumLengthAction(40.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());
      state = engine.processAction(state, const SetPendulumLengthAction(60.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());
      state = engine.processAction(state, const SetPendulumLengthAction(80.0));
      state = engine.processAction(state, const RecordPendulumTrialAction());

      // Set student input g = 9.80
      state = engine.processAction(state, const SetStudentInputsAction(gravity: '9.80'));

      // Submit
      state = engine.processAction(state, const SubmitPendulumCalculationsAction());

      expect(state.isCompleted, isTrue);
      expect(state.scoreResult, isNotNull);
      expect(state.scoreResult!.totalScore, greaterThanOrEqualTo(85));
      expect(state.scoreResult!.competencies.length, 5);
    });

    test('engine is registered in PracticalEngineRegistry', () {
      final registry = PracticalEngineRegistry();
      expect(registry.isEngineRegistered('pendulum'), isTrue);

      final resolved = registry.resolveEngine('pendulum');
      expect(resolved, isNotNull);
      expect(resolved!.subject, PracticalSubject.physics);
      expect(resolved.supportedModes, contains(PracticalMode.guidedPractice));
    });
  });
}
