import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/ohms_law_state.dart';
import '../../domain/ohms_law_engine.dart';

final ohmsLawControllerProvider = StateNotifierProvider.family<OhmsLawController, OhmsLawState, PracticalMode>((ref, mode) {
  final engine = OhmsLawEngine();
  return OhmsLawController(engine, mode);
});

class OhmsLawController extends StateNotifier<OhmsLawState> {
  final OhmsLawEngine _engine;
  Timer? _sessionTimer;

  OhmsLawController(this._engine, PracticalMode mode)
      : super(_engine.createInitialState(mode)) {
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isCompleted) {
        state = _engine.processAction(state, const TickTimerAction());
      }
    });
  }

  void inspectItem(String itemKey) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, InspectOhmsItemAction(itemKey));
  }

  void connectCircuit() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const ConnectCircuitAction());
  }

  void toggleSwitch(bool isClosed) {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, ToggleSwitchAction(isClosed));
  }

  void setVoltage(double voltage) {
    state = _engine.processAction(state, SetVoltageAction(voltage));
  }

  void recordCurrentReading() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const RecordCurrentReadingAction());
  }

  void deleteReading(int index) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, DeleteReadingAction(index));
  }

  void resetReadings() {
    HapticFeedback.lightImpact();
    state = _engine.processAction(state, const ResetReadingsAction());
  }

  void nextStep() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const NextStepAction());
  }

  void previousStep() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const PreviousStepAction());
  }

  void setStep(int stepIndex) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, SetStepIndexAction(stepIndex));
  }

  void submitCalculation(String slope, String calculatedResistance) {
    HapticFeedback.heavyImpact();
    state = _engine.processAction(
      state,
      SubmitCalculationAction(
        slope: slope,
        calculatedResistance: calculatedResistance,
      ),
    );
  }

  void resetPractical(PracticalMode mode) {
    HapticFeedback.mediumImpact();
    _startSessionTimer();
    state = _engine.processAction(state, ResetEngineAction(mode));
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
