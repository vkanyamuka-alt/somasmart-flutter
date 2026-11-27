import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lab_apparatus.dart';

/// Electrical apparatus as it lies on a school bench, seen from above
/// ([LabPaint.paintTop]): dry cells in a cell holder, a plug key, moving-coil
/// meters, a resistor on its board and the connecting wires. These are the
/// pieces NECTA physics practicals provide ("a dry cell E, a key K, an
/// ammeter A, a voltmeter V, connecting wires"), so the bench looks like the
/// one learners use in school. The website draws the same pieces
/// (components/laboratory/apparatus/Electrical.jsx).
class LabElectrical {
  LabElectrical._();

  static const Color _label = Color(0xFF3B4B5C);
  static const Color _dial = Color(0xFF2E3640);

  static Paint _brass(Rect r) =>
      LabPaint.radial(r, const [Color(0xFFFFF1C9), Color(0xFFDBA94A), Color(0xFF8C6420)], stops: const [0, 0.45, 1]);
  static Paint _chrome(Rect r) =>
      LabPaint.radial(r, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]);

  /// SVG-style text: [baseline] is where the letters sit, as on the website.
  static void _text(Canvas canvas, String s, double x, double baseline, double size, Color color,
      {FontWeight weight = FontWeight.w700}) {
    LabPaint.text(canvas, s, Offset(x, baseline - size * 0.36), size, color, weight: weight);
  }

  static void _shadowRect(Canvas canvas, Rect r, double radius, {double opacity = 0.12}) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..color = Colors.black.withValues(alpha: opacity));
  }

  /// A 4 mm terminal post seen from above: red (positive) or black (negative).
  static void terminal(Canvas canvas, Offset c, {bool positive = false, double r = 7}) {
    canvas.drawCircle(c, r, Paint()..color = positive ? const Color(0xFFC8392F) : const Color(0xFF1F2731));
    canvas.drawCircle(c, r, LabPaint.stroke(positive ? const Color(0xFFE57368) : const Color(0xFF6B7784), 1.5));
    final inner = Rect.fromCircle(center: c, radius: r * 0.4);
    canvas.drawOval(inner, _chrome(inner));
  }

  static const double _cellW = 52;
  static const double _cellH = 30;

  /// Size D dry cells (1.5 V each) lying in a cell holder, left edge at [x]
  /// and top at [y]. [inUse] cells, counted from the left, are in the circuit
  /// and the crocodile clip sits after the last of them. Terminals at
  /// [cellHolderTerminals].
  static void cellHolder(Canvas canvas, {required double x, required double y, int cells = 4, int inUse = 1}) {
    final t = cellHolderTerminals(x, y, inUse);
    final width = cells * _cellW + 28;
    _shadowRect(canvas, Rect.fromLTWH(x + 3, y + 5, width, _cellH + 22), 6);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, width, _cellH + 22), const Radius.circular(6));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2A3440));
    canvas.drawRRect(body, LabPaint.stroke(const Color(0xFF4A5562), 1));
    for (int i = 0; i < cells; i++) {
      final cx = x + 14 + i * _cellW;
      final used = i < inUse;
      final cellRect = Rect.fromLTWH(cx, y + 11, _cellW - 6, _cellH);
      if (!used) canvas.saveLayer(cellRect.inflate(8), Paint()..color = const Color(0x8C000000));
      final cell = RRect.fromRectAndRadius(cellRect, const Radius.circular(4));
      canvas.drawRRect(cell, LabPaint.iron(cellRect));
      canvas.drawRRect(cell, LabPaint.stroke(used ? const Color(0xFFDB9E3D) : const Color(0xFF55616D), used ? 1.6 : 1));
      final nub = Rect.fromLTWH(cx + _cellW - 6, y + 11 + _cellH / 2 - 5, 5, 10);
      canvas.drawRRect(RRect.fromRectAndRadius(nub, const Radius.circular(1.5)), _chrome(nub));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6, y + 15, _cellW - 18, 5), const Radius.circular(2)),
          Paint()..color = const Color(0x1FFFFFFF));
      _text(canvas, '1.5 V', cx + (_cellW - 6) / 2, y + 11 + _cellH / 2 + 4, 10, const Color(0xFFF4F7FA));
      if (!used) canvas.restore();
    }
    terminal(canvas, t.negative);
    // crocodile clip on the + end of the last cell in use
    final px = t.positive.dx;
    final clip = RRect.fromRectAndRadius(Rect.fromLTWH(px - 6, y - 6, 12, 20), const Radius.circular(3));
    canvas.drawRRect(clip, Paint()..color = const Color(0xFFC8392F));
    canvas.drawRRect(clip, LabPaint.stroke(const Color(0xFF8E2A22), 1));
    final jaw = Path()
      ..moveTo(px - 4, y + 13)
      ..lineTo(px, y + 22)
      ..lineTo(px + 4, y + 13);
    canvas.drawPath(jaw, LabPaint.metal(Rect.fromLTWH(px - 4, y + 13, 8, 9)));
    canvas.drawPath(jaw, LabPaint.stroke(const Color(0xFF55616D), 0.8));
  }

  /// Where the wires join a cell holder drawn at [x], [y] with [inUse] cells:
  /// the − terminal, and the + (the crocodile clip, which moves).
  static ({Offset negative, Offset positive}) cellHolderTerminals(double x, double y, int inUse) =>
      (negative: Offset(x + 7, y + 26), positive: Offset(x + 12 + inUse * _cellW, y - 6));

  /// A plug key (K) on its black base, left edge at [x], top at [y] (90 x
  /// 44): two brass blocks and the brass plug, pushed in between them when
  /// closed and lying beside them when open. [plugOut] (0 in .. 1 out) lets
  /// the plug move as the hand pushes it. Terminals at x + 12 and x + 78, y + 22.
  static void plugKey(Canvas canvas, {required double x, required double y, required double plugOut}) {
    _shadowRect(canvas, Rect.fromLTWH(x + 3, y + 4, 90, 44), 5);
    final base = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 90, 44), const Radius.circular(5));
    canvas.drawRRect(base, Paint()..color = const Color(0xFF1F2731));
    canvas.drawRRect(base, LabPaint.stroke(const Color(0xFF4A5562), 1));
    for (final bx in [x + 22, x + 48]) {
      final block = Rect.fromLTWH(bx, y + 10, 20, 24);
      canvas.drawRRect(RRect.fromRectAndRadius(block, const Radius.circular(2)), _brass(block));
      canvas.drawRRect(RRect.fromRectAndRadius(block, const Radius.circular(2)), LabPaint.stroke(const Color(0xFF8C6420), 0.8));
    }
    terminal(canvas, Offset(x + 12, y + 22), r: 6);
    terminal(canvas, Offset(x + 78, y + 22), r: 6);
    final plug = Offset(x + 45, y + 22 + 30 * plugOut.clamp(0.0, 1.0));
    canvas.drawCircle(plug, 9, Paint()..color = const Color(0xFF1F2731));
    canvas.drawCircle(plug, 9, LabPaint.stroke(const Color(0xFF6B7784), 1.2));
    final head = Rect.fromCircle(center: plug, radius: 4);
    canvas.drawOval(head, _brass(head));
    _text(canvas, 'K', x + 45, y - 6, 11, _label);
  }

  static String _number(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// A moving-coil meter seen face-on (150 x 120), left edge at [x], top at
  /// [y]: a white scale from 0 to [max] with a division every [minor],
  /// numbers every [major], the unit letter, and a red needle at [value].
  /// Terminals along the top: − at x + 30 and + at x + 120, y + 4.
  static void meterFace(Canvas canvas,
      {required double x,
      required double y,
      required double value,
      required double max,
      required double major,
      required double minor,
      required String unit,
      String? label,
      Color labelColor = _label}) {
    final cx = x + 75;
    final cy = y + 104;
    const r = 70.0;
    const sweep = 116.0; // degrees, -58 to +58
    double at(double v) => (-sweep / 2 + (v.clamp(0.0, max) / max) * sweep) * math.pi / 180;
    Offset onDial(double a, double radius) => Offset(cx + radius * math.sin(a), cy - radius * math.cos(a));

    _shadowRect(canvas, Rect.fromLTWH(x + 3, y + 5, 150, 120), 10, opacity: 0.14);
    final caseRect = Rect.fromLTWH(x, y, 150, 120);
    canvas.drawRRect(RRect.fromRectAndRadius(caseRect, const Radius.circular(10)), LabPaint.iron(caseRect));
    canvas.drawRRect(RRect.fromRectAndRadius(caseRect, const Radius.circular(10)), LabPaint.stroke(const Color(0xFF5B6878), 1));
    final face = RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, y + 16, 134, 96), const Radius.circular(6));
    canvas.drawRRect(face, Paint()..color = const Color(0xFFFBFBF7));
    canvas.drawRRect(face, LabPaint.stroke(const Color(0xFFB4BEC8), 1));
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), at(0) - math.pi / 2, at(max) - at(0), false,
        LabPaint.stroke(_dial, 1.2));
    final divisions = (max / minor).round();
    for (int k = 0; k <= divisions; k++) {
      final v = k * minor;
      final a = at(v);
      final isMajor = (v / major - (v / major).round()).abs() < 1e-6;
      canvas.drawLine(onDial(a, isMajor ? r - 10 : r - 5), onDial(a, r), LabPaint.stroke(_dial, isMajor ? 1.3 : 0.7));
      if (isMajor) {
        final n = onDial(a, r - 20);
        _text(canvas, _number(v), n.dx, n.dy - 1, 10.5, _dial, weight: FontWeight.w600);
      }
    }
    _text(canvas, unit, x + 24, y + 104, 18, const Color(0xFF184E78), weight: FontWeight.w800);
    canvas.drawLine(
      Offset(cx, cy),
      onDial(at(value), r - 3),
      Paint()
        ..color = const Color(0xFFD0342C)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = _dial);
    terminal(canvas, Offset(x + 30, y + 4), r: 6);
    terminal(canvas, Offset(x + 120, y + 4), r: 6, positive: true);
    _text(canvas, '−', x + 30, y + 22, 9, _dial);
    _text(canvas, '+', x + 120, y + 22, 9, const Color(0xFFC8392F));
    if (label != null) _text(canvas, label, cx, y + 136, 11, labelColor);
  }

  /// A carbon resistor between two brass terminals on a wooden board (140 x
  /// 40), left edge at [x], top at [y]. Terminals at x + 16 and x + 124,
  /// y + 20. [warm] (0..1) tints it when current flows.
  static void resistorBoard(Canvas canvas, {required double x, required double y, double warm = 0, String label = 'R', Color labelColor = _label}) {
    _shadowRect(canvas, Rect.fromLTWH(x + 3, y + 4, 140, 40), 4);
    final board = Rect.fromLTWH(x, y, 140, 40);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(4)), LabPaint.wood(board));
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(4)), LabPaint.stroke(const Color(0xFFA9783E), 1));
    canvas.drawLine(Offset(x + 16, y + 20), Offset(x + 124, y + 20), LabPaint.stroke(const Color(0xFF9AA5B1), 2));
    final w = warm.clamp(0.0, 1.0);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(x + 45, y + 12, 50, 16), const Radius.circular(8));
    canvas.drawRRect(body, Paint()..color = Color.fromARGB(255, (222 + 20 * w).round(), (196 - 40 * w).round(), (150 - 60 * w).round()));
    canvas.drawRRect(body, LabPaint.stroke(const Color(0xFFA07D4A), 1));
    const bands = [Color(0xFF7A4A1E), Color(0xFF1F1F1F), Color(0xFF1F1F1F)];
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(x + 54 + i * 9, y + 12, 5, 16), Paint()..color = bands[i]);
    }
    canvas.drawRect(Rect.fromLTWH(x + 83, y + 12, 5, 16), Paint()..color = const Color(0xFFC9A227));
    for (final px in [x + 16, x + 124]) {
      final post = Rect.fromCircle(center: Offset(px, y + 20), radius: 7);
      canvas.drawOval(post, _brass(post));
      canvas.drawOval(post, LabPaint.stroke(const Color(0xFF8C6420), 0.8));
    }
    _text(canvas, label, x + 70, y - 6, 11, labelColor);
  }

  /// A connecting wire lying on the bench top between two terminals, bowed
  /// sideways by [bow] so wires do not lie on top of each other, or laid
  /// along two [controls] points to route it round other apparatus. With
  /// [flow] (0..1, animated) current shows as dots moving along it, from
  /// [from] to [to]. [opacity] fades it in as the hand joins it.
  static void wire(Canvas canvas, Offset from, Offset to,
      {Color color = const Color(0xFFC8392F), double bow = 0, List<Offset>? controls, double? flow, double opacity = 1}) {
    final path = Path()..moveTo(from.dx, from.dy);
    if (controls != null) {
      path.cubicTo(controls[0].dx, controls[0].dy, controls[1].dx, controls[1].dy, to.dx, to.dy);
    } else {
      final mid = (from + to) / 2;
      final d = to - from;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final c = mid + Offset(-d.dy / len, d.dx / len) * bow;
      path.quadraticBezierTo(c.dx, c.dy, to.dx, to.dy);
    }
    if (opacity <= 0) return;
    if (opacity < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawPath(path.shift(const Offset(2, 3)), LabPaint.stroke(const Color(0x29000000), 6));
    canvas.drawPath(
        path,
        LabPaint.stroke(color, 4)
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, LabPaint.stroke(const Color(0x40FFFFFF), 1.2)..strokeCap = StrokeCap.round);
    if (flow != null) {
      final dot = Paint()..color = const Color(0xFFFFE7A3);
      for (final metric in path.computeMetrics()) {
        for (double s = (flow % 1.0) * 12; s < metric.length; s += 12) {
          final tangent = metric.getTangentForOffset(s);
          if (tangent != null) canvas.drawCircle(tangent.position, 1.2, dot);
        }
      }
    }
    if (opacity < 1) canvas.restore();
  }

  /// A bundle of loose connecting wires (with crocodile clips) lying on the
  /// bench, centred at [c].
  static void wireBundle(Canvas canvas, Offset c) {
    canvas.drawOval(Rect.fromCenter(center: c, width: 68, height: 32), LabPaint.stroke(const Color(0xFFC8392F), 3.6));
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(5, 2), width: 52, height: 22), LabPaint.stroke(const Color(0xFF1F2731), 3.6));
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(-4, -1), width: 36, height: 14), LabPaint.stroke(const Color(0xFFC8392F), 3.2));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx + 30, c.dy - 4, 12, 7), const Radius.circular(2)),
        Paint()..color = const Color(0xFFC8392F));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 42, c.dy - 2, 12, 7), const Radius.circular(2)),
        Paint()..color = const Color(0xFF1F2731));
  }
}
