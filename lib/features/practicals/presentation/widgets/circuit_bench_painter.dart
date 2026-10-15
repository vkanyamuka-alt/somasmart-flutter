import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircuitBenchPainter extends CustomPainter {
  final bool isConnected;
  final bool isSwitchClosed;
  final double measuredVoltage;
  final double measuredCurrent;
  final double animationProgress; // 0.0 to 1.0 for current flow dots
  final bool isDarkMode;

  CircuitBenchPainter({
    required this.isConnected,
    required this.isSwitchClosed,
    required this.measuredVoltage,
    required this.measuredCurrent,
    required this.animationProgress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      bgPaint,
    );

    // Border grid / bench outline
    final borderPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      borderPaint,
    );

    if (!isConnected) {
      _drawUnconnectedState(canvas, size);
      return;
    }

    final isActive = isConnected && isSwitchClosed && measuredCurrent > 0;

    // Circuit Layout Coordinates (Relative to canvas)
    // Circuit Loop:
    // Top-Left: Battery (x: 0.20, y: 0.25)
    // Top-Right: Switch (x: 0.80, y: 0.25)
    // Bottom-Right: Ammeter (x: 0.80, y: 0.70)
    // Bottom-Center: Resistor (x: 0.50, y: 0.70)
    // Voltmeter branch in parallel across Resistor (y: 0.90)

    final w = size.width;
    final h = size.height;

    final batteryPt = Offset(w * 0.18, h * 0.28);
    final switchPt = Offset(w * 0.82, h * 0.28);
    final ammeterPt = Offset(w * 0.82, h * 0.68);
    final resistorPt = Offset(w * 0.46, h * 0.68);
    final cornerBtmLeft = Offset(w * 0.18, h * 0.68);

    // 1. Draw Main Circuit Wire Path
    final wirePaint = Paint()
      ..color = isActive
          ? (isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
          : (isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;

    final mainWirePath = Path()
      // Top wire (Battery -> Switch)
      ..moveTo(batteryPt.dx + 28, batteryPt.dy)
      ..lineTo(switchPt.dx - 28, switchPt.dy)
      // Right wire (Switch -> Ammeter)
      ..moveTo(switchPt.dx, switchPt.dy + 20)
      ..lineTo(ammeterPt.dx, ammeterPt.dy - 25)
      // Bottom-Right wire (Ammeter -> Resistor)
      ..moveTo(ammeterPt.dx - 25, ammeterPt.dy)
      ..lineTo(resistorPt.dx + 40, resistorPt.dy)
      // Bottom-Left wire (Resistor -> Bottom-Left Corner -> Battery)
      ..moveTo(resistorPt.dx - 40, resistorPt.dy)
      ..lineTo(cornerBtmLeft.dx, cornerBtmLeft.dy)
      ..lineTo(batteryPt.dx, batteryPt.dy + 32);

    canvas.drawPath(mainWirePath, wirePaint);

    // 2. Parallel Voltmeter Wires
    final voltWirePaint = Paint()
      ..color = isActive
          ? const Color(0xFF10B981)
          : (isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final voltMeterPt = Offset(resistorPt.dx, h * 0.88);
    final voltPath = Path()
      ..moveTo(resistorPt.dx - 35, resistorPt.dy)
      ..lineTo(resistorPt.dx - 35, voltMeterPt.dy)
      ..lineTo(voltMeterPt.dx - 25, voltMeterPt.dy)
      ..moveTo(voltMeterPt.dx + 25, voltMeterPt.dy)
      ..lineTo(resistorPt.dx + 35, voltMeterPt.dy)
      ..lineTo(resistorPt.dx + 35, resistorPt.dy);

    canvas.drawPath(voltPath, voltWirePaint);

    // 3. Draw Animated Current Particles if active
    if (isActive) {
      _drawCurrentFlowParticles(canvas, size, batteryPt, switchPt, ammeterPt, resistorPt, cornerBtmLeft);
    }

    // 4. Draw Components
    _drawBattery(canvas, batteryPt);
    _drawSwitch(canvas, switchPt, isSwitchClosed);
    _drawAmmeter(canvas, ammeterPt, measuredCurrent, isActive);
    _drawResistor(canvas, resistorPt, isActive);
    _drawVoltmeter(canvas, voltMeterPt, measuredVoltage, isActive);
  }

  void _drawUnconnectedState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚠️ Circuit Disconnected\nTap "Connect Circuit" below to assemble apparatus.',
        style: TextStyle(
          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  void _drawCurrentFlowParticles(
    Canvas canvas,
    Size size,
    Offset batteryPt,
    Offset switchPt,
    Offset ammeterPt,
    Offset resistorPt,
    Offset cornerBtmLeft,
  ) {
    final particlePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0x66F59E0B)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Loop coordinates sequence: battery -> switch -> ammeter -> resistor -> corner -> battery
    final points = [
      Offset(batteryPt.dx + 28, batteryPt.dy),
      Offset(switchPt.dx - 28, switchPt.dy),
      Offset(switchPt.dx, switchPt.dy + 20),
      Offset(ammeterPt.dx, ammeterPt.dy - 25),
      Offset(ammeterPt.dx - 25, ammeterPt.dy),
      Offset(resistorPt.dx + 40, resistorPt.dy),
      Offset(resistorPt.dx - 40, resistorPt.dy),
      cornerBtmLeft,
      Offset(batteryPt.dx, batteryPt.dy + 32),
      Offset(batteryPt.dx, batteryPt.dy),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final dist = (end - start).distance;
      if (dist <= 0) continue;

      final count = (dist / 24).ceil();
      for (int j = 0; j < count; j++) {
        final t = (j / count + animationProgress) % 1.0;
        final pos = Offset.lerp(start, end, t)!;
        canvas.drawCircle(pos, 5, glowPaint);
        canvas.drawCircle(pos, 2.5, particlePaint);
      }
    }
  }

  void _drawBattery(Canvas canvas, Offset pt) {
    final rect = Rect.fromCenter(center: pt, width: 56, height: 48);
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), strokePaint);

    // Positive and Negative terminal marks
    final tp = TextPainter(
      text: const TextSpan(
        text: '+\nDC\n-',
        style: TextStyle(
          color: Color(0xFF3B82F6),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  void _drawSwitch(Canvas canvas, Offset pt, bool isClosed) {
    final terminalPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;

    // Contact terminals
    canvas.drawCircle(Offset(pt.dx - 18, pt.dy), 4, terminalPaint);
    canvas.drawCircle(Offset(pt.dx + 18, pt.dy), 4, terminalPaint);

    final bladePaint = Paint()
      ..color = isClosed ? const Color(0xFF10B981) : const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (isClosed) {
      // Closed contact bridge
      canvas.drawLine(Offset(pt.dx - 18, pt.dy), Offset(pt.dx + 18, pt.dy), bladePaint);
    } else {
      // Open contact tilted 35 degrees up
      final endX = pt.dx - 18 + 32 * math.cos(-math.pi / 4);
      final endY = pt.dy + 32 * math.sin(-math.pi / 4);
      canvas.drawLine(Offset(pt.dx - 18, pt.dy), Offset(endX, endY), bladePaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: isClosed ? 'SWITCH (CLOSED)' : 'SWITCH (OPEN)',
        style: TextStyle(
          color: isClosed ? const Color(0xFF10B981) : const Color(0xFFE11D48),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - 22));
  }

  void _drawAmmeter(Canvas canvas, Offset pt, double current, bool isActive) {
    final rect = Rect.fromCenter(center: pt, width: 56, height: 48);
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'A\n${current.toStringAsFixed(3)} A',
        style: TextStyle(
          color: isActive ? const Color(0xFFF59E0B) : (isDarkMode ? Colors.white70 : Colors.black87),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  void _drawResistor(Canvas canvas, Offset pt, bool isActive) {
    final rect = Rect.fromCenter(center: pt, width: 72, height: 32);
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'R = 10.0 Ω',
        style: TextStyle(
          color: Color(0xFF3B82F6),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  void _drawVoltmeter(Canvas canvas, Offset pt, double voltage, bool isActive) {
    final rect = Rect.fromCenter(center: pt, width: 56, height: 42);
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'V\n${voltage.toStringAsFixed(2)} V',
        style: TextStyle(
          color: isActive ? const Color(0xFF10B981) : (isDarkMode ? Colors.white70 : Colors.black87),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CircuitBenchPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected ||
        oldDelegate.isSwitchClosed != isSwitchClosed ||
        oldDelegate.measuredVoltage != measuredVoltage ||
        oldDelegate.measuredCurrent != measuredCurrent ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
