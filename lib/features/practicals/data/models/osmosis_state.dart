import 'package:flutter/foundation.dart';
import '../models/practical_model.dart';
import '../models/practical_score_result.dart';

/// Steps in the Osmosis in Potato Tissues Virtual Laboratory Practical
enum OsmosisStep {
  inspectApparatus,
  prepareSpecimens,
  initialWeighing,
  immerseIncubate,
  blotFinalWeighing,
  observationTable,
  graphAnalysis;

  String get labelEn {
    switch (this) {
      case OsmosisStep.inspectApparatus:
        return '1. Inspect Apparatus';
      case OsmosisStep.prepareSpecimens:
        return '2. Cut & Prepare Cylinders';
      case OsmosisStep.initialWeighing:
        return '3. Initial Mass (m₀)';
      case OsmosisStep.immerseIncubate:
        return '4. Immerse & Incubate';
      case OsmosisStep.blotFinalWeighing:
        return '5. Blot & Final Mass (m₁)';
      case OsmosisStep.observationTable:
        return '6. Observation Table';
      case OsmosisStep.graphAnalysis:
        return '7. Graph & Isotonic Point';
    }
  }

  String get labelSw {
    switch (this) {
      case OsmosisStep.inspectApparatus:
        return '1. Kagua Vifaa';
      case OsmosisStep.prepareSpecimens:
        return '2. Kata Vipande vya Viazi';
      case OsmosisStep.initialWeighing:
        return '3. Uzito wa Awali (m₀)';
      case OsmosisStep.immerseIncubate:
        return '4. Loweka na Subiri';
      case OsmosisStep.blotFinalWeighing:
        return '5. Kausha na Uzito Mpya (m₁)';
      case OsmosisStep.observationTable:
        return '6. Jedwali la Matokeo';
      case OsmosisStep.graphAnalysis:
        return '7. Grafu na Eneo la Msawazo';
    }
  }
}

/// Represents an individual potato tissue sample tested in a specific solution concentration
@immutable
class PotatoSample {
  final String id; // 'A', 'B', 'C', 'D', 'E'
  final String labelEn;
  final String labelSw;
  final double concentration; // in Molar (M, mol/dm³) e.g. 0.0, 0.2, 0.4, 0.6, 0.8
  final double initialMass; // m0 in grams (e.g. ~2.00 g)
  final double finalMass; // m1 in grams after osmosis
  final bool isPrepared;
  final bool isInitialWeighed;
  final bool isImmersed;
  final bool isIncubationComplete;
  final bool isBlotted;
  final bool isFinalWeighed;
  final String textureEn; // e.g. 'Very Turgid & Rigid', 'Firm', 'Slightly Soft', 'Flaccid', 'Plasmolysed & Limp'
  final String textureSw;

  const PotatoSample({
    required this.id,
    required this.labelEn,
    required this.labelSw,
    required this.concentration,
    this.initialMass = 2.00,
    this.finalMass = 2.00,
    this.isPrepared = false,
    this.isInitialWeighed = false,
    this.isImmersed = false,
    this.isIncubationComplete = false,
    this.isBlotted = false,
    this.isFinalWeighed = false,
    this.textureEn = 'Firm / Untreated',
    this.textureSw = 'Kawaida / Haijatibiwa',
  });

  /// Change in mass: delta m = m1 - m0
  double get massChange => finalMass - initialMass;

  /// Percentage change in mass: ((m1 - m0) / m0) * 100
  double get percentChange {
    if (initialMass <= 0) return 0.0;
    return ((finalMass - initialMass) / initialMass) * 100.0;
  }

  PotatoSample copyWith({
    String? id,
    String? labelEn,
    String? labelSw,
    double? concentration,
    double? initialMass,
    double? finalMass,
    bool? isPrepared,
    bool? isInitialWeighed,
    bool? isImmersed,
    bool? isIncubationComplete,
    bool? isBlotted,
    bool? isFinalWeighed,
    String? textureEn,
    String? textureSw,
  }) {
    return PotatoSample(
      id: id ?? this.id,
      labelEn: labelEn ?? this.labelEn,
      labelSw: labelSw ?? this.labelSw,
      concentration: concentration ?? this.concentration,
      initialMass: initialMass ?? this.initialMass,
      finalMass: finalMass ?? this.finalMass,
      isPrepared: isPrepared ?? this.isPrepared,
      isInitialWeighed: isInitialWeighed ?? this.isInitialWeighed,
      isImmersed: isImmersed ?? this.isImmersed,
      isIncubationComplete: isIncubationComplete ?? this.isIncubationComplete,
      isBlotted: isBlotted ?? this.isBlotted,
      isFinalWeighed: isFinalWeighed ?? this.isFinalWeighed,
      textureEn: textureEn ?? this.textureEn,
      textureSw: textureSw ?? this.textureSw,
    );
  }
}

/// Represents an apparatus item to inspect in Step 1
@immutable
class OsmosisApparatusItem {
  final String id;
  final String nameEn;
  final String nameSw;
  final String specEn;
  final String specSw;
  final bool inspected;

  const OsmosisApparatusItem({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.specEn,
    required this.specSw,
    this.inspected = false,
  });

  OsmosisApparatusItem copyWith({bool? inspected}) {
    return OsmosisApparatusItem(
      id: id,
      nameEn: nameEn,
      nameSw: nameSw,
      specEn: specEn,
      specSw: specSw,
      inspected: inspected ?? this.inspected,
    );
  }
}

/// Comprehensive State for the Osmosis in Potato Tissues Virtual Laboratory
@immutable
class OsmosisState {
  final OsmosisStep step;
  final List<PotatoSample> samples;
  final List<OsmosisApparatusItem> apparatus;
  final int activeSampleIndex; // 0..4
  final double balanceDisplay; // grams on digital balance
  final String? balanceOccupiedBySampleId;
  final bool isIncubating;
  final int incubationSeconds; // 0..30 (representing 30 min)
  final int incubationTargetSeconds;
  final bool isIncubationFinished;
  final double? enteredIsotonicConcentration;
  final int experimentDurationSeconds;
  final PracticalMode practicalMode;
  final PracticalScoreResult? scoreResult;

  const OsmosisState({
    required this.step,
    required this.samples,
    required this.apparatus,
    this.activeSampleIndex = 0,
    this.balanceDisplay = 0.00,
    this.balanceOccupiedBySampleId,
    this.isIncubating = false,
    this.incubationSeconds = 0,
    this.incubationTargetSeconds = 30,
    this.isIncubationFinished = false,
    this.enteredIsotonicConcentration,
    this.experimentDurationSeconds = 0,
    this.practicalMode = PracticalMode.guidedPractice,
    this.scoreResult,
  });

  /// Factory for the initial state of the practical
  factory OsmosisState.initial(PracticalMode mode) {
    return OsmosisState(
      step: OsmosisStep.inspectApparatus,
      practicalMode: mode,
      samples: const [
        PotatoSample(
          id: 'A',
          labelEn: 'Tube A: 0.0 M (Distilled Water)',
          labelSw: 'Bomba A: 0.0 M (Maji Yaliyosafishwa)',
          concentration: 0.0,
          initialMass: 2.00,
          finalMass: 2.30, // +15.0%
          textureEn: 'Very Turgid & Stiff',
          textureSw: 'Imevimba Sana na Imekakamaa',
        ),
        PotatoSample(
          id: 'B',
          labelEn: 'Tube B: 0.2 M Sucrose Solution',
          labelSw: 'Bomba B: 0.2 M Myeyusho wa Sukari',
          concentration: 0.2,
          initialMass: 2.02,
          finalMass: 2.16, // +6.9%
          textureEn: 'Firm & Moderately Turgid',
          textureSw: 'Imara na Imevimba Kiasi',
        ),
        PotatoSample(
          id: 'C',
          labelEn: 'Tube C: 0.4 M Sucrose Solution',
          labelSw: 'Bomba C: 0.4 M Myeyusho wa Sukari',
          concentration: 0.4,
          initialMass: 1.98,
          finalMass: 1.94, // -2.0%
          textureEn: 'Slightly Soft (Near Equilibrium)',
          textureSw: 'Laini Kiasi (Karibu na Msawazo)',
        ),
        PotatoSample(
          id: 'D',
          labelEn: 'Tube D: 0.6 M Sucrose Solution',
          labelSw: 'Bomba D: 0.6 M Myeyusho wa Sukari',
          concentration: 0.6,
          initialMass: 2.01,
          finalMass: 1.79, // -10.9%
          textureEn: 'Flaccid & Flexible',
          textureSw: 'Haikakamaa na Inanyumbulika',
        ),
        PotatoSample(
          id: 'E',
          labelEn: 'Tube E: 0.8 M Sucrose Solution',
          labelSw: 'Bomba E: 0.8 M Myeyusho wa Sukari',
          concentration: 0.8,
          initialMass: 1.99,
          finalMass: 1.61, // -19.1%
          textureEn: 'Very Limp / Plasmolysed',
          textureSw: 'Imesinyaa Sana (Plasmolysed)',
        ),
      ],
      apparatus: const [
        OsmosisApparatusItem(
          id: 'potato_tuber',
          nameEn: 'Fresh Potato Tuber (Solanum tuberosum)',
          nameSw: 'Kiazi Mviringo Kibichi (Solanum tuberosum)',
          specEn: 'Firm, uniform storage parenchyma tissue containing osmotic cell sap.',
          specSw: 'Tishu ya viazi yenye majimaji ya seli za mmea kwa ajili ya osmosisi.',
        ),
        OsmosisApparatusItem(
          id: 'cork_borer',
          nameEn: 'Cork Borer & Ceramic Cutting Tile',
          nameSw: 'Kikatia cha Kizibo na Kigae cha Kauri',
          specEn: 'Standard #4 size (8 mm diameter) for cutting uniform potato cylinders.',
          specSw: 'Kipenyo cha mm 8 cha kukata vipande vinavyolingana vya viazi.',
        ),
        OsmosisApparatusItem(
          id: 'scalpel_ruler',
          nameEn: 'Surgical Scalpel & Millimeter Ruler',
          nameSw: 'Kisu cha Upasuaji na Rula ya Milimita',
          specEn: 'Used to trim cylinders to exact equal lengths (40 mm) removing potato skin.',
          specSw: 'Inatumika kukata urefu sawa (mm 40) na kumenya gome la kiazi.',
        ),
        OsmosisApparatusItem(
          id: 'digital_balance',
          nameEn: 'Electronic Digital Balance (0.01 g)',
          nameSw: 'Mzani wa Kidijitali (Usahihi 0.01 g)',
          specEn: 'High-precision tare balance for accurate initial (m₀) and final (m₁) mass recording.',
          specSw: 'Mzani sahihi wa kupima uzito wa awali na wa mwisho wa viazi.',
        ),
        OsmosisApparatusItem(
          id: 'boiling_tubes',
          nameEn: '5 Boiling Tubes in Wooden Rack',
          nameSw: 'Mabomba 5 ya Kuchemshia kwenye Raki ya Mbao',
          specEn: 'Labelled A to E containing 20 mL of graded sucrose solutions.',
          specSw: 'Mabomba yenye lebo A hadi E yenye mililita 20 za sukari.',
        ),
        OsmosisApparatusItem(
          id: 'filter_paper',
          nameEn: 'Filter Paper & Forceps',
          nameSw: 'Karatasi ya Kuchuja na Koleo (Forceps)',
          specEn: 'Used to gently blot excess surface solution off potato cylinders before re-weighing.',
          specSw: 'Kukausha matone ya maji ya juu kabla ya kupima uzito tena.',
        ),
      ],
    );
  }

  bool get allApparatusInspected => apparatus.every((item) => item.inspected);
  bool get allSamplesPrepared => samples.every((s) => s.isPrepared);
  bool get allInitialWeighed => samples.every((s) => s.isInitialWeighed);
  bool get allImmersed => samples.every((s) => s.isImmersed);
  bool get allBlottedAndFinalWeighed => samples.every((s) => s.isBlotted && s.isFinalWeighed);

  PotatoSample get activeSample => samples[activeSampleIndex.clamp(0, samples.length - 1)];

  /// Computes the linear regression or interpolated isotonic point where % change in mass is 0%
  /// y = m*x + c  =>  at y=0, x_iso = -c / m
  double get calculatedIsotonicConcentration {
    // Using least squares on (concentration, percentChange)
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = samples.length;
    for (final s in samples) {
      final x = s.concentration;
      final y = s.percentChange;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final denom = (n * sumXX - sumX * sumX);
    if (denom.abs() < 1e-6) return 0.36;
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    if (slope.abs() < 1e-6) return 0.36;
    final xIso = -intercept / slope;
    return double.parse(xIso.toStringAsFixed(2));
  }

  static const Object _sentinel = Object();

  OsmosisState copyWith({
    OsmosisStep? step,
    List<PotatoSample>? samples,
    List<OsmosisApparatusItem>? apparatus,
    int? activeSampleIndex,
    double? balanceDisplay,
    Object? balanceOccupiedBySampleId = _sentinel,
    bool? isIncubating,
    int? incubationSeconds,
    int? incubationTargetSeconds,
    bool? isIncubationFinished,
    double? enteredIsotonicConcentration,
    int? experimentDurationSeconds,
    PracticalMode? practicalMode,
    PracticalScoreResult? scoreResult,
  }) {
    return OsmosisState(
      step: step ?? this.step,
      samples: samples ?? this.samples,
      apparatus: apparatus ?? this.apparatus,
      activeSampleIndex: activeSampleIndex ?? this.activeSampleIndex,
      balanceDisplay: balanceDisplay ?? this.balanceDisplay,
      balanceOccupiedBySampleId: identical(balanceOccupiedBySampleId, _sentinel)
          ? this.balanceOccupiedBySampleId
          : balanceOccupiedBySampleId as String?,
      isIncubating: isIncubating ?? this.isIncubating,
      incubationSeconds: incubationSeconds ?? this.incubationSeconds,
      incubationTargetSeconds: incubationTargetSeconds ?? this.incubationTargetSeconds,
      isIncubationFinished: isIncubationFinished ?? this.isIncubationFinished,
      enteredIsotonicConcentration: enteredIsotonicConcentration ?? this.enteredIsotonicConcentration,
      experimentDurationSeconds: experimentDurationSeconds ?? this.experimentDurationSeconds,
      practicalMode: practicalMode ?? this.practicalMode,
      scoreResult: scoreResult ?? this.scoreResult,
    );
  }
}
