import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/data/models/optics_state.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/circuit_bench_painter.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/optics_bench_painter.dart';

void main() {
  final painters = <String, CustomPainter>{
    'circuit not connected': CircuitBenchPainter(
        isConnected: false, isSwitchClosed: false, cells: 1, measuredVoltage: 0, measuredCurrent: 0, animationProgress: 0, isDarkMode: true),
    'circuit live at 6 V': CircuitBenchPainter(
        isConnected: true, isSwitchClosed: true, cells: 4, measuredVoltage: 6, measuredCurrent: 0.6, animationProgress: 0.4, isDarkMode: false),
    'prism at 45°': OpticsBenchPainter(state: const OpticsState(incidentAngleDeg: 45), isDark: true),
    'prism at 70°': OpticsBenchPainter(state: const OpticsState(incidentAngleDeg: 70), isDark: false),
    'prism at 20° (total internal reflection)': OpticsBenchPainter(state: const OpticsState(incidentAngleDeg: 20), isDark: true),
    'prism with guides hidden': OpticsBenchPainter(
        state: const OpticsState(incidentAngleDeg: 40, showProtractor: false, showNormalLines: false, showOpticalPins: false, laserActive: false),
        isDark: true),
  };

  for (final entry in painters.entries) {
    for (final size in const [Size(358, 240), Size(900, 300)]) {
      testWidgets('paints ${entry.key} at ${size.width.toInt()} wide', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Center(child: SizedBox(width: size.width, height: size.height, child: CustomPaint(size: size, painter: entry.value))),
        ));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
