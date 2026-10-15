import 'dart:math' as math;
import '../data/models/pendulum_state.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import 'practical_simulation_engine.dart';

/// Base class for all Simple Pendulum actions
abstract class PendulumAction {
  const PendulumAction();
}

class InspectPendulumItemAction extends PendulumAction {
  final String itemKey;
  const InspectPendulumItemAction(this.itemKey);
}

class SetPendulumLengthAction extends PendulumAction {
  final double lengthCm;
  const SetPendulumLengthAction(this.lengthCm);
}

class SetDeflectionAngleAction extends PendulumAction {
  final double angleDeg;
  const SetDeflectionAngleAction(this.angleDeg);
}

class StartPendulumOscillationAction extends PendulumAction {
  const StartPendulumOscillationAction();
}

class StopPendulumOscillationAction extends PendulumAction {
  const StopPendulumOscillationAction();
}

class ResetPendulumOscillationAction extends PendulumAction {
  const ResetPendulumOscillationAction();
}

class TickPendulumSimulationAction extends PendulumAction {
  final double deltaSeconds;
  const TickPendulumSimulationAction(this.deltaSeconds);
}

class RecordPendulumTrialAction extends PendulumAction {
  const RecordPendulumTrialAction();
}

class DeletePendulumTrialAction extends PendulumAction {
  final int index;
  const DeletePendulumTrialAction(this.index);
}

class SetStudentInputsAction extends PendulumAction {
  final String? gradient;
  final String? gravity;
  const SetStudentInputsAction({this.gradient, this.gravity});
}

class SubmitPendulumCalculationsAction extends PendulumAction {
  const SubmitPendulumCalculationsAction();
}

class ResetPendulumExperimentAction extends PendulumAction {
  final PracticalMode mode;
  const ResetPendulumExperimentAction(this.mode);
}

class NextPendulumStepAction extends PendulumAction {
  const NextPendulumStepAction();
}

class PreviousPendulumStepAction extends PendulumAction {
  const PreviousPendulumStepAction();
}

class JumpToPendulumStepAction extends PendulumAction {
  final int stepIndex;
  const JumpToPendulumStepAction(this.stepIndex);
}

/// Pure Dart Simulation Engine for O-Level Physics: Simple Pendulum (g determination).
class PendulumEngine implements PracticalSimulationEngine<PendulumState, PendulumAction> {
  @override
  String get engineId => 'pendulum';

  @override
  String get titleEn => 'Simple Pendulum Gravitational Acceleration (g)';

  @override
  String get titleSw => 'Kipimio cha Mvuto wa Dunia (g) kwa Penduli';

  @override
  PracticalSubject get subject => PracticalSubject.physics;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  List<String> get apparatusListEn => const [
        'Retort Stand & Clamp',
        'Heavy Metallic Bob',
        'Inextensible Thread (Nylon)',
        'Metre Rule (0–100 cm)',
        'Digital Stopwatch (0.01s precision)',
        'Split Cork Suspension Jaws',
      ];

  List<String> get apparatusListSw => const [
        'Standi na Kishikio cha Chuma',
        'Tufe ya Metali Nzito',
        'Uzi Usionyooka wa Nailoni',
        'Rula ya Mita (cm 0–100)',
        'Saa ya Kidijitali ya Kupimia',
        'Vizibo Vilivyogawanyika vya Kushikia',
      ];

  @override
  PendulumState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return PendulumState(mode: mode);
  }

  @override
  PendulumState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  PendulumState processAction(PendulumState currentState, PendulumAction action) {
    if (action is InspectPendulumItemAction) {
      return _handleInspectItem(currentState, action.itemKey);
    } else if (action is SetPendulumLengthAction) {
      return _handleSetLength(currentState, action.lengthCm);
    } else if (action is SetDeflectionAngleAction) {
      return _handleSetDeflectionAngle(currentState, action.angleDeg);
    } else if (action is StartPendulumOscillationAction) {
      return _handleStartOscillation(currentState);
    } else if (action is StopPendulumOscillationAction) {
      return _handleStopOscillation(currentState);
    } else if (action is ResetPendulumOscillationAction) {
      return _handleResetOscillation(currentState);
    } else if (action is TickPendulumSimulationAction) {
      return _handleTick(currentState, action.deltaSeconds);
    } else if (action is RecordPendulumTrialAction) {
      return _handleRecordTrial(currentState);
    } else if (action is DeletePendulumTrialAction) {
      return _handleDeleteTrial(currentState, action.index);
    } else if (action is SetStudentInputsAction) {
      return currentState.copyWith(
        studentGradientInput: action.gradient ?? currentState.studentGradientInput,
        studentGravityInput: action.gravity ?? currentState.studentGravityInput,
      );
    } else if (action is SubmitPendulumCalculationsAction) {
      return _handleSubmitCalculations(currentState);
    } else if (action is ResetPendulumExperimentAction) {
      return createInitialState(action.mode);
    } else if (action is NextPendulumStepAction) {
      final nextStep = (currentState.currentStepIndex + 1).clamp(0, 6);
      return currentState.copyWith(currentStepIndex: nextStep);
    } else if (action is PreviousPendulumStepAction) {
      final prevStep = (currentState.currentStepIndex - 1).clamp(0, 6);
      return currentState.copyWith(currentStepIndex: prevStep);
    } else if (action is JumpToPendulumStepAction) {
      return currentState.copyWith(currentStepIndex: action.stepIndex.clamp(0, 6));
    }
    return currentState;
  }

  PendulumState _handleInspectItem(PendulumState state, String itemKey) {
    final updatedInspected = Set<String>.from(state.inspectedItems)..add(itemKey);
    final log = '• Inspected apparatus: ${_getApparatusName(itemKey)}.';
    return state.copyWith(
      inspectedItems: updatedInspected,
      selectedInspectItemKey: itemKey,
      notebookLogs: [...state.notebookLogs, log],
    );
  }

  PendulumState _handleSetLength(PendulumState state, double lengthCm) {
    final clampedLength = lengthCm.clamp(20.0, 100.0);
    return state.copyWith(
      pendulumLengthCm: clampedLength,
      isOscillating: false,
      currentAngleDeg: 0.0,
      currentOscillations: 0,
      stopwatchRunning: false,
      stopwatchElapsedSec: 0.0,
      notebookLogs: [
        ...state.notebookLogs,
        '• Pendulum length adjusted to ${clampedLength.toStringAsFixed(1)} cm.',
      ],
    );
  }

  PendulumState _handleSetDeflectionAngle(PendulumState state, double angleDeg) {
    final clampedAngle = angleDeg.clamp(2.0, 10.0);
    return state.copyWith(
      deflectionAngleDeg: clampedAngle,
      currentAngleDeg: clampedAngle,
    );
  }

  PendulumState _handleStartOscillation(PendulumState state) {
    return state.copyWith(
      isOscillating: true,
      stopwatchRunning: true,
      currentAngleDeg: state.deflectionAngleDeg,
      currentOscillations: 0,
      stopwatchElapsedSec: 0.0,
      notebookLogs: [
        ...state.notebookLogs,
        '• Bob released at ${state.deflectionAngleDeg.toStringAsFixed(1)}°. Stopwatch started for ${state.targetOscillations} oscillations.',
      ],
    );
  }

  PendulumState _handleStopOscillation(PendulumState state) {
    return state.copyWith(
      isOscillating: false,
      stopwatchRunning: false,
      currentAngleDeg: 0.0,
      notebookLogs: [
        ...state.notebookLogs,
        '• Stopwatch stopped at ${state.stopwatchElapsedSec.toStringAsFixed(2)}s (${state.currentOscillations} oscillations).',
      ],
    );
  }

  PendulumState _handleResetOscillation(PendulumState state) {
    return state.copyWith(
      isOscillating: false,
      stopwatchRunning: false,
      currentAngleDeg: 0.0,
      currentOscillations: 0,
      stopwatchElapsedSec: 0.0,
    );
  }

  PendulumState _handleTick(PendulumState state, double deltaSeconds) {
    if (!state.isOscillating && !state.stopwatchRunning) return state;

    final newElapsed = state.stopwatchElapsedSec + deltaSeconds;
    final period = state.theoreticalPeriod;

    final phase = (2.0 * math.pi * newElapsed) / period;
    final liveAngle = state.deflectionAngleDeg * math.cos(phase);

    final completedOscillations = (newElapsed / period).floor();

    if (completedOscillations >= state.targetOscillations && state.isOscillating) {
      final finalTime = state.theoreticalTotalTime;
      return state.copyWith(
        isOscillating: false,
        stopwatchRunning: false,
        currentAngleDeg: 0.0,
        currentOscillations: state.targetOscillations,
        stopwatchElapsedSec: double.parse(finalTime.toStringAsFixed(2)),
        notebookLogs: [
          ...state.notebookLogs,
          '• Completed ${state.targetOscillations} oscillations in ${finalTime.toStringAsFixed(2)}s (T = ${(finalTime / state.targetOscillations).toStringAsFixed(3)}s).',
        ],
      );
    }

    return state.copyWith(
      stopwatchElapsedSec: newElapsed,
      currentAngleDeg: liveAngle,
      currentOscillations: completedOscillations.clamp(0, state.targetOscillations),
    );
  }

  PendulumState _handleRecordTrial(PendulumState state) {
    final timeTaken = state.stopwatchElapsedSec > 0
        ? state.stopwatchElapsedSec
        : double.parse(state.theoreticalTotalTime.toStringAsFixed(2));
    final oscCount = state.targetOscillations;
    final period = timeTaken / oscCount;
    final periodSq = period * period;

    final newTrial = PendulumTrial(
      trialNumber: state.recordedTrials.length + 1,
      lengthCm: state.pendulumLengthCm,
      oscillationCount: oscCount,
      timeSeconds: double.parse(timeTaken.toStringAsFixed(2)),
      periodSeconds: double.parse(period.toStringAsFixed(3)),
      periodSquared: double.parse(periodSq.toStringAsFixed(3)),
    );

    final updatedTrials = [...state.recordedTrials, newTrial];
    final log =
        '• Trial #${newTrial.trialNumber} recorded: L = ${newTrial.lengthCm} cm, t = ${newTrial.timeSeconds}s, T = ${newTrial.periodSeconds}s, T² = ${newTrial.periodSquared} s².';

    return state.copyWith(
      recordedTrials: updatedTrials,
      isOscillating: false,
      stopwatchRunning: false,
      currentAngleDeg: 0.0,
      currentOscillations: 0,
      stopwatchElapsedSec: 0.0,
      notebookLogs: [...state.notebookLogs, log],
    );
  }

  PendulumState _handleDeleteTrial(PendulumState state, int index) {
    if (index < 0 || index >= state.recordedTrials.length) return state;
    final updatedTrials = List<PendulumTrial>.from(state.recordedTrials)..removeAt(index);
    final renumberedTrials = [
      for (int i = 0; i < updatedTrials.length; i++)
        PendulumTrial(
          trialNumber: i + 1,
          lengthCm: updatedTrials[i].lengthCm,
          oscillationCount: updatedTrials[i].oscillationCount,
          timeSeconds: updatedTrials[i].timeSeconds,
          periodSeconds: updatedTrials[i].periodSeconds,
          periodSquared: updatedTrials[i].periodSquared,
        ),
    ];
    return state.copyWith(recordedTrials: renumberedTrials);
  }

  PendulumState _handleSubmitCalculations(PendulumState state) {
    final score = calculateScore(state);
    return state.copyWith(
      calculationSubmitted: true,
      isCompleted: true,
      scoreResult: score,
      notebookLogs: [
        ...state.notebookLogs,
        '• Calculations submitted. Final Practical Score: ${score.totalScore}% (${score.grade}).',
      ],
    );
  }

  @override
  PracticalScoreResult calculateScore(PendulumState state) {
    final parsedG = double.tryParse(state.studentGravityInput.trim()) ??
        state.calculatedExperimentalGravity ??
        PendulumState.standardGravity;

    return PracticalScoreResult.calculatePendulumScore(
      studentGravity: parsedG,
      theoreticalGravity: PendulumState.standardGravity,
      recordedTrialsCount: state.recordedTrials.length,
      inspectedCount: state.inspectedItems.length,
      smallAngleMaintained: state.deflectionAngleDeg <= 10.0,
      durationSeconds: state.elapsedSeconds,
    );
  }

  String _getApparatusName(String key) {
    switch (key) {
      case 'stand':
        return 'Retort Stand & Clamp';
      case 'bob':
        return 'Heavy Metallic Pendulum Bob';
      case 'thread':
        return 'Inextensible Nylon Thread';
      case 'ruler':
        return 'Metre Rule (0–100 cm)';
      case 'stopwatch':
        return 'Digital Precision Stopwatch';
      default:
        return 'Apparatus Component';
    }
  }
}
