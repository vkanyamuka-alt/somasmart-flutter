import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pendulum_state.dart';
import '../../data/models/practical_model.dart';
import '../../domain/pendulum_engine.dart';

final pendulumControllerProvider =
    StateNotifierProvider.family<PendulumController, PendulumState, PracticalMode>((ref, mode) {
  final engine = PendulumEngine();
  return PendulumController(engine, mode);
});

class PendulumController extends StateNotifier<PendulumState> {
  final PendulumEngine _engine;
  Timer? _sessionTimer;
  Timer? _animationTicker;

  PendulumController(this._engine, PracticalMode mode)
      : super(_engine.createInitialState(mode)) {
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isCompleted) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void inspectItem(String itemKey) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, InspectPendulumItemAction(itemKey));
  }

  void setLength(double lengthCm) {
    state = _engine.processAction(state, SetPendulumLengthAction(lengthCm));
  }

  void setDeflectionAngle(double angleDeg) {
    state = _engine.processAction(state, SetDeflectionAngleAction(angleDeg));
  }

  void startOscillation() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const StartPendulumOscillationAction());

    // Start 60 FPS animation ticker (16ms interval)
    _animationTicker?.cancel();
    _animationTicker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (state.isOscillating || state.stopwatchRunning) {
        state = _engine.processAction(state, const TickPendulumSimulationAction(0.016));
        if (!state.isOscillating) {
          _animationTicker?.cancel();
          HapticFeedback.lightImpact();
        }
      } else {
        _animationTicker?.cancel();
      }
    });
  }

  void stopOscillation() {
    HapticFeedback.mediumImpact();
    _animationTicker?.cancel();
    state = _engine.processAction(state, const StopPendulumOscillationAction());
  }

  void resetOscillation() {
    HapticFeedback.lightImpact();
    _animationTicker?.cancel();
    state = _engine.processAction(state, const ResetPendulumOscillationAction());
  }

  void recordTrial() {
    HapticFeedback.mediumImpact();
    _animationTicker?.cancel();
    state = _engine.processAction(state, const RecordPendulumTrialAction());
  }

  void deleteTrial(int index) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, DeletePendulumTrialAction(index));
  }

  void setStudentInputs({String? gradient, String? gravity}) {
    state = _engine.processAction(
      state,
      SetStudentInputsAction(gradient: gradient, gravity: gravity),
    );
  }

  void submitCalculations() {
    HapticFeedback.heavyImpact();
    state = _engine.processAction(state, const SubmitPendulumCalculationsAction());
  }

  void resetExperiment(PracticalMode mode) {
    HapticFeedback.mediumImpact();
    _animationTicker?.cancel();
    _startSessionTimer();
    state = _engine.processAction(state, ResetPendulumExperimentAction(mode));
  }

  void nextStep() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const NextPendulumStepAction());
  }

  void previousStep() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const PreviousPendulumStepAction());
  }

  void jumpToStep(int stepIndex) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, JumpToPendulumStepAction(stepIndex));
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _animationTicker?.cancel();
    super.dispose();
  }
}
