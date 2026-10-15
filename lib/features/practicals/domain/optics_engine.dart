import '../data/models/optics_state.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import 'practical_simulation_engine.dart';

/// Pure domain actions for the Optics Refraction & Prism simulation.
abstract class OpticsAction {
  const OpticsAction();
}

class InspectApparatusAction extends OpticsAction {
  final String apparatusId;
  const InspectApparatusAction(this.apparatusId);
}

class SetIncidentAngleAction extends OpticsAction {
  final double angleDeg;
  const SetIncidentAngleAction(this.angleDeg);
}

class ToggleProtractorAction extends OpticsAction {
  const ToggleProtractorAction();
}

class ToggleNormalLinesAction extends OpticsAction {
  const ToggleNormalLinesAction();
}

class ToggleOpticalPinsAction extends OpticsAction {
  const ToggleOpticalPinsAction();
}

class ToggleRayExtensionAction extends OpticsAction {
  const ToggleRayExtensionAction();
}

class ToggleLaserAction extends OpticsAction {
  const ToggleLaserAction();
}

class RecordTrialAction extends OpticsAction {
  const RecordTrialAction();
}

class RemoveTrialAction extends OpticsAction {
  final int trialNumber;
  const RemoveTrialAction(this.trialNumber);
}

class SetStepAction extends OpticsAction {
  final OpticsStep step;
  const SetStepAction(this.step);
}

class NextStepAction extends OpticsAction {
  const NextStepAction();
}

class PreviousStepAction extends OpticsAction {
  const PreviousStepAction();
}

class CalculateRefractiveIndexAction extends OpticsAction {
  final double calculatedIndex;
  const CalculateRefractiveIndexAction(this.calculatedIndex);
}

class SubmitCalculationsAction extends OpticsAction {
  const SubmitCalculationsAction();
}

class TickTimerAction extends OpticsAction {
  final int elapsedSeconds;
  const TickTimerAction(this.elapsedSeconds);
}

class ResetExperimentAction extends OpticsAction {
  final PracticalMode mode;
  const ResetExperimentAction([this.mode = PracticalMode.guidedPractice]);
}

/// Pure Dart simulation engine for Refraction & Prism / Determination of Refractive Index.
class OpticsEngine implements PracticalSimulationEngine<OpticsState, OpticsAction> {
  @override
  String get engineId => 'optics';

  @override
  String get titleEn => 'Refraction & Prism Refractive Index';

  @override
  String get titleSw => 'Mchepuko na Kielezo cha Mgawanyiko wa Mwanga';

  @override
  PracticalSubject get subject => PracticalSubject.physics;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  OpticsState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return OpticsState(mode: mode);
  }

  @override
  OpticsState reset(PracticalMode mode) => createInitialState(mode);

  @override
  OpticsState processAction(OpticsState currentState, OpticsAction action) {
    if (action is InspectApparatusAction) {
      final updatedApparatus = currentState.apparatusItems.map((item) {
        if (item.id == action.apparatusId) {
          return item.copyWith(isInspected: true);
        }
        return item;
      }).toList();
      return currentState.copyWith(apparatusItems: updatedApparatus);
    }

    if (action is SetIncidentAngleAction) {
      final clampedAngle = action.angleDeg.clamp(20.0, 70.0);
      return currentState.copyWith(
        incidentAngleDeg: double.parse(clampedAngle.toStringAsFixed(1)),
      );
    }

    if (action is ToggleProtractorAction) {
      return currentState.copyWith(showProtractor: !currentState.showProtractor);
    }

    if (action is ToggleNormalLinesAction) {
      return currentState.copyWith(showNormalLines: !currentState.showNormalLines);
    }

    if (action is ToggleOpticalPinsAction) {
      return currentState.copyWith(showOpticalPins: !currentState.showOpticalPins);
    }

    if (action is ToggleRayExtensionAction) {
      return currentState.copyWith(showRayExtension: !currentState.showRayExtension);
    }

    if (action is ToggleLaserAction) {
      return currentState.copyWith(laserActive: !currentState.laserActive);
    }

    if (action is RecordTrialAction) {
      // Check if trial with identical angle already exists
      final existingIndex = currentState.recordedTrials.indexWhere(
        (t) => (t.incidentAngleDeg - currentState.incidentAngleDeg).abs() < 0.5,
      );

      final newTrial = OpticsTrial.fromAngles(
        trialNumber: existingIndex >= 0 ? currentState.recordedTrials[existingIndex].trialNumber : currentState.recordedTrials.length + 1,
        incidentAngleDeg: currentState.incidentAngleDeg,
        glassRefractiveIndex: currentState.trueGlassRefractiveIndex,
        prismAngleDeg: currentState.prismRefractingAngleDeg,
      );

      List<OpticsTrial> updatedTrials;
      if (existingIndex >= 0) {
        updatedTrials = List<OpticsTrial>.from(currentState.recordedTrials);
        updatedTrials[existingIndex] = newTrial;
      } else {
        updatedTrials = [...currentState.recordedTrials, newTrial];
      }

      return currentState.copyWith(recordedTrials: updatedTrials);
    }

    if (action is RemoveTrialAction) {
      final filtered = currentState.recordedTrials.where((t) => t.trialNumber != action.trialNumber).toList();
      // Re-index remaining trials
      final reindexed = <OpticsTrial>[];
      for (int i = 0; i < filtered.length; i++) {
        final t = filtered[i];
        reindexed.add(
          OpticsTrial(
            trialNumber: i + 1,
            incidentAngleDeg: t.incidentAngleDeg,
            refractedAngleDeg: t.refractedAngleDeg,
            emergentAngleDeg: t.emergentAngleDeg,
            deviationAngleDeg: t.deviationAngleDeg,
            sinI: t.sinI,
            sinR: t.sinR,
            calculatedIndex: t.calculatedIndex,
          ),
        );
      }
      return currentState.copyWith(recordedTrials: reindexed);
    }

    if (action is SetStepAction) {
      return currentState.copyWith(step: action.step);
    }

    if (action is NextStepAction) {
      final nextIdx = currentState.step.index + 1;
      if (nextIdx < OpticsStep.values.length) {
        return currentState.copyWith(step: OpticsStep.values[nextIdx]);
      }
      return currentState;
    }

    if (action is PreviousStepAction) {
      final prevIdx = currentState.step.index - 1;
      if (prevIdx >= 0) {
        return currentState.copyWith(step: OpticsStep.values[prevIdx]);
      }
      return currentState;
    }

    if (action is CalculateRefractiveIndexAction) {
      return currentState.copyWith(
        studentCalculatedIndex: action.calculatedIndex,
      );
    }

    if (action is SubmitCalculationsAction) {
      final score = calculateScore(currentState);
      return currentState.copyWith(
        isCompleted: true,
        scoreResult: score,
      );
    }

    if (action is TickTimerAction) {
      return currentState.copyWith(
        experimentDurationSeconds: currentState.experimentDurationSeconds + action.elapsedSeconds,
      );
    }

    if (action is ResetExperimentAction) {
      return createInitialState(action.mode);
    }

    return currentState;
  }

  @override
  PracticalScoreResult calculateScore(OpticsState currentState) {
    final studentIdx = currentState.studentCalculatedIndex > 0
        ? currentState.studentCalculatedIndex
        : currentState.experimentalRefractiveIndex;

    return PracticalScoreResult.calculateOpticsScore(
      studentIndex: studentIdx,
      theoreticalIndex: currentState.trueGlassRefractiveIndex,
      recordedTrialsCount: currentState.recordedTrials.length,
      inspectedCount: currentState.apparatusItems.where((i) => i.isInspected).length,
      durationSeconds: currentState.experimentDurationSeconds,
    );
  }
}
