import 'practical_model.dart';
import 'practical_score_result.dart';

enum StopcockState {
  closed,
  flow,
  slow,
  single,
  paused,
}

enum FlaskColorStage {
  colourless,
  pinkFlash,
  permanentPalePink,
  darkMagenta,
}

class TitrationState {
  final PracticalMode mode;
  final int currentStepIndex; // 0 to 8 (9 total steps)
  final bool isCompleted;
  final int elapsedSeconds;

  // Equipment inspection state (Step 0)
  final Set<String> inspectedItems;
  final String? selectedInspectItemKey;

  // Burette state (Step 1)
  final bool buretteFilled;
  final double buretteReading; // 0.0 to 26.0 mL

  // Pipette sub-state (Step 2)
  final int pipetteStep; // 0 to 7
  final double pipetteVolume; // 0.0 to 25.0 mL
  final bool isDrawingLiquid;
  final bool isTransferringLiquid;

  // Conical flask state
  final double flaskVolume; // starts 0.0, reaches 25.0 in Step 2, + volumeDelivered

  // Indicator sub-state (Step 3)
  final int indicatorStep; // 0 to 3
  final int indicatorDropsCount; // 0 to 3
  final bool isDroppingIndicator;
  final bool indicatorAdded;

  // Flask positioning (Step 4)
  final bool flaskPositioned;

  // Titration delivery (Step 5)
  final StopcockState stopcockState;
  final StopcockState previousActiveStopcockState;
  final double volumeDelivered; // 0.0 to 26.0 mL
  final bool isDropFalling;
  final double dropY;
  final bool flaskRipple;

  // Swirling & Observation (Step 6)
  final bool isSwirling;
  final bool hasSwirledAtCurrentVolume;
  final bool endpointConfirmed;

  // Student recorded values (Step 7)
  final String initialReadingInput;
  final String finalReadingInput;
  final String titreVolumeInput;
  final String observedColorInput;
  final bool readingsSubmitted;

  // Student calculations (Step 8)
  final String calculatedTitreInput;
  final String calculatedMolarityInput;
  final bool calculationSubmitted;
  final PracticalScoreResult? scoreResult;

  // Dynamic log entries
  final List<String> notebookLogs;

  const TitrationState({
    required this.mode,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.inspectedItems = const {},
    this.selectedInspectItemKey,
    this.buretteFilled = false,
    this.buretteReading = 0.0,
    this.pipetteStep = 0,
    this.pipetteVolume = 0.0,
    this.isDrawingLiquid = false,
    this.isTransferringLiquid = false,
    this.flaskVolume = 0.0,
    this.indicatorStep = 0,
    this.indicatorDropsCount = 0,
    this.isDroppingIndicator = false,
    this.indicatorAdded = false,
    this.flaskPositioned = false,
    this.stopcockState = StopcockState.closed,
    this.previousActiveStopcockState = StopcockState.slow,
    this.volumeDelivered = 0.0,
    this.isDropFalling = false,
    this.dropY = 252.0,
    this.flaskRipple = false,
    this.isSwirling = false,
    this.hasSwirledAtCurrentVolume = false,
    this.endpointConfirmed = false,
    this.initialReadingInput = '0.00',
    this.finalReadingInput = '',
    this.titreVolumeInput = '',
    this.observedColorInput = 'Permanent Pale Pink',
    this.readingsSubmitted = false,
    this.calculatedTitreInput = '',
    this.calculatedMolarityInput = '',
    this.calculationSubmitted = false,
    this.scoreResult,
    this.notebookLogs = const ['• Virtual Laboratory initialized for Acid–Base Titration.'],
  });

  FlaskColorStage get flaskColorStage {
    if (flaskVolume == 0 || !indicatorAdded) {
      return FlaskColorStage.colourless;
    }
    if (volumeDelivered < 24.00) {
      return FlaskColorStage.colourless;
    } else if (volumeDelivered >= 24.00 && volumeDelivered < 24.45) {
      return hasSwirledAtCurrentVolume
          ? FlaskColorStage.colourless
          : FlaskColorStage.pinkFlash;
    } else if (volumeDelivered >= 24.45 && volumeDelivered <= 24.75) {
      return FlaskColorStage.permanentPalePink;
    } else {
      return FlaskColorStage.darkMagenta;
    }
  }

  String get colorStageNameEn {
    switch (flaskColorStage) {
      case FlaskColorStage.colourless:
        return '1. Colourless (Acid Environment)';
      case FlaskColorStage.pinkFlash:
        return '2. Temporary Faint Pink Flash';
      case FlaskColorStage.permanentPalePink:
        return '3. Permanent Pale Pink — Endpoint Reached';
      case FlaskColorStage.darkMagenta:
        return '4. Darker Pink / Magenta — Overshot Endpoint';
    }
  }

  String get colorStageNameSw {
    switch (flaskColorStage) {
      case FlaskColorStage.colourless:
        return '1. Haina Rangi (Mazingira ya Asidi)';
      case FlaskColorStage.pinkFlash:
        return '2. Mwanga wa Waridi wa Muda';
      case FlaskColorStage.permanentPalePink:
        return '3. Rangi ya Waridi Isiyofifia — Kilele Kimefikiwa';
      case FlaskColorStage.darkMagenta:
        return '4. Waridi Iliyokolea / Magenta — Umezidisha';
    }
  }

  String get observationMessageEn {
    if (!indicatorAdded) {
      return 'Solution contains 25.0 mL 0.10M HCl (Indicator not yet added).';
    }
    if (volumeDelivered < 24.00) {
      return 'Solution remains completely colourless in acidic environment (pH < 8.2).';
    }
    if (volumeDelivered >= 24.00 && volumeDelivered < 24.45) {
      return hasSwirledAtCurrentVolume
          ? 'Pink color disappeared after swirling — endpoint not yet reached.'
          : 'Faint pink flash observed at point of drop impact. Swirl flask to mix solution.';
    }
    if (volumeDelivered >= 24.45 && volumeDelivered <= 24.75) {
      return 'Endpoint reached: permanent pale pink colour remains after swirling.';
    }
    return 'Overshot endpoint: excess titrant has caused solution to turn dark pink/magenta.';
  }

  String get observationMessageSw {
    if (!indicatorAdded) {
      return 'Mchanganyiko una 25.0 mL 0.10M HCl (Kielelezo bado hakijawekwa).';
    }
    if (volumeDelivered < 24.00) {
      return 'Mchanganyiko unabaki hauna rangi katika mazingira ya asidi (pH < 8.2).';
    }
    if (volumeDelivered >= 24.00 && volumeDelivered < 24.45) {
      return hasSwirledAtCurrentVolume
          ? 'Rangi ya waridi imepotea baada ya kuchanganya — kilele bado hakijafikiwa.'
          : 'Rangi ya waridi imeonekana panapodondokea tone. Tikisa chupa kuchanganya.';
    }
    if (volumeDelivered >= 24.45 && volumeDelivered <= 24.75) {
      return 'Kilele kimefikiwa: rangi hafifu ya waridi inadumu baada ya kutikisa chupa.';
    }
    return 'Umezidisha kilele: kiasi kikubwa cha titrant kimefanya mchanganyiko kuwa waridi mzito.';
  }

  bool canAdvanceStep() {
    if (mode == PracticalMode.freeExploration) return true;
    switch (currentStepIndex) {
      case 0:
        return inspectedItems.length >= 4;
      case 1:
        return buretteFilled;
      case 2:
        return flaskVolume >= 25.0 && pipetteStep >= 7;
      case 3:
        return indicatorAdded && indicatorStep >= 3;
      case 4:
        return flaskPositioned;
      case 5:
        return volumeDelivered >= 24.00;
      case 6:
        return volumeDelivered >= 24.45 && hasSwirledAtCurrentVolume;
      case 7:
        return readingsSubmitted;
      case 8:
        return calculationSubmitted;
      default:
        return true;
    }
  }

  TitrationState copyWith({
    PracticalMode? mode,
    int? currentStepIndex,
    bool? isCompleted,
    int? elapsedSeconds,
    Set<String>? inspectedItems,
    String? selectedInspectItemKey,
    bool? buretteFilled,
    double? buretteReading,
    int? pipetteStep,
    double? pipetteVolume,
    bool? isDrawingLiquid,
    bool? isTransferringLiquid,
    double? flaskVolume,
    int? indicatorStep,
    int? indicatorDropsCount,
    bool? isDroppingIndicator,
    bool? indicatorAdded,
    bool? flaskPositioned,
    StopcockState? stopcockState,
    StopcockState? previousActiveStopcockState,
    double? volumeDelivered,
    bool? isDropFalling,
    double? dropY,
    bool? flaskRipple,
    bool? isSwirling,
    bool? hasSwirledAtCurrentVolume,
    bool? endpointConfirmed,
    String? initialReadingInput,
    String? finalReadingInput,
    String? titreVolumeInput,
    String? observedColorInput,
    bool? readingsSubmitted,
    String? calculatedTitreInput,
    String? calculatedMolarityInput,
    bool? calculationSubmitted,
    PracticalScoreResult? scoreResult,
    List<String>? notebookLogs,
  }) {
    return TitrationState(
      mode: mode ?? this.mode,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      inspectedItems: inspectedItems ?? this.inspectedItems,
      selectedInspectItemKey: selectedInspectItemKey,
      buretteFilled: buretteFilled ?? this.buretteFilled,
      buretteReading: buretteReading ?? this.buretteReading,
      pipetteStep: pipetteStep ?? this.pipetteStep,
      pipetteVolume: pipetteVolume ?? this.pipetteVolume,
      isDrawingLiquid: isDrawingLiquid ?? this.isDrawingLiquid,
      isTransferringLiquid: isTransferringLiquid ?? this.isTransferringLiquid,
      flaskVolume: flaskVolume ?? this.flaskVolume,
      indicatorStep: indicatorStep ?? this.indicatorStep,
      indicatorDropsCount: indicatorDropsCount ?? this.indicatorDropsCount,
      isDroppingIndicator: isDroppingIndicator ?? this.isDroppingIndicator,
      indicatorAdded: indicatorAdded ?? this.indicatorAdded,
      flaskPositioned: flaskPositioned ?? this.flaskPositioned,
      stopcockState: stopcockState ?? this.stopcockState,
      previousActiveStopcockState: previousActiveStopcockState ?? this.previousActiveStopcockState,
      volumeDelivered: volumeDelivered ?? this.volumeDelivered,
      isDropFalling: isDropFalling ?? this.isDropFalling,
      dropY: dropY ?? this.dropY,
      flaskRipple: flaskRipple ?? this.flaskRipple,
      isSwirling: isSwirling ?? this.isSwirling,
      hasSwirledAtCurrentVolume: hasSwirledAtCurrentVolume ?? this.hasSwirledAtCurrentVolume,
      endpointConfirmed: endpointConfirmed ?? this.endpointConfirmed,
      initialReadingInput: initialReadingInput ?? this.initialReadingInput,
      finalReadingInput: finalReadingInput ?? this.finalReadingInput,
      titreVolumeInput: titreVolumeInput ?? this.titreVolumeInput,
      observedColorInput: observedColorInput ?? this.observedColorInput,
      readingsSubmitted: readingsSubmitted ?? this.readingsSubmitted,
      calculatedTitreInput: calculatedTitreInput ?? this.calculatedTitreInput,
      calculatedMolarityInput: calculatedMolarityInput ?? this.calculatedMolarityInput,
      calculationSubmitted: calculationSubmitted ?? this.calculationSubmitted,
      scoreResult: scoreResult ?? this.scoreResult,
      notebookLogs: notebookLogs ?? this.notebookLogs,
    );
  }
}
