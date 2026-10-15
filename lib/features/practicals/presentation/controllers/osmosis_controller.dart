import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/osmosis_state.dart';
import '../../data/models/practical_model.dart';
import '../../domain/osmosis_engine.dart';
import '../../domain/practical_engine_registry.dart';

final osmosisEngineProvider = Provider<OsmosisEngine>((ref) {
  final registry = ref.watch(practicalEngineRegistryProvider);
  return registry.resolveEngine('osmosis') as OsmosisEngine;
});

final osmosisControllerProvider = StateNotifierProvider.autoDispose<OsmosisController, OsmosisState>((ref) {
  final engine = ref.watch(osmosisEngineProvider);
  return OsmosisController(engine);
});

class OsmosisController extends StateNotifier<OsmosisState> {
  final OsmosisEngine _engine;
  Timer? _durationTimer;
  Timer? _incubationTimer;

  OsmosisController(this._engine) : super(_engine.createInitialState(PracticalMode.guidedPractice)) {
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _engine.processAction(state, const TickOsmosisDurationAction());
    });
  }

  /// Initialize state for a specific practical mode
  void initializeForMode(PracticalMode mode) {
    _incubationTimer?.cancel();
    state = _engine.createInitialState(mode);
    _startDurationTimer();
  }

  /// Inspect a single apparatus item
  void inspectItem(String apparatusId) {
    state = _engine.processAction(state, InspectOsmosisApparatusAction(apparatusId));
  }

  /// Inspect all apparatus items (Guided shortcut)
  void inspectAll() {
    state = _engine.processAction(state, const InspectAllOsmosisApparatusAction());
  }

  /// Select active sample index
  void selectSample(int index) {
    state = _engine.processAction(state, SelectOsmosisSampleAction(index));
  }

  /// Prepare/cut a potato cylinder
  void prepareSample(String sampleId) {
    state = _engine.processAction(state, PreparePotatoSampleAction(sampleId));
  }

  /// Prepare all potato cylinders
  void prepareAll() {
    state = _engine.processAction(state, const PrepareAllPotatoSamplesAction());
  }

  /// Place potato cylinder on digital electronic balance
  void placeSampleOnBalance(String sampleId, {required bool isInitial}) {
    state = _engine.processAction(state, PlaceSampleOnBalanceAction(sampleId, isInitial: isInitial));
  }

  /// Remove cylinder from balance pan
  void removeSampleFromBalance() {
    state = _engine.processAction(state, const RemoveSampleFromBalanceAction());
  }

  /// Immerse potato cylinder into boiling tube solution
  void immerseSample(String sampleId) {
    state = _engine.processAction(state, ImmerseSampleAction(sampleId));
  }

  /// Immerse all potato cylinders into boiling tubes
  void immerseAll() {
    state = _engine.processAction(state, const ImmerseAllSamplesAction());
  }

  /// Start osmotic incubation timer
  void startIncubation() {
    state = _engine.processAction(state, const StartOsmosisIncubationAction());
    _incubationTimer?.cancel();
    _incubationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isIncubating) {
        timer.cancel();
        return;
      }
      state = _engine.processAction(state, const TickOsmosisIncubationAction());
      if (state.isIncubationFinished) {
        timer.cancel();
      }
    });
  }

  /// Fast-forward / complete incubation instantly
  void completeIncubation() {
    _incubationTimer?.cancel();
    state = _engine.processAction(state, const CompleteOsmosisIncubationAction());
  }

  /// Blot potato cylinder on filter paper
  void blotSample(String sampleId) {
    state = _engine.processAction(state, BlotPotatoSampleAction(sampleId));
  }

  /// Blot all potato cylinders on filter paper
  void blotAll() {
    state = _engine.processAction(state, const BlotAllPotatoSamplesAction());
  }

  /// Set navigation step
  void setStep(OsmosisStep step) {
    state = _engine.processAction(state, SetOsmosisStepAction(step));
  }

  /// Set entered isotonic concentration
  void setEnteredIsotonic(double val) {
    state = _engine.processAction(state, SetEnteredIsotonicConcentrationAction(val));
  }

  /// Reset practical experiment
  void resetExperiment(PracticalMode mode) {
    _incubationTimer?.cancel();
    state = _engine.processAction(state, ResetOsmosisAction(mode));
  }

  /// Submit practical for scoring
  void submitPractical(double enteredIsotonic) {
    state = _engine.processAction(state, SubmitOsmosisPracticalAction(enteredIsotonic));
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _incubationTimer?.cancel();
    super.dispose();
  }
}
