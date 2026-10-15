import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gas_preparation_state.dart';
import '../../data/models/practical_model.dart';
import '../../domain/gas_preparation_engine.dart';
import '../../domain/practical_engine_registry.dart';

final gasPreparationEngineProvider = Provider<GasPreparationEngine>((ref) {
  final registry = ref.watch(practicalEngineRegistryProvider);
  return registry.resolveEngine('gas_preparation') as GasPreparationEngine;
});

final gasPreparationControllerProvider =
    StateNotifierProvider.autoDispose<GasPreparationController, GasPreparationState>((ref) {
  final engine = ref.watch(gasPreparationEngineProvider);
  return GasPreparationController(engine);
});

class GasPreparationController extends StateNotifier<GasPreparationState> {
  final GasPreparationEngine _engine;
  Timer? _durationTimer;
  Timer? _generationTimer;

  GasPreparationController(this._engine)
      : super(_engine.createInitialState(PracticalMode.guidedPractice)) {
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _engine.processAction(state, const TickGasDurationAction());
    });
  }

  /// Initialize state for a specific practical mode
  void initializeForMode(PracticalMode mode) {
    _generationTimer?.cancel();
    state = _engine.createInitialState(mode);
    _startDurationTimer();
  }

  /// Select the gas to prepare (O2, CO2, H2)
  void selectGas(PreparedGasType gasType) {
    _generationTimer?.cancel();
    state = _engine.processAction(state, SelectGasTypeAction(gasType));
  }

  /// Inspect a single apparatus item
  void inspectItem(String apparatusId) {
    state = _engine.processAction(state, InspectGasApparatusAction(apparatusId));
  }

  /// Inspect all apparatus items (Guided shortcut)
  void inspectAll() {
    state = _engine.processAction(state, const InspectAllGasApparatusAction());
  }

  /// Add solid reactant into generator flask
  void addSolidReactant() {
    state = _engine.processAction(state, const AddSolidReactantAction());
  }

  /// Add liquid reactant via thistle funnel to start gas generation
  void addLiquidReactant() {
    state = _engine.processAction(state, const AddLiquidReactantAction());

    _generationTimer?.cancel();
    _generationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!state.isGenerating) {
        timer.cancel();
        return;
      }
      state = _engine.processAction(state, const TickGasGenerationAction(deltaVolume: 4.0));
      if (state.isGasJarFull) {
        timer.cancel();
      }
    });
  }

  /// Complete gas collection instantly (or when volume reaches 100)
  void completeGasCollection() {
    _generationTimer?.cancel();
    state = _engine.processAction(state, const CompleteGasCollectionAction());
  }

  /// Perform diagnostic test for the collected gas
  void performGasTest() {
    state = _engine.processAction(state, const PerformGasTestAction());
  }

  /// Switch workflow step
  void setStep(GasPrepStep step) {
    state = _engine.processAction(state, SetGasPrepStepAction(step));
  }

  /// Reset practical to fresh state
  void reset(PracticalMode mode) {
    _generationTimer?.cancel();
    state = _engine.reset(mode);
    _startDurationTimer();
  }

  /// Submit practical for scoring
  void submit() {
    _generationTimer?.cancel();
    state = _engine.processAction(state, const SubmitGasPracticalAction());
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _generationTimer?.cancel();
    super.dispose();
  }
}
