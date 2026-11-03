import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/gas_preparation_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/microscope_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/optics_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/osmosis_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/rates_of_reaction_state.dart';
import 'package:somasmart_flutter/features/practicals/data/models/titration_state.dart';
import 'package:somasmart_flutter/features/practicals/domain/microscope_engine.dart';
import 'package:somasmart_flutter/features/practicals/domain/titration_engine.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/circuit_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/gas_preparation_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/lab_hand.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/microscope_slide_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/optics_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/osmosis_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/pendulum_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/rates_of_reaction_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/titration_bench_painter.dart';

/// A bench that shows [before] and then, when flipped, [after], so its hands play.
class _Bench extends StatefulWidget {
  final Widget Function(bool after) builder;
  const _Bench({super.key, required this.builder});

  @override
  State<_Bench> createState() => _BenchState();
}

class _BenchState extends State<_Bench> {
  bool after = false;
  void flip() => setState(() => after = !after);

  @override
  Widget build(BuildContext context) => widget.builder(after);
}

void main() {
  group('LabHandRuns', () {
    testWidgets('a hand plays when the student changes something, not when the bench first appears', (tester) async {
      final runs = LabHandRuns(const TestVSync());
      addTearDown(runs.dispose);
      runs.watch('key', false);
      runs.watch('key', false);
      expect(runs.since('key'), isNull);
      expect(runs.isTicking, isFalse);

      runs.watch('key', true);
      expect(runs.since('key'), 0);
      expect(runs.previous('key'), false);
      expect(runs.isTicking, isTrue);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(runs.since('key'), closeTo(600, 1));

      // Time stops once every hand has long finished.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(runs.isTicking, isFalse);
    });

    testWidgets('no hand moves when the phone asks for reduced motion', (tester) async {
      final runs = LabHandRuns(const TestVSync())..enabled = false;
      addTearDown(runs.dispose);
      runs.watch('cells', 1);
      runs.watch('cells', 3);
      expect(runs.since('cells'), isNull);
      expect(runs.isTicking, isFalse);
    });
  });

  final titration = AcidBaseTitrationEngine().createInitialState(PracticalMode.guidedPractice);
  final osmosis = OsmosisState.initial(PracticalMode.guidedPractice);
  final rates = RatesOfReactionState.initial(PracticalMode.guidedPractice);
  final microscope = MicroscopeEngine().createInitialState(PracticalMode.guidedPractice);

  // Each bench before and after the student acts, so every hand on it plays.
  final benches = <String, (Size, Map<String, Object?> Function(bool), CustomPainter Function(bool, LabHandRuns))>{
    "Ohm's law: wires, cells and key": (
      const Size(360, 400),
      (a) => {'wired': a, 'cells': a ? 3 : 1, 'key': a},
      (a, h) => CircuitBenchPainter(
          isConnected: a,
          isSwitchClosed: a,
          cells: a ? 3 : 1,
          measuredVoltage: a ? 4.5 : 0,
          measuredCurrent: a ? 0.45 : 0,
          animationProgress: 0.3,
          isDarkMode: false,
          hands: h),
    ),
    'titration: tap, flask and pipette': (
      const Size(358, 240),
      (a) => TitrationBenchPainter.handKeys(_titration(titration, a)),
      (a, h) => TitrationBenchPainter(state: _titration(titration, a), isDark: false, hands: h),
    ),
    'titration: indicator drops': (
      const Size(358, 240),
      (a) => TitrationBenchPainter.handKeys(_drops(titration, a)),
      (a, h) => TitrationBenchPainter(state: _drops(titration, a), isDark: true, hands: h),
    ),
    'pendulum: rule away and bob held': (
      const Size(330, 306),
      (a) => {'rule': !a, 'hold': a},
      (a, h) => PendulumBenchPainter(
          lengthCm: 80, angleDeg: a ? 8 : 0, releaseAngleDeg: 8, isOscillating: false, isDark: false, showRule: !a, holding: a, hands: h),
    ),
    'pendulum: bob let go and stopwatch pressed': (
      const Size(330, 306),
      (a) => {'rule': false, 'hold': !a, 'watch': a},
      (a, h) => PendulumBenchPainter(
          lengthCm: 50, angleDeg: 4, releaseAngleDeg: 8, isOscillating: a, isDark: true, showRule: false, holding: !a, hands: h),
    ),
    'optics: protractor and pins': (
      const Size(358, 240),
      (a) => OpticsBenchPainter.handKeys(OpticsState(incidentAngleDeg: 40, showProtractor: a, showOpticalPins: a)),
      (a, h) => OpticsBenchPainter(state: OpticsState(incidentAngleDeg: 40, showProtractor: a, showOpticalPins: a), isDark: false, hands: h),
    ),
    'gas preparation: solid, liquid and test': (
      const Size(330, 250),
      (a) => GasPreparationBenchPainter.handKeys(_gas(a)),
      (a, h) => GasPreparationBenchPainter(state: _gas(a), isDark: false, hands: h),
    ),
    'osmosis: cut, weigh, immerse and blot': (
      const Size(330, 250),
      (a) => OsmosisBenchPainter.handKeys(_osmosis(osmosis, a)),
      (a, h) => OsmosisBenchPainter(state: _osmosis(osmosis, a), isDark: false, animationValue: 0.2, hands: h),
    ),
    'rates of reaction: flask and acid': (
      const Size(330, 240),
      (a) => RatesOfReactionBenchPainter.handKeys(_rates(rates, a)),
      (a, h) => RatesOfReactionBenchPainter(state: _rates(rates, a), isDark: true, hands: h),
    ),
    'microscope slide: peel, stain and coverslip': (
      const Size(330, 138),
      (a) => MicroscopeSlidePainter.handKeys(_slide(microscope, a)),
      (a, h) => MicroscopeSlidePainter(state: _slide(microscope, a), hands: h),
    ),
  };

  for (final entry in benches.entries) {
    testWidgets('paints every moment of the hands on ${entry.key}', (tester) async {
      final (size, keys, painter) = entry.value;
      final key = GlobalKey<_BenchState>();
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: _Bench(
              key: key,
              builder: (a) => LabHandPaint(
                size: size,
                watch: keys(a),
                painter: (h) => painter(a, h),
              ),
            ),
          ),
        ),
      ));
      key.currentState!.flip();
      for (int ms = 0; ms <= 4000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'at $ms ms');
      }
    });
  }
}

TitrationState _titration(TitrationState s, bool a) => a
    ? s.copyWith(currentStepIndex: 2, pipetteStep: 5, isTransferringLiquid: true, flaskPositioned: true, stopcockState: StopcockState.slow)
    : s;

TitrationState _drops(TitrationState s, bool a) =>
    s.copyWith(currentStepIndex: 3, indicatorStep: a ? 2 : 1, indicatorDropsCount: a ? 2 : 1, isDroppingIndicator: a);

GasPreparationState _gas(bool a) =>
    GasPreparationState.initial(PracticalMode.guidedPractice).copyWith(isSolidAdded: a, isLiquidAdded: a, isTestPerformed: a);

OsmosisState _osmosis(OsmosisState s, bool a) => s.copyWith(
      samples: [for (final x in s.samples) x.copyWith(isPrepared: a, isImmersed: a, isBlotted: a)],
      balanceOccupiedBySampleId: a ? s.samples.first.id : null,
    );

RatesOfReactionState _rates(RatesOfReactionState s, bool a) => s.copyWith(
      isFlaskOnCross: a,
      trials: [for (final t in s.trials) t.copyWith(isAcidAdded: a)],
    );

MicroscopeState _slide(MicroscopeState s, bool a) =>
    s.copyWith(isSpecimenPlaced: a, appliedStain: a ? StainType.iodine : StainType.none, isCoverslipMounted: a);
