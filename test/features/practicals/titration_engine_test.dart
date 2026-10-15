import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/titration_state.dart';
import 'package:somasmart_flutter/features/practicals/domain/titration_engine.dart';

void main() {
  group('Acid-Base Titration Engine Tests', () {
    late AcidBaseTitrationEngine engine;

    setUp(() {
      engine = AcidBaseTitrationEngine();
    });

    test('Initial State is correctly configured for Guided Practice', () {
      final state = engine.createInitialState(PracticalMode.guidedPractice);
      expect(state.mode, equals(PracticalMode.guidedPractice));
      expect(state.currentStepIndex, equals(0));
      expect(state.isCompleted, isFalse);
      expect(state.buretteFilled, isFalse);
      expect(state.buretteReading, equals(0.0));
      expect(state.flaskVolume, equals(0.0));
      expect(state.pipetteVolume, equals(0.0));
      expect(state.indicatorAdded, isFalse);
      expect(state.flaskPositioned, isFalse);
      expect(state.volumeDelivered, equals(0.0));
      expect(state.stopcockState, equals(StopcockState.closed));
      expect(state.flaskColorStage, equals(FlaskColorStage.colourless));
      expect(state.canAdvanceStep(), isFalse); // Needs 4 items inspected
    });

    test('Step 0: Inspection requires at least 4 apparatus items to unlock next step', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      expect(state.canAdvanceStep(), isFalse);

      state = engine.processAction(state, const InspectItemAction('burette'));
      state = engine.processAction(state, const InspectItemAction('flask'));
      state = engine.processAction(state, const InspectItemAction('pipette'));
      expect(state.canAdvanceStep(), isFalse); // 3 items

      state = engine.processAction(state, const InspectItemAction('naoh'));
      expect(state.inspectedItems.length, equals(4));
      expect(state.canAdvanceStep(), isTrue); // 4 items -> can advance
    });

    test('Step 1: Fill Burette sets buretteFilled to true and reading to 0.00 mL', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const FillBuretteAction());
      expect(state.buretteFilled, isTrue);
      expect(state.buretteReading, equals(0.0));
    });

    test('Step 2: Pipette suction and transfer properly fills flask to 25.0 mL', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const SelectPipetteAction());
      expect(state.pipetteStep, equals(1));

      state = engine.processAction(state, const AttachPipetteBulbAction());
      expect(state.pipetteStep, equals(2));

      state = engine.processAction(state, const InsertPipetteInHClAction());
      expect(state.pipetteStep, equals(3));

      // Suction to 25.0 mL
      for (int i = 0; i < 50; i++) {
        state = engine.processAction(state, const DrawHClAction(0.5));
      }
      expect(state.pipetteVolume, equals(25.0));
      expect(state.pipetteStep, equals(4));

      state = engine.processAction(state, const PositionPipetteAboveFlaskAction());
      expect(state.pipetteStep, equals(5));

      // Transfer into flask
      for (int i = 0; i < 50; i++) {
        state = engine.processAction(state, const TransferHClToFlaskAction(0.5));
      }
      expect(state.pipetteVolume, equals(0.0));
      expect(state.flaskVolume, equals(25.0));
      expect(state.pipetteStep, equals(7));
    });

    test('Step 3: Indicator addition requires 3 drops before indicatorAdded is true', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = engine.processAction(state, const SelectIndicatorBottleAction());
      state = engine.processAction(state, const PositionDropperAboveFlaskAction());

      state = engine.processAction(state, const AddIndicatorDropAction());
      expect(state.indicatorDropsCount, equals(1));
      expect(state.indicatorAdded, isFalse);

      state = engine.processAction(state, const AddIndicatorDropAction());
      expect(state.indicatorDropsCount, equals(2));
      expect(state.indicatorAdded, isFalse);

      state = engine.processAction(state, const AddIndicatorDropAction());
      expect(state.indicatorDropsCount, equals(3));
      expect(state.indicatorAdded, isTrue);

      // Attempting to add a 4th drop is ignored
      state = engine.processAction(state, const AddIndicatorDropAction());
      expect(state.indicatorDropsCount, equals(3));
    });

    test('Step 5: Delivery rates and max 26.00 mL clamping behavior', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(
        buretteFilled: true,
        flaskVolume: 25.0,
        indicatorAdded: true,
        flaskPositioned: true,
      );

      // Single drop increments by 0.05 mL
      state = engine.processAction(state, const DeliverSingleDropAction());
      expect(state.volumeDelivered, closeTo(0.05, 0.001));
      expect(state.buretteReading, closeTo(0.05, 0.001));

      // Flow mode increments by 0.20 mL
      state = engine.processAction(state, const SetStopcockStateAction(StopcockState.flow));
      state = engine.processAction(state, const DeliverTitrantTickAction());
      expect(state.volumeDelivered, closeTo(0.25, 0.001));

      // Slow mode increments by 0.05 mL
      state = engine.processAction(state, const SetStopcockStateAction(StopcockState.slow));
      state = engine.processAction(state, const DeliverTitrantTickAction());
      expect(state.volumeDelivered, closeTo(0.30, 0.001));

      // Test Max limit clamp at 26.00 mL
      state = state.copyWith(volumeDelivered: 25.90, stopcockState: StopcockState.flow);
      state = engine.processAction(state, const DeliverTitrantTickAction());
      expect(state.volumeDelivered, equals(26.00));
      expect(state.stopcockState, equals(StopcockState.closed)); // Automatically closes
    });

    test('Exact Endpoint Boundaries and Swirling Color Transitions', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(flaskVolume: 25.0, indicatorAdded: true);

      // 1. V = 23.99 mL -> Colourless
      state = state.copyWith(volumeDelivered: 23.99, hasSwirledAtCurrentVolume: false);
      expect(state.flaskColorStage, equals(FlaskColorStage.colourless));

      // 2. V = 24.00 mL unswirled -> Temporary Pink Flash
      state = state.copyWith(volumeDelivered: 24.00, hasSwirledAtCurrentVolume: false);
      expect(state.flaskColorStage, equals(FlaskColorStage.pinkFlash));

      // 3. V = 24.00 mL swirled -> Returns to Colourless
      state = engine.processAction(state, const SwirlFlaskAction());
      state = engine.processAction(state, const FinishSwirlingAction());
      expect(state.hasSwirledAtCurrentVolume, isTrue);
      expect(state.flaskColorStage, equals(FlaskColorStage.colourless));

      // 4. V = 24.44 mL swirled -> Remains Colourless
      state = state.copyWith(volumeDelivered: 24.44, hasSwirledAtCurrentVolume: true);
      expect(state.flaskColorStage, equals(FlaskColorStage.colourless));

      // 5. V = 24.45 mL -> Permanent Pale Pink (Endpoint)
      state = state.copyWith(volumeDelivered: 24.45);
      expect(state.flaskColorStage, equals(FlaskColorStage.permanentPalePink));

      // 6. V = 24.50 mL -> Permanent Pale Pink (Theoretical Endpoint)
      state = state.copyWith(volumeDelivered: 24.50);
      expect(state.flaskColorStage, equals(FlaskColorStage.permanentPalePink));

      // 7. V = 24.75 mL -> Permanent Pale Pink (Upper boundary)
      state = state.copyWith(volumeDelivered: 24.75);
      expect(state.flaskColorStage, equals(FlaskColorStage.permanentPalePink));

      // 8. V = 24.76 mL -> Dark Magenta (Overshot)
      state = state.copyWith(volumeDelivered: 24.76);
      expect(state.flaskColorStage, equals(FlaskColorStage.darkMagenta));

      // 9. V = 26.00 mL -> Dark Magenta
      state = state.copyWith(volumeDelivered: 26.00);
      expect(state.flaskColorStage, equals(FlaskColorStage.darkMagenta));
    });

    test('Molarity Calculations & Scoring Rubric (100, 95, 85)', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(volumeDelivered: 24.50, elapsedSeconds: 300);

      // Perfect accuracy (0.0980 M) -> 100% / A+
      state = engine.processAction(
        state,
        const SubmitCalculationsAction(
          calculatedTitre: '24.50',
          calculatedMolarity: '0.0980',
        ),
      );
      expect(state.isCompleted, isTrue);
      expect(state.scoreResult, isNotNull);
      expect(state.scoreResult?.totalScore, equals(100));
      expect(state.scoreResult?.grade, contains('Distinction'));

      // < 5% error (0.0970 M) -> 95% / A+
      var state2 = engine.createInitialState(PracticalMode.guidedPractice);
      state2 = state2.copyWith(volumeDelivered: 24.50, elapsedSeconds: 300);
      state2 = engine.processAction(
        state2,
        const SubmitCalculationsAction(
          calculatedTitre: '24.50',
          calculatedMolarity: '0.0970',
        ),
      );
      expect(state2.scoreResult?.totalScore, equals(95));
      expect(state2.scoreResult?.grade, contains('Distinction'));

      // >= 5% error (0.0800 M) -> 85% / Credit
      var state3 = engine.createInitialState(PracticalMode.guidedPractice);
      state3 = state3.copyWith(volumeDelivered: 24.50, elapsedSeconds: 300);
      state3 = engine.processAction(
        state3,
        const SubmitCalculationsAction(
          calculatedTitre: '24.50',
          calculatedMolarity: '0.0800',
        ),
      );
      expect(state3.scoreResult?.totalScore, equals(85));
      expect(state3.scoreResult?.grade, contains('Credit'));
    });

    test('Reset action restores initial state', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(
        currentStepIndex: 5,
        buretteFilled: true,
        volumeDelivered: 24.50,
      );

      state = engine.processAction(state, const ResetTitrationAction());
      expect(state.currentStepIndex, equals(0));
      expect(state.buretteFilled, isFalse);
      expect(state.volumeDelivered, equals(0.0));
      expect(state.isCompleted, isFalse);
    });
  });
}
