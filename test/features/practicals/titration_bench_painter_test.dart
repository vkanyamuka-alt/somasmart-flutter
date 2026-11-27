import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/practical_model.dart';
import 'package:somasmart_flutter/features/practicals/data/models/titration_state.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/titration_bench_painter.dart';

void main() {
  const base = TitrationState(mode: PracticalMode.guidedPractice);

  final stages = <String, TitrationState>{
    'set up': base,
    'burette filled': base.copyWith(currentStepIndex: 1, buretteFilled: true),
    'drawing HCl': base.copyWith(currentStepIndex: 2, buretteFilled: true, pipetteStep: 4, pipetteVolume: 12, isDrawingLiquid: true),
    'pipette over flask': base.copyWith(
        currentStepIndex: 2, buretteFilled: true, pipetteStep: 6, pipetteVolume: 10, flaskVolume: 15, isTransferringLiquid: true),
    'adding indicator': base.copyWith(
        currentStepIndex: 3, buretteFilled: true, flaskVolume: 25, indicatorStep: 2, isDroppingIndicator: true),
    'titrating': base.copyWith(
        currentStepIndex: 5,
        buretteFilled: true,
        flaskVolume: 45,
        indicatorAdded: true,
        flaskPositioned: true,
        stopcockState: StopcockState.slow,
        volumeDelivered: 20),
    'endpoint, swirling': base.copyWith(
        currentStepIndex: 5,
        buretteFilled: true,
        flaskVolume: 49.6,
        indicatorAdded: true,
        flaskPositioned: true,
        volumeDelivered: 24.6,
        isSwirling: true),
  };

  for (final entry in stages.entries) {
    for (final size in const [Size(358, 240), Size(900, 240)]) {
      testWidgets('paints the bench (${entry.key}) at ${size.width.toInt()} wide', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(
                  size: size,
                  painter: TitrationBenchPainter(state: entry.value, isDark: true, animationValue: 0.4),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
