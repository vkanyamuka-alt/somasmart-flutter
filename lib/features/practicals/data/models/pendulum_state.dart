import 'dart:math' as math;
import 'practical_model.dart';
import 'practical_score_result.dart';

/// Represents a single experimental pendulum trial reading
class PendulumTrial {
  final int trialNumber;
  final double lengthCm; // Length in centimeters (e.g. 40.0 cm)
  final int oscillationCount; // Target oscillations n (usually 20)
  final double timeSeconds; // Time t for n oscillations
  final double periodSeconds; // Period T = t / n
  final double periodSquared; // T² (s²)

  const PendulumTrial({
    required this.trialNumber,
    required this.lengthCm,
    required this.oscillationCount,
    required this.timeSeconds,
    required this.periodSeconds,
    required this.periodSquared,
  });

  double get lengthMeters => lengthCm / 100.0;
}

/// Inspection item definition for apparatus inspection step
class ApparatusInspectItem {
  final String key;
  final String nameEn;
  final String nameSw;
  final String roleEn;
  final String roleSw;
  final String icon;

  const ApparatusInspectItem({
    required this.key,
    required this.nameEn,
    required this.nameSw,
    required this.roleEn,
    required this.roleSw,
    required this.icon,
  });
}

/// Pure state model for the Simple Pendulum simulation
class PendulumState {
  final PracticalMode mode;
  final int currentStepIndex; // 0: Inspect, 1: Length, 2: Deflection, 3: Timing, 4: Trials, 5: Graph, 6: Calculation
  final bool isCompleted;
  final int elapsedSeconds;

  // Step 0: Apparatus Inspection
  final Set<String> inspectedItems;
  final String? selectedInspectItemKey;

  // Step 1: Pendulum Configuration
  final double pendulumLengthCm; // 20.0 to 100.0 cm (default 40.0 cm)

  // Step 2 & 3: Oscillation & Motion Physics
  final double deflectionAngleDeg; // 2.0 to 10.0 degrees (default 6.0 deg)
  final bool isOscillating;
  final double currentAngleDeg; // Instantaneous angle for animation
  final int currentOscillations; // Live completed oscillation count
  final int targetOscillations; // Default 20 oscillations
  final bool stopwatchRunning;
  final double stopwatchElapsedSec; // Live stopwatch seconds

  // Step 4: Multi-Trial Observation Records
  final List<PendulumTrial> recordedTrials;

  // Step 5 & 6: Graph & Physics Evaluation
  final String studentGradientInput;
  final String studentGravityInput;
  final bool calculationSubmitted;
  final PracticalScoreResult? scoreResult;

  // Dynamic Laboratory Notebook Logs
  final List<String> notebookLogs;

  const PendulumState({
    required this.mode,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.inspectedItems = const {},
    this.selectedInspectItemKey,
    this.pendulumLengthCm = 40.0,
    this.deflectionAngleDeg = 6.0,
    this.isOscillating = false,
    this.currentAngleDeg = 0.0,
    this.currentOscillations = 0,
    this.targetOscillations = 20,
    this.stopwatchRunning = false,
    this.stopwatchElapsedSec = 0.0,
    this.recordedTrials = const [],
    this.studentGradientInput = '',
    this.studentGravityInput = '',
    this.calculationSubmitted = false,
    this.scoreResult,
    this.notebookLogs = const [
      '• Virtual Physics Laboratory initialized: Simple Pendulum Gravitational Acceleration.',
    ],
  });

  // Physical constant: True standard gravity g = 9.80 m/s²
  static const double standardGravity = 9.80;

  /// Theoretical period for the current length in meters: T = 2π * sqrt(L/g)
  double get theoreticalPeriod {
    final lMeters = pendulumLengthCm / 100.0;
    return 2.0 * math.pi * math.sqrt(lMeters / standardGravity);
  }

  /// Theoretical time for target oscillations: t = n * T
  double get theoreticalTotalTime => targetOscillations * theoreticalPeriod;

  /// Theoretical period squared: T² = 4π²L/g
  double get theoreticalPeriodSquared => theoreticalPeriod * theoreticalPeriod;

  /// Best-fit linear regression slope m = Δ(T²)/ΔL from recorded trials
  double? get calculatedRegressionSlope {
    if (recordedTrials.length < 2) return null;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    final n = recordedTrials.length.toDouble();

    for (final trial in recordedTrials) {
      final x = trial.lengthMeters;
      final y = trial.periodSquared;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return null;
    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Experimental acceleration due to gravity from slope: g = 4π² / slope
  double? get calculatedExperimentalGravity {
    final slope = calculatedRegressionSlope;
    if (slope == null || slope <= 0) return null;
    return (4.0 * math.pi * math.pi) / slope;
  }

  /// Percentage error compared to standard g = 9.80 m/s²
  double? get percentageError {
    final expG = calculatedExperimentalGravity;
    if (expG == null) return null;
    return ((expG - standardGravity).abs() / standardGravity) * 100.0;
  }

  /// Step validity check for navigation
  bool canAdvanceStep() {
    if (mode == PracticalMode.freeExploration) return true;
    switch (currentStepIndex) {
      case 0: // Apparatus inspection
        return inspectedItems.length >= 4;
      case 1: // Length setup
        return pendulumLengthCm >= 20.0 && pendulumLengthCm <= 100.0;
      case 2: // Deflection angle
        return deflectionAngleDeg > 0 && deflectionAngleDeg <= 10.0;
      case 3: // Timing
        return stopwatchElapsedSec > 0 || currentOscillations >= targetOscillations;
      case 4: // Multi-trial table
        return recordedTrials.length >= (mode == PracticalMode.guidedPractice ? 3 : 2);
      case 5: // Graph
        return recordedTrials.length >= 2;
      case 6: // Calculation
        return calculationSubmitted || isCompleted;
      default:
        return true;
    }
  }

  String get observationMessageEn {
    switch (currentStepIndex) {
      case 0:
        return 'Tap and inspect all apparatus items (Retort Stand, Pendulum Bob, Thread, Metre Rule, Stopwatch).';
      case 1:
        return 'Set pendulum string length to ${pendulumLengthCm.toStringAsFixed(1)} cm measured to the centre of the bob.';
      case 2:
        return 'Deflect bob by small angle (${deflectionAngleDeg.toStringAsFixed(1)}°) to ensure simple harmonic motion.';
      case 3:
        if (stopwatchRunning) {
          return 'Oscillating: $currentOscillations / $targetOscillations complete. Elapsed: ${stopwatchElapsedSec.toStringAsFixed(2)}s.';
        }
        if (currentOscillations >= targetOscillations) {
          return 'Completed $targetOscillations oscillations in ${stopwatchElapsedSec.toStringAsFixed(2)}s! Record this trial.';
        }
        return 'Press Start to release the bob and time $targetOscillations oscillations.';
      case 4:
        return '${recordedTrials.length} trials recorded. Adjust length and record at least 3 trials for graph analysis.';
      case 5:
        final slope = calculatedRegressionSlope;
        if (slope != null) {
          return 'T² vs L plotted. Linear slope m = ${slope.toStringAsFixed(3)} s²/m.';
        }
        return 'Plotting T² against L. Record more trials to observe linear proportionality.';
      case 6:
        if (isCompleted && scoreResult != null) {
          return 'Practical complete! Score: ${scoreResult!.totalScore}% (${scoreResult!.grade}).';
        }
        return 'Calculate acceleration due to gravity g = 4π² / slope and submit.';
      default:
        return '';
    }
  }

  String get observationMessageSw {
    switch (currentStepIndex) {
      case 0:
        return 'Gusa na kagua vifaa vyote vya maabara (Standi, Tufe ya Penduli, Uzi, Rula ya Mita, Saa ya Mkononi).';
      case 1:
        return 'Weka urefu wa uzi wa penduli kuwa cm ${pendulumLengthCm.toStringAsFixed(1)} ukipima hadi katikati ya tufe.';
      case 2:
        return 'Vuta tufe kwa pembe ndogo (${deflectionAngleDeg.toStringAsFixed(1)}°) ili kuhakikisha mtetemo sahihi wa harmonic.';
      case 3:
        if (stopwatchRunning) {
          return 'Inatetemeka: Mitetemo $currentOscillations / $targetOscillations imekamilika. Muda: sekunde ${stopwatchElapsedSec.toStringAsFixed(2)}.';
        }
        if (currentOscillations >= targetOscillations) {
          return 'Mitetemo $targetOscillations imekamilika kwa sekunde ${stopwatchElapsedSec.toStringAsFixed(2)}! Hifadhi jaribio hili.';
        }
        return 'Bonyeza Anza ili kuachia tufe na kupima muda wa mitetemo $targetOscillations.';
      case 4:
        return 'Majaribio ${recordedTrials.length} yamehifadhiwa. Badilisha urefu na pima angalau majaribio 3 kwa grafu.';
      case 5:
        final slope = calculatedRegressionSlope;
        if (slope != null) {
          return 'Grafu ya T² dhidi ya L imechorwa. Mteremko m = ${slope.toStringAsFixed(3)} s²/m.';
        }
        return 'Grafu ya T² dhidi ya L. Hifadhi majaribio zaidi ili kuona uwiano.';
      case 6:
        if (isCompleted && scoreResult != null) {
          return 'Jaribio limekamilika! Alama: ${scoreResult!.totalScore}% (${scoreResult!.grade}).';
        }
        return 'Hesabu kani ya mvuto wa dunia g = 4π² / mteremko na uwasilishe.';
      default:
        return '';
    }
  }

  PendulumState copyWith({
    PracticalMode? mode,
    int? currentStepIndex,
    bool? isCompleted,
    int? elapsedSeconds,
    Set<String>? inspectedItems,
    String? selectedInspectItemKey,
    double? pendulumLengthCm,
    double? deflectionAngleDeg,
    bool? isOscillating,
    double? currentAngleDeg,
    int? currentOscillations,
    int? targetOscillations,
    bool? stopwatchRunning,
    double? stopwatchElapsedSec,
    List<PendulumTrial>? recordedTrials,
    String? studentGradientInput,
    String? studentGravityInput,
    bool? calculationSubmitted,
    PracticalScoreResult? scoreResult,
    List<String>? notebookLogs,
  }) {
    return PendulumState(
      mode: mode ?? this.mode,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      inspectedItems: inspectedItems ?? this.inspectedItems,
      selectedInspectItemKey: selectedInspectItemKey ?? this.selectedInspectItemKey,
      pendulumLengthCm: pendulumLengthCm ?? this.pendulumLengthCm,
      deflectionAngleDeg: deflectionAngleDeg ?? this.deflectionAngleDeg,
      isOscillating: isOscillating ?? this.isOscillating,
      currentAngleDeg: currentAngleDeg ?? this.currentAngleDeg,
      currentOscillations: currentOscillations ?? this.currentOscillations,
      targetOscillations: targetOscillations ?? this.targetOscillations,
      stopwatchRunning: stopwatchRunning ?? this.stopwatchRunning,
      stopwatchElapsedSec: stopwatchElapsedSec ?? this.stopwatchElapsedSec,
      recordedTrials: recordedTrials ?? this.recordedTrials,
      studentGradientInput: studentGradientInput ?? this.studentGradientInput,
      studentGravityInput: studentGravityInput ?? this.studentGravityInput,
      calculationSubmitted: calculationSubmitted ?? this.calculationSubmitted,
      scoreResult: scoreResult ?? this.scoreResult,
      notebookLogs: notebookLogs ?? this.notebookLogs,
    );
  }
}
