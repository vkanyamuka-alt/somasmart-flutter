import 'package:flutter/foundation.dart';
import '../data/models/osmosis_state.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import 'practical_simulation_engine.dart';

/// Sealed hierarchy of user/engine actions for the Osmosis Practical
@immutable
abstract class OsmosisAction {
  const OsmosisAction();
}

class InspectOsmosisApparatusAction extends OsmosisAction {
  final String apparatusId;
  const InspectOsmosisApparatusAction(this.apparatusId);
}

class InspectAllOsmosisApparatusAction extends OsmosisAction {
  const InspectAllOsmosisApparatusAction();
}

class SelectOsmosisSampleAction extends OsmosisAction {
  final int index;
  const SelectOsmosisSampleAction(this.index);
}

class PreparePotatoSampleAction extends OsmosisAction {
  final String sampleId;
  const PreparePotatoSampleAction(this.sampleId);
}

class PrepareAllPotatoSamplesAction extends OsmosisAction {
  const PrepareAllPotatoSamplesAction();
}

class PlaceSampleOnBalanceAction extends OsmosisAction {
  final String sampleId;
  final bool isInitial; // true = initial weighing (m0), false = final weighing (m1)
  const PlaceSampleOnBalanceAction(this.sampleId, {required this.isInitial});
}

class RemoveSampleFromBalanceAction extends OsmosisAction {
  const RemoveSampleFromBalanceAction();
}

class ImmerseSampleAction extends OsmosisAction {
  final String sampleId;
  const ImmerseSampleAction(this.sampleId);
}

class ImmerseAllSamplesAction extends OsmosisAction {
  const ImmerseAllSamplesAction();
}

class StartOsmosisIncubationAction extends OsmosisAction {
  const StartOsmosisIncubationAction();
}

class TickOsmosisIncubationAction extends OsmosisAction {
  const TickOsmosisIncubationAction();
}

class CompleteOsmosisIncubationAction extends OsmosisAction {
  const CompleteOsmosisIncubationAction();
}

class BlotPotatoSampleAction extends OsmosisAction {
  final String sampleId;
  const BlotPotatoSampleAction(this.sampleId);
}

class BlotAllPotatoSamplesAction extends OsmosisAction {
  const BlotAllPotatoSamplesAction();
}

class SetOsmosisStepAction extends OsmosisAction {
  final OsmosisStep step;
  const SetOsmosisStepAction(this.step);
}

class SetEnteredIsotonicConcentrationAction extends OsmosisAction {
  final double concentration;
  const SetEnteredIsotonicConcentrationAction(this.concentration);
}

class TickOsmosisDurationAction extends OsmosisAction {
  const TickOsmosisDurationAction();
}

class ResetOsmosisAction extends OsmosisAction {
  final PracticalMode mode;
  const ResetOsmosisAction(this.mode);
}

class SubmitOsmosisPracticalAction extends OsmosisAction {
  final double enteredIsotonic;
  const SubmitOsmosisPracticalAction(this.enteredIsotonic);
}

/// Osmosis in Potato Tissues Virtual Laboratory Simulation Engine
class OsmosisEngine implements PracticalSimulationEngine<OsmosisState, OsmosisAction> {
  @override
  String get engineId => 'osmosis';

  String get practicalId => 'osmosis-bio';

  @override
  String get titleEn => 'Osmosis in Potato Tissues';

  @override
  String get titleSw => 'Mchakato wa Osmosis Kwenye Viazi';

  @override
  PracticalSubject get subject => PracticalSubject.biology;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  OsmosisState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return OsmosisState.initial(mode);
  }

  @override
  OsmosisState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  OsmosisState processAction(OsmosisState currentState, OsmosisAction action) {
    if (action is InspectOsmosisApparatusAction) {
      final updated = currentState.apparatus.map((item) {
        if (item.id == action.apparatusId) {
          return item.copyWith(inspected: true);
        }
        return item;
      }).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is InspectAllOsmosisApparatusAction) {
      final updated = currentState.apparatus.map((item) => item.copyWith(inspected: true)).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is SelectOsmosisSampleAction) {
      return currentState.copyWith(
        activeSampleIndex: action.index.clamp(0, currentState.samples.length - 1),
      );
    }

    if (action is PreparePotatoSampleAction) {
      final updated = currentState.samples.map((s) {
        if (s.id == action.sampleId) {
          return s.copyWith(isPrepared: true);
        }
        return s;
      }).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is PrepareAllPotatoSamplesAction) {
      final updated = currentState.samples.map((s) => s.copyWith(isPrepared: true)).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is PlaceSampleOnBalanceAction) {
      final sample = currentState.samples.firstWhere((s) => s.id == action.sampleId);
      final massToDisplay = action.isInitial ? sample.initialMass : sample.finalMass;

      final updatedSamples = currentState.samples.map((s) {
        if (s.id == action.sampleId) {
          if (action.isInitial) {
            return s.copyWith(isInitialWeighed: true);
          } else {
            return s.copyWith(isFinalWeighed: true);
          }
        }
        return s;
      }).toList();

      return currentState.copyWith(
        samples: updatedSamples,
        balanceDisplay: massToDisplay,
        balanceOccupiedBySampleId: action.sampleId,
      );
    }

    if (action is RemoveSampleFromBalanceAction) {
      return currentState.copyWith(
        balanceDisplay: 0.00,
        balanceOccupiedBySampleId: null,
      );
    }

    if (action is ImmerseSampleAction) {
      final updated = currentState.samples.map((s) {
        if (s.id == action.sampleId) {
          return s.copyWith(isImmersed: true);
        }
        return s;
      }).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is ImmerseAllSamplesAction) {
      final updated = currentState.samples.map((s) => s.copyWith(isImmersed: true)).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is StartOsmosisIncubationAction) {
      return currentState.copyWith(
        isIncubating: true,
        incubationSeconds: 0,
        isIncubationFinished: false,
      );
    }

    if (action is TickOsmosisIncubationAction) {
      if (!currentState.isIncubating) return currentState;
      final nextSec = currentState.incubationSeconds + 1;
      if (nextSec >= currentState.incubationTargetSeconds) {
        final updatedSamples = currentState.samples.map((s) {
          return s.copyWith(isIncubationComplete: true);
        }).toList();

        return currentState.copyWith(
          isIncubating: false,
          incubationSeconds: currentState.incubationTargetSeconds,
          isIncubationFinished: true,
          samples: updatedSamples,
        );
      }
      return currentState.copyWith(incubationSeconds: nextSec);
    }

    if (action is CompleteOsmosisIncubationAction) {
      final updatedSamples = currentState.samples.map((s) {
        return s.copyWith(isIncubationComplete: true);
      }).toList();

      return currentState.copyWith(
        isIncubating: false,
        incubationSeconds: currentState.incubationTargetSeconds,
        isIncubationFinished: true,
        samples: updatedSamples,
      );
    }

    if (action is BlotPotatoSampleAction) {
      final updated = currentState.samples.map((s) {
        if (s.id == action.sampleId) {
          return s.copyWith(isBlotted: true);
        }
        return s;
      }).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is BlotAllPotatoSamplesAction) {
      final updated = currentState.samples.map((s) => s.copyWith(isBlotted: true)).toList();
      return currentState.copyWith(samples: updated);
    }

    if (action is SetOsmosisStepAction) {
      return currentState.copyWith(step: action.step);
    }

    if (action is SetEnteredIsotonicConcentrationAction) {
      return currentState.copyWith(enteredIsotonicConcentration: action.concentration);
    }

    if (action is TickOsmosisDurationAction) {
      return currentState.copyWith(
        experimentDurationSeconds: currentState.experimentDurationSeconds + 1,
      );
    }

    if (action is ResetOsmosisAction) {
      return createInitialState(action.mode);
    }

    if (action is SubmitOsmosisPracticalAction) {
      final score = evaluateSubmission(currentState, action.enteredIsotonic);
      return currentState.copyWith(
        enteredIsotonicConcentration: action.enteredIsotonic,
        scoreResult: score,
      );
    }

    return currentState;
  }

  /// Comprehensive Evaluation for Osmosis Practical
  PracticalScoreResult evaluateSubmission(OsmosisState state, double enteredIsotonic) {
    return PracticalScoreResult.calculateOsmosisScore(
      studentIsotonicConc: enteredIsotonic,
      theoreticalIsotonicConc: state.calculatedIsotonicConcentration,
      inspectedCount: state.apparatus.where((a) => a.inspected).length,
      preparedCount: state.samples.where((s) => s.isPrepared).length,
      weighedCount: state.samples.where((s) => s.isFinalWeighed).length,
      durationSeconds: state.experimentDurationSeconds,
    );
  }

  @override
  PracticalScoreResult calculateScore(OsmosisState currentState) {
    final enteredIso = currentState.enteredIsotonicConcentration ?? currentState.calculatedIsotonicConcentration;
    return evaluateSubmission(currentState, enteredIso);
  }
}
