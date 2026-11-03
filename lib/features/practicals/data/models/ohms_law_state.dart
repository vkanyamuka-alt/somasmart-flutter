import 'practical_model.dart';
import 'practical_score_result.dart';

class CircuitReading {
  final int trialNumber;
  final double voltage; // Volts (V)
  final double current; // Amperes (A)
  final double calculatedResistance; // Ohms (Ω)

  const CircuitReading({
    required this.trialNumber,
    required this.voltage,
    required this.current,
    required this.calculatedResistance,
  });
}

class OhmsLawState {
  final PracticalMode mode;
  final int currentStepIndex; // 0 to 5 (6 total steps)
  final bool isCompleted;
  final int elapsedSeconds;

  // Equipment inspection state (Step 0)
  final Set<String> inspectedItems;
  final String? selectedInspectItemKey;

  // Circuit assembly & connection (Step 1)
  final bool circuitConnected;

  // Circuit simulation state (Step 2 & 3)
  final bool isSwitchClosed;
  final double voltageSetting; // the cells in use: 1.5, 3.0, 4.5 or 6.0 V
  final double knownResistance; // Fixed standard resistor = 10.0 Ω
  final double measuredVoltage; // Voltmeter reading (V)
  final double measuredCurrent; // Ammeter reading (A)

  // Experimental Readings Table (Step 3 & 4)
  final List<CircuitReading> recordedReadings;

  // Slope & calculations (Step 5)
  final String slopeCalculationInput;
  final String calculatedResistanceInput;
  final bool calculationSubmitted;
  final PracticalScoreResult? scoreResult;

  // Dynamic log entries
  final List<String> notebookLogs;

  const OhmsLawState({
    required this.mode,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.inspectedItems = const {},
    this.selectedInspectItemKey,
    this.circuitConnected = false,
    this.isSwitchClosed = false,
    this.voltageSetting = 1.5,
    this.knownResistance = 10.0,
    this.measuredVoltage = 0.0,
    this.measuredCurrent = 0.0,
    this.recordedReadings = const [],
    this.slopeCalculationInput = '',
    this.calculatedResistanceInput = '',
    this.calculationSubmitted = false,
    this.scoreResult,
    this.notebookLogs = const ['• Virtual Laboratory initialized for Ohm’s Law Verification.'],
  });

  bool get isCircuitActive => circuitConnected && isSwitchClosed && voltageSetting > 0;

  /// The number of 1.5 V dry cells in the circuit (1 to 4).
  int get cells => (voltageSetting / 1.5).round().clamp(1, 4);

  String get observationMessageEn {
    if (!circuitConnected) {
      return 'The circuit is not connected yet. The ammeter goes in series with the resistor, the voltmeter in parallel across it.';
    }
    if (!isSwitchClosed) {
      return 'The key is open, so no current flows and both needles rest at zero.';
    }
    if (measuredCurrent > 0) {
      return 'Key closed: the voltmeter reads ${measuredVoltage.toStringAsFixed(2)} V and the ammeter ${measuredCurrent.toStringAsFixed(3)} A.';
    }
    return 'Choose how many dry cells to use, then read both meters.';
  }

  String get observationMessageSw {
    if (!circuitConnected) {
      return 'Saketi haijaunganishwa. Ammita huwekwa mfululizo na kikinza, voltimita sambamba nacho.';
    }
    if (!isSwitchClosed) {
      return 'Ufunguo uko wazi, hivyo hakuna mkondo na sindano zote ziko kwenye sifuri.';
    }
    if (measuredCurrent > 0) {
      return 'Ufunguo umefungwa: voltimita inasoma ${measuredVoltage.toStringAsFixed(2)} V na ammita ${measuredCurrent.toStringAsFixed(3)} A.';
    }
    return 'Chagua idadi ya seli kavu, kisha soma mita zote mbili.';
  }

  bool canAdvanceStep() {
    if (mode == PracticalMode.freeExploration) return true;
    switch (currentStepIndex) {
      case 0:
        return inspectedItems.length >= 4;
      case 1:
        return circuitConnected;
      case 2:
        return isSwitchClosed;
      case 3:
        return recordedReadings.length >= 3;
      case 4:
        return recordedReadings.length >= 3;
      case 5:
        return calculationSubmitted;
      default:
        return true;
    }
  }

  OhmsLawState copyWith({
    PracticalMode? mode,
    int? currentStepIndex,
    bool? isCompleted,
    int? elapsedSeconds,
    Set<String>? inspectedItems,
    String? selectedInspectItemKey,
    bool? circuitConnected,
    bool? isSwitchClosed,
    double? voltageSetting,
    double? knownResistance,
    double? measuredVoltage,
    double? measuredCurrent,
    List<CircuitReading>? recordedReadings,
    String? slopeCalculationInput,
    String? calculatedResistanceInput,
    bool? calculationSubmitted,
    PracticalScoreResult? scoreResult,
    List<String>? notebookLogs,
  }) {
    return OhmsLawState(
      mode: mode ?? this.mode,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      inspectedItems: inspectedItems ?? this.inspectedItems,
      selectedInspectItemKey: selectedInspectItemKey,
      circuitConnected: circuitConnected ?? this.circuitConnected,
      isSwitchClosed: isSwitchClosed ?? this.isSwitchClosed,
      voltageSetting: voltageSetting ?? this.voltageSetting,
      knownResistance: knownResistance ?? this.knownResistance,
      measuredVoltage: measuredVoltage ?? this.measuredVoltage,
      measuredCurrent: measuredCurrent ?? this.measuredCurrent,
      recordedReadings: recordedReadings ?? this.recordedReadings,
      slopeCalculationInput: slopeCalculationInput ?? this.slopeCalculationInput,
      calculatedResistanceInput: calculatedResistanceInput ?? this.calculatedResistanceInput,
      calculationSubmitted: calculationSubmitted ?? this.calculationSubmitted,
      scoreResult: scoreResult ?? this.scoreResult,
      notebookLogs: notebookLogs ?? this.notebookLogs,
    );
  }
}
