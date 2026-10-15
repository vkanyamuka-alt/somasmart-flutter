import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/microscope_state.dart';
import '../../data/models/practical_model.dart';
import '../../domain/microscope_engine.dart';

final microscopeControllerProvider = StateNotifierProvider.family<MicroscopeController, MicroscopeState, PracticalMode>((ref, mode) {
  final engine = MicroscopeEngine();
  return MicroscopeController(engine, mode);
});

class MicroscopeController extends StateNotifier<MicroscopeState> {
  final MicroscopeEngine _engine;
  Timer? _sessionTimer;

  MicroscopeController(this._engine, PracticalMode mode)
      : super(_engine.createInitialState(mode)) {
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.currentStep != MicroscopeStep.completed) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void inspectItem(String itemId) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, InspectMicroscopeApparatusAction(itemId));
  }

  void placeSpecimen() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const PlaceSpecimenAction());
  }

  void applyStain(StainType stain) {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, ApplyStainAction(stain));
  }

  void mountCoverslip() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const MountCoverslipAction());
  }

  void placeSlideOnStage() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const PlaceSlideOnStageAction());
  }

  void setLightIntensity(double intensity) {
    state = _engine.processAction(state, SetLightIntensityAction(intensity));
  }

  void setCoarseFocus(double focus) {
    state = _engine.processAction(state, SetCoarseFocusAction(focus));
  }

  void setFineFocus(double focus) {
    state = _engine.processAction(state, SetFineFocusAction(focus));
  }

  void setObjective(MicroscopeObjective objective) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, SetObjectiveAction(objective));
  }

  void toggleOrganelleSelection(String organelleId) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, ToggleOrganelleSelectionAction(organelleId));
  }

  void setStep(MicroscopeStep step) {
    HapticFeedback.selectionClick();
    state = state.copyWith(currentStep: step);
  }

  void submitObservations(int calculatedMagnification) {
    HapticFeedback.heavyImpact();
    state = _engine.processAction(state, SubmitMicroscopeObservationsAction(calculatedMagnification));
  }

  void resetPractical(PracticalMode mode) {
    HapticFeedback.mediumImpact();
    _startSessionTimer();
    state = _engine.processAction(state, const ResetMicroscopeAction());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
