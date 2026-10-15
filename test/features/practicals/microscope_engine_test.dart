import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/microscope_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/domain/microscope_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/practical_engine_registry.dart';

void main() {
  group('Light Microscope Practical Domain Engine Tests', () {
    late MicroscopeEngine engine;

    setUp(() {
      engine = MicroscopeEngine();
    });

    test('Engine metadata and subject alignment', () {
      expect(engine.engineId, 'microscope');
      expect(engine.titleEn, 'Light Microscope Plant Cell Staining');
      expect(engine.titleSw, 'Upakaji Rangi na Uchunguzi wa Seli za Mimea');
      expect(engine.subject, PracticalSubject.biology);
    });

    test('Initial state in Guided Practice requires apparatus inspection and preparation', () {
      final state = engine.createInitialState(PracticalMode.guidedPractice);

      expect(state.currentStep, MicroscopeStep.inspectApparatus);
      expect(state.inspectedItems.isEmpty, true);
      expect(state.isSpecimenPlaced, false);
      expect(state.appliedStain, StainType.none);
      expect(state.isCoverslipMounted, false);
      expect(state.isSlideOnStage, false);
      expect(state.isLightOn, false);
      expect(state.selectedObjective, MicroscopeObjective.low4x);
      expect(state.totalMagnification, 40);
      expect(state.isSlideFullyPrepared, false);
    });

    test('Initial state in Free Exploration provides ready-to-focus laboratory', () {
      final state = engine.createInitialState(PracticalMode.freeExploration);

      expect(state.currentStep, MicroscopeStep.adjustFocus);
      expect(state.isSpecimenPlaced, true);
      expect(state.appliedStain, StainType.iodine);
      expect(state.isCoverslipMounted, true);
      expect(state.isSlideOnStage, true);
      expect(state.isLightOn, true);
      expect(state.isSlideFullyPrepared, true);
    });

    test('Apparatus inspection unlocks slide mounting after 4 items', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);

      state = engine.processAction(state, const InspectMicroscopeApparatusAction('microscope'));
      state = engine.processAction(state, const InspectMicroscopeApparatusAction('glass_slide'));
      state = engine.processAction(state, const InspectMicroscopeApparatusAction('onion_peel'));
      expect(state.currentStep, MicroscopeStep.inspectApparatus);

      state = engine.processAction(state, const InspectMicroscopeApparatusAction('iodine_dropper'));
      expect(state.currentStep, MicroscopeStep.prepareSlide);
      expect(state.inspectedItems.length, 4);
    });

    test('Slide preparation sequence: specimen -> iodine stain -> coverslip -> stage', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(currentStep: MicroscopeStep.prepareSlide);

      // 1. Mount specimen
      state = engine.processAction(state, const PlaceSpecimenAction());
      expect(state.isSpecimenPlaced, true);
      expect(state.currentStep, MicroscopeStep.applyStain);

      // 2. Apply iodine stain
      state = engine.processAction(state, const ApplyStainAction(StainType.iodine));
      expect(state.appliedStain, StainType.iodine);
      expect(state.currentStep, MicroscopeStep.mountCoverslip);

      // 3. Lower coverslip with needle
      state = engine.processAction(state, const MountCoverslipAction());
      expect(state.isCoverslipMounted, true);
      expect(state.isSlideFullyPrepared, true);
      expect(state.currentStep, MicroscopeStep.placeOnStage);

      // 4. Place on stage
      state = engine.processAction(state, const PlaceSlideOnStageAction());
      expect(state.isSlideOnStage, true);
      expect(state.currentStep, MicroscopeStep.adjustIllumination);
    });

    test('Illumination adjustment enables optical transmission', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(
        currentStep: MicroscopeStep.adjustIllumination,
        isSlideOnStage: true,
      );

      state = engine.processAction(state, const SetLightIntensityAction(80.0));
      expect(state.isLightOn, true);
      expect(state.lightIntensity, 80.0);
      expect(state.currentStep, MicroscopeStep.adjustFocus);
    });

    test('Focus adjustment sharpness and focus lock', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(
        currentStep: MicroscopeStep.adjustFocus,
        isSlideOnStage: true,
        isLightOn: true,
        lightIntensity: 75.0,
        selectedObjective: MicroscopeObjective.low4x,
        coarseFocus: 10.0,
        fineFocus: 10.0,
      );

      expect(state.isInFocus, false);
      expect(state.sharpness < 0.5, true);

      // Dial in coarse focus to 45.0 and fine focus to 48.0 (optimal for 4x)
      state = engine.processAction(state, const SetCoarseFocusAction(45.0));
      state = engine.processAction(state, const SetFineFocusAction(48.0));

      expect(state.sharpness >= 0.85, true);
      expect(state.isInFocus, true);
      expect(state.currentStep, MicroscopeStep.switchMagnification);
    });

    test('Total optical magnification formula M = Eyepiece (10x) * Objective', () {
      var state = engine.createInitialState();

      state = engine.processAction(state, const SetObjectiveAction(MicroscopeObjective.low4x));
      expect(state.totalMagnification, 40);

      state = engine.processAction(state, const SetObjectiveAction(MicroscopeObjective.medium10x));
      expect(state.totalMagnification, 100);

      state = engine.processAction(state, const SetObjectiveAction(MicroscopeObjective.high40x));
      expect(state.totalMagnification, 400);
    });

    test('Organelle selection and scoring evaluation awards distinction', () {
      var state = engine.createInitialState(PracticalMode.guidedPractice);
      state = state.copyWith(
        currentStep: MicroscopeStep.recordObservations,
        isSpecimenPlaced: true,
        appliedStain: StainType.iodine,
        isCoverslipMounted: true,
        isSlideOnStage: true,
        isLightOn: true,
        coarseFocus: 55.0,
        fineFocus: 50.0,
        selectedObjective: MicroscopeObjective.high40x,
        inspectedItems: {'microscope', 'glass_slide', 'onion_peel', 'iodine_dropper'},
      );

      state = engine.processAction(state, const ToggleOrganelleSelectionAction('cell_wall'));
      state = engine.processAction(state, const ToggleOrganelleSelectionAction('nucleus'));
      state = engine.processAction(state, const ToggleOrganelleSelectionAction('cytoplasm'));
      state = engine.processAction(state, const ToggleOrganelleSelectionAction('vacuole'));

      expect(state.identifiedOrganelleIds.length, 4);

      // Student calculates M = 10 * 40 = 400x
      state = engine.processAction(state, const SubmitMicroscopeObservationsAction(400));

      expect(state.currentStep, MicroscopeStep.completed);
      expect(state.scoreResult != null, true);
      expect(state.scoreResult!.totalScore, 100);
      expect(state.scoreResult!.grade, 'A+ (Distinction)');
      expect(state.scoreResult!.errorPercentage, 0.0);
    });

    test('PracticalEngineRegistry registers and resolves microscope engine', () {
      final registry = PracticalEngineRegistry();

      expect(registry.isEngineRegistered('microscope'), true);
      expect(registry.isEngineRegistered('acid_base_titration'), true);
      expect(registry.isEngineRegistered('ohms_law'), true);

      final resolved = registry.resolveEngine('microscope');
      expect(resolved, isNotNull);
      expect(resolved is MicroscopeEngine, true);
      expect(resolved!.subject, PracticalSubject.biology);
    });
  });
}
