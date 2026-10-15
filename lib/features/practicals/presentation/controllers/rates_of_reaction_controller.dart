import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/rates_of_reaction_state.dart';
import '../../domain/practical_engine_registry.dart';
import '../../domain/rates_of_reaction_engine.dart';

final ratesOfReactionEngineProvider = Provider<RatesOfReactionEngine>((ref) {
  final registry = ref.watch(practicalEngineRegistryProvider);
  return registry.resolveEngine('rates_of_reaction') as RatesOfReactionEngine;
});

final ratesOfReactionControllerProvider =
    StateNotifierProvider.autoDispose<RatesOfReactionController, RatesOfReactionState>((ref) {
  final engine = ref.watch(ratesOfReactionEngineProvider);
  return RatesOfReactionController(engine);
});

class RatesOfReactionController extends StateNotifier<RatesOfReactionState> {
  final RatesOfReactionEngine _engine;
  Timer? _durationTimer;
  Timer? _stopwatchTicker;

  RatesOfReactionController(this._engine)
      : super(_engine.createInitialState(PracticalMode.guidedPractice)) {
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _engine.processAction(state, const TickRatesDurationAction());
    });
  }

  /// Initialize state for a specific practical mode
  void initializeForMode(PracticalMode mode) {
    _stopwatchTicker?.cancel();
    state = _engine.createInitialState(mode);
    _startDurationTimer();
  }

  /// Inspect a single apparatus item
  void inspectItem(String apparatusId) {
    state = _engine.processAction(state, InspectRatesApparatusAction(apparatusId));
  }

  /// Inspect all apparatus items (Guided shortcut)
  void inspectAll() {
    state = _engine.processAction(state, const InspectAllRatesApparatusAction());
  }

  /// Select active trial index (0..4)
  void selectTrial(int index) {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, SelectTrialAction(index));
  }

  /// Prepare/dilute solution in a specific flask
  void prepareSolution(int flaskNumber) {
    state = _engine.processAction(state, PrepareSolutionAction(flaskNumber));
  }

  /// Prepare all flasks in sequence
  void prepareAllSolutions() {
    state = _engine.processAction(state, const PrepareAllSolutionsAction());
  }

  /// Place active flask on the cross tile
  void placeFlaskOnCross() {
    state = _engine.processAction(state, const PlaceFlaskOnCrossAction());
  }

  /// Remove flask from cross tile
  void removeFlaskFromCross() {
    state = _engine.processAction(state, const RemoveFlaskFromCrossAction());
  }

  /// Add 5.0 mL 2.0 M HCl to initiate reaction and start real-time timer
  void addAcidAndStartReaction(int flaskNumber) {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, AddAcidAction(flaskNumber));

    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isStopwatchRunning) {
        timer.cancel();
        return;
      }
      state = _engine.processAction(state, const TickStopwatchAction(deltaSeconds: 0.1));
    });
  }

  /// Start stopwatch manually
  void startStopwatch() {
    state = _engine.processAction(state, const StartStopwatchAction());
    _stopwatchTicker?.cancel();
    _stopwatchTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!state.isStopwatchRunning) return;
      state = _engine.processAction(state, const TickStopwatchAction(deltaSeconds: 0.1));
    });
  }

  /// Stop stopwatch manually
  void stopStopwatch() {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, const StopStopwatchAction());
  }

  /// Reset stopwatch for the active trial
  void resetStopwatch() {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, const ResetStopwatchAction());
  }

  /// Trigger disappearing cross observed event & record trial endpoint
  void recordDisappearance(int flaskNumber) {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, RecordDisappearanceAction(flaskNumber));
  }

  /// Switch workflow step
  void setStep(RatesOfReactionStep step) {
    state = _engine.processAction(state, SetRatesStepAction(step));
  }

  /// Enter student's estimated slope k'
  void setEnteredSlope(double slope) {
    state = _engine.processAction(state, SetEnteredSlopeAction(slope));
  }

  /// Reset practical to fresh state
  void reset(PracticalMode mode) {
    _stopwatchTicker?.cancel();
    state = _engine.reset(mode);
    _startDurationTimer();
  }

  /// Final submission and score calculation
  void submit(double enteredSlope) {
    _stopwatchTicker?.cancel();
    state = _engine.processAction(state, SubmitRatesPracticalAction(enteredSlope));
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _stopwatchTicker?.cancel();
    super.dispose();
  }
}
