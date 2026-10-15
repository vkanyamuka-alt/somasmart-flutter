import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/gas_preparation_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/gas_preparation_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  group('Laboratory Preparation of Gases Engine Tests', () {
    late GasPreparationEngine engine;

    setUp(() {
      engine = GasPreparationEngine();
    });

    test('Initial state metadata and defaults are valid', () {
      expect(engine.engineId, 'gas_preparation');
      expect(engine.practicalId, 'gas-prep');
      expect(engine.titleEn, 'Laboratory Preparation of Gases');
      expect(engine.titleSw, 'Utayarishaji wa Gesi Maabarani');
      expect(engine.subject, PracticalSubject.chemistry);

      final state = engine.createInitialState();
      expect(state.step, GasPrepStep.selectGas);
      expect(state.selectedGas, PreparedGasType.oxygen);
      expect(state.apparatus.length, 6);
      expect(state.allApparatusInspected, isFalse);
      expect(state.isSolidAdded, isFalse);
      expect(state.isLiquidAdded, isFalse);
      expect(state.isGenerating, isFalse);
      expect(state.collectedVolumeMl, 0.0);
      expect(state.isGasJarFull, isFalse);
      expect(state.isTestPerformed, isFalse);
      expect(state.testPassed, isFalse);
      expect(state.scoreResult, isNull);
    });

    test('Engine is registered in PracticalEngineRegistry for gas_preparation and gas-prep', () {
      final registry = PracticalEngineRegistry();
      expect(registry.isEngineRegistered('gas_preparation'), isTrue);
      expect(registry.isEngineRegistered('gas-prep'), isTrue);
      expect(registry.isEngineRegistered('gas_prep'), isTrue);
      expect(registry.isEngineRegistered('gas-preparation'), isTrue);

      final resolved = registry.resolveEngine('gas_preparation');
      expect(resolved, isNotNull);
      expect(resolved, isA<GasPreparationEngine>());

      final resolvedAlias = registry.resolveEngine('gas-prep');
      expect(resolvedAlias, isNotNull);
      expect(resolvedAlias, isA<GasPreparationEngine>());
    });

    test('Selecting different target gas updates chemical metadata and resets reactants', () {
      var state = engine.createInitialState();
      expect(state.selectedGas, PreparedGasType.oxygen);

      state = engine.processAction(state, const SelectGasTypeAction(PreparedGasType.carbonDioxide));
      expect(state.selectedGas, PreparedGasType.carbonDioxide);
      expect(state.selectedGas.formula, 'CO₂');
      expect(state.selectedGas.solidFormula, 'CaCO₃');
      expect(state.selectedGas.liquidFormula, '2.0M HCl');

      state = engine.processAction(state, const SelectGasTypeAction(PreparedGasType.hydrogen));
      expect(state.selectedGas, PreparedGasType.hydrogen);
      expect(state.selectedGas.formula, 'H₂');
      expect(state.selectedGas.solidFormula, 'Zn');
      expect(state.selectedGas.liquidFormula, '2.0M HCl');
    });

    test('Apparatus inspection toggles inspected state for all 6 items', () {
      var state = engine.createInitialState();
      expect(state.allApparatusInspected, isFalse);

      final itemIds = [
        'generator_flask',
        'thistle_funnel',
        'delivery_tube',
        'pneumatic_trough',
        'beehive_shelf',
        'gas_jar',
      ];
      for (final id in itemIds) {
        state = engine.processAction(state, InspectGasApparatusAction(id));
      }

      expect(state.allApparatusInspected, isTrue);
      expect(state.apparatus.where((i) => i.inspected).length, 6);
    });

    test('Inspect all action sets all items to inspected', () {
      var state = engine.createInitialState();
      expect(state.allApparatusInspected, isFalse);

      state = engine.processAction(state, const InspectAllGasApparatusAction());
      expect(state.allApparatusInspected, isTrue);
      expect(state.apparatus.every((i) => i.inspected), isTrue);
    });

    test('Reactant workflow: adding solid then liquid initiates gas generation', () {
      var state = engine.createInitialState();

      state = engine.processAction(state, const AddSolidReactantAction());
      expect(state.isSolidAdded, isTrue);
      expect(state.isLiquidAdded, isFalse);
      expect(state.isGenerating, isFalse);

      state = engine.processAction(state, const AddLiquidReactantAction());
      expect(state.isLiquidAdded, isTrue);
      expect(state.isGenerating, isTrue);
    });

    test('Gas generation ticks volume up to 100 mL and sets isGasJarFull', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const AddSolidReactantAction());
      state = engine.processAction(state, const AddLiquidReactantAction());

      expect(state.collectedVolumeMl, 0.0);
      expect(state.isGasJarFull, isFalse);

      for (int i = 0; i < 20; i++) {
        state = engine.processAction(state, const TickGasGenerationAction(deltaVolume: 5.0));
      }

      expect(state.collectedVolumeMl, 100.0);
      expect(state.isGasJarFull, isTrue);
      expect(state.isGenerating, isFalse);
    });

    test('CompleteGasCollectionAction immediately fills gas jar to 100 mL', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const CompleteGasCollectionAction());

      expect(state.collectedVolumeMl, 100.0);
      expect(state.isGasJarFull, isTrue);
      expect(state.isGenerating, isFalse);
    });

    test('Confirmatory gas test passes if gas jar is full', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const CompleteGasCollectionAction());

      state = engine.processAction(state, const PerformGasTestAction());
      expect(state.isTestPerformed, isTrue);
      expect(state.testPassed, isTrue);
    });

    test('Confirmatory gas test fails if gas jar is empty', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const PerformGasTestAction());
      expect(state.isTestPerformed, isTrue);
      expect(state.testPassed, isFalse);
    });

    test('Submitting practical calculates complete score result with 100% mastery', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const InspectAllGasApparatusAction());
      state = engine.processAction(state, const AddSolidReactantAction());
      state = engine.processAction(state, const AddLiquidReactantAction());
      state = engine.processAction(state, const CompleteGasCollectionAction());
      state = engine.processAction(state, const PerformGasTestAction());

      state = engine.processAction(state, const SubmitGasPracticalAction());

      expect(state.scoreResult, isNotNull);
      expect(state.scoreResult!.totalScore, 100);
      expect(state.scoreResult!.grade.startsWith('A'), isTrue);
      expect(state.scoreResult!.competencies.length, 5);
      expect(state.scoreResult!.achievementsEn.isNotEmpty, isTrue);
    });

    test('Reset returns fresh initial state for given mode', () {
      var state = engine.createInitialState();
      state = engine.processAction(state, const InspectAllGasApparatusAction());
      state = engine.processAction(state, const CompleteGasCollectionAction());

      final resetState = engine.reset(PracticalMode.examMode);
      expect(resetState.practicalMode, PracticalMode.examMode);
      expect(resetState.allApparatusInspected, isFalse);
      expect(resetState.collectedVolumeMl, 0.0);
      expect(resetState.isGasJarFull, isFalse);
      expect(resetState.scoreResult, isNull);
    });
  });
}
