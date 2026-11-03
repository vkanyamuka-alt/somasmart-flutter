import 'package:flutter/material.dart';
import 'lab_apparatus.dart';
import 'lab_electrical.dart';
import 'lab_hand.dart';

/// The Ohm's law bench, seen from above and laid out for a phone held
/// upright: the dry cells across the top, the key and the resistor below
/// them, and the ammeter and voltmeter side by side at the bottom so both
/// readings are taken together. Series loop: cells + -> key -> ammeter ->
/// resistor -> cells -; the voltmeter across the resistor. Current shows as
/// moving dots along the wires. A hand does each action: it joins the wires,
/// moves the crocodile clip to the cells in use and pushes the plug into the
/// key. Built from the shared lab kit ([LabPaint], [LabElectrical], [LabHand]);
/// the website draws the same bench (OhmsLawBench.jsx).
class CircuitBenchPainter extends CustomPainter {
  final bool isConnected;
  final bool isSwitchClosed;
  final int cells; // dry cells in the circuit, 1 to 4
  final double measuredVoltage;
  final double measuredCurrent;
  final double animationProgress; // 0.0 to 1.0 for current flow dots
  final bool isDarkMode;
  final LabHandRuns? hands; // 'wired', 'cells', 'key'

  CircuitBenchPainter({
    required this.isConnected,
    required this.isSwitchClosed,
    required this.cells,
    required this.measuredVoltage,
    required this.measuredCurrent,
    required this.animationProgress,
    required this.isDarkMode,
    this.hands,
  }) : super(repaint: hands);

  static const double width = 360;
  static const double height = 400;

  static const _holder = Offset(20, 46);
  static const _key = Offset(262, 140);
  static const _resistor = Offset(20, 144);
  static const _voltmeter = Offset(15, 250);
  static const _ammeter = Offset(195, 250);

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintTop(canvas, size, width, height, () {
      final live = isConnected && isSwitchClosed;
      final flow = live ? animationProgress : null;
      final cell = LabElectrical.cellHolderTerminals(_holder.dx, _holder.dy, cells);
      final keyL = _key + const Offset(12, 22);
      final keyR = _key + const Offset(78, 22);
      final resL = _resistor + const Offset(16, 20);
      final resR = _resistor + const Offset(124, 20);
      final aNeg = _ammeter + const Offset(30, 4);
      final aPos = _ammeter + const Offset(120, 4);
      final vNeg = _voltmeter + const Offset(30, 4);
      final vPos = _voltmeter + const Offset(120, 4);
      final wired = hands?.since('wired');
      final keyMoved = hands?.since('key');

      LabElectrical.cellHolder(canvas, x: _holder.dx, y: _holder.dy, inUse: cells);
      LabPaint.text(canvas, '$cells cell${cells == 1 ? '' : 's'} in use: E = ${(cells * 1.5).toStringAsFixed(1)} V',
          Offset(_holder.dx + 118, _holder.dy + 64), 12, const Color(0xFF184E78));
      LabElectrical.plugKey(canvas, x: _key.dx, y: _key.dy, plugOut: _plugOut(keyMoved));
      LabElectrical.resistorBoard(canvas, x: _resistor.dx, y: _resistor.dy, warm: live ? measuredCurrent / 0.6 : 0);
      LabElectrical.meterFace(canvas,
          x: _voltmeter.dx, y: _voltmeter.dy, value: measuredVoltage, max: 6, major: 1, minor: 0.2, unit: 'V', label: 'Voltmeter');
      LabElectrical.meterFace(canvas,
          x: _ammeter.dx, y: _ammeter.dy, value: measuredCurrent, max: 1, major: 0.2, minor: 0.05, unit: 'A', label: 'Ammeter');

      if (isConnected) {
        // The wires appear as the hand lays them, then current flows round.
        final shown = LabHand.appear(wired, 150, fade: 600);
        // the lead from the crocodile clip goes over the top of the cell holder
        LabElectrical.wire(canvas, cell.positive, keyL,
            controls: [Offset(cell.positive.dx, 6), const Offset(318, 0)], flow: flow, opacity: shown);
        LabElectrical.wire(canvas, keyR, aPos, bow: -14, flow: flow, opacity: shown);
        LabElectrical.wire(canvas, aNeg, resR, color: const Color(0xFF1F2731), bow: 10, flow: flow, opacity: shown);
        LabElectrical.wire(canvas, resL, cell.negative, color: const Color(0xFF1F2731), bow: 16, flow: flow, opacity: shown);
        LabElectrical.wire(canvas, vPos, resR, bow: 8, opacity: shown);
        LabElectrical.wire(canvas, vNeg, resL, color: const Color(0xFF1F2731), bow: -8, opacity: shown);
        LabHand.move(canvas, wired, from: const Offset(214, 230), to: keyL);
      } else {
        LabElectrical.wireBundle(canvas, const Offset(204, 216));
      }
      LabHand.move(canvas, hands?.since('cells'), to: cell.positive);
      LabHand.move(canvas, keyMoved, to: _key + Offset(45, isSwitchClosed ? 22 : 52));
    });
  }

  /// The plug moves while the hand presses it (45% to 55% of its motion).
  double _plugOut(double? t) {
    final end = isSwitchClosed ? 0.0 : 1.0;
    if (t == null) return end;
    final f = ((t - 520) / 200).clamp(0.0, 1.0);
    return isSwitchClosed ? 1 - f : f;
  }

  @override
  bool shouldRepaint(covariant CircuitBenchPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected ||
        oldDelegate.isSwitchClosed != isSwitchClosed ||
        oldDelegate.cells != cells ||
        oldDelegate.measuredVoltage != measuredVoltage ||
        oldDelegate.measuredCurrent != measuredCurrent ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
