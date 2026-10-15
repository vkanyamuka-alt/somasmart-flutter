import 'dart:math' as math;
import 'practical_model.dart';
import 'practical_score_result.dart';

/// Steps in the Guided Practice mode of the Refraction & Prism practical.
enum OpticsStep {
  inspectApparatus,
  alignPrismAndNormal,
  setIncidentAngle,
  placePinsAndTraceRay,
  observationTable,
  graphAnalysis,
  calculateRefractiveIndex,
}

extension OpticsStepExtension on OpticsStep {
  String get titleEn {
    switch (this) {
      case OpticsStep.inspectApparatus:
        return '1. Inspect Apparatus';
      case OpticsStep.alignPrismAndNormal:
        return '2. Align Prism & Normal';
      case OpticsStep.setIncidentAngle:
        return '3. Set Incident Angle';
      case OpticsStep.placePinsAndTraceRay:
        return '4. Place Pins & Trace Ray';
      case OpticsStep.observationTable:
        return '5. Observation Table';
      case OpticsStep.graphAnalysis:
        return '6. sin(i)–sin(r) Graph';
      case OpticsStep.calculateRefractiveIndex:
        return '7. Calculate Refractive Index (n)';
    }
  }

  String get titleSw {
    switch (this) {
      case OpticsStep.inspectApparatus:
        return '1. Kagua Vifaa';
      case OpticsStep.alignPrismAndNormal:
        return '2. Pangilia Mche na Msambamba';
      case OpticsStep.setIncidentAngle:
        return '3. Weka Pembe ya Mwanga';
      case OpticsStep.placePinsAndTraceRay:
        return '4. Weka Pini na Fuatilia Miale';
      case OpticsStep.observationTable:
        return '5. Jedwali la Vipimo';
      case OpticsStep.graphAnalysis:
        return '6. Grafu ya sin(i)–sin(r)';
      case OpticsStep.calculateRefractiveIndex:
        return '7. Hesabu Kielezo cha Mgawanyiko (n)';
    }
  }

  String get descriptionEn {
    switch (this) {
      case OpticsStep.inspectApparatus:
        return 'Examine the triangular glass prism, optical drawing board, optical pins, protractor, and laser ray source.';
      case OpticsStep.alignPrismAndNormal:
        return 'Position the equilateral triangular glass prism (A = 60.0°) and draw the perpendicular normal line (N1) on face AB.';
      case OpticsStep.setIncidentAngle:
        return 'Adjust the angle of incidence (i) between 30.0° and 60.0° relative to the normal line.';
      case OpticsStep.placePinsAndTraceRay:
        return 'Align optical pins P1, P2 on the incident beam and P3, P4 on the emergent ray to trace the path.';
      case OpticsStep.observationTable:
        return 'Record angles of incidence (i), refraction (r), emergence (e), and deviation (D) across multiple trials.';
      case OpticsStep.graphAnalysis:
        return 'Plot sin(i) against sin(r) and determine the linear regression gradient representing refractive index (n).';
      case OpticsStep.calculateRefractiveIndex:
        return 'Apply Snell’s Law (n = sin(i)/sin(r)) and verify the refractive index of crown glass against accepted value (1.500).';
    }
  }

  String get descriptionSw {
    switch (this) {
      case OpticsStep.inspectApparatus:
        return 'Kagua mche wa kioo wa pembe tatu, ubao wa kuchorea, pini za macho, kipimapembe, na chanzo cha mwanga.';
      case OpticsStep.alignPrismAndNormal:
        return 'Weka mche wa kioo (A = 60.0°) na chora msambamba (N1) kwenye uso wa kwanza wa AB.';
      case OpticsStep.setIncidentAngle:
        return 'Rekebisha pembe ya mwanga (i) kati ya 30.0° na 60.0° kulingana na mstari msambamba.';
      case OpticsStep.placePinsAndTraceRay:
        return 'Pangilia pini P1, P2 kwenye mwale unaoingia na P3, P4 kwenye mwale unaotoka ili kuona mkondo wa mwanga.';
      case OpticsStep.observationTable:
        return 'Hifadhi vipimo vya pembe za kuingia (i), kupinda (r), kutoka (e), na mgawanyiko (D) kwa majaribio mbalimbali.';
      case OpticsStep.graphAnalysis:
        return 'Chora grafu ya sin(i) dhidi ya sin(r) na utafute mteremko wa mstari unaowakilisha kielezo cha kioo (n).';
      case OpticsStep.calculateRefractiveIndex:
        return 'Tumia Kanuni ya Snell (n = sin(i)/sin(r)) na uhakiki kielezo cha kioo kulingana na thamani halisi (1.500).';
    }
  }
}

/// An individual apparatus item in the optics laboratory bench.
class OpticsApparatusItem {
  final String id;
  final String nameEn;
  final String nameSw;
  final String descriptionEn;
  final String descriptionSw;
  final bool isInspected;

  const OpticsApparatusItem({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.descriptionEn,
    required this.descriptionSw,
    this.isInspected = false,
  });

  OpticsApparatusItem copyWith({bool? isInspected}) {
    return OpticsApparatusItem(
      id: id,
      nameEn: nameEn,
      nameSw: nameSw,
      descriptionEn: descriptionEn,
      descriptionSw: descriptionSw,
      isInspected: isInspected ?? this.isInspected,
    );
  }
}

/// A recorded observation trial for a specific angle of incidence.
class OpticsTrial {
  final int trialNumber;
  final double incidentAngleDeg; // i (degrees)
  final double refractedAngleDeg; // r1 (degrees)
  final double emergentAngleDeg; // e (degrees)
  final double deviationAngleDeg; // D = i + e - A (degrees)
  final double sinI; // sin(i)
  final double sinR; // sin(r)
  final double calculatedIndex; // sin(i) / sin(r)

  const OpticsTrial({
    required this.trialNumber,
    required this.incidentAngleDeg,
    required this.refractedAngleDeg,
    required this.emergentAngleDeg,
    required this.deviationAngleDeg,
    required this.sinI,
    required this.sinR,
    required this.calculatedIndex,
  });

  Map<String, dynamic> toMap() => {
        'trialNumber': trialNumber,
        'incidentAngleDeg': incidentAngleDeg,
        'refractedAngleDeg': refractedAngleDeg,
        'emergentAngleDeg': emergentAngleDeg,
        'deviationAngleDeg': deviationAngleDeg,
        'sinI': sinI,
        'sinR': sinR,
        'calculatedIndex': calculatedIndex,
      };

  factory OpticsTrial.fromAngles({
    required int trialNumber,
    required double incidentAngleDeg,
    double glassRefractiveIndex = 1.500,
    double prismAngleDeg = 60.0,
  }) {
    final iRad = incidentAngleDeg * math.pi / 180.0;
    final sinI = math.sin(iRad);
    final sinR = (sinI / glassRefractiveIndex).clamp(0.0, 1.0);
    final r1Rad = math.asin(sinR);
    final r1Deg = r1Rad * 180.0 / math.pi;

    // Inside prism: r2 = A - r1
    final r2Deg = prismAngleDeg - r1Deg;
    final r2Rad = r2Deg * math.pi / 180.0;
    final sinE = (glassRefractiveIndex * math.sin(r2Rad)).clamp(0.0, 1.0);
    final eRad = math.asin(sinE);
    final eDeg = eRad * 180.0 / math.pi;

    final dDeg = (incidentAngleDeg + eDeg) - prismAngleDeg;
    final calculatedIndex = sinR > 0 ? (sinI / sinR) : glassRefractiveIndex;

    return OpticsTrial(
      trialNumber: trialNumber,
      incidentAngleDeg: incidentAngleDeg,
      refractedAngleDeg: double.parse(r1Deg.toStringAsFixed(1)),
      emergentAngleDeg: double.parse(eDeg.toStringAsFixed(1)),
      deviationAngleDeg: double.parse(dDeg.toStringAsFixed(1)),
      sinI: double.parse(sinI.toStringAsFixed(3)),
      sinR: double.parse(sinR.toStringAsFixed(3)),
      calculatedIndex: double.parse(calculatedIndex.toStringAsFixed(3)),
    );
  }
}

/// Pure domain state model for the Refraction & Prism Virtual Laboratory simulation.
class OpticsState {
  final PracticalMode mode;
  final OpticsStep step;
  final double incidentAngleDeg; // i in degrees (30.0 - 60.0)
  final double prismRefractingAngleDeg; // A = 60.0 degrees
  final double trueGlassRefractiveIndex; // 1.500 (Crown Glass)
  final bool showProtractor;
  final bool showNormalLines;
  final bool showOpticalPins;
  final bool showRayExtension;
  final bool laserActive;
  final List<OpticsApparatusItem> apparatusItems;
  final List<OpticsTrial> recordedTrials;
  final double studentCalculatedIndex;
  final int experimentDurationSeconds;
  final List<String> notebookLogs;
  final PracticalScoreResult? scoreResult;
  final bool isCompleted;

  const OpticsState({
    this.mode = PracticalMode.guidedPractice,
    this.step = OpticsStep.inspectApparatus,
    this.incidentAngleDeg = 45.0,
    this.prismRefractingAngleDeg = 60.0,
    this.trueGlassRefractiveIndex = 1.500,
    this.showProtractor = true,
    this.showNormalLines = true,
    this.showOpticalPins = true,
    this.showRayExtension = true,
    this.laserActive = true,
    this.apparatusItems = defaultApparatus,
    this.recordedTrials = const [],
    this.studentCalculatedIndex = 0.0,
    this.experimentDurationSeconds = 0,
    this.notebookLogs = const [],
    this.scoreResult,
    this.isCompleted = false,
  });

  static const List<OpticsApparatusItem> defaultApparatus = [
    OpticsApparatusItem(
      id: 'prism',
      nameEn: 'Equilateral Glass Prism',
      nameSw: 'Mche wa Kioo wa Pembe Tatu',
      descriptionEn: 'Refracting angle A = 60.0°, high optical clarity crown glass with polished faces.',
      descriptionSw: 'Pembe ya mgawanyiko A = 60.0°, kioo safi cha daraja la juu na nyuso zilizosuguliwa.',
    ),
    OpticsApparatusItem(
      id: 'board',
      nameEn: 'Optical Drawing Board & Sheet',
      nameSw: 'Ubao wa Kuchorea na Karatasi',
      descriptionEn: 'Softwood drawing board with clean white paper secured by fixing thumb-pins.',
      descriptionSw: 'Ubao laini wenye karatasi nyeupe iliyofungwa kwa pini za pembeni.',
    ),
    OpticsApparatusItem(
      id: 'pins',
      nameEn: 'Optical Target Pins (P1–P4)',
      nameSw: 'Pini za Macho (P1–P4)',
      descriptionEn: 'Stainless steel optical pins used for ray tracing alignment along incident and emergent paths.',
      descriptionSw: 'Pini za chuma zisizopinda zinazotumiwa kupangilia mwelekeo wa miale ya mwanga.',
    ),
    OpticsApparatusItem(
      id: 'protractor',
      nameEn: '360°/180° Optical Protractor',
      nameSw: 'Kipimapembe cha Macho',
      descriptionEn: 'Clear circular degree scale graduated in 1° intervals for accurate normal and ray angle measurement.',
      descriptionSw: 'Kipimapembe cha uwazi chenye vipimo vya digrii 1° kwa upimaji sahihi wa pembe za mwanga.',
    ),
    OpticsApparatusItem(
      id: 'light_source',
      nameEn: 'Monochromatic Laser / Ray Box',
      nameSw: 'Chanzo cha Mwale wa Mwanga / Laser',
      descriptionEn: 'High-intensity collimated single-slit optical ray emitter providing narrow light beam.',
      descriptionSw: 'Kifaa cha kutoa mwale mwembamba na wenye nguvu wa mwanga wa laser.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Real-Time Optical Geometry Computations
  // ---------------------------------------------------------------------------

  /// Angle of refraction at first face: r1 = arcsin(sin(i) / n)
  double get refractedAngleDeg {
    final iRad = incidentAngleDeg * math.pi / 180.0;
    final sinI = math.sin(iRad);
    final sinR = (sinI / trueGlassRefractiveIndex).clamp(0.0, 1.0);
    return (math.asin(sinR) * 180.0 / math.pi);
  }

  /// Angle of incidence at second internal face: r2 = A - r1
  double get internalIncidenceAngleDeg {
    return prismRefractingAngleDeg - refractedAngleDeg;
  }

  /// Angle of emergence at second face: e = arcsin(n * sin(r2))
  double get emergentAngleDeg {
    final r2Rad = internalIncidenceAngleDeg * math.pi / 180.0;
    final sinE = (trueGlassRefractiveIndex * math.sin(r2Rad)).clamp(0.0, 1.0);
    return (math.asin(sinE) * 180.0 / math.pi);
  }

  /// Angle of deviation: D = (i + e) - A
  double get deviationAngleDeg {
    return (incidentAngleDeg + emergentAngleDeg) - prismRefractingAngleDeg;
  }

  /// sin(i)
  double get sinI => math.sin(incidentAngleDeg * math.pi / 180.0);

  /// sin(r)
  double get sinR => math.sin(refractedAngleDeg * math.pi / 180.0);

  /// Real-time Snell ratio: sin(i) / sin(r)
  double get currentSnellRatio => sinR > 0 ? (sinI / sinR) : trueGlassRefractiveIndex;

  /// Determines if all apparatus items have been inspected
  bool get allApparatusInspected => apparatusItems.every((item) => item.isInspected);

  /// Calculates the linear regression slope m for the graph of sin(i) vs sin(r).
  /// When sin(i) = n * sin(r), slope m = n_glass.
  double get regressionSlope {
    if (recordedTrials.isEmpty) return trueGlassRefractiveIndex;
    if (recordedTrials.length == 1) return recordedTrials.first.calculatedIndex;

    // Linear regression constrained through origin: m = sum(x*y) / sum(x^2)
    // where x = sin(r), y = sin(i)
    double sumXY = 0.0;
    double sumX2 = 0.0;

    for (final trial in recordedTrials) {
      final x = trial.sinR;
      final y = trial.sinI;
      sumXY += x * y;
      sumX2 += x * x;
    }

    if (sumX2 == 0) return trueGlassRefractiveIndex;
    return sumXY / sumX2;
  }

  /// Experimental refractive index derived from the observation graph slope
  double get experimentalRefractiveIndex {
    if (studentCalculatedIndex > 0) return studentCalculatedIndex;
    return double.parse(regressionSlope.toStringAsFixed(3));
  }

  /// Percentage error against the accepted standard crown glass value (1.500)
  double get percentageError {
    final diff = (experimentalRefractiveIndex - trueGlassRefractiveIndex).abs();
    return (diff / trueGlassRefractiveIndex) * 100.0;
  }

  OpticsState copyWith({
    PracticalMode? mode,
    OpticsStep? step,
    double? incidentAngleDeg,
    double? prismRefractingAngleDeg,
    double? trueGlassRefractiveIndex,
    bool? showProtractor,
    bool? showNormalLines,
    bool? showOpticalPins,
    bool? showRayExtension,
    bool? laserActive,
    List<OpticsApparatusItem>? apparatusItems,
    List<OpticsTrial>? recordedTrials,
    double? studentCalculatedIndex,
    int? experimentDurationSeconds,
    List<String>? notebookLogs,
    PracticalScoreResult? scoreResult,
    bool? isCompleted,
  }) {
    return OpticsState(
      mode: mode ?? this.mode,
      step: step ?? this.step,
      incidentAngleDeg: incidentAngleDeg ?? this.incidentAngleDeg,
      prismRefractingAngleDeg: prismRefractingAngleDeg ?? this.prismRefractingAngleDeg,
      trueGlassRefractiveIndex: trueGlassRefractiveIndex ?? this.trueGlassRefractiveIndex,
      showProtractor: showProtractor ?? this.showProtractor,
      showNormalLines: showNormalLines ?? this.showNormalLines,
      showOpticalPins: showOpticalPins ?? this.showOpticalPins,
      showRayExtension: showRayExtension ?? this.showRayExtension,
      laserActive: laserActive ?? this.laserActive,
      apparatusItems: apparatusItems ?? this.apparatusItems,
      recordedTrials: recordedTrials ?? this.recordedTrials,
      studentCalculatedIndex: studentCalculatedIndex ?? this.studentCalculatedIndex,
      experimentDurationSeconds: experimentDurationSeconds ?? this.experimentDurationSeconds,
      notebookLogs: notebookLogs ?? this.notebookLogs,
      scoreResult: scoreResult ?? this.scoreResult,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
