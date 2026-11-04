import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/optics_state.dart';
import 'lab_apparatus.dart';
import 'lab_hand.dart';

/// The refraction bench: a drawing board seen from above with the 60° glass
/// prism, the normals, a protractor on face AB, a ray box sending a ray
/// through the prism and the four optical pins, drawn as students draw it on
/// paper. The student's hand lays the protractor on face AB and pushes the
/// pins in one at a time ([LabHand]). Built from the shared lab kit
/// ([LabPaint]); the website draws the same board (RefractionBench.jsx) with
/// the same geometry.
class OpticsBenchPainter extends CustomPainter {
  final OpticsState state;
  final bool isDark;
  final LabHandRuns? hands; // keys from [handKeys]
  /// The apparatus tapped on the inspect step, shown glowing as active.
  final String? inspectedItemKey;

  OpticsBenchPainter({
    required this.state,
    required this.isDark,
    this.hands,
    this.inspectedItemKey,
  }) : super(repaint: hands);

  /// The values the hands on this bench react to, for [LabHandPaint.watch].
  static Map<String, Object?> handKeys(OpticsState s) =>
      {'protractor': s.showProtractor, 'pins': s.showOpticalPins, 'angle': s.incidentAngleDeg};

  /// Where the protractor and the tray of pins lie until the hand takes them.
  static const _protractorRest = Offset(140, 92);
  static const _pinTray = Rect.fromLTWH(304, 304, 92, 28);

  static const double _pinGap = 900; // ms between the hand pushing in one pin and the next

  // The prism on the board: apex A, base corners B and C.
  static const _a = Offset(350, 80);
  static const _b = Offset(245, 261.9);
  static const _c = Offset(455, 261.9);
  static const _ray = Color(0xFFE2A93B);
  static const _ink = Color(0xFF1F2933);

  static Offset _dir(double deg) => Offset(math.cos(deg * math.pi / 180), math.sin(deg * math.pi / 180));

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintBoard(canvas, size, () {
      final i = state.incidentAngleDeg;
      final r = state.refractedAngleDeg;
      final n = state.trueGlassRefractiveIndex;
      final r2 = state.prismRefractingAngleDeg - r;
      // Below about 28° the ray cannot leave face AC: total internal reflection.
      final tir = n * math.sin(r2 * math.pi / 180) > 1;
      final e = tir ? null : math.asin(n * math.sin(r2 * math.pi / 180)) * 180 / math.pi;

      // Where the ray meets the prism and which way it goes.
      final p = _a + (_b - _a) * 0.45;
      final dIn = _dir(30 - i); // AB's inward normal points at 30°
      final dR = _dir(30 - r);
      final w = _c - _a;
      final den = dR.dx * w.dy - dR.dy * w.dx;
      final t = ((_a.dx - p.dx) * w.dy - (_a.dy - p.dy) * w.dx) / den;
      final q = p + dR * t;
      final dE = e == null ? null : _dir(-30 + e); // AC's outward normal points at -30°

      // Prism
      final prism = Path()
        ..moveTo(_a.dx, _a.dy)
        ..lineTo(_b.dx, _b.dy)
        ..lineTo(_c.dx, _c.dy)
        ..close();
      canvas.drawPath(prism, LabPaint.glass(Rect.fromPoints(_b, _a)));
      canvas.drawPath(prism, Paint()..color = const Color(0x40BAD6EC));
      canvas.drawPath(prism, LabPaint.stroke(const Color(0xFF5E7F99), 2));
      canvas.drawLine(_a + const Offset(-8, 22), _b + const Offset(10, -8),
          Paint()
            ..color = const Color(0x99FFFFFF)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);

      if (state.showNormalLines) {
        final nAB = _dir(30);
        final nAC = _dir(-30);
        _dashed(canvas, p - nAB * 70, p + nAB * 60);
        _dashed(canvas, q - nAC * 60, q + nAC * 70);
      }
      if (state.showProtractor) {
        LabHand.carry(canvas, hands?.since('protractor'),
            offset: _protractorRest - p, grip: p + const Offset(-30, 40), pose: HandPose.pinch, rotate: -30, draw: () => _protractor(canvas, p));
      } else {
        _protractor(canvas, _protractorRest);
      }

      final source = p - dIn * 235;
      final rayPaint = Paint()
        ..color = _ray
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      if (state.laserActive) {
        canvas.drawLine(source, p, rayPaint);
        canvas.drawLine(p, q, Paint()
          ..color = _ray.withValues(alpha: 0.85)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
        if (dE != null && state.showRayExtension) canvas.drawLine(q, q + dE * 230, rayPaint);
      }

      // Angle marks
      _arc(canvas, p, 32, 210 - i, 210, 'i');
      _arc(canvas, p, 30, 30 - r, 30, 'r');
      if (e != null) _arc(canvas, q, 32, -30, -30 + e, 'e');
      if (tir) LabPaint.text(canvas, 'Total internal reflection: no emergent ray', q + const Offset(70, -24), 10, const Color(0xFFC8392F));

      // Ray box
      canvas.save();
      canvas.translate(source.dx, source.dy);
      canvas.rotate((30 - i) * math.pi / 180);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-46, -13, 46, 26), const Radius.circular(4)),
          Paint()..color = const Color(0xFF2E3640));
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 5, 4), Paint()..color = const Color(0xFFFFF3C4));
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-40, -9, 22, 4), const Radius.circular(2)),
          Paint()..color = const Color(0xFF4A5562));
      canvas.restore();
      // The hand turns the ray box to the new angle of incidence.
      final turned = hands?.since('angle');
      if (turned != null) {
        final grip = source - dIn * 24;
        if (turned < 900) {
          LabHand.paint(canvas, HandPose.grip, at: grip, scale: 0.8);
        } else {
          LabHand.letGo(canvas, turned - 900, at: grip, pose: HandPose.grip, scale: 0.8);
        }
      }

      // The pins wait in their tray until the hand pushes them in.
      final pinsIn = hands?.since('pins');
      final used = dE == null ? 2 : 4;
      final taken = pinsIn == null ? used : (pinsIn < 150 ? 0 : ((pinsIn - 150) / _pinGap).floor() + 1).clamp(0, used);
      _pinTrayWith(canvas, state.showOpticalPins ? 4 - taken : 4);

      if (state.showOpticalPins) {
        final pins = [
          (p - dIn * 150, 'P1'),
          (p - dIn * 78, 'P2'),
          if (dE != null) (q + dE * 78, 'P3'),
          if (dE != null) (q + dE * 150, 'P4'),
        ];
        // Each pin shows once the hand has pushed it into the board.
        final t = hands?.since('pins');
        for (int k = 0; k < pins.length; k++) {
          _pin(canvas, pins[k].$1, pins[k].$2, opacity: LabHand.appear(t, k * _pinGap + 500));
        }
        for (int k = 0; k < pins.length; k++) {
          LabHand.move(canvas, t, from: _pinTray.center, to: pins[k].$1, duration: 1100, delay: k * _pinGap);
        }
      }

      if (inspectedItemKey == 'prism') {
        LabPaint.activeGlowPath(canvas, prism);
      } else if (inspectedItemKey == 'pins' && state.showOpticalPins) {
        final rings = Path();
        for (final c in [p - dIn * 150, p - dIn * 78, if (dE != null) q + dE * 78, if (dE != null) q + dE * 150]) {
          rings.addOval(Rect.fromCircle(center: c, radius: 11));
        }
        LabPaint.activeGlowPath(canvas, rings);
      } else {
        final area = _inspectArea(inspectedItemKey, p, source, dIn);
        if (area != null) LabPaint.activeGlow(canvas, area, radius: 10);
      }

      LabPaint.text(canvas, 'A', _a + const Offset(0, -12), 11, _ink);
      LabPaint.text(canvas, 'B', _b + const Offset(-12, 10), 11, _ink);
      LabPaint.text(canvas, 'C', _c + const Offset(12, 10), 11, _ink);
      LabPaint.text(canvas, '60°', _a + const Offset(0, 38), 10, const Color(0xFF3B4B5C), weight: FontWeight.w400);
    });
  }

  /// Where each inspected apparatus lies on the board.
  Rect? _inspectArea(String? id, Offset p, Offset source, Offset dIn) {
    switch (id) {
      case 'board':
        return const Rect.fromLTWH(24, 18, 652, 344);
      case 'pins':
        return _pinTray;
      case 'protractor':
        final c = state.showProtractor ? p : _protractorRest;
        return Rect.fromLTRB(c.dx - 54, c.dy - 48, c.dx + 28, c.dy + 48);
      case 'light_source':
        return Rect.fromCircle(center: source - dIn * 23, radius: 28);
    }
    return null;
  }

  /// A small tray holding the [count] pins not yet pushed into the board.
  void _pinTrayWith(Canvas canvas, int count) {
    if (count == 0) return;
    final tray = RRect.fromRectAndRadius(_pinTray, const Radius.circular(5));
    canvas.drawRRect(tray, Paint()..color = const Color(0xFFE9E4D6));
    canvas.drawRRect(tray, LabPaint.stroke(const Color(0xFFB9B09A), 1));
    for (int k = 0; k < count; k++) {
      final c = Offset(_pinTray.left + 16 + k * 20, _pinTray.center.dy);
      canvas.drawLine(c, c + const Offset(9, 5), LabPaint.stroke(const Color(0xFF8C9BAA), 1.4));
      final head = Rect.fromCircle(center: c, radius: 4.5);
      canvas.drawOval(head, LabPaint.radial(head, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]));
      canvas.drawCircle(c, 2, Paint()..color = const Color(0xFFC8392F));
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b) {
    final paint = LabPaint.stroke(const Color(0xFF3B4B5C), 1);
    final len = (b - a).distance;
    final d = (b - a) / len;
    for (double t = 0; t < len; t += 9) {
      canvas.drawLine(a + d * t, a + d * math.min(t + 5, len), paint);
    }
  }

  /// Protractor laid on face AB, on the outside of the prism (120°..300°).
  void _protractor(Canvas canvas, Offset c) {
    const r = 52.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    final half = Path()
      ..moveTo(c.dx + r * math.cos(120 * math.pi / 180), c.dy + r * math.sin(120 * math.pi / 180))
      ..arcTo(rect, 120 * math.pi / 180, math.pi, false)
      ..close();
    canvas.drawPath(half, Paint()..color = const Color(0x59C8E1F5));
    canvas.drawPath(half, LabPaint.stroke(const Color(0xFF8EA8BE), 1));
    for (int d = 0; d <= 180; d += 10) {
      final a = (120 + d) * math.pi / 180;
      final inner = d % 30 == 0 ? r - 8 : r - 4;
      canvas.drawLine(Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)), Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)),
          LabPaint.stroke(const Color(0xFF3B4B5C), d % 30 == 0 ? 1 : 0.6));
    }
  }

  void _arc(Canvas canvas, Offset c, double r, double fromDeg, double toDeg, String label) {
    const color = Color(0xFF184E78);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), fromDeg * math.pi / 180, (toDeg - fromDeg) * math.pi / 180, false,
        LabPaint.stroke(color, 1.3));
    final mid = (fromDeg + toDeg) / 2 * math.pi / 180;
    LabPaint.text(canvas, label, c + Offset(math.cos(mid), math.sin(mid)) * (r + 11), 10.5, color);
  }

  void _pin(Canvas canvas, Offset p, String label, {double opacity = 1}) {
    if (opacity <= 0) return;
    if (opacity < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawOval(Rect.fromCenter(center: p + const Offset(3, 3), width: 10, height: 6), Paint()..color = const Color(0x2E0B1A2A));
    final head = Rect.fromCircle(center: p, radius: 5);
    canvas.drawOval(head, LabPaint.radial(head, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]));
    canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFC8392F));
    LabPaint.text(canvas, label, p + const Offset(14, -9), 10, _ink);
    if (opacity < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OpticsBenchPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.isDark != isDark || oldDelegate.inspectedItemKey != inspectedItemKey;
}
