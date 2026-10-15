import 'package:flutter/foundation.dart';
import '../data/models/gas_preparation_state.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import 'practical_simulation_engine.dart';

/// Sealed hierarchy of user/engine actions for the Gas Preparation Practical
@immutable
abstract class GasPreparationAction {
  const GasPreparationAction();
}

class InspectGasApparatusAction extends GasPreparationAction {
  final String apparatusId;
  const InspectGasApparatusAction(this.apparatusId);
}

class InspectAllGasApparatusAction extends GasPreparationAction {
  const InspectAllGasApparatusAction();
}

class SelectGasTypeAction extends GasPreparationAction {
  final PreparedGasType gasType;
  const SelectGasTypeAction(this.gasType);
}

class AddSolidReactantAction extends GasPreparationAction {
  const AddSolidReactantAction();
}

class AddLiquidReactantAction extends GasPreparationAction {
  const AddLiquidReactantAction();
}

class TickGasGenerationAction extends GasPreparationAction {
  final double deltaVolume;
  const TickGasGenerationAction({this.deltaVolume = 5.0});
}

class CompleteGasCollectionAction extends GasPreparationAction {
  const CompleteGasCollectionAction();
}

class PerformGasTestAction extends GasPreparationAction {
  const PerformGasTestAction();
}

class SetGasPrepStepAction extends GasPreparationAction {
  final GasPrepStep step;
  const SetGasPrepStepAction(this.step);
}

class TickGasDurationAction extends GasPreparationAction {
  const TickGasDurationAction();
}

class ResetGasAction extends GasPreparationAction {
  final PracticalMode mode;
  const ResetGasAction(this.mode);
}

class SubmitGasPracticalAction extends GasPreparationAction {
  const SubmitGasPracticalAction();
}

/// Laboratory Preparation of Gases Simulation Engine
class GasPreparationEngine implements PracticalSimulationEngine<GasPreparationState, GasPreparationAction> {
  @override
  String get engineId => 'gas_preparation';

  String get practicalId => 'gas-prep';

  @override
  String get titleEn => 'Laboratory Preparation of Gases';

  @override
  String get titleSw => 'Utayarishaji wa Gesi Maabarani';

  @override
  PracticalSubject get subject => PracticalSubject.chemistry;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  GasPreparationState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return GasPreparationState.initial(mode);
  }

  @override
  GasPreparationState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  GasPreparationState processAction(GasPreparationState currentState, GasPreparationAction action) {
    if (action is InspectGasApparatusAction) {
      final updated = currentState.apparatus.map((item) {
        if (item.id == action.apparatusId) {
          return item.copyWith(inspected: true);
        }
        return item;
      }).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is InspectAllGasApparatusAction) {
      final updated = currentState.apparatus.map((item) => item.copyWith(inspected: true)).toList();
      return currentState.copyWith(apparatus: updated);
    }

    if (action is SelectGasTypeAction) {
      return currentState.copyWith(
        selectedGas: action.gasType,
        isSolidAdded: false,
        isLiquidAdded: false,
        isGenerating: false,
        collectedVolumeMl: 0.0,
        isGasJarFull: false,
        isTestPerformed: false,
        testPassed: false,
      );
    }

    if (action is AddSolidReactantAction) {
      return currentState.copyWith(isSolidAdded: true);
    }

    if (action is AddLiquidReactantAction) {
      return currentState.copyWith(
        isLiquidAdded: true,
        isGenerating: true,
      );
    }

    if (action is TickGasGenerationAction) {
      if (!currentState.isGenerating) return currentState;
      final newVol = (currentState.collectedVolumeMl + action.deltaVolume).clamp(0.0, 100.0);
      final isFull = newVol >= 100.0;

      return currentState.copyWith(
        collectedVolumeMl: newVol,
        isGasJarFull: isFull,
        isGenerating: !isFull,
      );
    }

    if (action is CompleteGasCollectionAction) {
      return currentState.copyWith(
        collectedVolumeMl: 100.0,
        isGasJarFull: true,
        isGenerating: false,
      );
    }

    if (action is PerformGasTestAction) {
      return currentState.copyWith(
        isTestPerformed: true,
        testPassed: currentState.isGasJarFull,
      );
    }

    if (action is SetGasPrepStepAction) {
      return currentState.copyWith(step: action.step);
    }

    if (action is TickGasDurationAction) {
      return currentState.copyWith(
        experimentDurationSeconds: currentState.experimentDurationSeconds + 1,
      );
    }

    if (action is ResetGasAction) {
      return createInitialState(action.mode);
    }

    if (action is SubmitGasPracticalAction) {
      final score = evaluateSubmission(currentState);
      return currentState.copyWith(scoreResult: score);
    }

    return currentState;
  }

  /// Evaluates student performance and returns a graded PracticalScoreResult
  PracticalScoreResult evaluateSubmission(GasPreparationState state) {
    return PracticalScoreResult.calculateGasPreparationScore(
      gasNameEn: state.selectedGas.nameEn,
      gasNameSw: state.selectedGas.nameSw,
      inspectedCount: state.apparatus.where((a) => a.inspected).length,
      solidAdded: state.isSolidAdded,
      liquidAdded: state.isLiquidAdded,
      gasCollectedFull: state.isGasJarFull,
      testSuccessful: state.testPassed,
      durationSeconds: state.experimentDurationSeconds,
    );
  }

  @override
  PracticalScoreResult calculateScore(GasPreparationState currentState) {
    return evaluateSubmission(currentState);
  }
}
