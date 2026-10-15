import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import '../data/models/ohms_law_state.dart';
import 'practical_simulation_engine.dart';

abstract class OhmsLawAction {
  const OhmsLawAction();
}

class InspectOhmsItemAction extends OhmsLawAction {
  final String itemKey;
  const InspectOhmsItemAction(this.itemKey);
}

class ConnectCircuitAction extends OhmsLawAction {
  const ConnectCircuitAction();
}

class ToggleSwitchAction extends OhmsLawAction {
  final bool isClosed;
  const ToggleSwitchAction(this.isClosed);
}

class SetVoltageAction extends OhmsLawAction {
  final double voltage;
  const SetVoltageAction(this.voltage);
}

class RecordCurrentReadingAction extends OhmsLawAction {
  const RecordCurrentReadingAction();
}

class DeleteReadingAction extends OhmsLawAction {
  final int index;
  const DeleteReadingAction(this.index);
}

class ResetReadingsAction extends OhmsLawAction {
  const ResetReadingsAction();
}

class NextStepAction extends OhmsLawAction {
  const NextStepAction();
}

class PreviousStepAction extends OhmsLawAction {
  const PreviousStepAction();
}

class SetStepIndexAction extends OhmsLawAction {
  final int stepIndex;
  const SetStepIndexAction(this.stepIndex);
}

class SubmitCalculationAction extends OhmsLawAction {
  final String slope;
  final String calculatedResistance;
  const SubmitCalculationAction({
    required this.slope,
    required this.calculatedResistance,
  });
}

class TickTimerAction extends OhmsLawAction {
  const TickTimerAction();
}

class ResetEngineAction extends OhmsLawAction {
  final PracticalMode mode;
  const ResetEngineAction(this.mode);
}

/// Domain Engine for Ohm's Law Verification practical simulation.
/// Adheres to: V = I * R <=> I = V / R <=> R = V / I
class OhmsLawEngine implements PracticalSimulationEngine<OhmsLawState, OhmsLawAction> {
  @override
  String get engineId => 'ohms_law';

  @override
  String get titleEn => "Ohm's Law Verification";

  @override
  String get titleSw => "Uhakiki wa Sheria ya Ohm";

  @override
  PracticalSubject get subject => PracticalSubject.physics;

  @override
  List<PracticalMode> get supportedModes => [
    PracticalMode.guidedPractice,
    PracticalMode.examMode,
    PracticalMode.freeExploration,
  ];

  @override
  OhmsLawState createInitialState(PracticalMode mode) {
    return OhmsLawState(
      mode: mode,
      currentStepIndex: 0,
      isCompleted: false,
      elapsedSeconds: 0,
      inspectedItems: const {},
      circuitConnected: mode == PracticalMode.freeExploration, // Auto-connect in free exploration
      isSwitchClosed: false,
      voltageSetting: 1.0,
      knownResistance: 10.0,
      measuredVoltage: 0.0,
      measuredCurrent: 0.0,
      recordedReadings: const [],
      slopeCalculationInput: '',
      calculatedResistanceInput: '',
      calculationSubmitted: false,
      scoreResult: null,
      notebookLogs: const ['• Virtual Laboratory initialized for Ohm’s Law Verification.'],
    );
  }

  @override
  OhmsLawState processAction(OhmsLawState currentState, OhmsLawAction action) {
    if (action is ResetEngineAction) {
      return createInitialState(action.mode);
    }

    if (action is TickTimerAction) {
      return currentState.copyWith(elapsedSeconds: currentState.elapsedSeconds + 1);
    }

    if (action is InspectOhmsItemAction) {
      final updatedInspected = Set<String>.from(currentState.inspectedItems)..add(action.itemKey);
      final logs = List<String>.from(currentState.notebookLogs);
      final itemName = _getApparatusName(action.itemKey);
      logs.add('• Inspected $itemName: ${_getApparatusDescription(action.itemKey)}');

      return currentState.copyWith(
        inspectedItems: updatedInspected,
        selectedInspectItemKey: action.itemKey,
        notebookLogs: logs,
      );
    }

    if (action is ConnectCircuitAction) {
      final logs = List<String>.from(currentState.notebookLogs);
      logs.add('• Circuit assembled: Connected Power Supply, Standard Resistor (10.0 Ω), Ammeter in series, and Voltmeter in parallel.');
      return currentState.copyWith(
        circuitConnected: true,
        notebookLogs: logs,
      );
    }

    if (action is ToggleSwitchAction) {
      final isClosed = action.isClosed;
      final logs = List<String>.from(currentState.notebookLogs);
      
      double measuredV = 0.0;
      double measuredI = 0.0;

      if (isClosed && currentState.circuitConnected) {
        measuredV = currentState.voltageSetting;
        measuredI = _computeCurrent(measuredV, currentState.knownResistance);
        logs.add('• Switch CLOSED. Voltage = ${measuredV.toStringAsFixed(2)} V, Current = ${measuredI.toStringAsFixed(3)} A.');
      } else {
        logs.add('• Switch OPENED. Circuit is de-energized (I = 0.00 A).');
      }

      return currentState.copyWith(
        isSwitchClosed: isClosed,
        measuredVoltage: measuredV,
        measuredCurrent: measuredI,
        notebookLogs: logs,
      );
    }

    if (action is SetVoltageAction) {
      final newV = action.voltage.clamp(0.0, 10.0);
      double measuredV = 0.0;
      double measuredI = 0.0;

      if (currentState.isSwitchClosed && currentState.circuitConnected) {
        measuredV = newV;
        measuredI = _computeCurrent(measuredV, currentState.knownResistance);
      }

      return currentState.copyWith(
        voltageSetting: newV,
        measuredVoltage: measuredV,
        measuredCurrent: measuredI,
      );
    }

    if (action is RecordCurrentReadingAction) {
      if (!currentState.circuitConnected || !currentState.isSwitchClosed) {
        return currentState;
      }

      final currentV = currentState.measuredVoltage;
      final currentI = currentState.measuredCurrent;
      final calculatedR = currentI > 0 ? (currentV / currentI) : 0.0;

      final updatedReadings = List<CircuitReading>.from(currentState.recordedReadings);
      final newTrialIndex = updatedReadings.length + 1;

      // Avoid duplicates with identical voltage
      final exists = updatedReadings.any((r) => (r.voltage - currentV).abs() < 0.05);
      if (!exists) {
        updatedReadings.add(CircuitReading(
          trialNumber: newTrialIndex,
          voltage: currentV,
          current: currentI,
          calculatedResistance: double.parse(calculatedR.toStringAsFixed(2)),
        ));

        final logs = List<String>.from(currentState.notebookLogs);
        logs.add('• Recorded Trial #$newTrialIndex: V = ${currentV.toStringAsFixed(2)} V, I = ${currentI.toStringAsFixed(3)} A, R = ${calculatedR.toStringAsFixed(2)} Ω.');

        return currentState.copyWith(
          recordedReadings: updatedReadings,
          notebookLogs: logs,
        );
      }
      return currentState;
    }

    if (action is DeleteReadingAction) {
      if (action.index >= 0 && action.index < currentState.recordedReadings.length) {
        final updatedReadings = List<CircuitReading>.from(currentState.recordedReadings)..removeAt(action.index);
        return currentState.copyWith(recordedReadings: updatedReadings);
      }
      return currentState;
    }

    if (action is ResetReadingsAction) {
      return currentState.copyWith(recordedReadings: const []);
    }

    if (action is NextStepAction) {
      final nextIdx = (currentState.currentStepIndex + 1).clamp(0, 5);
      return currentState.copyWith(currentStepIndex: nextIdx);
    }

    if (action is PreviousStepAction) {
      final prevIdx = (currentState.currentStepIndex - 1).clamp(0, 5);
      return currentState.copyWith(currentStepIndex: prevIdx);
    }

    if (action is SetStepIndexAction) {
      return currentState.copyWith(currentStepIndex: action.stepIndex.clamp(0, 5));
    }

    if (action is SubmitCalculationAction) {
      final logs = List<String>.from(currentState.notebookLogs);
      logs.add('• Submitted calculations: Slope = ${action.slope} Ω, Calculated R = ${action.calculatedResistance} Ω.');

      final nextState = currentState.copyWith(
        slopeCalculationInput: action.slope,
        calculatedResistanceInput: action.calculatedResistance,
        calculationSubmitted: true,
      );

      final score = calculateScore(nextState);
      return nextState.copyWith(
        isCompleted: true,
        scoreResult: score,
      );
    }

    return currentState;
  }

  /// Calculates the expected theoretical current: I = V / R
  static double _computeCurrent(double voltage, double resistance) {
    if (resistance <= 0) return 0.0;
    final current = voltage / resistance;
    // Round to 3 decimal places
    return double.parse(current.toStringAsFixed(3));
  }

  /// Calculates experimental slope: ΔV / ΔI from recorded readings
  static double calculateExperimentalSlope(List<CircuitReading> readings) {
    if (readings.length < 2) return 10.0;
    // Linear regression slope: Σ((x - x̄)(y - ȳ)) / Σ((x - x̄)²)
    // Here x = current (I), y = voltage (V) => slope = R
    double sumI = 0.0;
    double sumV = 0.0;
    for (final r in readings) {
      sumI += r.current;
      sumV += r.voltage;
    }
    final n = readings.length;
    final meanI = sumI / n;
    final meanV = sumV / n;

    double numerator = 0.0;
    double denominator = 0.0;
    for (final r in readings) {
      final diffI = r.current - meanI;
      final diffV = r.voltage - meanV;
      numerator += diffI * diffV;
      denominator += diffI * diffI;
    }

    if (denominator == 0) return 10.0;
    return numerator / denominator;
  }

  @override
  OhmsLawState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  PracticalScoreResult calculateScore(OhmsLawState currentState) {
    if (currentState.scoreResult != null) {
      return currentState.scoreResult!;
    }
    final parsedR = double.tryParse(currentState.calculatedResistanceInput.trim()) ??
        double.tryParse(currentState.slopeCalculationInput.trim()) ??
        currentState.knownResistance;

    return PracticalScoreResult.calculateOhmsLawScore(
      studentResistance: parsedR,
      theoreticalResistance: currentState.knownResistance,
      recordedReadingsCount: currentState.recordedReadings.length,
      inspectedCount: currentState.inspectedItems.length,
      durationSeconds: currentState.elapsedSeconds,
    );
  }

  static String _getApparatusName(String key) {
    switch (key) {
      case 'battery':
        return 'DC Power Supply';
      case 'resistor':
        return 'Standard Resistor (10.0 Ω)';
      case 'ammeter':
        return 'Digital Ammeter';
      case 'voltmeter':
        return 'Digital Voltmeter';
      case 'switch':
        return 'Single-Pole Knife Switch';
      case 'wires':
        return 'Copper Connecting Wires';
      default:
        return 'Apparatus';
    }
  }

  static String _getApparatusDescription(String key) {
    switch (key) {
      case 'battery':
        return 'Provides variable direct current voltage (0.0 V - 6.0 V) to power the circuit.';
      case 'resistor':
        return 'Standard ohmic resistor of fixed resistance R = 10.0 Ω obeying Ohm’s Law.';
      case 'ammeter':
        return 'Connected in series with the resistor to measure current (I) in amperes (A).';
      case 'voltmeter':
        return 'Connected in parallel across the resistor to measure potential difference (V) in volts (V).';
      case 'switch':
        return 'Closes or opens the electrical loop to initiate or interrupt current flow.';
      case 'wires':
        return 'Insulated low-resistance copper wires linking all components into a closed circuit.';
      default:
        return 'Standard physics laboratory equipment.';
    }
  }
}
