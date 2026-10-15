import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/optics_state.dart';
import '../../data/models/practical_model.dart';
import '../../domain/optics_engine.dart';
import '../../domain/practical_engine_registry.dart';

final opticsControllerProvider =
    StateNotifierProvider.autoDispose<OpticsController, OpticsState>((ref) {
  final registry = ref.watch(practicalEngineRegistryProvider);
  final engine = registry.resolveEngine('optics') as OpticsEngine? ?? OpticsEngine();
  return OpticsController(engine);
});

class OpticsController extends StateNotifier<OpticsState> {
  final OpticsEngine _engine;
  Timer? _timer;

  OpticsController(this._engine) : super(_engine.createInitialState()) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _engine.processAction(state, const TickTimerAction(1));
    });
  }

  void inspectApparatus(String apparatusId) {
    state = _engine.processAction(state, InspectApparatusAction(apparatusId));
  }

  void setIncidentAngle(double angleDeg) {
    state = _engine.processAction(state, SetIncidentAngleAction(angleDeg));
  }

  void toggleProtractor() {
    state = _engine.processAction(state, const ToggleProtractorAction());
  }

  void toggleNormalLines() {
    state = _engine.processAction(state, const ToggleNormalLinesAction());
  }

  void toggleOpticalPins() {
    state = _engine.processAction(state, const ToggleOpticalPinsAction());
  }

  void toggleRayExtension() {
    state = _engine.processAction(state, const ToggleRayExtensionAction());
  }

  void toggleLaser() {
    state = _engine.processAction(state, const ToggleLaserAction());
  }

  void recordTrial() {
    state = _engine.processAction(state, const RecordTrialAction());
  }

  void removeTrial(int trialNumber) {
    state = _engine.processAction(state, RemoveTrialAction(trialNumber));
  }

  void setStep(OpticsStep step) {
    state = _engine.processAction(state, SetStepAction(step));
  }

  void nextStep() {
    state = _engine.processAction(state, const NextStepAction());
  }

  void previousStep() {
    state = _engine.processAction(state, const PreviousStepAction());
  }

  void calculateRefractiveIndex(double calculatedIndex) {
    state = _engine.processAction(state, CalculateRefractiveIndexAction(calculatedIndex));
  }

  void submitCalculations() {
    state = _engine.processAction(state, const SubmitCalculationsAction());
  }

  void resetExperiment([PracticalMode mode = PracticalMode.guidedPractice]) {
    _timer?.cancel();
    state = _engine.createInitialState(mode);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
