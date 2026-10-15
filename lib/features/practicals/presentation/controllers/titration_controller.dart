import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/titration_state.dart';
import '../../domain/titration_engine.dart';

final titrationControllerProvider = StateNotifierProvider.family<TitrationController, TitrationState, PracticalMode>((ref, mode) {
  final engine = AcidBaseTitrationEngine();
  return TitrationController(engine, mode);
});

class TitrationController extends StateNotifier<TitrationState> {
  final AcidBaseTitrationEngine _engine;
  Timer? _sessionTimer;
  Timer? _flowTimer;
  Timer? _pipetteTimer;
  Timer? _swirlTimer;

  TitrationController(this._engine, PracticalMode mode)
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
    state = _engine.processAction(state, InspectItemAction(itemKey));
  }

  void fillBurette() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const FillBuretteAction());
  }

  // Pipette workflow
  void selectPipette() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const SelectPipetteAction());
  }

  void attachPipetteBulb() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const AttachPipetteBulbAction());
  }

  void insertPipetteInHCl() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const InsertPipetteInHClAction());
  }

  void drawHCl() {
    HapticFeedback.lightImpact();
    state = state.copyWith(isDrawingLiquid: true);

    _pipetteTimer?.cancel();
    _pipetteTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      state = _engine.processAction(state, const DrawHClAction(0.5));
      if (state.pipetteVolume >= 25.0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void positionPipetteAboveFlask() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const PositionPipetteAboveFlaskAction());
  }

  void transferHClToFlask() {
    HapticFeedback.lightImpact();
    state = state.copyWith(isTransferringLiquid: true);

    _pipetteTimer?.cancel();
    _pipetteTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      state = _engine.processAction(state, const TransferHClToFlaskAction(0.5));
      if (state.pipetteVolume <= 0.0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
      }
    });
  }

  // Indicator workflow
  void selectIndicatorBottle() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const SelectIndicatorBottleAction());
  }

  void positionDropperAboveFlask() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const PositionDropperAboveFlaskAction());
  }

  void addIndicatorDrop() {
    if (state.indicatorDropsCount >= 3 || state.isDroppingIndicator) return;
    HapticFeedback.lightImpact();
    state = state.copyWith(isDroppingIndicator: true);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      state = _engine.processAction(state, const AddIndicatorDropAction());
      state = state.copyWith(isDroppingIndicator: false, flaskRipple: true);
      HapticFeedback.selectionClick();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          state = state.copyWith(flaskRipple: false);
        }
      });
    });
  }

  void positionFlaskOnTile() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const PositionFlaskOnTileAction());
  }

  // Delivery & Stopcock
  void setContinuousFlow() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const SetStopcockStateAction(StopcockState.flow));
    _startFlowInterval(const Duration(milliseconds: 120));
  }

  void setSlowFlow() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const SetStopcockStateAction(StopcockState.slow));
    _startFlowInterval(const Duration(milliseconds: 250));
  }

  void deliverSingleDrop() {
    if (state.volumeDelivered >= 26.00) return;
    HapticFeedback.lightImpact();
    state = _engine.processAction(state, const SetStopcockStateAction(StopcockState.single));
    state = state.copyWith(isDropFalling: true, flaskRipple: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      state = _engine.processAction(state, const DeliverSingleDropAction());
      state = state.copyWith(
        isDropFalling: false,
        flaskRipple: false,
        stopcockState: StopcockState.closed,
      );
      HapticFeedback.selectionClick();
    });
  }

  void pauseTitration() {
    HapticFeedback.selectionClick();
    _flowTimer?.cancel();
    state = _engine.processAction(state, const PauseTitrationAction());
  }

  void resumeTitration() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const ResumeTitrationAction());
    final isFlow = state.stopcockState == StopcockState.flow;
    _startFlowInterval(Duration(milliseconds: isFlow ? 120 : 250));
  }

  void closeStopcock() {
    HapticFeedback.mediumImpact();
    _flowTimer?.cancel();
    state = _engine.processAction(state, const CloseStopcockAction());
  }

  void _startFlowInterval(Duration period) {
    _flowTimer?.cancel();
    _flowTimer = Timer.periodic(period, (_) {
      if (state.volumeDelivered >= 26.00 ||
          (state.stopcockState != StopcockState.flow && state.stopcockState != StopcockState.slow)) {
        _flowTimer?.cancel();
        return;
      }
      state = _engine.processAction(state, const DeliverTitrantTickAction());
      state = state.copyWith(isDropFalling: true, flaskRipple: true);
    });
  }

  // Swirling
  void swirlFlask() {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(state, const SwirlFlaskAction());

    _swirlTimer?.cancel();
    _swirlTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        state = _engine.processAction(state, const FinishSwirlingAction());
        HapticFeedback.lightImpact();
      }
    });
  }

  void confirmEndpoint() {
    HapticFeedback.heavyImpact();
    state = _engine.processAction(state, const ConfirmEndpointAction());
  }

  // Form Submissions
  void submitReadings({
    required String initialReading,
    required String finalReading,
    required String titreVolume,
    required String observedColor,
  }) {
    HapticFeedback.mediumImpact();
    state = _engine.processAction(
      state,
      SubmitReadingsAction(
        initialReading: initialReading,
        finalReading: finalReading,
        titreVolume: titreVolume,
        observedColor: observedColor,
      ),
    );
  }

  void submitCalculations({
    required String calculatedTitre,
    required String calculatedMolarity,
  }) {
    HapticFeedback.heavyImpact();
    _flowTimer?.cancel();
    _sessionTimer?.cancel();
    state = _engine.processAction(
      state,
      SubmitCalculationsAction(
        calculatedTitre: calculatedTitre,
        calculatedMolarity: calculatedMolarity,
      ),
    );
  }

  void nextStep() {
    if (state.canAdvanceStep()) {
      HapticFeedback.selectionClick();
      state = _engine.processAction(state, const NextStepAction());
    }
  }

  void prevStep() {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, const PrevStepAction());
  }

  void jumpToStep(int stepIndex) {
    HapticFeedback.selectionClick();
    state = _engine.processAction(state, JumpToStepAction(stepIndex));
  }

  void reset() {
    HapticFeedback.mediumImpact();
    _flowTimer?.cancel();
    _pipetteTimer?.cancel();
    _swirlTimer?.cancel();
    state = _engine.reset(state.mode);
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _flowTimer?.cancel();
    _pipetteTimer?.cancel();
    _swirlTimer?.cancel();
    super.dispose();
  }
}
