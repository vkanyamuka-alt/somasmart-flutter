import 'package:flutter/foundation.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import '../data/models/rates_of_reaction_state.dart';
import 'practical_simulation_engine.dart';

/// Sealed hierarchy of user/engine actions for the Rates of Chemical Reactions Practical
@immutable
abstract class RatesOfReactionAction {
  const RatesOfReactionAction();
}

class InspectRatesApparatusAction extends RatesOfReactionAction {
  final String apparatusId;
  const InspectRatesApparatusAction(this.apparatusId);
}

class InspectAllRatesApparatusAction extends RatesOfReactionAction {
  const InspectAllRatesApparatusAction();
}

class SelectTrialAction extends RatesOfReactionAction {
  final int index;
  const SelectTrialAction(this.index);
}

class PrepareSolutionAction extends RatesOfReactionAction {
  final int flaskNumber;
  const PrepareSolutionAction(this.flaskNumber);
}

class PrepareAllSolutionsAction extends RatesOfReactionAction {
  const PrepareAllSolutionsAction();
}

class PlaceFlaskOnCrossAction extends RatesOfReactionAction {
  const PlaceFlaskOnCrossAction();
}

class RemoveFlaskFromCrossAction extends RatesOfReactionAction {
  const RemoveFlaskFromCrossAction();
}

class AddAcidAction extends RatesOfReactionAction {
  final int flaskNumber;
  const AddAcidAction(this.flaskNumber);
}

class StartStopwatchAction extends RatesOfReactionAction {
  const StartStopwatchAction();
}

class StopStopwatchAction extends RatesOfReactionAction {
  const StopStopwatchAction();
}

class ResetStopwatchAction extends RatesOfReactionAction {
  const ResetStopwatchAction();
}

class TickStopwatchAction extends RatesOfReactionAction {
  final double deltaSeconds;
  const TickStopwatchAction({this.deltaSeconds = 0.1});
}

class RecordDisappearanceAction extends RatesOfReactionAction {
  final int flaskNumber;
  const RecordDisappearanceAction(this.flaskNumber);
}

class SetRatesStepAction extends RatesOfReactionAction {
  final RatesOfReactionStep step;
  const SetRatesStepAction(this.step);
}

class SetEnteredSlopeAction extends RatesOfReactionAction {
  final double slope;
  const SetEnteredSlopeAction(this.slope);
}

class TickRatesDurationAction extends RatesOfReactionAction {
  const TickRatesDurationAction();
}

class ResetRatesAction extends RatesOfReactionAction {
  final PracticalMode mode;
  const ResetRatesAction(this.mode);
}

class SubmitRatesPracticalAction extends RatesOfReactionAction {
  final double enteredSlope;
  const SubmitRatesPracticalAction(this.enteredSlope);
}

/// Rates of Chemical Reactions Virtual Laboratory Simulation Engine
class RatesOfReactionEngine implements PracticalSimulationEngine<RatesOfReactionState, RatesOfReactionAction> {
  @override
  String get engineId => 'rates_of_reaction';

  String get practicalId => 'reaction-rates';

  @override
  String get titleEn => 'Rates of Chemical Reactions (Thiosulfate & Acid)';

  @override
  String get titleSw => 'Kasi ya Miitikio ya Kikemia';

  @override
  PracticalSubject get subject => PracticalSubject.chemistry;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  RatesOfReactionState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return RatesOfReactionState.initial(mode);
  }

  @override
  RatesOfReactionState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  RatesOfReactionState processAction(RatesOfReactionState currentState, RatesOfReactionAction action) {
    if (action is InspectRatesApparatusAction) {
      final updated = currentState.apparatus.map((item) {
        if (item.id == action.apparatusId) {
          return item.copyWith(inspected: true);
        }
        return item;
      }).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is InspectAllRatesApparatusAction) {
      final updated = currentState.apparatus.map((item) => item.copyWith(inspected: true)).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is SelectTrialAction) {
      final idx = action.index.clamp(0, currentState.trials.length - 1);
      final trial = currentState.trials[idx];
      return currentState.copyWith(
        activeTrialIndex: idx,
        isStopwatchRunning: false,
        currentStopwatchSeconds: trial.recordedTimeSeconds ?? 0.0,
        turbidityOpacity: trial.isCompleted ? 1.0 : 0.0,
        isFlaskOnCross: trial.isPrepared,
      );
    }

    if (action is PrepareSolutionAction) {
      final updated = currentState.trials.map((t) {
        if (t.flaskNumber == action.flaskNumber) {
          return t.copyWith(isPrepared: true);
        }
        return t;
      }).toList();
      return currentState.copyWith(trials: updated, isFlaskOnCross: true);
    }

    if (action is PrepareAllSolutionsAction) {
      final updated = currentState.trials.map((t) => t.copyWith(isPrepared: true)).toList();
      return currentState.copyWith(trials: updated, isFlaskOnCross: true);
    }

    if (action is PlaceFlaskOnCrossAction) {
      return currentState.copyWith(isFlaskOnCross: true);
    }

    if (action is RemoveFlaskFromCrossAction) {
      return currentState.copyWith(isFlaskOnCross: false);
    }

    if (action is AddAcidAction) {
      final updated = currentState.trials.map((t) {
        if (t.flaskNumber == action.flaskNumber) {
          return t.copyWith(isPrepared: true, isAcidAdded: true);
        }
        return t;
      }).toList();
      return currentState.copyWith(
        trials: updated,
        isStopwatchRunning: true,
        currentStopwatchSeconds: 0.0,
        turbidityOpacity: 0.0,
        isFlaskOnCross: true,
      );
    }

    if (action is StartStopwatchAction) {
      return currentState.copyWith(isStopwatchRunning: true);
    }

    if (action is StopStopwatchAction) {
      return currentState.copyWith(isStopwatchRunning: false);
    }

    if (action is ResetStopwatchAction) {
      return currentState.copyWith(
        isStopwatchRunning: false,
        currentStopwatchSeconds: 0.0,
        turbidityOpacity: 0.0,
      );
    }

    if (action is TickStopwatchAction) {
      if (!currentState.isStopwatchRunning) return currentState;
      final newSec = currentState.currentStopwatchSeconds + action.deltaSeconds;
      final trial = currentState.activeTrial;
      final expSec = trial.expectedTimeSeconds;
      final opacity = (newSec / expSec).clamp(0.0, 1.0);

      return currentState.copyWith(
        currentStopwatchSeconds: double.parse(newSec.toStringAsFixed(1)),
        turbidityOpacity: double.parse(opacity.toStringAsFixed(3)),
      );
    }

    if (action is RecordDisappearanceAction) {
      final time = currentState.currentStopwatchSeconds > 0
          ? currentState.currentStopwatchSeconds
          : currentState.activeTrial.expectedTimeSeconds;

      final updated = currentState.trials.map((t) {
        if (t.flaskNumber == action.flaskNumber) {
          return t.copyWith(
            isPrepared: true,
            isAcidAdded: true,
            isCompleted: true,
            recordedTimeSeconds: time,
          );
        }
        return t;
      }).toList();

      return currentState.copyWith(
        trials: updated,
        isStopwatchRunning: false,
        turbidityOpacity: 1.0,
      );
    }

    if (action is SetRatesStepAction) {
      return currentState.copyWith(step: action.step);
    }

    if (action is SetEnteredSlopeAction) {
      return currentState.copyWith(enteredSlope: action.slope);
    }

    if (action is TickRatesDurationAction) {
      return currentState.copyWith(
        experimentDurationSeconds: currentState.experimentDurationSeconds + 1,
      );
    }

    if (action is ResetRatesAction) {
      return createInitialState(action.mode);
    }

    if (action is SubmitRatesPracticalAction) {
      final score = evaluateSubmission(currentState, action.enteredSlope);
      return currentState.copyWith(
        enteredSlope: action.enteredSlope,
        scoreResult: score,
      );
    }

    return currentState;
  }

  /// Evaluates student performance and returns a graded PracticalScoreResult
  PracticalScoreResult evaluateSubmission(RatesOfReactionState state, double enteredSlope) {
    return PracticalScoreResult.calculateRatesOfReactionScore(
      studentSlope: enteredSlope,
      theoreticalSlope: state.calculatedSlope,
      inspectedCount: state.apparatus.where((a) => a.inspected).length,
      preparedCount: state.trials.where((t) => t.isPrepared).length,
      completedTrialsCount: state.trials.where((t) => t.isCompleted).length,
      durationSeconds: state.experimentDurationSeconds,
    );
  }

  @override
  PracticalScoreResult calculateScore(RatesOfReactionState currentState) {
    final entered = currentState.enteredSlope ?? currentState.calculatedSlope;
    return evaluateSubmission(currentState, entered);
  }
}
