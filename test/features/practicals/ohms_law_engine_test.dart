import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/ohms_law_state.dart';
import 'package:somasmart_flutter/features/practicals/domain/ohms_law_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  group("Ohm's Law Verification Engine Tests", () {
    late OhmsLawEngine engine;

    setUp(() {
      engine = OhmsLawEngine();
    });

    test('Initial State is correctly configured for Guided Practice', () {
      final state = engine.createInitialState(PracticalMode.guidedPractice);
      expect(state.mode, equals(PracticalMode.guidedPractice));
      expect(state.currentStepIndex, equals(0));
      expect(state.isCompleted, isFalse);
      expect(state.circuitConnected, isFalse);
      expect(state.isSwitchClosed, isFalse);
      expect(state.voltageSetting, equals(1.0));
      expect(state.knownResistance, equals(10.0));
      expect(state.measuredVoltage, equals(0.0));
      expect(state.measuredCurrent, equals(0.0));
      expect(state.recordedReadings, isEmpty);
      expect(state.canAdvanceStep(), isFalse); // Requires apparatus inspection
    });

    test('Step 0: Inspection requires >= 4 apparatus items to unlock advance', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      expect(state.canAdvanceStep(), isFalse);

      state = engine.processAction(state, const InspectOhmsItemAction('battery'));
      state = engine.processAction(state, const InspectOhmsItemAction('resistor'));
      state = engine.processAction(state, const InspectOhmsItemAction('ammeter'));
      expect(state.canAdvanceStep(), isFalse); // 3 items

      state = engine.processAction(state, const InspectOhmsItemAction('voltmeter'));
      expect(state.inspectedItems.length, equals(4));
      expect(state.canAdvanceStep(), isTrue); // 4 items -> can advance
    });

    test('Step 1: Connecting circuit updates circuitConnected', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const SetStepIndexAction(1));
      expect(state.circuitConnected, isFalse);

      state = engine.processAction(state, const ConnectCircuitAction());
      expect(state.circuitConnected, isTrue);
      expect(state.canAdvanceStep(), isTrue);
    });

    test('Step 2 & Physics: Current is 0 when switch is OPEN, and I = V/R when switch is CLOSED', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const ConnectCircuitAction());
      state = engine.processAction(state, const SetVoltageAction(3.0));

      // With switch open, current must remain 0.0 A
      expect(state.isSwitchClosed, isFalse);
      expect(state.measuredCurrent, equals(0.0));

      // Close switch -> I = V / R = 3.0 V / 10.0 Ω = 0.300 A
      state = engine.processAction(state, const ToggleSwitchAction(true));
      expect(state.isSwitchClosed, isTrue);
      expect(state.measuredVoltage, equals(3.0));
      expect(state.measuredCurrent, equals(0.300));
      expect(state.isCircuitActive, isTrue);

      // Open switch -> current de-energizes to 0.0 A
      state = engine.processAction(state, const ToggleSwitchAction(false));
      expect(state.isSwitchClosed, isFalse);
      expect(state.measuredCurrent, equals(0.0));
      expect(state.isCircuitActive, isFalse);
    });

    test('Voltage variation dynamically recalculates current using V = I * R', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const ConnectCircuitAction());
      state = engine.processAction(state, const ToggleSwitchAction(true));

      // 1.0 V => 0.100 A
      state = engine.processAction(state, const SetVoltageAction(1.0));
      expect(state.measuredVoltage, equals(1.0));
      expect(state.measuredCurrent, equals(0.100));

      // 2.0 V => 0.200 A
      state = engine.processAction(state, const SetVoltageAction(2.0));
      expect(state.measuredVoltage, equals(2.0));
      expect(state.measuredCurrent, equals(0.200));

      // 5.0 V => 0.500 A
      state = engine.processAction(state, const SetVoltageAction(5.0));
      expect(state.measuredVoltage, equals(5.0));
      expect(state.measuredCurrent, equals(0.500));
    });

    test('Recording experimental readings populates table with R = V / I', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const SetStepIndexAction(3));
      state = engine.processAction(state, const ConnectCircuitAction());
      state = engine.processAction(state, const ToggleSwitchAction(true));

      // Record 1.0 V
      state = engine.processAction(state, const SetVoltageAction(1.0));
      state = engine.processAction(state, const RecordCurrentReadingAction());
      expect(state.recordedReadings.length, equals(1));
      expect(state.recordedReadings.first.voltage, equals(1.0));
      expect(state.recordedReadings.first.current, equals(0.100));
      expect(state.recordedReadings.first.calculatedResistance, equals(10.0));

      // Record 2.0 V
      state = engine.processAction(state, const SetVoltageAction(2.0));
      state = engine.processAction(state, const RecordCurrentReadingAction());
      expect(state.recordedReadings.length, equals(2));

      // Record 3.0 V
      state = engine.processAction(state, const SetVoltageAction(3.0));
      state = engine.processAction(state, const RecordCurrentReadingAction());
      expect(state.recordedReadings.length, equals(3));
      expect(state.canAdvanceStep(), isTrue);
    });

    test('Experimental Slope calculation computes linear gradient ΔV / ΔI correctly', () {
      final readings = [
        const CircuitReading(trialNumber: 1, voltage: 1.0, current: 0.100, calculatedResistance: 10.0),
        const CircuitReading(trialNumber: 2, voltage: 2.0, current: 0.200, calculatedResistance: 10.0),
        const CircuitReading(trialNumber: 3, voltage: 3.0, current: 0.300, calculatedResistance: 10.0),
        const CircuitReading(trialNumber: 4, voltage: 4.0, current: 0.400, calculatedResistance: 10.0),
      ];

      final slope = OhmsLawEngine.calculateExperimentalSlope(readings);
      expect(slope, closeTo(10.0, 0.001));
    });

    test('Calculation submission calculates final score and awards distinction for accurate results', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const InspectOhmsItemAction('battery'));
      state = engine.processAction(state, const InspectOhmsItemAction('resistor'));
      state = engine.processAction(state, const InspectOhmsItemAction('ammeter'));
      state = engine.processAction(state, const InspectOhmsItemAction('voltmeter'));
      state = engine.processAction(state, const ConnectCircuitAction());
      state = engine.processAction(state, const ToggleSwitchAction(true));

      // Add 4 trials
      for (double v = 1.0; v <= 4.0; v += 1.0) {
        state = engine.processAction(state, SetVoltageAction(v));
        state = engine.processAction(state, const RecordCurrentReadingAction());
      }

      state = engine.processAction(
        state,
        const SubmitCalculationAction(
          slope: '10.0',
          calculatedResistance: '10.0',
        ),
      );

      expect(state.isCompleted, isTrue);
      expect(state.scoreResult, isNotNull);
      expect(state.scoreResult!.totalScore, equals(100));
      expect(state.scoreResult!.grade, contains('Distinction'));
      expect(state.scoreResult!.errorPercentage, equals(0.0));
    });

    test('PracticalEngineRegistry registers and resolves both titration and ohms_law', () {
      final registry = PracticalEngineRegistry();
      registry.registerEngine(OhmsLawEngine());

      expect(registry.isEngineRegistered('ohms_law'), isTrue);
      expect(registry.isEngineRegistered('acid_base_titration'), isTrue);

      final ohmsEngine = registry.resolveEngine('ohms_law');
      expect(ohmsEngine, isNotNull);
      expect(ohmsEngine!.engineId, equals('ohms_law'));
      expect(ohmsEngine.subject, equals(PracticalSubject.physics));

      final physicsEngines = registry.getEnginesForSubject(PracticalSubject.physics);
      expect(physicsEngines.any((e) => e.engineId == 'ohms_law'), isTrue);
    });
  });
}
