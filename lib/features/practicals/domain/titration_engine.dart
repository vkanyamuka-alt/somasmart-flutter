import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import '../data/models/titration_state.dart';
import 'practical_simulation_engine.dart';

abstract class TitrationAction {
  const TitrationAction();
}

class InspectItemAction extends TitrationAction {
  final String itemKey;
  const InspectItemAction(this.itemKey);
}

class FillBuretteAction extends TitrationAction {
  const FillBuretteAction();
}

class SelectPipetteAction extends TitrationAction {
  const SelectPipetteAction();
}

class AttachPipetteBulbAction extends TitrationAction {
  const AttachPipetteBulbAction();
}

class InsertPipetteInHClAction extends TitrationAction {
  const InsertPipetteInHClAction();
}

class DrawHClAction extends TitrationAction {
  final double volumeIncrement;
  const DrawHClAction([this.volumeIncrement = 0.5]);
}

class PositionPipetteAboveFlaskAction extends TitrationAction {
  const PositionPipetteAboveFlaskAction();
}

class TransferHClToFlaskAction extends TitrationAction {
  final double volumeDecrement;
  const TransferHClToFlaskAction([this.volumeDecrement = 0.5]);
}

class SelectIndicatorBottleAction extends TitrationAction {
  const SelectIndicatorBottleAction();
}

class PositionDropperAboveFlaskAction extends TitrationAction {
  const PositionDropperAboveFlaskAction();
}

class AddIndicatorDropAction extends TitrationAction {
  const AddIndicatorDropAction();
}

class PositionFlaskOnTileAction extends TitrationAction {
  const PositionFlaskOnTileAction();
}

class SetStopcockStateAction extends TitrationAction {
  final StopcockState state;
  const SetStopcockStateAction(this.state);
}

class DeliverTitrantTickAction extends TitrationAction {
  const DeliverTitrantTickAction();
}

class DeliverSingleDropAction extends TitrationAction {
  const DeliverSingleDropAction();
}

class PauseTitrationAction extends TitrationAction {
  const PauseTitrationAction();
}

class ResumeTitrationAction extends TitrationAction {
  const ResumeTitrationAction();
}

class CloseStopcockAction extends TitrationAction {
  const CloseStopcockAction();
}

class SwirlFlaskAction extends TitrationAction {
  const SwirlFlaskAction();
}

class FinishSwirlingAction extends TitrationAction {
  const FinishSwirlingAction();
}

class ConfirmEndpointAction extends TitrationAction {
  const ConfirmEndpointAction();
}

class SubmitReadingsAction extends TitrationAction {
  final String initialReading;
  final String finalReading;
  final String titreVolume;
  final String observedColor;
  const SubmitReadingsAction({
    required this.initialReading,
    required this.finalReading,
    required this.titreVolume,
    required this.observedColor,
  });
}

class SubmitCalculationsAction extends TitrationAction {
  final String calculatedTitre;
  final String calculatedMolarity;
  const SubmitCalculationsAction({
    required this.calculatedTitre,
    required this.calculatedMolarity,
  });
}

class NextStepAction extends TitrationAction {
  const NextStepAction();
}

class PrevStepAction extends TitrationAction {
  const PrevStepAction();
}

class JumpToStepAction extends TitrationAction {
  final int stepIndex;
  const JumpToStepAction(this.stepIndex);
}

class TickTimerAction extends TitrationAction {
  const TickTimerAction();
}

class ResetTitrationAction extends TitrationAction {
  const ResetTitrationAction();
}

/// Pure Dart implementation of Engine #1 (Acid–Base Titration).
/// Implements all chemical rules, state machine transitions, delivery rates, and scoring.
class AcidBaseTitrationEngine
    implements PracticalSimulationEngine<TitrationState, TitrationAction> {
  static const String id = 'acid_base_titration';

  @override
  String get engineId => id;

  @override
  String get titleEn => 'Acid–Base Titration (HCl vs NaOH)';

  @override
  String get titleSw => 'Titration ya Asidi na Besi (HCl vs NaOH)';

  @override
  PracticalSubject get subject => PracticalSubject.chemistry;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  TitrationState createInitialState(PracticalMode mode) {
    return TitrationState(
      mode: mode,
      currentStepIndex: 0,
      isCompleted: false,
      elapsedSeconds: 0,
      inspectedItems: const {},
      buretteFilled: false,
      buretteReading: 0.0,
      pipetteStep: 0,
      pipetteVolume: 0.0,
      isDrawingLiquid: false,
      isTransferringLiquid: false,
      flaskVolume: 0.0,
      indicatorStep: 0,
      indicatorDropsCount: 0,
      isDroppingIndicator: false,
      indicatorAdded: false,
      flaskPositioned: false,
      stopcockState: StopcockState.closed,
      previousActiveStopcockState: StopcockState.slow,
      volumeDelivered: 0.0,
      isDropFalling: false,
      flaskRipple: false,
      isSwirling: false,
      hasSwirledAtCurrentVolume: false,
      endpointConfirmed: false,
      initialReadingInput: '0.00',
      finalReadingInput: '',
      titreVolumeInput: '',
      observedColorInput: 'Permanent Pale Pink',
      readingsSubmitted: false,
      calculatedTitreInput: '',
      calculatedMolarityInput: '',
      calculationSubmitted: false,
      scoreResult: null,
      notebookLogs: const ['• Virtual Laboratory initialized for Acid–Base Titration.'],
    );
  }

  @override
  TitrationState processAction(TitrationState currentState, TitrationAction action) {
    if (action is TickTimerAction) {
      return currentState.copyWith(elapsedSeconds: currentState.elapsedSeconds + 1);
    }

    if (action is InspectItemAction) {
      final newSet = Set<String>.from(currentState.inspectedItems)..add(action.itemKey);
      return currentState.copyWith(
        inspectedItems: newSet,
        selectedInspectItemKey: action.itemKey,
      );
    }

    if (action is FillBuretteAction) {
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Filled burette with 0.10M NaOH solution to 50.0 mL mark (0.00 mL initial reading).');
      return currentState.copyWith(
        buretteFilled: true,
        buretteReading: 0.0,
        notebookLogs: newLogs,
      );
    }

    // Pipette Actions
    if (action is SelectPipetteAction) {
      return currentState.copyWith(pipetteStep: 1);
    }
    if (action is AttachPipetteBulbAction) {
      return currentState.copyWith(pipetteStep: 2);
    }
    if (action is InsertPipetteInHClAction) {
      return currentState.copyWith(pipetteStep: 3);
    }
    if (action is DrawHClAction) {
      final nextVol = (currentState.pipetteVolume + action.volumeIncrement).clamp(0.0, 25.0);
      final isDone = nextVol >= 25.0;
      final newLogs = List<String>.from(currentState.notebookLogs);
      if (isDone) {
        newLogs.add('✓ Pipette filled: 25.0 mL HCl at meniscus graduation mark.');
      }
      return currentState.copyWith(
        pipetteVolume: nextVol,
        pipetteStep: isDone ? 4 : 3,
        isDrawingLiquid: !isDone,
        notebookLogs: newLogs,
      );
    }
    if (action is PositionPipetteAboveFlaskAction) {
      return currentState.copyWith(pipetteStep: 5);
    }
    if (action is TransferHClToFlaskAction) {
      final nextPipetteVol = (currentState.pipetteVolume - action.volumeDecrement).clamp(0.0, 25.0);
      final transferred = 25.0 - nextPipetteVol;
      final isDone = nextPipetteVol <= 0.0;
      final newLogs = List<String>.from(currentState.notebookLogs);
      if (isDone) {
        newLogs.add('✓ 25.0 mL HCl transferred into conical flask.');
      }
      return currentState.copyWith(
        pipetteVolume: nextPipetteVol,
        flaskVolume: transferred,
        pipetteStep: isDone ? 7 : 6,
        isTransferringLiquid: !isDone,
        notebookLogs: newLogs,
      );
    }

    // Indicator Actions
    if (action is SelectIndicatorBottleAction) {
      return currentState.copyWith(indicatorStep: 1);
    }
    if (action is PositionDropperAboveFlaskAction) {
      return currentState.copyWith(indicatorStep: 2);
    }
    if (action is AddIndicatorDropAction) {
      if (currentState.indicatorDropsCount >= 3) return currentState;
      final nextCount = currentState.indicatorDropsCount + 1;
      final isDone = nextCount >= 3;
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Added Phenolphthalein indicator drop $nextCount of 3 (Solution remains colourless).');
      return currentState.copyWith(
        indicatorDropsCount: nextCount,
        indicatorStep: isDone ? 3 : 2,
        indicatorAdded: isDone,
        notebookLogs: newLogs,
      );
    }

    if (action is PositionFlaskOnTileAction) {
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Positioned conical flask on white ceramic tile directly beneath burette stopcock.');
      return currentState.copyWith(
        flaskPositioned: true,
        notebookLogs: newLogs,
      );
    }

    // Titration Stopcock Actions
    if (action is SetStopcockStateAction) {
      return currentState.copyWith(
        stopcockState: action.state,
        previousActiveStopcockState: (action.state == StopcockState.flow || action.state == StopcockState.slow)
            ? action.state
            : currentState.previousActiveStopcockState,
      );
    }

    if (action is DeliverTitrantTickAction) {
      if (currentState.stopcockState != StopcockState.flow && currentState.stopcockState != StopcockState.slow) {
        return currentState;
      }
      final increment = currentState.stopcockState == StopcockState.flow ? 0.20 : 0.05;
      final nextDelivered = (currentState.volumeDelivered + increment).clamp(0.0, 26.00);
      final reachedMax = nextDelivered >= 26.00;

      final newLogs = List<String>.from(currentState.notebookLogs);
      if (reachedMax && currentState.volumeDelivered < 26.00) {
        newLogs.add('✓ Burette limit reached at 26.0 mL.');
      }

      return currentState.copyWith(
        volumeDelivered: nextDelivered,
        buretteReading: nextDelivered,
        flaskVolume: 25.0 + nextDelivered,
        stopcockState: reachedMax ? StopcockState.closed : currentState.stopcockState,
        isDropFalling: !reachedMax,
        flaskRipple: !reachedMax,
        hasSwirledAtCurrentVolume: false,
        notebookLogs: newLogs,
      );
    }

    if (action is DeliverSingleDropAction) {
      if (currentState.volumeDelivered >= 26.00) return currentState;
      final nextDelivered = (currentState.volumeDelivered + 0.05).clamp(0.0, 26.00);
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Delivered single drop (0.05 mL). Current reading: ${nextDelivered.toStringAsFixed(2)} mL.');

      return currentState.copyWith(
        volumeDelivered: nextDelivered,
        buretteReading: nextDelivered,
        flaskVolume: 25.0 + nextDelivered,
        hasSwirledAtCurrentVolume: false,
        notebookLogs: newLogs,
      );
    }

    if (action is PauseTitrationAction) {
      return currentState.copyWith(
        stopcockState: StopcockState.paused,
        isDropFalling: false,
        flaskRipple: false,
        previousActiveStopcockState: currentState.stopcockState == StopcockState.flow || currentState.stopcockState == StopcockState.slow
            ? currentState.stopcockState
            : currentState.previousActiveStopcockState,
      );
    }

    if (action is ResumeTitrationAction) {
      return currentState.copyWith(
        stopcockState: currentState.previousActiveStopcockState,
      );
    }

    if (action is CloseStopcockAction) {
      // nothing more leaves the jet once the tap is shut
      return currentState.copyWith(stopcockState: StopcockState.closed, isDropFalling: false, flaskRipple: false);
    }

    // Swirling & Endpoint Actions
    if (action is SwirlFlaskAction) {
      return currentState.copyWith(isSwirling: true);
    }

    if (action is FinishSwirlingAction) {
      final newLogs = List<String>.from(currentState.notebookLogs);
      if (currentState.volumeDelivered >= 24.45 && currentState.volumeDelivered <= 24.75) {
        newLogs.add('✓ Endpoint reached: permanent pale pink colour persists after swirling.');
      } else if (currentState.volumeDelivered >= 24.00 && currentState.volumeDelivered < 24.45) {
        newLogs.add('✓ Solution returned to colourless after swirling (endpoint not yet reached).');
      }
      return currentState.copyWith(
        isSwirling: false,
        hasSwirledAtCurrentVolume: true,
        notebookLogs: newLogs,
      );
    }

    if (action is ConfirmEndpointAction) {
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Endpoint confirmed: permanent pale pink colour at ${currentState.volumeDelivered.toStringAsFixed(2)} mL NaOH delivered.');
      return currentState.copyWith(
        endpointConfirmed: true,
        currentStepIndex: currentState.currentStepIndex < 8 ? currentState.currentStepIndex + 1 : currentState.currentStepIndex,
        notebookLogs: newLogs,
      );
    }

    // Readings & Calculations
    if (action is SubmitReadingsAction) {
      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Recorded readings — Initial: ${action.initialReading} mL, Final: ${action.finalReading} mL, Titre: ${action.titreVolume} mL.');
      return currentState.copyWith(
        initialReadingInput: action.initialReading,
        finalReadingInput: action.finalReading,
        titreVolumeInput: action.titreVolume,
        observedColorInput: action.observedColor,
        readingsSubmitted: true,
        currentStepIndex: currentState.currentStepIndex < 8 ? currentState.currentStepIndex + 1 : currentState.currentStepIndex,
        notebookLogs: newLogs,
      );
    }

    if (action is SubmitCalculationsAction) {
      final studentMolarity = double.tryParse(action.calculatedMolarity) ?? 0.0980;
      final studentTitre = double.tryParse(action.calculatedTitre) ?? currentState.volumeDelivered;

      final score = PracticalScoreResult.calculateTitrationScore(
        studentMolarity: studentMolarity,
        studentTitre: studentTitre,
        durationSeconds: currentState.elapsedSeconds,
      );

      final newLogs = List<String>.from(currentState.notebookLogs)
        ..add('✓ Calculated unknown acid molarity: ${action.calculatedMolarity} M.')
        ..add('✓ Volumetric titration practical successfully completed!');

      return currentState.copyWith(
        calculatedTitreInput: action.calculatedTitre,
        calculatedMolarityInput: action.calculatedMolarity,
        calculationSubmitted: true,
        isCompleted: true,
        scoreResult: score,
        notebookLogs: newLogs,
      );
    }

    if (action is NextStepAction) {
      if (currentState.currentStepIndex < 8) {
        return currentState.copyWith(currentStepIndex: currentState.currentStepIndex + 1);
      }
      return currentState;
    }

    if (action is PrevStepAction) {
      if (currentState.currentStepIndex > 0) {
        return currentState.copyWith(currentStepIndex: currentState.currentStepIndex - 1);
      }
      return currentState;
    }

    if (action is JumpToStepAction) {
      if (currentState.mode == PracticalMode.freeExploration || action.stepIndex <= currentState.currentStepIndex) {
        return currentState.copyWith(currentStepIndex: action.stepIndex);
      }
      return currentState;
    }

    if (action is ResetTitrationAction) {
      return reset(currentState.mode);
    }

    return currentState;
  }

  @override
  TitrationState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  PracticalScoreResult calculateScore(TitrationState currentState) {
    if (currentState.scoreResult != null) {
      return currentState.scoreResult!;
    }
    final studentMolarity = double.tryParse(currentState.calculatedMolarityInput) ?? 0.0980;
    final studentTitre = double.tryParse(currentState.calculatedTitreInput) ?? currentState.volumeDelivered;
    return PracticalScoreResult.calculateTitrationScore(
      studentMolarity: studentMolarity,
      studentTitre: studentTitre,
      durationSeconds: currentState.elapsedSeconds,
    );
  }
}
