import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/optics_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_score_result.dart';
import 'package:somasmart_flutter/features/practicals/domain/optics_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  group('Refraction & Prism Optics Engine Tests', () {
    late OpticsEngine engine;

    setUp(() {
      engine = OpticsEngine();
    });

    test('Initial state metadata and defaults are valid', () {
      expect(engine.engineId, 'optics');
      expect(engine.subject, PracticalSubject.physics);
      expect(engine.titleEn, 'Refraction & Prism Refractive Index');

      final state = engine.createInitialState();
      expect(state.step, OpticsStep.inspectApparatus);
      expect(state.incidentAngleDeg, 45.0);
      expect(state.prismRefractingAngleDeg, 60.0);
      expect(state.trueGlassRefractiveIndex, 1.500);
      expect(state.showProtractor, isTrue);
      expect(state.showNormalLines, isTrue);
      expect(state.showOpticalPins, isTrue);
      expect(state.showRayExtension, isTrue);
      expect(state.laserActive, isTrue);
      expect(state.apparatusItems.length, 5);
      expect(state.recordedTrials, isEmpty);
      expect(state.isCompleted, isFalse);
    });

    test('Engine is registered in PracticalEngineRegistry', () {
      final registry = PracticalEngineRegistry();
      expect(registry.isEngineRegistered('optics'), isTrue);
      final resolved = registry.resolveEngine('optics');
      expect(resolved, isNotNull);
      expect(resolved, isA<OpticsEngine>());
    });

    test('Apparatus inspection toggles isInspected state', () {
      var state = engine.createInitialState();
      expect(state.allApparatusInspected, isFalse);

      state = engine.processAction(state, const InspectApparatusAction('prism'));
      state = engine.processAction(state, const InspectApparatusAction('board'));
      state = engine.processAction(state, const InspectApparatusAction('pins'));
      state = engine.processAction(state, const InspectApparatusAction('protractor'));
      state = engine.processAction(state, const InspectApparatusAction('light_source'));

      expect(state.allApparatusInspected, isTrue);
      expect(state.apparatusItems.where((i) => i.isInspected).length, 5);
    });

    test('Snell’s law calculations for 45° incidence in crown glass (n=1.500)', () {
      final state = engine.createInitialState();
      // i = 45.0°
      // sin(45°) = 0.7071
      // sin(r1) = sin(45°) / 1.500 = 0.4714 => r1 ≈ 28.1°
      expect(state.sinI, closeTo(0.707, 0.005));
      expect(state.sinR, closeTo(0.471, 0.005));
      expect(state.refractedAngleDeg, closeTo(28.1, 0.2));
      // Inside prism: r2 = 60° - 28.1° = 31.9°
      expect(state.internalIncidenceAngleDeg, closeTo(31.9, 0.2));
      // Emergent: sin(e) = 1.5 * sin(31.9°) ≈ 1.5 * 0.5284 = 0.7926 => e ≈ 52.4°
      expect(state.emergentAngleDeg, closeTo(52.4, 0.5));
      // Deviation: D = (45 + 52.4) - 60 = 37.4°
      expect(state.deviationAngleDeg, closeTo(37.4, 0.5));
      // Real-time Snell ratio: sin(i)/sin(r) = 1.500
      expect(state.currentSnellRatio, closeTo(1.500, 0.005));
    });

    test('Angle changes clamp between 20° and 70°', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const SetIncidentAngleAction(10.0));
      expect(state.incidentAngleDeg, 20.0);

      state = engine.processAction(state, const SetIncidentAngleAction(85.0));
      expect(state.incidentAngleDeg, 70.0);

      state = engine.processAction(state, const SetIncidentAngleAction(30.0));
      expect(state.incidentAngleDeg, 30.0);
      // For i = 30°: sin(30°) = 0.500, sin(r) = 0.5/1.5 = 0.333 => r ≈ 19.5°
      expect(state.refractedAngleDeg, closeTo(19.5, 0.2));
    });

    test('Recording multiple trials generates valid observations and linear regression slope', () {
      var state = engine.createInitialState();

      // Trial 1: i = 30°
      state = engine.processAction(state, const SetIncidentAngleAction(30.0));
      state = engine.processAction(state, const RecordTrialAction());

      // Trial 2: i = 45°
      state = engine.processAction(state, const SetIncidentAngleAction(45.0));
      state = engine.processAction(state, const RecordTrialAction());

      // Trial 3: i = 60°
      state = engine.processAction(state, const SetIncidentAngleAction(60.0));
      state = engine.processAction(state, const RecordTrialAction());

      expect(state.recordedTrials.length, 3);
      expect(state.recordedTrials[0].incidentAngleDeg, 30.0);
      expect(state.recordedTrials[1].incidentAngleDeg, 45.0);
      expect(state.recordedTrials[2].incidentAngleDeg, 60.0);

      // Regression slope of sin(i) vs sin(r) should match 1.500
      expect(state.regressionSlope, closeTo(1.500, 0.01));
      expect(state.experimentalRefractiveIndex, closeTo(1.500, 0.01));
      expect(state.percentageError, closeTo(0.0, 0.5));
    });

    test('Removing a trial re-indexes the trial list', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const SetIncidentAngleAction(30.0));
      state = engine.processAction(state, const RecordTrialAction());
      state = engine.processAction(state, const SetIncidentAngleAction(45.0));
      state = engine.processAction(state, const RecordTrialAction());
      state = engine.processAction(state, const SetIncidentAngleAction(60.0));
      state = engine.processAction(state, const RecordTrialAction());

      expect(state.recordedTrials.length, 3);

      state = engine.processAction(state, const RemoveTrialAction(2));
      expect(state.recordedTrials.length, 2);
      expect(state.recordedTrials[0].trialNumber, 1);
      expect(state.recordedTrials[0].incidentAngleDeg, 30.0);
      expect(state.recordedTrials[1].trialNumber, 2);
      expect(state.recordedTrials[1].incidentAngleDeg, 60.0);
    });

    test('Visual overlay toggles operate correctly', () {
      var state = engine.createInitialState();
      expect(state.showProtractor, isTrue);
      state = engine.processAction(state, const ToggleProtractorAction());
      expect(state.showProtractor, isFalse);

      expect(state.showNormalLines, isTrue);
      state = engine.processAction(state, const ToggleNormalLinesAction());
      expect(state.showNormalLines, isFalse);

      expect(state.showOpticalPins, isTrue);
      state = engine.processAction(state, const ToggleOpticalPinsAction());
      expect(state.showOpticalPins, isFalse);

      expect(state.laserActive, isTrue);
      state = engine.processAction(state, const ToggleLaserAction());
      expect(state.laserActive, isFalse);
    });

    test('Scoring rubric produces accurate grade and competencies', () {
      final score = PracticalScoreResult.calculateOpticsScore(
        studentIndex: 1.502,
        theoreticalIndex: 1.500,
        recordedTrialsCount: 4,
        inspectedCount: 5,
        durationSeconds: 720,
      );

      expect(score.totalScore, 100);
      expect(score.grade, 'A+ (Distinction)');
      expect(score.errorPercentage, closeTo(0.13, 0.05));
      expect(score.competencies.length, 5);
      expect(score.achievementsEn.length, 5);
      expect(score.durationFormatted, '12m 0s');
    });
  });
}
