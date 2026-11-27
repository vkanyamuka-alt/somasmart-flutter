import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/rates_of_reaction_state.dart';
import 'lab_apparatus.dart';
import 'lab_hand.dart';

/// CustomPainter that renders the interactive chemical kinetics laboratory
/// bench. The student's hand carries each flask onto the paper marked X and
/// pours in the acid ([LabHand]).
class RatesOfReactionBenchPainter extends CustomPainter {
  final RatesOfReactionState state;
  final bool isDark;
  final double animationValue;
  final LabHandRuns? hands; // keys from [handKeys]
  /// The apparatus tapped on the inspect step, shown glowing as active.
  final String? inspectedItemKey;

  const RatesOfReactionBenchPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 0.0,
    this.hands,
    this.inspectedItemKey,
  }) : super(repaint: hands);

  /// Where the 10 mL measuring cylinder stands until the hand picks it up.
  static const Offset _cylinderAt = Offset(36, 167);
  static const double _pourMs = 1700;

  /// The values the hands on this bench react to, for [LabHandPaint.watch].
  static Map<String, Object?> handKeys(RatesOfReactionState s) => {
        'flask': s.isFlaskOnCross,
        'acid': s.trials.isEmpty ? null : '${s.activeTrialIndex}:${s.trials[s.activeTrialIndex].isAcidAdded}',
        'prep': s.trials.map((t) => t.isPrepared ? '1' : '0').join(),
      };

  static const double _prepGap = 1100; // ms for each flask filled, one after the other

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawLabBenchBackground(canvas, size);
    _drawReagentBottles(canvas, size);
    _drawCrossTileAndFlask(canvas, size);
    _drawTopDownCrossPortal(canvas, size);
    _drawFlaskRack(canvas, size);
    _drawStopwatch(canvas);
    _drawStandingCylinder(canvas);
    final area = _inspectArea(inspectedItemKey, size);
    if (area != null) LabPaint.activeGlow(canvas, area, radius: 6);
    _drawAcidPour(canvas, size);
    _drawPrepPours(canvas, size);
    canvas.restore();
  }

  /// Where each inspected apparatus sits on the bench.
  Rect? _inspectArea(String? id, Size size) {
    final cx = size.width * 0.52;
    final cy = size.height * 0.55;
    switch (id) {
      case 'conical_flasks':
        return state.isFlaskOnCross
            ? Rect.fromLTRB(cx - 48, cy - 70, cx + 48, cy + 80)
            : Rect.fromPoints(_flaskBadge(0, size), _flaskBadge(math.max(0, state.trials.length - 1), size)).inflate(11);
      case 'cross_tile':
        return Rect.fromCenter(center: Offset(cx, cy + 30), width: 140, height: 140);
      case 'stopwatch':
        return Rect.fromCircle(center: const Offset(76, 182), radius: 16);
      case 'measuring_cylinders':
        return Rect.fromCenter(center: _cylinderAt, width: 20, height: 62);
      case 'thiosulfate_stock':
        return const Rect.fromLTWH(20, 14, 42, 81);
      case 'hydrochloric_acid':
        return const Rect.fromLTWH(72, 14, 42, 81);
    }
    return null;
  }

  bool get _pouring {
    final t = hands?.since('acid');
    if (t != null && t < _pourMs) return true;
    final p = hands?.since('prep');
    return p != null && p < _justPrepared.length * _prepGap;
  }

  /// How far the flask is on its way to the cross. When the same tap fills
  /// the flasks and puts the first on the cross, it is carried after the
  /// pours, so only one hand is on the bench at a time.
  double? get _flaskCarry {
    final t = hands?.since('flask');
    final p = hands?.since('prep');
    if (t == null || p == null || (t - p).abs() > 50) return t;
    return t - _justPrepared.length * _prepGap;
  }

  /// The flasks whose solution has just been measured in.
  List<int> get _justPrepared {
    final before = hands?.previous('prep');
    final now = state.trials.map((t) => t.isPrepared ? '1' : '0').join();
    if (before is! String || before.length != now.length) return const [];
    return [for (int i = 0; i < now.length; i++) if (now[i] == '1' && before[i] == '0') i];
  }

  /// The hand pours the measured thiosulfate from the cylinder into each
  /// flask as it is prepared.
  void _drawPrepPours(Canvas canvas, Size size) {
    final done = _justPrepared;
    for (int k = 0; k < done.length; k++) {
      LabHand.move(canvas, hands?.since('prep'),
          from: _cylinderAt, to: _flaskBadge(done[k], size) + const Offset(-22, -30), pose: HandPose.grip, scale: 0.6,
          duration: _prepGap, delay: k * _prepGap, holding: _tippedCylinder);
    }
  }

  /// The empty 10 mL measuring cylinder standing on the bench, away while
  /// the hand pours from it.
  void _drawStandingCylinder(Canvas canvas) {
    if (_pouring) return;
    final glass = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: _cylinderAt, width: 12, height: 54), const Radius.circular(2));
    canvas.drawRRect(body, Paint()..color = const Color(0x40BAE6FD));
    canvas.drawRRect(body, glass);
    canvas.drawRect(Rect.fromCenter(center: _cylinderAt + const Offset(0, 29), width: 20, height: 4), Paint()..color = const Color(0xFF64748B));
    for (final y in [-16.0, -8.0, 0.0, 8.0, 16.0]) {
      canvas.drawLine(_cylinderAt + Offset(-6, y), _cylinderAt + Offset(-2, y), glass..strokeWidth = 0.8);
    }
  }

  /// The stopwatch lying ready on the bench.
  void _drawStopwatch(Canvas canvas) {
    const c = Offset(76, 182);
    canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, -15), width: 6, height: 4), Paint()..color = const Color(0xFF475569));
    canvas.drawCircle(c, 12, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(c, 9.5, Paint()..color = Colors.white);
    canvas.drawLine(c, c + const Offset(0, -7), LabPaint.stroke(const Color(0xFFB91C1C), 1.2));
    canvas.drawCircle(c, 1.3, Paint()..color = const Color(0xFF334155));
  }

  /// The 5 mL of acid poured from a measuring cylinder into the flask; the
  /// hand picks the cylinder up from the bench and puts it back.
  void _drawAcidPour(Canvas canvas, Size size) {
    if (!state.isFlaskOnCross || state.trials.isEmpty || !state.trials[state.activeTrialIndex].isAcidAdded) return;
    final centerX = size.width * 0.52;
    final flaskTopY = size.height * 0.55 - 65;
    LabHand.move(canvas, hands?.since('acid'),
        from: _cylinderAt, to: Offset(centerX + 33, flaskTopY - 26), pose: HandPose.grip, scale: 0.6, duration: _pourMs,
        holding: _tippedCylinder);
  }

  /// A measuring cylinder held tipped so its mouth (+y end) points down,
  /// pouring.
  void _tippedCylinder(Canvas c) {
    // A 10 mL measuring cylinder tipped so its mouth (+y end) points down
    // into the flask neck; long enough to show either side of the fist.
    c.save();
    c.rotate(0.75);
    final glass = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final cylinder = RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -24, 12, 54), const Radius.circular(2));
    c.drawRRect(cylinder, Paint()..color = const Color(0x40BAE6FD));
    c.drawRect(const Rect.fromLTWH(-5, 16, 10, 13), Paint()..color = const Color(0xB3FDE68A));
    c.drawRRect(cylinder, glass);
    c.drawRect(const Rect.fromLTWH(-10, -28, 20, 4), Paint()..color = const Color(0xFF64748B));
    for (final y in [-14.0, -6.0, 2.0, 10.0]) {
      c.drawLine(Offset(-6, y), Offset(-2, y), glass..strokeWidth = 0.8);
    }
    c.restore();
    c.drawLine(const Offset(-20, 22), const Offset(-20, 40), Paint()
      ..color = const Color(0x99FDE68A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round);
  }

  void _drawLabBenchBackground(Canvas canvas, Size size) {
    final benchRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    canvas.drawRRect(RRect.fromRectAndRadius(benchRect, const Radius.circular(16)), bgPaint);

    // Benchtop surface
    final topRect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final surfacePaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(12)), surfacePaint);

    // Subtle laboratory grid / mat lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double x = 24; x < size.width - 24; x += 30) {
      canvas.drawLine(Offset(x, 12), Offset(x, size.height - 12), gridPaint);
    }
    for (double y = 24; y < size.height - 24; y += 30) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), gridPaint);
    }
  }

  void _drawReagentBottles(Canvas canvas, Size size) {
    // 1. Sodium Thiosulfate Stock Bottle (Left)
    final thioRect = Rect.fromLTWH(20, 30, 42, 65);
    final bottlePaint = Paint()
      ..color = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF3B82F6).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(thioRect, const Radius.circular(6)), bottlePaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(thioRect, const Radius.circular(6)), borderPaint);

    // Thiosulfate Label
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'Na₂S₂O₃\n0.2M',
      style: TextStyle(
        fontSize: 7.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3B82F6),
        height: 1.1,
      ),
    );
    textPainter.layout(maxWidth: 40);
    textPainter.paint(canvas, const Offset(23, 50));

    // Bottle Neck & Cap
    final neckRect = const Rect.fromLTWH(33, 20, 16, 10);
    canvas.drawRect(neckRect, borderPaint);
    final capPaint = Paint()..color = const Color(0xFF1D4ED8);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 14, 20, 8), const Radius.circular(2)), capPaint);

    // 2. Hydrochloric Acid Bottle (2.0 M HCl)
    final acidRect = Rect.fromLTWH(72, 30, 42, 65);
    final acidBottlePaint = Paint()
      ..color = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(acidRect, const Radius.circular(6)), acidBottlePaint);

    final acidBorderPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(acidRect, const Radius.circular(6)), acidBorderPaint);

    textPainter.text = const TextSpan(
      text: '2.0M\nHCl',
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFFEF4444),
        height: 1.1,
      ),
    );
    textPainter.layout(maxWidth: 40);
    textPainter.paint(canvas, const Offset(79, 50));

    // Acid Cap (Red Dropper Cap)
    final acidCapPaint = Paint()..color = const Color(0xFFB91C1C);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(83, 14, 20, 8), const Radius.circular(2)), acidCapPaint);
  }

  void _drawCrossTileAndFlask(Canvas canvas, Size size) {
    final centerX = size.width * 0.52;
    final centerY = size.height * 0.55;

    // 1. White Ceramic Tile on Bench
    final tileRect = Rect.fromCenter(center: Offset(centerX, centerY + 30), width: 140, height: 140);
    final tilePaint = Paint()
      ..color = isDark ? const Color(0xFFF8FAFC) : Colors.white
      ..style = PaintingStyle.fill;
    final tileShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(RRect.fromRectAndRadius(tileRect.shift(const Offset(0, 4)), const Radius.circular(10)), tileShadow);
    canvas.drawRRect(RRect.fromRectAndRadius(tileRect, const Radius.circular(10)), tilePaint);

    final tileBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(tileRect, const Radius.circular(10)), tileBorder);

    // 2. Bold Black Cross (X) printed on the tile
    final crossPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final crossCenter = Offset(centerX, centerY + 30);
    const crossRadius = 38.0;
    canvas.drawLine(
      crossCenter + const Offset(-crossRadius, -crossRadius),
      crossCenter + const Offset(crossRadius, crossRadius),
      crossPaint,
    );
    canvas.drawLine(
      crossCenter + const Offset(crossRadius, -crossRadius),
      crossCenter + const Offset(-crossRadius, crossRadius),
      crossPaint,
    );

    // 3. Conical Flask (250 mL Pyrex) on top of the tile, carried there by the hand
    final carried = _flaskCarry;
    if (state.isFlaskOnCross && (carried == null || carried >= 0)) {
      LabHand.carry(canvas, carried,
          offset: Offset(size.width * 0.42, 4), grip: Offset(centerX + 2, centerY - 42), scale: 0.7,
          draw: () => _drawFlask(canvas, centerX, centerY));
    }
  }

  void _drawFlask(Canvas canvas, double centerX, double centerY) {
    final flaskBaseY = centerY + 78;
    final flaskTopY = centerY - 65;
    final flaskWidth = 100.0;
    final neckWidth = 26.0;

    // Flask Path
    final flaskPath = Path();
    // Lip top
    flaskPath.moveTo(centerX - neckWidth / 2 - 2, flaskTopY);
    flaskPath.lineTo(centerX + neckWidth / 2 + 2, flaskTopY);
    // Neck right
    flaskPath.lineTo(centerX + neckWidth / 2, flaskTopY + 32);
    // Conical slope right
    flaskPath.lineTo(centerX + flaskWidth / 2, flaskBaseY - 8);
    // Base curve
    flaskPath.quadraticBezierTo(centerX + flaskWidth / 2, flaskBaseY, centerX + flaskWidth / 2 - 8, flaskBaseY);
    flaskPath.lineTo(centerX - flaskWidth / 2 + 8, flaskBaseY);
    flaskPath.quadraticBezierTo(centerX - flaskWidth / 2, flaskBaseY, centerX - flaskWidth / 2, flaskBaseY - 8);
    // Conical slope left
    flaskPath.lineTo(centerX - neckWidth / 2, flaskTopY + 32);
    flaskPath.lineTo(centerX - neckWidth / 2 - 2, flaskTopY);
    flaskPath.close();

    // Liquid in flask
    final liquidPath = Path();
    final liquidTopY = flaskBaseY - 48;
    liquidPath.moveTo(centerX - flaskWidth / 2 + 10, liquidTopY);
    liquidPath.lineTo(centerX + flaskWidth / 2 - 10, liquidTopY);
    liquidPath.lineTo(centerX + flaskWidth / 2 - 2, flaskBaseY - 8);
    liquidPath.quadraticBezierTo(centerX + flaskWidth / 2, flaskBaseY, centerX + flaskWidth / 2 - 8, flaskBaseY);
    liquidPath.lineTo(centerX - flaskWidth / 2 + 8, flaskBaseY);
    liquidPath.quadraticBezierTo(centerX - flaskWidth / 2, flaskBaseY, centerX - flaskWidth / 2 + 2, flaskBaseY - 8);
    liquidPath.close();

    // Liquid Opacity & Color: Clear water -> Colloidal sulfur (milky bright yellow)
    final opacity = state.turbidityOpacity.clamp(0.0, 1.0);
    final liquidColor = Color.lerp(
      const Color(0xFF38BDF8).withValues(alpha: 0.25), // Initial clear solution
      const Color(0xFFFDE047), // Colloidal sulfur yellow
      opacity,
    )!;

    final liquidPaint = Paint()
      ..color = liquidColor.withValues(alpha: 0.35 + (0.60 * opacity))
      ..style = PaintingStyle.fill;
    canvas.drawPath(liquidPath, liquidPaint);

    // Colloidal precipitate particles when reacting
    if (opacity > 0.05) {
      final particlePaint = Paint()
        ..color = const Color(0xFFEAB308).withValues(alpha: (0.8 * opacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      final rng = math.Random(42);
      for (int i = 0; i < (opacity * 35).toInt(); i++) {
        final px = centerX - 35 + rng.nextDouble() * 70;
        final py = liquidTopY + 5 + rng.nextDouble() * 38;
        final pr = 1.2 + rng.nextDouble() * 2.2;
        canvas.drawCircle(Offset(px, py), pr, particlePaint);
      }
    }

    // Flask Glass Outlines and Highlights
    final glassOutline = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(flaskPath, glassOutline);

    // Glass highlight reflection
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(centerX - flaskWidth / 2 + 8, flaskBaseY - 14),
      Offset(centerX - neckWidth / 2 + 2, flaskTopY + 36),
      highlightPaint,
    );

    // Volume graduation marks on flask
    final markPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 3; i++) {
      final my = flaskBaseY - 12 - (i * 12.0);
      canvas.drawLine(Offset(centerX + 18, my), Offset(centerX + 28, my), markPaint);
    }
  }

  void _drawTopDownCrossPortal(Canvas canvas, Size size) {
    // Top-down viewpoint circle in upper-right corner
    final portalCenter = Offset(size.width - 48, 52);
    const portalRadius = 34.0;

    // Outer ring
    final ringPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(portalCenter, portalRadius + 3, ringPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(portalCenter, portalRadius, innerPaint);

    // Cross beneath the portal
    final opacity = state.turbidityOpacity.clamp(0.0, 1.0);
    final crossAlpha = ((1.0 - opacity) * 255).clamp(0, 255).toInt();

    if (crossAlpha > 0) {
      final portalCrossPaint = Paint()
        ..color = Color.fromARGB(crossAlpha, 15, 23, 42)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      const pCrossR = 18.0;
      canvas.drawLine(
        portalCenter + const Offset(-pCrossR, -pCrossR),
        portalCenter + const Offset(pCrossR, pCrossR),
        portalCrossPaint,
      );
      canvas.drawLine(
        portalCenter + const Offset(pCrossR, -pCrossR),
        portalCenter + const Offset(-pCrossR, pCrossR),
        portalCrossPaint,
      );
    }

    // Liquid overlay on portal
    if (state.isFlaskOnCross && opacity > 0.0) {
      final liquidPortal = Paint()
        ..color = const Color(0xFFFDE047).withValues(alpha: (0.4 + 0.55 * opacity).clamp(0.0, 0.95))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(portalCenter, portalRadius, liquidPortal);
    }

    // Portal Border
    final portalBorder = Paint()
      ..color = opacity >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF184E78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(portalCenter, portalRadius, portalBorder);

    // Label: "TOP VIEW"
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: opacity >= 1.0 ? 'OBSCURED' : 'TOP VIEW',
      style: TextStyle(
        fontSize: 7.5,
        fontWeight: FontWeight.w800,
        color: opacity >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF184E78),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(portalCenter.dx - (textPainter.width / 2), portalCenter.dy + portalRadius + 5));
  }

  /// Where flask badge [i] sits, in a column below the top view.
  static Offset _flaskBadge(int i, Size size) {
    final gap = math.min(24.0, (size.height - 128) / 5);
    return Offset(size.width - 48, 118 + i * gap);
  }

  void _drawFlaskRack(Canvas canvas, Size size) {
    // Mini flask indicators in a column under the top view, clear of the tile
    for (int i = 0; i < state.trials.length; i++) {
      final trial = state.trials[i];
      final c = _flaskBadge(i, size);
      final fx = c.dx;
      final rackY = c.dy;
      final isSelected = i == state.activeTrialIndex;

      final badgePaint = Paint()
        ..color = isSelected
            ? const Color(0xFF184E78)
            : (trial.isCompleted
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(fx, rackY), 10, badgePaint);

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: 'F${trial.flaskNumber}',
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(fx - (textPainter.width / 2), rackY - (textPainter.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant RatesOfReactionBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.inspectedItemKey != inspectedItemKey;
  }
}
