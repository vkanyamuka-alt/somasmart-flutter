import 'package:flutter/material.dart';
import 'lab_apparatus.dart';
import 'lab_electrical.dart';

/// The Ohm's law bench, built from the shared lab kit ([LabPaint],
/// [LabElectrical]): power supply, knife switch, ammeter and the 10 Ω
/// resistor in series, with the voltmeter across the resistor. The wires lie
/// on the bench once connected; current shows as moving dots. The same bench
/// is drawn on the website (OhmsLawBench.jsx).
class CircuitBenchPainter extends CustomPainter {
  final bool isConnected;
  final bool isSwitchClosed;
  final double measuredVoltage;
  final double measuredCurrent;
  final double animationProgress; // 0.0 to 1.0 for current flow dots
  final bool isDarkMode;
  final double? supplyVoltage; // the voltage set on the supply, shown even when the switch is open

  CircuitBenchPainter({
    required this.isConnected,
    required this.isSwitchClosed,
    required this.measuredVoltage,
    required this.measuredCurrent,
    required this.animationProgress,
    required this.isDarkMode,
    this.supplyVoltage,
  });

  // Laid out 560 units wide and drawn 1.25 times larger about the middle of
  // the table, so the circuit fills the bench.
  static const double _psX = 70;
  static const double _switchX = 210;
  static const double _ammeterX = 290;
  static const double _resistorX = 400;
  static const double _voltmeterX = 530;

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintScene(canvas, size, isDarkMode, (left, right) {
      canvas.save();
      canvas.translate(350, LabPaint.tableY);
      canvas.scale(1.25);
      canvas.translate(-350, -LabPaint.tableY);

      final live = isConnected && isSwitchClosed;
      final flow = live ? animationProgress : null;
      const y = 300.0;
      const meterY = 306.0;
      const postY = 296.0;
      if (isConnected) {
        LabElectrical.wire(canvas, const Offset(_psX + 88, y), const Offset(_switchX + 12, y), flow: flow);
        LabElectrical.wire(canvas, const Offset(_switchX + 58, y), const Offset(_ammeterX + 26, meterY), flow: flow);
        LabElectrical.wire(canvas, const Offset(_ammeterX + 74, meterY), const Offset(_resistorX + 14, postY),
            color: const Color(0xFF1F2731), sag: 16, flow: flow);
        LabElectrical.wire(canvas, const Offset(_resistorX + 106, postY), const Offset(_psX + 112, y),
            color: const Color(0xFF1F2731), sag: 38, flow: flow);
        LabElectrical.wire(canvas, const Offset(_voltmeterX + 74, meterY), const Offset(_resistorX + 14, postY), sag: 24);
        LabElectrical.wire(canvas, const Offset(_voltmeterX + 26, meterY), const Offset(_resistorX + 106, postY),
            color: const Color(0xFF1F2731), sag: 10);
      } else {
        LabElectrical.wireCoil(canvas, cx: 350);
      }

      LabElectrical.powerSupply(canvas, x: _psX, volts: supplyVoltage ?? measuredVoltage, on: live);
      LabElectrical.knifeSwitch(canvas, x: _switchX, closed: isSwitchClosed);
      LabElectrical.analogMeter(canvas,
          x: _ammeterX, value: measuredCurrent, max: 1, unit: 'A', ticks: const ['0', '0.5', '1'], positiveLeft: true);
      LabElectrical.resistorBoard(canvas,
          x: _resistorX,
          warm: live ? (measuredCurrent / 0.6) : 0,
          labelColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
      LabElectrical.analogMeter(canvas, x: _voltmeterX, value: measuredVoltage, max: 6, unit: 'V', ticks: const ['0', '3', '6']);
      canvas.restore();
    });
  }

  @override
  bool shouldRepaint(covariant CircuitBenchPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected ||
        oldDelegate.isSwitchClosed != isSwitchClosed ||
        oldDelegate.measuredVoltage != measuredVoltage ||
        oldDelegate.measuredCurrent != measuredCurrent ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.supplyVoltage != supplyVoltage;
  }
}
