import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lab_apparatus.dart';

/// Electrical apparatus for the bench painters: a bench power supply,
/// analogue meters, a resistor on its board, a knife switch and connecting
/// wires, in the same materials as [LabPaint]. The website draws the same
/// pieces (components/laboratory/apparatus/Electrical.jsx). Positions are in
/// the 700 x 380 bench box, standing on [LabPaint.tableY].
class LabElectrical {
  LabElectrical._();

  static const double _t = LabPaint.tableY;

  /// A 4 mm terminal post: red (positive) or black (negative).
  static void terminal(Canvas canvas, Offset c, {bool positive = false}) {
    canvas.drawCircle(c, 6, Paint()..color = positive ? const Color(0xFFC8392F) : const Color(0xFF1F2731));
    canvas.drawCircle(c, 6, LabPaint.stroke(positive ? const Color(0xFFE57368) : const Color(0xFF6B7784), 1.5));
    final r = Rect.fromCircle(center: c, radius: 2.2);
    canvas.drawOval(r, LabPaint.radial(r, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]));
  }

  /// Bench power supply (130 x 92), left edge at [x]. Terminals at x + 88 (+)
  /// and x + 112 (-), y = tableY - 18.
  static void powerSupply(Canvas canvas, {required double x, double volts = 0, bool on = false}) {
    const y = _t - 92;
    LabPaint.shadow(canvas, Offset(x + 65, _t + 2), 72, 4);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 130, 92), const Radius.circular(8));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFD9DEE4));
    canvas.drawRRect(body, LabPaint.stroke(const Color(0xFF8C9BAA), 1));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 130, 14), const Radius.circular(8)), Paint()..color = const Color(0xFFB9C2CC));
    final display = RRect.fromRectAndRadius(Rect.fromLTWH(x + 10, y + 22, 70, 30), const Radius.circular(3));
    canvas.drawRRect(display, Paint()..color = const Color(0xFF1D2A1E));
    LabPaint.text(canvas, '${volts.toStringAsFixed(1)} V', Offset(x + 45, y + 37), 14,
        on ? const Color(0xFF7CF29A) : const Color(0xFF365A3C), fontFamily: 'monospace');
    final knob = Rect.fromCircle(center: Offset(x + 102, y + 37), radius: 13);
    canvas.drawOval(knob, LabPaint.iron(knob));
    final a = (-130 + (volts / 6) * 260) * math.pi / 180;
    canvas.drawLine(
      Offset(x + 102, y + 37),
      Offset(x + 102 + 9 * math.sin(a), y + 37 - 9 * math.cos(a)),
      Paint()
        ..color = const Color(0xFFF4F7FA)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    LabPaint.text(canvas, 'VOLTAGE', Offset(x + 102, y + 58), 6.5, const Color(0xFF3B4B5C), weight: FontWeight.w400);
    LabPaint.text(canvas, 'DC 0–6 V', Offset(x + 30, y + 62), 7, const Color(0xFF3B4B5C));
    canvas.drawCircle(Offset(x + 20, y + 78), 3.5, Paint()..color = on ? const Color(0xFF2F9E5B) : const Color(0xFF6B7784));
    terminal(canvas, Offset(x + 88, _t - 18), positive: true);
    terminal(canvas, Offset(x + 112, _t - 18));
  }

  /// Analogue meter (100 x 84), left edge at [x], dial 0 to [max] with a red
  /// needle at [value]. Terminals at x + 26 and x + 74, y = tableY - 12; +
  /// on the right unless [positiveLeft].
  static void analogMeter(Canvas canvas,
      {required double x, required double value, required double max, required String unit, required List<String> ticks, bool positiveLeft = false}) {
    const y = _t - 84;
    final cx = x + 50;
    const cy = y + 58;
    const r = 34.0;
    LabPaint.shadow(canvas, Offset(x + 50, _t + 2), 56, 4);
    final body = Path()
      ..moveTo(x + 4, _t)
      ..lineTo(x + 96, _t)
      ..lineTo(x + 100, y + 8)
      ..quadraticBezierTo(x + 100, y, x + 92, y)
      ..lineTo(x + 8, y)
      ..quadraticBezierTo(x, y, x, y + 8)
      ..close();
    canvas.drawPath(body, LabPaint.iron(Rect.fromLTWH(x, y, 100, 84)));
    canvas.drawPath(body, LabPaint.stroke(const Color(0xFF5B6878), 1));
    final dial = RRect.fromRectAndRadius(Rect.fromLTWH(x + 10, y + 8, 80, 52), const Radius.circular(4));
    canvas.drawRRect(dial, Paint()..color = const Color(0xFFFBFBF7));
    final arc = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(arc, (-90 - 50) * math.pi / 180, 100 * math.pi / 180, false, LabPaint.stroke(const Color(0xFF2E3640), 1));
    for (int i = 0; i <= 10; i++) {
      final a = (-50 + i * 10) * math.pi / 180;
      final inner = i % 5 == 0 ? r - 6 : r - 3.5;
      canvas.drawLine(Offset(cx + inner * math.sin(a), cy - inner * math.cos(a)), Offset(cx + r * math.sin(a), cy - r * math.cos(a)),
          LabPaint.stroke(const Color(0xFF2E3640), i % 5 == 0 ? 1 : 0.6));
    }
    for (int i = 0; i < ticks.length; i++) {
      final a = (-50 + (i / (ticks.length - 1)) * 100) * math.pi / 180;
      LabPaint.text(canvas, ticks[i], Offset(cx + (r - 12) * math.sin(a), cy - (r - 12) * math.cos(a)), 6.5, const Color(0xFF2E3640),
          weight: FontWeight.w400);
    }
    LabPaint.text(canvas, unit, Offset(cx, cy - 10), 10, const Color(0xFF2E3640));
    final a = (-50 + (value.clamp(0.0, max) / max) * 100) * math.pi / 180;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + (r - 2) * math.sin(a), cy - (r - 2) * math.cos(a)),
      Paint()
        ..color = const Color(0xFFD0342C)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 2.6, Paint()..color = const Color(0xFF2E3640));
    terminal(canvas, Offset(x + 26, _t - 12), positive: positiveLeft);
    terminal(canvas, Offset(x + 74, _t - 12), positive: !positiveLeft);
  }

  /// A 10 Ω carbon resistor between brass posts on a wooden board (120 wide),
  /// left edge at [x]. Posts at x + 14 and x + 106, y = tableY - 22. [warm]
  /// (0..1) tints it as current flows.
  static void resistorBoard(Canvas canvas, {required double x, double warm = 0, String label = '10 Ω', Color labelColor = const Color(0xFF64748B)}) {
    LabPaint.shadow(canvas, Offset(x + 60, _t + 2), 64, 3.5);
    final board = Rect.fromLTWH(x, _t - 14, 120, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(3)), LabPaint.wood(board));
    for (final px in [x + 14, x + 106]) {
      final post = Rect.fromLTWH(px - 4, _t - 30, 8, 18);
      canvas.drawRRect(RRect.fromRectAndRadius(post, const Radius.circular(2)),
          LabPaint.radial(post, const [Color(0xFFFFF1C9), Color(0xFFDBA94A), Color(0xFF8C6420)], stops: const [0, 0.45, 1]));
      final cap = Rect.fromCircle(center: Offset(px, _t - 22), radius: 5);
      canvas.drawOval(cap, LabPaint.radial(cap, const [Color(0xFFFFF1C9), Color(0xFFDBA94A), Color(0xFF8C6420)], stops: const [0, 0.45, 1]));
    }
    canvas.drawLine(Offset(x + 14, _t - 24), Offset(x + 106, _t - 24), LabPaint.stroke(const Color(0xFF9AA5B1), 1.6));
    final w = warm.clamp(0.0, 1.0);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(x + 38, _t - 31, 44, 14), const Radius.circular(7));
    canvas.drawRRect(body, Paint()..color = Color.fromARGB(255, (222 + 20 * w).round(), (196 - 40 * w).round(), (150 - 60 * w).round()));
    canvas.drawRRect(body, LabPaint.stroke(const Color(0xFFA07D4A), 1));
    const bands = [Color(0xFF7A4A1E), Color(0xFF1F1F1F), Color(0xFF1F1F1F)];
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(x + 46 + i * 8, _t - 31, 4, 14), Paint()..color = bands[i]);
    }
    canvas.drawRect(Rect.fromLTWH(x + 72, _t - 31, 4, 14), Paint()..color = const Color(0xFFC9A227));
    LabPaint.text(canvas, label, Offset(x + 60, _t - 41), 8, labelColor);
  }

  /// Knife switch on a wooden base (70 wide), left edge at [x]. Contacts at
  /// x + 12 and x + 58, y = tableY - 18.
  static void knifeSwitch(Canvas canvas, {required double x, required bool closed}) {
    const py = _t - 18;
    LabPaint.shadow(canvas, Offset(x + 35, _t + 2), 40, 3);
    final base = Rect.fromLTWH(x, _t - 10, 70, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(2)), LabPaint.wood(base));
    final post = Rect.fromLTWH(x + 8, py - 4, 8, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(post, const Radius.circular(1.5)), LabPaint.metal(post));
    final clip = Rect.fromLTWH(x + 52, py - 6, 12, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(clip, const Radius.circular(1.5)), LabPaint.metal(clip));
    canvas.save();
    canvas.translate(x + 12, py);
    canvas.rotate(closed ? 0 : -55 * math.pi / 180);
    final blade = Rect.fromLTWH(-2, -2.5, 50, 5);
    canvas.drawRRect(RRect.fromRectAndRadius(blade, const Radius.circular(2)), LabPaint.metalV(blade));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, -9, 7, 12), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1F2731));
    canvas.restore();
  }

  static Offset _bezier(Offset a, Offset c1, Offset c2, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + b * (t * t * t);
  }

  /// A connecting wire lying on the bench, sagging by [sag] below its lower
  /// end. With [flow] (0..1, animated) current shows as dots moving along it.
  static void wire(Canvas canvas, Offset from, Offset to, {Color color = const Color(0xFFC8392F), double sag = 14, double? flow}) {
    final my = math.max(from.dy, to.dy) + sag;
    final c1 = Offset(from.dx, my);
    final c2 = Offset(to.dx, my);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, LabPaint.stroke(const Color(0x2E000000), 5));
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
    canvas.drawPath(path, LabPaint.stroke(const Color(0x40FFFFFF), 1));
    if (flow != null) {
      final dot = Paint()..color = const Color(0xFFFFE7A3);
      for (int k = 0; k < 8; k++) {
        final t = ((k + flow) / 8) % 1.0;
        canvas.drawCircle(_bezier(from, c1, c2, to, t), 1.3, dot);
      }
    }
  }

  /// A coil of loose connecting wires lying on the bench, centred at [cx].
  static void wireCoil(Canvas canvas, {required double cx}) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, _t + 8), width: 60, height: 14), LabPaint.stroke(const Color(0xFFC8392F), 3.2));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 4, _t + 9), width: 48, height: 10), LabPaint.stroke(const Color(0xFF1F2731), 3.2));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 3, _t + 7), width: 36, height: 8), LabPaint.stroke(const Color(0xFFC8392F), 3));
  }
}
