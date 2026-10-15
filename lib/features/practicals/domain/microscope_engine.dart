import '../data/models/microscope_state.dart';
import '../data/models/practical_model.dart';
import '../data/models/practical_score_result.dart';
import 'practical_simulation_engine.dart';

/// Base class for all microscope practical simulation actions
abstract class MicroscopeAction {
  const MicroscopeAction();
}

class InspectMicroscopeApparatusAction extends MicroscopeAction {
  final String itemId;
  const InspectMicroscopeApparatusAction(this.itemId);
}

class PlaceSpecimenAction extends MicroscopeAction {
  const PlaceSpecimenAction();
}

class ApplyStainAction extends MicroscopeAction {
  final StainType stain;
  const ApplyStainAction(this.stain);
}

class MountCoverslipAction extends MicroscopeAction {
  const MountCoverslipAction();
}

class PlaceSlideOnStageAction extends MicroscopeAction {
  const PlaceSlideOnStageAction();
}

class SetLightIntensityAction extends MicroscopeAction {
  final double intensity;
  const SetLightIntensityAction(this.intensity);
}

class SetCoarseFocusAction extends MicroscopeAction {
  final double coarseFocus;
  const SetCoarseFocusAction(this.coarseFocus);
}

class SetFineFocusAction extends MicroscopeAction {
  final double fineFocus;
  const SetFineFocusAction(this.fineFocus);
}

class SetObjectiveAction extends MicroscopeAction {
  final MicroscopeObjective objective;
  const SetObjectiveAction(this.objective);
}

class ToggleOrganelleSelectionAction extends MicroscopeAction {
  final String organelleId;
  const ToggleOrganelleSelectionAction(this.organelleId);
}

class SubmitMicroscopeObservationsAction extends MicroscopeAction {
  final int calculatedMagnification;
  const SubmitMicroscopeObservationsAction(this.calculatedMagnification);
}

class ResetMicroscopeAction extends MicroscopeAction {
  const ResetMicroscopeAction();
}

/// Pure Dart Domain Engine for Light Microscope Plant Cell Staining practical.
/// Contains no UI/Flutter dependencies, implementing mathematical, biological, and step-transition rules.
class MicroscopeEngine implements PracticalSimulationEngine<MicroscopeState, MicroscopeAction> {
  @override
  String get engineId => 'microscope';

  @override
  String get titleEn => 'Light Microscope Plant Cell Staining';

  @override
  String get titleSw => 'Upakaji Rangi na Uchunguzi wa Seli za Mimea';

  @override
  PracticalSubject get subject => PracticalSubject.biology;

  @override
  List<PracticalMode> get supportedModes => const [
        PracticalMode.guidedPractice,
        PracticalMode.examMode,
        PracticalMode.freeExploration,
      ];

  @override
  MicroscopeState createInitialState([PracticalMode mode = PracticalMode.guidedPractice]) {
    return MicroscopeState(
      mode: mode,
      currentStep: mode == PracticalMode.freeExploration
          ? MicroscopeStep.adjustFocus
          : MicroscopeStep.inspectApparatus,
      isSpecimenPlaced: mode == PracticalMode.freeExploration,
      isWaterDropAdded: mode == PracticalMode.freeExploration,
      appliedStain: mode == PracticalMode.freeExploration ? StainType.iodine : StainType.none,
      isCoverslipMounted: mode == PracticalMode.freeExploration,
      isExcessStainBlotted: mode == PracticalMode.freeExploration,
      isSlideOnStage: mode == PracticalMode.freeExploration,
      areStageClipsLocked: mode == PracticalMode.freeExploration,
      isLightOn: mode == PracticalMode.freeExploration,
      coarseFocus: mode == PracticalMode.freeExploration ? 45.0 : 10.0,
      fineFocus: mode == PracticalMode.freeExploration ? 48.0 : 20.0,
    );
  }

  @override
  MicroscopeState reset(PracticalMode mode) {
    return createInitialState(mode);
  }

  @override
  PracticalScoreResult calculateScore(MicroscopeState state) {
    return PracticalScoreResult.calculateMicroscopeScore(
      studentMagnification: state.studentCalculatedMagnification ?? state.totalMagnification,
      theoreticalMagnification: state.totalMagnification,
      identifiedOrganellesCount: state.identifiedOrganelleIds.length,
      totalTargetOrganelles: 4,
      slideProperlyPrepared: state.isSlideFullyPrepared,
      focusedSuccessfully: state.isInFocus,
      inspectedCount: state.inspectedItems.length,
      durationSeconds: state.elapsedSeconds,
    );
  }

  @override
  MicroscopeState processAction(MicroscopeState state, MicroscopeAction action) {
    if (action is ResetMicroscopeAction) {
      return createInitialState(state.mode);
    }

    if (action is InspectMicroscopeApparatusAction) {
      final updated = Set<String>.from(state.inspectedItems)..add(action.itemId);
      final nextStep = (state.currentStep == MicroscopeStep.inspectApparatus && updated.length >= 4)
          ? MicroscopeStep.prepareSlide
          : state.currentStep;

      return state.copyWith(
        inspectedItems: updated,
        currentStep: nextStep,
        observationEn: 'Inspected apparatus (${updated.length}/4 required). Mount a single-cell onion peel on the glass slide.',
        observationSw: 'Vifaa vimekaguliwa (${updated.length}/4 vinavyohitajika). Weka kiolezo cha kitunguu kwenye kioo cha slide.',
      );
    }

    if (action is PlaceSpecimenAction) {
      final nextStep = state.currentStep == MicroscopeStep.prepareSlide
          ? MicroscopeStep.applyStain
          : state.currentStep;

      return state.copyWith(
        isSpecimenPlaced: true,
        isWaterDropAdded: true,
        currentStep: nextStep,
        observationEn: 'Onion epidermal peel mounted flat in a drop of water. Now add 1-2 drops of dilute iodine stain.',
        observationSw: 'Kiolezo cha kitunguu kimewekwa bapa kwenye tone la maji. Sasa weka matone 1-2 ya rangi ya iodini.',
      );
    }

    if (action is ApplyStainAction) {
      final nextStep = state.currentStep == MicroscopeStep.applyStain
          ? MicroscopeStep.mountCoverslip
          : state.currentStep;

      return state.copyWith(
        appliedStain: action.stain,
        currentStep: nextStep,
        observationEn: 'Iodine stain applied. Use a mounted needle at 45° to gently lower the glass coverslip without air bubbles.',
        observationSw: 'Rangi ya iodini imewekwa. Tumia sindano ya maabara kwa pembe ya 45° kuteremsha kioo kidogo bila mapovu ya hewa.',
      );
    }

    if (action is MountCoverslipAction) {
      final nextStep = state.currentStep == MicroscopeStep.mountCoverslip
          ? MicroscopeStep.placeOnStage
          : state.currentStep;

      return state.copyWith(
        isCoverslipMounted: true,
        isExcessStainBlotted: true,
        currentStep: nextStep,
        observationEn: 'Coverslip lowered smoothly and excess stain blotted. Place the prepared slide onto the microscope stage.',
        observationSw: 'Kioo kidogo kimefunikwa vizuri na rangi ya ziada imefutwa. Weka kiolezo kwenye meza ya darubini.',
      );
    }

    if (action is PlaceSlideOnStageAction) {
      final nextStep = state.currentStep == MicroscopeStep.placeOnStage
          ? MicroscopeStep.adjustIllumination
          : state.currentStep;

      return state.copyWith(
        isSlideOnStage: true,
        areStageClipsLocked: true,
        currentStep: nextStep,
        observationEn: 'Slide clipped securely over the condenser lens. Turn on the light source and adjust illumination.',
        observationSw: 'Kiolezo kimefungwa imara juu ya lenzi ya condenser. Washa chanzo cha mwanga na urekebishe mwangaza.',
      );
    }

    if (action is SetLightIntensityAction) {
      final nextStep = (state.currentStep == MicroscopeStep.adjustIllumination && action.intensity > 20.0)
          ? MicroscopeStep.adjustFocus
          : state.currentStep;

      final newState = state.copyWith(
        isLightOn: action.intensity > 0.0,
        lightIntensity: action.intensity.clamp(0.0, 100.0),
        currentStep: nextStep,
        observationEn: 'Illumination set to ${action.intensity.toStringAsFixed(0)}%. Use coarse & fine focus knobs to sharpen cell boundaries.',
        observationSw: 'Mwangaza umewekwa ${action.intensity.toStringAsFixed(0)}%. Tumia vitufe vya kuelekeza kuweka seli ziwe wazi.',
      );
      return newState;
    }

    if (action is SetCoarseFocusAction) {
      final updated = state.copyWith(coarseFocus: action.coarseFocus.clamp(0.0, 100.0));
      return _checkFocusStep(updated);
    }

    if (action is SetFineFocusAction) {
      final updated = state.copyWith(fineFocus: action.fineFocus.clamp(0.0, 100.0));
      return _checkFocusStep(updated);
    }

    if (action is SetObjectiveAction) {
      final nextStep = (state.currentStep == MicroscopeStep.switchMagnification)
          ? MicroscopeStep.recordObservations
          : state.currentStep;

      final updated = state.copyWith(
        selectedObjective: action.objective,
        currentStep: nextStep,
        observationEn: 'Switched objective to ${action.objective.labelEn}. Total magnification is ${MicroscopeState.eyepieceMagnification * action.objective.magnification}×.',
        observationSw: 'Lenzi imebadilishwa kuwa ${action.objective.labelSw}. Ukuzaji kamili ni ${MicroscopeState.eyepieceMagnification * action.objective.magnification}×.',
      );
      return updated;
    }

    if (action is ToggleOrganelleSelectionAction) {
      final set = Set<String>.from(state.identifiedOrganelleIds);
      if (set.contains(action.organelleId)) {
        set.remove(action.organelleId);
      } else {
        set.add(action.organelleId);
      }
      return state.copyWith(identifiedOrganelleIds: set);
    }

    if (action is SubmitMicroscopeObservationsAction) {
      final theoreticalMag = state.totalMagnification;
      final scoreResult = PracticalScoreResult.calculateMicroscopeScore(
        studentMagnification: action.calculatedMagnification,
        theoreticalMagnification: theoreticalMag,
        identifiedOrganellesCount: state.identifiedOrganelleIds.length,
        totalTargetOrganelles: 4, // Cell wall, Nucleus, Cytoplasm, Vacuole
        slideProperlyPrepared: state.isSlideFullyPrepared,
        focusedSuccessfully: state.isInFocus,
        inspectedCount: state.inspectedItems.length,
        durationSeconds: state.elapsedSeconds,
      );

      return state.copyWith(
        currentStep: MicroscopeStep.completed,
        studentCalculatedMagnification: action.calculatedMagnification,
        scoreResult: scoreResult,
        observationEn: 'Practical completed! Score: ${scoreResult.totalScore}% (${scoreResult.grade}).',
        observationSw: 'Jaribio limekamilika! Alama: ${scoreResult.totalScore}% (${scoreResult.grade}).',
      );
    }

    return state;
  }

  MicroscopeState _checkFocusStep(MicroscopeState state) {
    if (state.currentStep == MicroscopeStep.adjustFocus && state.isInFocus) {
      return state.copyWith(
        currentStep: MicroscopeStep.switchMagnification,
        observationEn: 'Cell walls and nuclei in sharp focus (${(state.sharpness * 100).toStringAsFixed(0)}% sharpness). Switch to 10× or 40× objective.',
        observationSw: 'Kuta za seli na viini vinaonekana vizuri sana (usahihi ${(state.sharpness * 100).toStringAsFixed(0)}%). Badilisha lenzi kuwa 10× au 40×.',
      );
    }
    return state;
  }
}
