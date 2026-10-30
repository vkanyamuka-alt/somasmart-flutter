import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lab_apparatus.dart';

/// The simple pendulum bench, built from the shared lab apparatus kit
/// ([LabPaint]): a retort stand with a split cork, the thread and a brass bob
/// swinging at the real angle, a metre rule beside the thread, a protractor
/// scale under the cork and a digital stopwatch. The same bench is drawn on
/// the website (PendulumBench.jsx).
class PendulumBenchPainter extends CustomPainter {
  final double lengthCm; // 20.0 to 100.0 cm
  final double angleDeg; // live angle of the thread, degrees
  final double releaseAngleDeg; // the angle the bob is released from
  final bool isOscillating;
  final bool isDark;
  final double stopwatchSeconds;
  final int oscillations;
  final int targetOscillations;
  final String? inspectedItemKey;

  const PendulumBenchPainter({
    required this.lengthCm,
    required this.angleDeg,
    required this.isOscillating,
    required this.isDark,
    this.releaseAngleDeg = 6,
    this.stopwatchSeconds = 0,
    this.oscillations = 0,
    this.targetOscillations = 20,
    this.inspectedItemKey,
  });

  static const double _pivotX = 340;
  static const double _pivotY = 72;
  static const double _pxPerCm = 2.3; // 100 cm of thread reaches just above the base

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintScene(canvas, size, isDark, (left, right) {
      LabPaint.retortStand(canvas, baseX: 170, baseWidth: 170, rodX: 190, clampYs: const [40], armTo: 326);
      LabPaint.splitCork(canvas, x: _pivotX, y: 50);
      _protractor(canvas);

      final lengthPx = lengthCm * _pxPerCm;
      final bobY = _pivotY + lengthPx;
      // Rest line and release angle
      _dashedLine(canvas, const Offset(_pivotX, _pivotY), Offset(_pivotX, bobY + 14));
      final a = releaseAngleDeg * math.pi / 180;
      canvas.drawLine(
        const Offset(_pivotX, _pivotY),
        Offset(_pivotX + 56 * math.sin(a), _pivotY + 56 * math.cos(a)),
        LabPaint.stroke(const Color(0xCCC8392F), 1.2),
      );

      LabPaint.metreRule(canvas, x: 372, y0: _pivotY, pxPerCm: _pxPerCm);

      // Thread and bob, turned about the cork by the live angle.
      canvas.save();
      canvas.translate(_pivotX, _pivotY);
      canvas.rotate(-angleDeg * math.pi / 180);
      canvas.drawLine(Offset.zero, Offset(0, lengthPx - 11), LabPaint.stroke(const Color(0xFF2E3640), 1.3));
      LabPaint.bob(canvas, Offset(0, lengthPx));
      canvas.restore();

      LabPaint.stopwatch(canvas, cx: 548, seconds: stopwatchSeconds, running: isOscillating);
      LabPaint.text(
        canvas,
        '$oscillations / $targetOscillations oscillations',
        const Offset(548, LabPaint.tableY - 84),
        11,
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      );
    });
  }

  /// A clear protractor scale on an arc under the cork, 20° each side.
  void _protractor(Canvas canvas) {
    const r = 50.0;
    final arc = Rect.fromCircle(center: const Offset(_pivotX, _pivotY), radius: r);
    // Angles measured from straight down; Flutter's arc angles from +x.
    const start = math.pi / 2 - 20 * math.pi / 180;
    const sweep = 40 * math.pi / 180;
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..color = const Color(0x59C9D7E3)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(arc, start, sweep, false, LabPaint.stroke(const Color(0xFF8EA8BE), 1));
    for (int d = -20; d <= 20; d += 2) {
      final a = d * math.pi / 180;
      final inner = d % 10 == 0 ? r - 8 : r - 4;
      canvas.drawLine(
        Offset(_pivotX + inner * math.sin(a), _pivotY + inner * math.cos(a)),
        Offset(_pivotX + r * math.sin(a), _pivotY + r * math.cos(a)),
        LabPaint.stroke(const Color(0xFF3B4B5C), d % 10 == 0 ? 1 : 0.6),
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b) {
    final paint = LabPaint.stroke(const Color(0xB37D8A98), 1);
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (double t = 0; t < len; t += 8) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + 3, len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PendulumBenchPainter oldDelegate) {
    return oldDelegate.lengthCm != lengthCm ||
        oldDelegate.angleDeg != angleDeg ||
        oldDelegate.releaseAngleDeg != releaseAngleDeg ||
        oldDelegate.isOscillating != isOscillating ||
        oldDelegate.isDark != isDark ||
        oldDelegate.stopwatchSeconds != stopwatchSeconds ||
        oldDelegate.oscillations != oscillations ||
        oldDelegate.inspectedItemKey != inspectedItemKey;
  }
}
