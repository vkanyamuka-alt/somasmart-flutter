import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';

/// The generic contract for all interactive virtual laboratory simulation engines.
/// Designed to support Chemistry, Physics, and Biology engines independently.
abstract class PracticalSimulationEngine<TState, TAction> {
  /// Unique identifier of the engine (e.g. 'acid_base_titration', 'ohms_law', 'microscope')
  String get engineId;

  /// Human-readable title of the simulation engine
  String get titleEn;
  String get titleSw;

  /// Associated subject
  PracticalSubject get subject;

  /// Supported practical modes (Guided Practice, Exam Mode, Free Exploration)
  List<PracticalMode> get supportedModes;

  /// Creates initial state for a new session
  TState createInitialState(PracticalMode mode);

  /// Processes an action and deterministically returns the next state
  TState processAction(TState currentState, TAction action);

  /// Calculates final score and scorecard when simulation is completed
  PracticalScoreResult calculateScore(TState currentState);

  /// Resets state back to initial state
  TState reset(PracticalMode mode) => createInitialState(mode);
}
