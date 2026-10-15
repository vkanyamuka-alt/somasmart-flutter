import 'practical_model.dart';
import 'practical_score_result.dart';

/// Supported objective lenses on the compound light microscope
enum MicroscopeObjective {
  low4x(4, '4× (Low Power)', '4× (Nguvu ya Chini)'),
  medium10x(10, '10× (Medium Power)', '10× (Nguvu ya Kati)'),
  high40x(40, '40× (High Power)', '40× (Nguvu ya Juu)');

  final int magnification;
  final String labelEn;
  final String labelSw;

  const MicroscopeObjective(this.magnification, this.labelEn, this.labelSw);
}

/// Supported staining solutions
enum StainType {
  none('None (Unstained)', 'Hakuna (Bila Rangi)'),
  iodine('Dilute Iodine Solution', 'Myeyusho wa Iodini'),
  methyleneBlue('Methylene Blue Solution', 'Myeyusho wa Methylene Blue');

  final String labelEn;
  final String labelSw;

  const StainType(this.labelEn, this.labelSw);
}

/// Identifiable cellular organelles under light microscopy
class CellOrganelleInfo {
  final String id;
  final String nameEn;
  final String nameSw;
  final String descriptionEn;
  final String descriptionSw;

  const CellOrganelleInfo({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.descriptionEn,
    required this.descriptionSw,
  });
}

const List<CellOrganelleInfo> kIdentifiableOrganelles = [
  CellOrganelleInfo(
    id: 'cell_wall',
    nameEn: 'Cell Wall',
    nameSw: 'Ukuta wa Seli',
    descriptionEn: 'Rigid outer layer composed of cellulose providing structural support and protection.',
    descriptionSw: 'Tabaka gumu la nje lililotengenezwa kwa selulosi linalolinda na kushikilia umbo la seli.',
  ),
  CellOrganelleInfo(
    id: 'nucleus',
    nameEn: 'Nucleus',
    nameSw: 'Kiini (Nucleus)',
    descriptionEn: 'Dense, prominent spherical organelle stained dark brown containing genetic material (DNA).',
    descriptionSw: 'Sehemu ya duara yenye rangi ya kahawia iliyokolea inayobeba vinasaba (DNA).',
  ),
  CellOrganelleInfo(
    id: 'cytoplasm',
    nameEn: 'Cytoplasm',
    nameSw: 'Kioevu cha Seli (Cytoplasm)',
    descriptionEn: 'Granular jelly-like fluid where cellular metabolic activities take place.',
    descriptionSw: 'Kioevu kinene ndani ya seli ambapo shughuli mbalimbali za kikemikali hufanyika.',
  ),
  CellOrganelleInfo(
    id: 'vacuole',
    nameEn: 'Large Central Vacuole',
    nameSw: 'Kiputo Kikuu (Vacuole)',
    descriptionEn: 'Large fluid-filled membrane sac containing cell sap that maintains turgor pressure.',
    descriptionSw: 'Nafasi kubwa yenye maji na virutubisho inayosaidia seli kusimama wima bila kusinyaa.',
  ),
  CellOrganelleInfo(
    id: 'plasma_membrane',
    nameEn: 'Cell / Plasma Membrane',
    nameSw: 'Utando wa Seli (Plasma Membrane)',
    descriptionEn: 'Thin semi-permeable membrane closely pressed against the inner surface of the cell wall.',
    descriptionSw: 'Utando mwembamba unaoruhusu baadhi ya vitu kuingia au kutoka ndani ya seli.',
  ),
];

/// Step definition for Light Microscope practical workflow
enum MicroscopeStep {
  inspectApparatus(1, 'Inspect Apparatus', 'Kagua Vifaa'),
  prepareSlide(2, 'Mount Specimen', 'Weka Kiolezo'),
  applyStain(3, 'Apply Stain', 'Weka Rangi'),
  mountCoverslip(4, 'Mount Coverslip', 'Funika Kioo Kidogo'),
  placeOnStage(5, 'Place on Stage', 'Weka Kwenye Meza'),
  adjustIllumination(6, 'Adjust Light', 'Rekebisha Mwanga'),
  adjustFocus(7, 'Focus Specimen', 'Lenga Seli'),
  switchMagnification(8, 'Observe Cells', 'Chunguza Seli'),
  recordObservations(9, 'Record & Calculate', 'Rekodi & Hesabu'),
  completed(10, 'Completed', 'Imekamilika');

  final int stepNumber;
  final String titleEn;
  final String titleSw;

  const MicroscopeStep(this.stepNumber, this.titleEn, this.titleSw);
}

/// Immutable simulation state for Light Microscope Cell Staining
class MicroscopeState {
  final PracticalMode mode;
  final MicroscopeStep currentStep;
  final Set<String> inspectedItems;

  // Slide preparation states
  final bool isSpecimenPlaced;
  final bool isWaterDropAdded;
  final StainType appliedStain;
  final bool isCoverslipMounted;
  final bool isExcessStainBlotted;
  final bool isSlideOnStage;
  final bool areStageClipsLocked;

  // Optical and microscope adjustment states
  final bool isLightOn;
  final double lightIntensity; // 0.0 to 100.0%
  final MicroscopeObjective selectedObjective;
  final double coarseFocus; // 0.0 to 100.0 (optimal ~ 50.0)
  final double fineFocus; // 0.0 to 100.0 (optimal ~ 50.0)
  final double stageX; // -50.0 to 50.0 (horizontal specimen panning)
  final double stageY; // -50.0 to 50.0 (vertical specimen panning)

  // Observations & recordings
  final Set<String> identifiedOrganelleIds;
  final int? studentCalculatedMagnification;
  final PracticalScoreResult? scoreResult;

  // Timers & feedback
  final int elapsedSeconds;
  final String observationEn;
  final String observationSw;

  const MicroscopeState({
    this.mode = PracticalMode.guidedPractice,
    this.currentStep = MicroscopeStep.inspectApparatus,
    this.inspectedItems = const {},
    this.isSpecimenPlaced = false,
    this.isWaterDropAdded = false,
    this.appliedStain = StainType.none,
    this.isCoverslipMounted = false,
    this.isExcessStainBlotted = false,
    this.isSlideOnStage = false,
    this.areStageClipsLocked = false,
    this.isLightOn = false,
    this.lightIntensity = 75.0,
    this.selectedObjective = MicroscopeObjective.low4x,
    this.coarseFocus = 10.0,
    this.fineFocus = 20.0,
    this.stageX = 0.0,
    this.stageY = 0.0,
    this.identifiedOrganelleIds = const {},
    this.studentCalculatedMagnification,
    this.scoreResult,
    this.elapsedSeconds = 0,
    this.observationEn = 'Inspect all laboratory apparatus before preparing the wet mount slide.',
    this.observationSw = 'Kagua vifaa vyote vya maabara kabla ya kuandaa kiolezo cha kioo.',
  });

  /// Fixed eyepiece magnification (Standard educational compound microscope)
  static const int eyepieceMagnification = 10;

  /// Total optical magnification = Eyepiece (10x) * Selected Objective
  int get totalMagnification => eyepieceMagnification * selectedObjective.magnification;

  /// Target optimal coarse focus per objective
  double get targetCoarseFocus {
    switch (selectedObjective) {
      case MicroscopeObjective.low4x:
        return 45.0;
      case MicroscopeObjective.medium10x:
        return 50.0;
      case MicroscopeObjective.high40x:
        return 55.0;
    }
  }

  /// Target optimal fine focus per objective
  double get targetFineFocus {
    switch (selectedObjective) {
      case MicroscopeObjective.low4x:
        return 48.0;
      case MicroscopeObjective.medium10x:
        return 52.0;
      case MicroscopeObjective.high40x:
        return 50.0;
    }
  }

  /// Computed image sharpness (0.0 to 1.0)
  double get sharpness {
    if (!isLightOn || !isSlideOnStage) return 0.0;

    final coarseDiff = (coarseFocus - targetCoarseFocus).abs();
    final fineDiff = (fineFocus - targetFineFocus).abs();

    // Coarse focus provides rough window (tolerance +- 18.0)
    final coarseWeight = (1.0 - (coarseDiff / 18.0)).clamp(0.0, 1.0);
    // Fine focus locks into crystal sharp view (tolerance +- 12.0)
    final fineWeight = (1.0 - (fineDiff / 12.0)).clamp(0.0, 1.0);

    // Illumination factor (optimal 50% - 90%)
    double lightFactor;
    if (lightIntensity < 20.0) {
      lightFactor = lightIntensity / 20.0;
    } else if (lightIntensity > 95.0) {
      lightFactor = 0.85; // slightly washed out if overexposed
    } else {
      lightFactor = 1.0;
    }

    final rawSharpness = (coarseWeight * 0.4 + fineWeight * 0.6) * lightFactor;
    return rawSharpness.clamp(0.0, 1.0);
  }

  /// Whether the image is sharp enough for scientific observation (sharpness >= 0.82)
  bool get isInFocus => sharpness >= 0.82;

  /// Whether the slide is properly prepared with specimen, stain, and coverslip
  bool get isSlideFullyPrepared =>
      isSpecimenPlaced && appliedStain != StainType.none && isCoverslipMounted;

  MicroscopeState copyWith({
    PracticalMode? mode,
    MicroscopeStep? currentStep,
    Set<String>? inspectedItems,
    bool? isSpecimenPlaced,
    bool? isWaterDropAdded,
    StainType? appliedStain,
    bool? isCoverslipMounted,
    bool? isExcessStainBlotted,
    bool? isSlideOnStage,
    bool? areStageClipsLocked,
    bool? isLightOn,
    double? lightIntensity,
    MicroscopeObjective? selectedObjective,
    double? coarseFocus,
    double? fineFocus,
    double? stageX,
    double? stageY,
    Set<String>? identifiedOrganelleIds,
    int? studentCalculatedMagnification,
    PracticalScoreResult? scoreResult,
    int? elapsedSeconds,
    String? observationEn,
    String? observationSw,
  }) {
    return MicroscopeState(
      mode: mode ?? this.mode,
      currentStep: currentStep ?? this.currentStep,
      inspectedItems: inspectedItems ?? this.inspectedItems,
      isSpecimenPlaced: isSpecimenPlaced ?? this.isSpecimenPlaced,
      isWaterDropAdded: isWaterDropAdded ?? this.isWaterDropAdded,
      appliedStain: appliedStain ?? this.appliedStain,
      isCoverslipMounted: isCoverslipMounted ?? this.isCoverslipMounted,
      isExcessStainBlotted: isExcessStainBlotted ?? this.isExcessStainBlotted,
      isSlideOnStage: isSlideOnStage ?? this.isSlideOnStage,
      areStageClipsLocked: areStageClipsLocked ?? this.areStageClipsLocked,
      isLightOn: isLightOn ?? this.isLightOn,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      selectedObjective: selectedObjective ?? this.selectedObjective,
      coarseFocus: coarseFocus ?? this.coarseFocus,
      fineFocus: fineFocus ?? this.fineFocus,
      stageX: stageX ?? this.stageX,
      stageY: stageY ?? this.stageY,
      identifiedOrganelleIds: identifiedOrganelleIds ?? this.identifiedOrganelleIds,
      studentCalculatedMagnification: studentCalculatedMagnification ?? this.studentCalculatedMagnification,
      scoreResult: scoreResult ?? this.scoreResult,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      observationEn: observationEn ?? this.observationEn,
      observationSw: observationSw ?? this.observationSw,
    );
  }
}
