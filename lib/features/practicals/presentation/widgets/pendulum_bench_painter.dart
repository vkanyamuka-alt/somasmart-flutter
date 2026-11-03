import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lab_apparatus.dart';
import 'lab_hand.dart';

/// The simple pendulum bench, built from the shared lab apparatus kit
/// ([LabPaint]): a retort stand with a split cork, the thread and a brass bob
/// swinging at the real angle, a protractor scale under the cork and a
/// digital stopwatch. The metre rule stands beside the thread only while the
/// length is set ([showRule]), with L marked in gold, as in school: measure,
/// then put it away so it does not get in the way of the swing. The
/// student's hand takes the rule away, holds the bob at the release angle
/// ([holding]), lets it go and presses the stopwatch ([LabHand]). Cropped to
/// the apparatus so it fills a phone screen. The same bench is drawn on the
/// website (PendulumBench.jsx).
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
  final bool showRule;
  final bool holding;
  final LabHandRuns? hands; // 'rule', 'hold', 'watch'

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
    this.showRule = true,
    this.holding = false,
    this.hands,
  }) : super(repaint: hands);

  /// The part of the 700-wide bench that is drawn.
  static const double cropX = 150;
  static const double cropWidth = 410;
  static const Color _gold = Color(0xFFDB9E3D);
  static const double _stopwatchX = 490;

  static const double _pivotX = 340;
  static const double _pivotY = 72;
  static const double _pxPerCm = 2.3; // 100 cm of thread reaches just above the base

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintScene(canvas, size, isDark, cropX: cropX, cropWidth: cropWidth, (left, right) {
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

      _metreRule(canvas, lengthPx, bobY);

      // Thread and bob, turned about the cork by the live angle.
      canvas.save();
      canvas.translate(_pivotX, _pivotY);
      canvas.rotate(-angleDeg * math.pi / 180);
      canvas.drawLine(Offset.zero, Offset(0, lengthPx - 11), LabPaint.stroke(const Color(0xFF2E3640), 1.3));
      LabPaint.bob(canvas, Offset(0, lengthPx));
      canvas.restore();

      // The hand holds the bob beside its rest line at the release angle, then lets go.
      final held = Offset(_pivotX + lengthPx * math.sin(a) + 10, _pivotY + lengthPx * math.cos(a));
      final hold = hands?.since('hold');
      if (holding) {
        LabHand.rest(canvas, hold, at: held, rotate: -90, enter: const Offset(30, 10), delay: hands?.since('rule') == null ? 0 : 700);
      } else {
        LabHand.letGo(canvas, hold, at: held, rotate: -90);
      }

      LabPaint.stopwatch(canvas, cx: _stopwatchX, seconds: stopwatchSeconds, running: isOscillating);
      LabPaint.text(
        canvas,
        '$oscillations / $targetOscillations oscillations',
        const Offset(_stopwatchX, LabPaint.tableY - 84),
        11,
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      );
      LabHand.move(canvas, hands?.since('watch'),
          from: const Offset(512, 176), to: const Offset(_stopwatchX, LabPaint.tableY - 87), pose: HandPose.point, rotate: 180, duration: 900);
    });
  }

  /// The metre rule beside the thread while the length is set, with L marked
  /// from the bottom of the split cork to the centre of the bob. When the
  /// length is set the hand takes it away (700 ms); going back brings it back.
  void _metreRule(Canvas canvas, double lengthPx, double bobY) {
    final t = hands?.since('rule');
    final p = t == null ? 1.0 : Curves.easeIn.transform((t / 700).clamp(0.0, 1.0));
    final gone = showRule ? 1 - p : p; // 0 on the bench, 1 put away
    if (gone < 1) {
      canvas.save();
      canvas.translate(36 * gone, 30 * gone);
      if (gone > 0) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - gone));
      LabPaint.metreRule(canvas, x: 372, y0: _pivotY, pxPerCm: _pxPerCm);
      if (gone > 0) canvas.restore();
      canvas.restore();
    }
    if (showRule) {
      final dash = LabPaint.stroke(_gold, 1.4);
      _dashed(canvas, const Offset(_pivotX + 8, _pivotY), const Offset(368, _pivotY), dash, on: 3, off: 3);
      _dashed(canvas, Offset(_pivotX + 13, bobY), Offset(368, bobY), dash, on: 3, off: 3);
      final tp = TextPainter(
        text: TextSpan(
            text: 'L = ${lengthCm.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _gold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(404, _pivotY + lengthPx / 2 - tp.height / 2));
    } else {
      LabHand.letGo(canvas, t, at: const Offset(384, _pivotY + 80), pose: HandPose.grip);
    }
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
    _dashed(canvas, a, b, LabPaint.stroke(const Color(0xB37D8A98), 1), on: 3, off: 5);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, {required double on, required double off}) {
    final len = (b - a).distance;
    if (len == 0) return;
    final dir = (b - a) / len;
    for (double t = 0; t < len; t += on + off) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + on, len), paint);
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
        oldDelegate.inspectedItemKey != inspectedItemKey ||
        oldDelegate.showRule != showRule ||
        oldDelegate.holding != holding;
  }
}
