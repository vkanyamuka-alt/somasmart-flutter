class CompetencyScore {
  final String nameEn;
  final String nameSw;
  final int score;

  const CompetencyScore({
    required this.nameEn,
    required this.nameSw,
    required this.score,
  });
}

class PracticalScoreResult {
  final String practicalNameEn;
  final String practicalNameSw;
  final int totalScore;
  final String grade;
  final double errorPercentage;
  final double studentMolarity;
  final double theoreticalMolarity;
  final double studentTitreVolume;
  final String durationFormatted;
  final List<CompetencyScore> competencies;
  final List<String> achievementsEn;
  final List<String> achievementsSw;

  const PracticalScoreResult({
    required this.practicalNameEn,
    required this.practicalNameSw,
    required this.totalScore,
    required this.grade,
    required this.errorPercentage,
    required this.studentMolarity,
    required this.theoreticalMolarity,
    required this.studentTitreVolume,
    required this.durationFormatted,
    required this.competencies,
    required this.achievementsEn,
    required this.achievementsSw,
  });

  static PracticalScoreResult calculateTitrationScore({
    required double studentMolarity,
    required double studentTitre,
    required int durationSeconds,
  }) {
    const theoreticalMolarity = 0.0980; // 0.10M * 24.50mL / 25.0mL
    final errorFraction = (studentMolarity - theoreticalMolarity).abs() / theoreticalMolarity;
    final errorPercentage = errorFraction * 100;

    int finalScore;
    String grade;
    if (errorFraction == 0.0) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.05) {
      finalScore = 95;
      grade = 'A+ (Distinction)';
    } else {
      finalScore = 85;
      grade = 'A (Credit)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Equipment Handling (${(95 * (finalScore / 100)).round()}%)',
        nameSw: 'Utunzaji wa Vifaa (${(95 * (finalScore / 100)).round()}%)',
        score: (95 * (finalScore / 100)).round(),
      ),
      CompetencyScore(
        nameEn: 'Measurement Accuracy (${(90 * (finalScore / 100)).round()}%)',
        nameSw: 'Usahihi wa Vipimo (${(90 * (finalScore / 100)).round()}%)',
        score: (90 * (finalScore / 100)).round(),
      ),
      CompetencyScore(
        nameEn: 'Observation Skills (${(98 * (finalScore / 100)).round()}%)',
        nameSw: 'Umakini wa Uchunguzi (${(98 * (finalScore / 100)).round()}%)',
        score: (98 * (finalScore / 100)).round(),
      ),
      CompetencyScore(
        nameEn: 'Calculation Accuracy ($finalScore%)',
        nameSw: 'Usahihi wa Mahesabu ($finalScore%)',
        score: finalScore,
      ),
      CompetencyScore(
        nameEn: 'Laboratory Safety (100%)',
        nameSw: 'Usalama wa Maabara (100%)',
        score: 100,
      ),
    ];

    final achievementsEn = [
      'First Practical Completed',
      'Perfect Technique',
      'Excellent Safety Compliance',
      'Accurate Measurements',
      'Fast Completion',
    ];

    final achievementsSw = [
      'Jaribio la Kwanza Limekamilika',
      'Mbinu Bora ya Upimaji',
      'Uzingatiaji Bora wa Usalama',
      'Vipimo Sahihi vya Ujazo',
      'Ukamilishaji wa Haraka',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Acid–Base Titration (HCl vs NaOH)',
      practicalNameSw: 'Titration ya Asidi na Besi (HCl vs NaOH)',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentMolarity,
      theoreticalMolarity: theoreticalMolarity,
      studentTitreVolume: studentTitre,
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateOhmsLawScore({
    required double studentResistance,
    required double theoreticalResistance,
    required int recordedReadingsCount,
    required int inspectedCount,
    required int durationSeconds,
  }) {
    final errorFraction = theoreticalResistance > 0
        ? (studentResistance - theoreticalResistance).abs() / theoreticalResistance
        : 0.0;
    final errorPercentage = errorFraction * 100;

    int finalScore;
    String grade;
    if (errorFraction == 0.0) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.05) {
      finalScore = 95;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.15) {
      finalScore = 85;
      grade = 'A (Credit)';
    } else {
      finalScore = 70;
      grade = 'B (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 4 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 4 ? 100 : 75)}%)',
        score: inspectedCount >= 4 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Circuit Assembly (100%)',
        nameSw: 'Uunganishaji wa Saketi (100%)',
        score: 100,
      ),
      CompetencyScore(
        nameEn: 'Data Collection (${(recordedReadingsCount >= 3 ? 100 : 60)}%)',
        nameSw: 'Ukusanyaji wa Data (${(recordedReadingsCount >= 3 ? 100 : 60)}%)',
        score: recordedReadingsCount >= 3 ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Slope & Calculation ($finalScore%)',
        nameSw: 'Mteremko na Mahesabu ($finalScore%)',
        score: finalScore,
      ),
      CompetencyScore(
        nameEn: 'Laboratory Safety (100%)',
        nameSw: 'Usalama wa Maabara (100%)',
        score: 100,
      ),
    ];

    final achievementsEn = [
      'Physics Circuit Master',
      'Ohm’s Law Verified',
      'Linear Slope Precision',
      'Accurate Meter Readings',
      'Safety Compliance',
    ];

    final achievementsSw = [
      'Bingwa wa Saketi za Fizikia',
      'Sheria ya Ohm Imethibitishwa',
      'Usahihi wa Mteremko wa Grafu',
      'Vipimo Sahihi vya Mita',
      'Uzingatiaji wa Usalama',
    ];

    return PracticalScoreResult(
      practicalNameEn: "Ohm's Law Verification (V = IR)",
      practicalNameSw: "Uhakiki wa Sheria ya Ohm (V = IR)",
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentResistance, // stored as student calculated value
      theoreticalMolarity: theoreticalResistance, // stored as theoretical value
      studentTitreVolume: recordedReadingsCount.toDouble(),
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateMicroscopeScore({
    required int studentMagnification,
    required int theoreticalMagnification,
    required int identifiedOrganellesCount,
    required int totalTargetOrganelles,
    required bool slideProperlyPrepared,
    required bool focusedSuccessfully,
    required int inspectedCount,
    required int durationSeconds,
  }) {
    final magError = theoreticalMagnification > 0
        ? (studentMagnification - theoreticalMagnification).abs() / theoreticalMagnification
        : 0.0;
    final organelleRatio = totalTargetOrganelles > 0
        ? (identifiedOrganellesCount / totalTargetOrganelles).clamp(0.0, 1.0)
        : 1.0;

    int finalScore = 0;
    // Slide prep: 25 pts
    if (slideProperlyPrepared) finalScore += 25;
    // Focusing: 25 pts
    if (focusedSuccessfully) finalScore += 25;
    // Organelles identified: 25 pts
    finalScore += (25 * organelleRatio).round();
    // Magnification calculation: 25 pts
    if (magError == 0.0) {
      finalScore += 25;
    } else if (magError < 0.1) {
      finalScore += 15;
    }

    String grade;
    if (finalScore >= 95) {
      grade = 'A+ (Distinction)';
    } else if (finalScore >= 80) {
      grade = 'A (Credit)';
    } else if (finalScore >= 65) {
      grade = 'B (Pass)';
    } else {
      grade = 'C (Satisfactory)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 4 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 4 ? 100 : 75)}%)',
        score: inspectedCount >= 4 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Wet Mount Slide Preparation (${(slideProperlyPrepared ? 100 : 50)}%)',
        nameSw: 'Utayarishaji wa Kiolezo cha Kioo (${(slideProperlyPrepared ? 100 : 50)}%)',
        score: slideProperlyPrepared ? 100 : 50,
      ),
      CompetencyScore(
        nameEn: 'Microscope Optical Focusing (${(focusedSuccessfully ? 100 : 60)}%)',
        nameSw: 'Uelekezaji wa Lenzi ya Darubini (${(focusedSuccessfully ? 100 : 60)}%)',
        score: focusedSuccessfully ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Cytological Organelle Identification (${(organelleRatio * 100).round()}%)',
        nameSw: 'Utambuzi wa Sehemu za Seli (${(organelleRatio * 100).round()}%)',
        score: (organelleRatio * 100).round(),
      ),
      CompetencyScore(
        nameEn: 'Magnification Calculation (${(magError == 0.0 ? 100 : 60)}%)',
        nameSw: 'Hesabu ya Kukuza kwa Darubini (${(magError == 0.0 ? 100 : 60)}%)',
        score: magError == 0.0 ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Laboratory Safety (100%)',
        nameSw: 'Usalama wa Maabara (100%)',
        score: 100,
      ),
    ];

    final achievementsEn = [
      'Cytology Specialist',
      'Plant Cell Stained',
      'Optical Focus Mastery',
      'Organelles Identified',
      'Accurate Magnification',
    ];

    final achievementsSw = [
      'Bingwa wa Biolojia ya Seli',
      'Seli za Mmea Zilizopakwa Rangi',
      'Uelekezaji Bora wa Lenzi',
      'Utambuzi Sahihi wa Kokwa na Kuta',
      'Hesabu Sahihi ya Kukuza',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Light Microscope Plant Cell Staining',
      practicalNameSw: 'Upakaji Rangi na Uchunguzi wa Seli za Mimea',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: magError * 100,
      studentMolarity: studentMagnification.toDouble(),
      theoreticalMolarity: theoreticalMagnification.toDouble(),
      studentTitreVolume: identifiedOrganellesCount.toDouble(),
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculatePendulumScore({
    required double studentGravity,
    required double theoreticalGravity,
    required int recordedTrialsCount,
    required int inspectedCount,
    required bool smallAngleMaintained,
    required int durationSeconds,
  }) {
    final errorFraction = theoreticalGravity > 0
        ? (studentGravity - theoreticalGravity).abs() / theoreticalGravity
        : 0.0;
    final errorPercentage = errorFraction * 100;

    int finalScore;
    String grade;
    if (errorFraction < 0.03) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.08) {
      finalScore = 92;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.15) {
      finalScore = 84;
      grade = 'A (Credit)';
    } else {
      finalScore = 70;
      grade = 'B (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 4 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 4 ? 100 : 75)}%)',
        score: inspectedCount >= 4 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Small-Angle Condition (θ ≤ 10°) (${(smallAngleMaintained ? 100 : 60)}%)',
        nameSw: 'Pembe Ndogo ya Mtetemo (${(smallAngleMaintained ? 100 : 60)}%)',
        score: smallAngleMaintained ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Multi-Trial Data Collection (${(recordedTrialsCount >= 3 ? 100 : 60)}%)',
        nameSw: 'Ukusanyaji wa Data za Majaribio (${(recordedTrialsCount >= 3 ? 100 : 60)}%)',
        score: recordedTrialsCount >= 3 ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Linear Slope & Gravity Determination ($finalScore%)',
        nameSw: 'Mteremko wa Grafu na Kani ya Mvuto ($finalScore%)',
        score: finalScore,
      ),
      CompetencyScore(
        nameEn: 'Laboratory Safety (100%)',
        nameSw: 'Usalama wa Maabara (100%)',
        score: 100,
      ),
    ];

    final achievementsEn = [
      'Classical Mechanics Master',
      'Gravitational Precision',
      'Harmonic Motion Verified',
      'Linear Regression T²-L',
      'Stopwatch Timing Accuracy',
    ];

    final achievementsSw = [
      'Bingwa wa Makanika ya Asili',
      'Usahihi wa Kani ya Mvuto',
      'Mtetemo wa Harmonic Umethibitishwa',
      'Mteremko wa Grafu T²-L',
      'Usahihi wa Saa ya Kupimia',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Simple Pendulum Gravitational Acceleration (g)',
      practicalNameSw: 'Kipimio cha Mvuto wa Dunia (g) kwa Penduli',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentGravity,
      theoreticalMolarity: theoreticalGravity,
      studentTitreVolume: recordedTrialsCount.toDouble(),
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateOpticsScore({
    required double studentIndex,
    required double theoreticalIndex,
    required int recordedTrialsCount,
    required int inspectedCount,
    required int durationSeconds,
  }) {
    final errorFraction = theoreticalIndex > 0
        ? (studentIndex - theoreticalIndex).abs() / theoreticalIndex
        : 0.0;
    final errorPercentage = errorFraction * 100;

    int finalScore;
    String grade;
    if (errorFraction < 0.03) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.08) {
      finalScore = 92;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.15) {
      finalScore = 84;
      grade = 'A (Credit)';
    } else {
      finalScore = 70;
      grade = 'B (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 4 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 4 ? 100 : 75)}%)',
        score: inspectedCount >= 4 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Snell’s Law & Prism Alignment (100%)',
        nameSw: 'Sheria ya Snell na Mpangilio wa Mche (100%)',
        score: 100,
      ),
      CompetencyScore(
        nameEn: 'Multi-Angle Data Collection (${(recordedTrialsCount >= 3 ? 100 : 60)}%)',
        nameSw: 'Ukusanyaji wa Data za Pembe (${(recordedTrialsCount >= 3 ? 100 : 60)}%)',
        score: recordedTrialsCount >= 3 ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Linear Slope & Refractive Index ($finalScore%)',
        nameSw: 'Mteremko wa Grafu na Kielezo cha Kioo ($finalScore%)',
        score: finalScore,
      ),
      CompetencyScore(
        nameEn: 'Laboratory Safety & Optical Care (100%)',
        nameSw: 'Usalama na Utunzaji wa Vifaa vya Macho (100%)',
        score: 100,
      ),
    ];

    final achievementsEn = [
      'Geometrical Optics Master',
      'Snell’s Law Verified',
      'Prism Refraction Precision',
      'Linear Regression sin(i)–sin(r)',
      'Accurate Optical Angle Measurement',
    ];

    final achievementsSw = [
      'Bingwa wa Jiometri ya Mwanga',
      'Sheria ya Snell Imethibitishwa',
      'Usahihi wa Mche wa Kioo',
      'Mteremko wa Grafu sin(i)–sin(r)',
      'Upimaji Sahihi wa Pembe za Mwanga',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Refraction & Prism Refractive Index',
      practicalNameSw: 'Mchepuko na Kielezo cha Mgawanyiko wa Mwanga',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentIndex,
      theoreticalMolarity: theoreticalIndex,
      studentTitreVolume: recordedTrialsCount.toDouble(),
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateOsmosisScore({
    required double studentIsotonicConc,
    required double theoreticalIsotonicConc,
    required int inspectedCount,
    required int preparedCount,
    required int weighedCount,
    required int durationSeconds,
  }) {
    final errorFraction = (studentIsotonicConc - theoreticalIsotonicConc).abs() / theoreticalIsotonicConc;
    final errorPercentage = (errorFraction * 100).clamp(0.0, 100.0);

    int finalScore;
    String grade;
    if (errorFraction < 0.05) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.10) {
      finalScore = 95;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.15) {
      finalScore = 85;
      grade = 'A (Excellent)';
    } else if (errorFraction < 0.25) {
      finalScore = 75;
      grade = 'B (Good)';
    } else {
      finalScore = 65;
      grade = 'C (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 5 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 5 ? 100 : 75)}%)',
        score: inspectedCount >= 5 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Cylinder Preparation & Tare Weighing (${(preparedCount >= 5 ? 100 : 80)}%)',
        nameSw: 'Ukataji na Upimaji wa Uzito wa Awali (${(preparedCount >= 5 ? 100 : 80)}%)',
        score: preparedCount >= 5 ? 100 : 80,
      ),
      CompetencyScore(
        nameEn: 'Graded Incubation & Water Flux Control (100%)',
        nameSw: 'Udhibiti wa Muda na Mtiririko wa Maji (100%)',
        score: 100,
      ),
      CompetencyScore(
        nameEn: 'Blotting & Final Mass Measurement (${(weighedCount >= 5 ? 100 : 80)}%)',
        nameSw: 'Ukaushaji na Upimaji wa Mwisho wa Uzito (${(weighedCount >= 5 ? 100 : 80)}%)',
        score: weighedCount >= 5 ? 100 : 80,
      ),
      CompetencyScore(
        nameEn: 'Graphing & Isotonic Point Determination ($finalScore%)',
        nameSw: 'Uchoraji wa Grafu na Eneo la Msawazo ($finalScore%)',
        score: finalScore,
      ),
    ];

    final achievementsEn = [
      'Osmosis & Water Potential Master',
      'Plant Tissue Equilibrium Expert',
      'Precision Digital Mass Determination',
      'Concentration Gradient Analysis',
      'Isotonic Point Zero-Crossing Verified',
    ];

    final achievementsSw = [
      'Bingwa wa Osmosisi na Uwezo wa Maji',
      'Mtaalamu wa Msawazo wa Tishu za Mimea',
      'Upimaji Sahihi wa Uzito wa Kidijitali',
      'Uchambuzi wa Mgandamizo wa Myeyusho',
      'Eneo la Msawazo Limethibitishwa',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Osmosis in Potato Tissues',
      practicalNameSw: 'Mchakato wa Osmosis kwenye Viazi',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentIsotonicConc,
      theoreticalMolarity: theoreticalIsotonicConc,
      studentTitreVolume: 5.0,
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateRatesOfReactionScore({
    required double studentSlope,
    required double theoreticalSlope,
    required int inspectedCount,
    required int preparedCount,
    required int completedTrialsCount,
    required int durationSeconds,
  }) {
    final errorFraction = theoreticalSlope > 0
        ? (studentSlope - theoreticalSlope).abs() / theoreticalSlope
        : 0.0;
    final errorPercentage = (errorFraction * 100).clamp(0.0, 100.0);

    int finalScore;
    String grade;
    if (errorFraction < 0.05) {
      finalScore = 100;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.10) {
      finalScore = 95;
      grade = 'A+ (Distinction)';
    } else if (errorFraction < 0.18) {
      finalScore = 85;
      grade = 'A (Excellent)';
    } else if (errorFraction < 0.28) {
      finalScore = 75;
      grade = 'B (Good)';
    } else {
      finalScore = 65;
      grade = 'C (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus Inspection (${(inspectedCount >= 5 ? 100 : 75)}%)',
        nameSw: 'Ukaguzi wa Vifaa (${(inspectedCount >= 5 ? 100 : 75)}%)',
        score: inspectedCount >= 5 ? 100 : 75,
      ),
      CompetencyScore(
        nameEn: 'Volumetric Dilution Preparation (${(preparedCount >= 5 ? 100 : 80)}%)',
        nameSw: 'Upimaji na Utayarishaji wa Myeyusho (${(preparedCount >= 5 ? 100 : 80)}%)',
        score: preparedCount >= 5 ? 100 : 80,
      ),
      CompetencyScore(
        nameEn: 'Disappearing Cross Timing & Reaction (${(completedTrialsCount >= 5 ? 100 : 80)}%)',
        nameSw: 'Upimaji wa Muda wa Kutoweka kwa Msalaba (${(completedTrialsCount >= 5 ? 100 : 80)}%)',
        score: completedTrialsCount >= 5 ? 100 : 80,
      ),
      CompetencyScore(
        nameEn: 'Reciprocal Rate Calculation (1/t) (100%)',
        nameSw: 'Hesabu ya Kasi ya Mmenyuko (1/t) (100%)',
        score: 100,
      ),
      CompetencyScore(
        nameEn: 'Linear Slope & Rate Law Determination ($finalScore%)',
        nameSw: 'Mteremko wa Grafu na Kanuni ya Kasi ($finalScore%)',
        score: finalScore,
      ),
    ];

    final achievementsEn = [
      'Chemical Kinetics Master',
      'Disappearing Cross Expert',
      'Precision Reaction Timing',
      'Rate Law (1st Order) Deduced',
      'Direct Proportionality Verified',
    ];

    final achievementsSw = [
      'Bingwa wa Kasi za Kikemia',
      'Mtaalamu wa Mbinu ya Msalaba',
      'Usahihi wa Kupima Muda wa Mmenyuko',
      'Kanuni ya Kasi Imethibitishwa',
      'Uwiano wa Moja kwa Moja Umethibitishwa',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Rates of Chemical Reactions (Thiosulfate & Acid)',
      practicalNameSw: 'Kasi ya Miitikio ya Kikemia (Thiosulfate na Asidi)',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: errorPercentage,
      studentMolarity: studentSlope,
      theoreticalMolarity: theoreticalSlope,
      studentTitreVolume: completedTrialsCount.toDouble(),
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }

  static PracticalScoreResult calculateGasPreparationScore({
    required String gasNameEn,
    required String gasNameSw,
    required int inspectedCount,
    required bool solidAdded,
    required bool liquidAdded,
    required bool gasCollectedFull,
    required bool testSuccessful,
    required int durationSeconds,
  }) {
    int finalScore = 0;
    // Apparatus inspection: 20 pts
    if (inspectedCount >= 5) {
      finalScore += 20;
    } else {
      finalScore += 10;
    }

    // Reactants setup: 20 pts
    if (solidAdded) finalScore += 20;

    // Liquid addition & generation: 20 pts
    if (liquidAdded) finalScore += 20;

    // Collection: 20 pts
    if (gasCollectedFull) finalScore += 20;

    // Confirmatory test: 20 pts
    if (testSuccessful) finalScore += 20;

    String grade;
    if (finalScore >= 95) {
      grade = 'A+ (Distinction)';
    } else if (finalScore >= 80) {
      grade = 'A (Excellent)';
    } else if (finalScore >= 65) {
      grade = 'B (Good)';
    } else {
      grade = 'C (Pass)';
    }

    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final durationFormatted = '${mins}m ${secs}s';

    final competencies = [
      CompetencyScore(
        nameEn: 'Apparatus & Glassware Assembly (${inspectedCount >= 5 ? 100 : 60}%)',
        nameSw: 'Muunganisho wa Vifaa vya Maabara (${inspectedCount >= 5 ? 100 : 60}%)',
        score: inspectedCount >= 5 ? 100 : 60,
      ),
      CompetencyScore(
        nameEn: 'Reactant Stoichiometry Charging (${solidAdded ? 100 : 0}%)',
        nameSw: 'Uwekaji wa Kemikali Kigumu (${solidAdded ? 100 : 0}%)',
        score: solidAdded ? 100 : 0,
      ),
      CompetencyScore(
        nameEn: 'Liquid Delivery & Effervescence (${liquidAdded ? 100 : 0}%)',
        nameSw: 'Umiminaji wa Asidi na Utoaji Gesi (${liquidAdded ? 100 : 0}%)',
        score: liquidAdded ? 100 : 0,
      ),
      CompetencyScore(
        nameEn: 'Pneumatic / Air Displacement Collection (${gasCollectedFull ? 100 : 0}%)',
        nameSw: 'Ukamilishaji wa Ukusanyaji wa Gesi (${gasCollectedFull ? 100 : 0}%)',
        score: gasCollectedFull ? 100 : 0,
      ),
      CompetencyScore(
        nameEn: 'Diagnostic Confirmatory Testing (${testSuccessful ? 100 : 0}%)',
        nameSw: 'Vipimo vya Uthibitisho wa Gesi (${testSuccessful ? 100 : 0}%)',
        score: testSuccessful ? 100 : 0,
      ),
    ];

    final achievementsEn = [
      'Pneumatic Chemistry Specialist',
      'Catalytic Gas Generation',
      'Displacement Collection Master',
      'Confirmatory Splint & Test Expert',
      'Laboratory Safety Distinction',
    ];

    final achievementsSw = [
      'Bingwa wa Gesi za Maabara',
      'Uzalishaji wa Gesi kwa Kichocheo',
      'Ukusanyaji Sahihi wa Gesi Juu ya Maji',
      'Mtaalamu wa Vipimo vya Moto na Chokaa',
      'Uzingatiaji Bora wa Usalama',
    ];

    return PracticalScoreResult(
      practicalNameEn: 'Laboratory Preparation of Gases ($gasNameEn)',
      practicalNameSw: 'Utayarishaji wa Gesi Maabarani ($gasNameSw)',
      totalScore: finalScore,
      grade: grade,
      errorPercentage: (100 - finalScore).toDouble(),
      studentMolarity: 100.0,
      theoreticalMolarity: 100.0,
      studentTitreVolume: 100.0,
      durationFormatted: durationFormatted,
      competencies: competencies,
      achievementsEn: achievementsEn,
      achievementsSw: achievementsSw,
    );
  }
}

