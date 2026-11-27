import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/pendulum_bench_painter.dart';

void main() {
  final stages = <String, PendulumBenchPainter>{
    'at rest, short thread': const PendulumBenchPainter(lengthCm: 20, angleDeg: 0, isOscillating: false, isDark: true),
    'held at the release angle': const PendulumBenchPainter(lengthCm: 60, angleDeg: 8, releaseAngleDeg: 8, isOscillating: false, isDark: false),
    'swinging, full length': const PendulumBenchPainter(
        lengthCm: 100, angleDeg: -5.5, isOscillating: true, isDark: true, stopwatchSeconds: 12.34, oscillations: 6),
  };

  for (final entry in stages.entries) {
    for (final size in const [Size(358, 250), Size(900, 250)]) {
      testWidgets('paints the pendulum bench (${entry.key}) at ${size.width.toInt()} wide', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(width: size.width, height: size.height, child: CustomPaint(size: size, painter: entry.value)),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
