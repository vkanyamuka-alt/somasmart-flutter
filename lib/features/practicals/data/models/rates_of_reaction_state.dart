import 'package:flutter/foundation.dart';
import '../models/practical_model.dart';
import '../models/practical_score_result.dart';

/// Steps in the Rates of Chemical Reactions Virtual Laboratory Practical
enum RatesOfReactionStep {
  inspectApparatus,
  prepareSolutions,
  runReactionTrials,
  resultsTable,
  graphAnalysis;

  String get labelEn {
    switch (this) {
      case RatesOfReactionStep.inspectApparatus:
        return '1. Inspect Apparatus';
      case RatesOfReactionStep.prepareSolutions:
        return '2. Prepare Solutions';
      case RatesOfReactionStep.runReactionTrials:
        return '3. Reaction & Timing';
      case RatesOfReactionStep.resultsTable:
        return '4. Kinetic Results Table';
      case RatesOfReactionStep.graphAnalysis:
        return '5. Graph & Rate Law';
    }
  }

  String get labelSw {
    switch (this) {
      case RatesOfReactionStep.inspectApparatus:
        return '1. Kagua Vifaa';
      case RatesOfReactionStep.prepareSolutions:
        return '2. Pima Myeyusho';
      case RatesOfReactionStep.runReactionTrials:
        return '3. Mmenyuko na Muda';
      case RatesOfReactionStep.resultsTable:
        return '4. Jedwali la Matokeo';
      case RatesOfReactionStep.graphAnalysis:
        return '5. Grafu na Kanuni ya Kasi';
    }
  }
}

/// Represents an individual experimental trial in the reaction rates series
@immutable
class ReactionTrial {
  final int flaskNumber; // 1 to 5
  final double volumeThiosulfate; // mL (e.g. 50, 40, 30, 20, 10)
  final double volumeWater; // mL (e.g. 0, 10, 20, 30, 40)
  final double volumeAcid; // mL constant (5.0 mL)
  final double concentrationThio; // M (0.20, 0.16, 0.12, 0.08, 0.04)
  final double expectedTimeSeconds; // theoretical disappearance time
  final double? recordedTimeSeconds; // student measured time
  final bool isPrepared;
  final bool isAcidAdded;
  final bool isCompleted;

  const ReactionTrial({
    required this.flaskNumber,
    required this.volumeThiosulfate,
    required this.volumeWater,
    this.volumeAcid = 5.0,
    required this.concentrationThio,
    required this.expectedTimeSeconds,
    this.recordedTimeSeconds,
    this.isPrepared = false,
    this.isAcidAdded = false,
    this.isCompleted = false,
  });

  /// Rate of reaction proportional to reciprocal of time (1/t in s^-1)
  double? get calculatedRate {
    if (recordedTimeSeconds == null || recordedTimeSeconds! <= 0) return null;
    return 1.0 / recordedTimeSeconds!;
  }

  /// Theoretical rate 1/t_expected
  double get theoreticalRate => 1.0 / expectedTimeSeconds;

  ReactionTrial copyWith({
    int? flaskNumber,
    double? volumeThiosulfate,
    double? volumeWater,
    double? volumeAcid,
    double? concentrationThio,
    double? expectedTimeSeconds,
    double? recordedTimeSeconds,
    bool? isPrepared,
    bool? isAcidAdded,
    bool? isCompleted,
  }) {
    return ReactionTrial(
      flaskNumber: flaskNumber ?? this.flaskNumber,
      volumeThiosulfate: volumeThiosulfate ?? this.volumeThiosulfate,
      volumeWater: volumeWater ?? this.volumeWater,
      volumeAcid: volumeAcid ?? this.volumeAcid,
      concentrationThio: concentrationThio ?? this.concentrationThio,
      expectedTimeSeconds: expectedTimeSeconds ?? this.expectedTimeSeconds,
      recordedTimeSeconds: recordedTimeSeconds ?? this.recordedTimeSeconds,
      isPrepared: isPrepared ?? this.isPrepared,
      isAcidAdded: isAcidAdded ?? this.isAcidAdded,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Represents an apparatus item to inspect in Step 1
@immutable
class RatesApparatusItem {
  final String id;
  final String nameEn;
  final String nameSw;
  final String specEn;
  final String specSw;
  final bool inspected;

  const RatesApparatusItem({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.specEn,
    required this.specSw,
    this.inspected = false,
  });

  RatesApparatusItem copyWith({bool? inspected}) {
    return RatesApparatusItem(
      id: id,
      nameEn: nameEn,
      nameSw: nameSw,
      specEn: specEn,
      specSw: specSw,
      inspected: inspected ?? this.inspected,
    );
  }
}

/// Comprehensive State for the Rates of Chemical Reactions Virtual Laboratory
@immutable
class RatesOfReactionState {
  final RatesOfReactionStep step;
  final List<RatesApparatusItem> apparatus;
  final List<ReactionTrial> trials;
  final int activeTrialIndex; // 0..4
  final bool isStopwatchRunning;
  final double currentStopwatchSeconds;
  final double turbidityOpacity; // 0.0 (clear) to 1.0 (fully obscured)
  final bool isFlaskOnCross;
  final double? enteredSlope; // student entered k' (1/t per mol/dm^3)
  final int experimentDurationSeconds;
  final PracticalMode practicalMode;
  final PracticalScoreResult? scoreResult;

  const RatesOfReactionState({
    required this.step,
    required this.apparatus,
    required this.trials,
    this.activeTrialIndex = 0,
    this.isStopwatchRunning = false,
    this.currentStopwatchSeconds = 0.0,
    this.turbidityOpacity = 0.0,
    this.isFlaskOnCross = false,
    this.enteredSlope,
    this.experimentDurationSeconds = 0,
    this.practicalMode = PracticalMode.guidedPractice,
    this.scoreResult,
  });

  /// Factory for the initial state of the practical
  factory RatesOfReactionState.initial(PracticalMode mode) {
    return RatesOfReactionState(
      step: RatesOfReactionStep.inspectApparatus,
      practicalMode: mode,
      apparatus: const [
        RatesApparatusItem(
          id: 'conical_flasks',
          nameEn: '5 × 250 mL Conical Flasks (Pyrex)',
          nameSw: 'Chupa 5 za Koni za 250 mL (Pyrex)',
          specEn: 'Clean, flat-bottom borosilicate glass reaction vessels.',
          specSw: 'Vyombo safi vya glasi vyenye sakafu tambarare kwa ajili ya mmenyuko.',
        ),
        RatesApparatusItem(
          id: 'cross_tile',
          nameEn: 'White Ceramic Tile with Bold Black Cross (X)',
          nameSw: 'Kigae Cheupe cha Kauri chenye Msalaba Mweusi (X)',
          specEn: 'Visual indicator target placed underneath the conical flask.',
          specSw: 'Kielelezo cha kuona kinachowekwa chini ya chupa ya koni.',
        ),
        RatesApparatusItem(
          id: 'stopwatch',
          nameEn: 'Digital Electronic Stopwatch (0.01 s)',
          nameSw: 'Saa ya Kidijitali ya Maabara (Usahihi 0.01 s)',
          specEn: 'High-precision timer for measuring cross disappearance interval.',
          specSw: 'Saa sahihi ya kupima muda hadi msalaba utoweke kabisa.',
        ),
        RatesApparatusItem(
          id: 'measuring_cylinders',
          nameEn: 'Graduated Measuring Cylinders (50 mL & 10 mL)',
          nameSw: 'Silinda za Kupimia Ujazo (50 mL na 10 mL)',
          specEn: 'Used for accurate volumetric dilution of stock solutions and acid.',
          specSw: 'Zinatumika kupimia kwa usahihi ujazo wa myeyusho na asidi.',
        ),
        RatesApparatusItem(
          id: 'thiosulfate_stock',
          nameEn: '0.20 M Sodium Thiosulfate Stock (Na₂S₂O₃)',
          nameSw: 'Myeyusho Mkuu wa Sodium Thiosulfate 0.20 M',
          specEn: 'Clear aqueous reactant providing thiosulfate ions for sulfur precipitation.',
          specSw: 'Myeyusho safi unaotoa ioni za thiosulfate kutengeneza kiberiti.',
        ),
        RatesApparatusItem(
          id: 'hydrochloric_acid',
          nameEn: '2.0 M Hydrochloric Acid (HCl)',
          nameSw: 'Asidi ya Hydrochloric 2.0 M (HCl)',
          specEn: 'Acid catalyst and reactant initiating instantaneous sulfur turbidity.',
          specSw: 'Asidi inayoanzisha mara moja mmenyuko wa kutengeneza ukungu wa kiberiti.',
        ),
      ],
      trials: const [
        ReactionTrial(
          flaskNumber: 1,
          volumeThiosulfate: 50.0,
          volumeWater: 0.0,
          concentrationThio: 0.20,
          expectedTimeSeconds: 20.0,
        ),
        ReactionTrial(
          flaskNumber: 2,
          volumeThiosulfate: 40.0,
          volumeWater: 10.0,
          concentrationThio: 0.16,
          expectedTimeSeconds: 25.0,
        ),
        ReactionTrial(
          flaskNumber: 3,
          volumeThiosulfate: 30.0,
          volumeWater: 20.0,
          concentrationThio: 0.12,
          expectedTimeSeconds: 33.3,
        ),
        ReactionTrial(
          flaskNumber: 4,
          volumeThiosulfate: 20.0,
          volumeWater: 30.0,
          concentrationThio: 0.08,
          expectedTimeSeconds: 50.0,
        ),
        ReactionTrial(
          flaskNumber: 5,
          volumeThiosulfate: 10.0,
          volumeWater: 40.0,
          concentrationThio: 0.04,
          expectedTimeSeconds: 100.0,
        ),
      ],
    );
  }

  bool get allApparatusInspected => apparatus.every((item) => item.inspected);
  bool get allTrialsPrepared => trials.every((t) => t.isPrepared);
  bool get allTrialsCompleted => trials.every((t) => t.isCompleted);

  ReactionTrial get activeTrial => trials[activeTrialIndex.clamp(0, trials.length - 1)];

  /// Computes the linear regression slope k' = (1/t) / [Na2S2O3] from completed trials
  /// Theoretical value is 0.25 s^-1 M^-1
  double get calculatedSlope {
    final completed = trials.where((t) => t.calculatedRate != null).toList();
    if (completed.length < 2) return 0.25;

    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = completed.length;
    for (final t in completed) {
      final x = t.concentrationThio;
      final y = t.calculatedRate!;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final denom = (n * sumXX - sumX * sumX);
    if (denom.abs() < 1e-6) return 0.25;
    final slope = (n * sumXY - sumX * sumY) / denom;
    return double.parse(slope.toStringAsFixed(3));
  }

  RatesOfReactionState copyWith({
    RatesOfReactionStep? step,
    List<RatesApparatusItem>? apparatus,
    List<ReactionTrial>? trials,
    int? activeTrialIndex,
    bool? isStopwatchRunning,
    double? currentStopwatchSeconds,
    double? turbidityOpacity,
    bool? isFlaskOnCross,
    double? enteredSlope,
    int? experimentDurationSeconds,
    PracticalMode? practicalMode,
    PracticalScoreResult? scoreResult,
  }) {
    return RatesOfReactionState(
      step: step ?? this.step,
      apparatus: apparatus ?? this.apparatus,
      trials: trials ?? this.trials,
      activeTrialIndex: activeTrialIndex ?? this.activeTrialIndex,
      isStopwatchRunning: isStopwatchRunning ?? this.isStopwatchRunning,
      currentStopwatchSeconds: currentStopwatchSeconds ?? this.currentStopwatchSeconds,
      turbidityOpacity: turbidityOpacity ?? this.turbidityOpacity,
      isFlaskOnCross: isFlaskOnCross ?? this.isFlaskOnCross,
      enteredSlope: enteredSlope ?? this.enteredSlope,
      experimentDurationSeconds: experimentDurationSeconds ?? this.experimentDurationSeconds,
      practicalMode: practicalMode ?? this.practicalMode,
      scoreResult: scoreResult ?? this.scoreResult,
    );
  }
}
