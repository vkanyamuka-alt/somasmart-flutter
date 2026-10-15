import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/optics_state.dart';

/// High-fidelity CustomPainter rendering the Virtual Optics Laboratory Bench,
/// including the drawing board, equilateral glass prism, laser rays, optical pins,
/// normal lines, and angular protractor overlay.
class OpticsBenchPainter extends CustomPainter {
  final OpticsState state;
  final bool isDark;

  const OpticsBenchPainter({
    required this.state,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Laboratory Bench & Drawing Board
    _drawDrawingBoard(canvas, size);

    // 2. Compute Equilateral Prism Geometry
    final prismSide = math.min(w * 0.48, h * 0.62);
    final prismHeight = prismSide * math.sqrt(3) / 2;
    final prismCenterY = h * 0.52;
    final prismCenterX = w * 0.50;

    final vertexA = Offset(prismCenterX, prismCenterY - prismHeight * 0.55); // Top vertex (A = 60°)
    final vertexB = Offset(prismCenterX - prismSide / 2, prismCenterY + prismHeight * 0.45); // Bottom-left (B)
    final vertexC = Offset(prismCenterX + prismSide / 2, prismCenterY + prismHeight * 0.45); // Bottom-right (C)

    // Face AB properties: vector from B to A
    final abVector = vertexA - vertexB;
    final abAngle = math.atan2(abVector.dy, abVector.dx); // angle of face AB (approx -60°)
    // Normal to AB pointing outwards (leftwards/upwards): abAngle - pi/2
    final normal1Angle = abAngle - math.pi / 2;

    // Point of incidence I1 on face AB (at 45% of edge from B to A)
    final incPoint = vertexB + abVector * 0.46;

    // 3. Incident Ray Geometry
    final iRad = state.incidentAngleDeg * math.pi / 180.0;
    // The incident ray approaches I1. Its direction vector pointing INTO I1:
    // angle = normal1Angle + pi + iRad (or normal1Angle + pi - iRad depending on orientation)
    // Face AB normal points out-left. Ray comes from top-left.
    final incRayAngle = normal1Angle + math.pi - iRad;
    final raySourceLength = math.min(w * 0.38, 170.0);
    final sourcePoint = Offset(
      incPoint.dx - raySourceLength * math.cos(incRayAngle),
      incPoint.dy - raySourceLength * math.sin(incRayAngle),
    );

    // 4. Refracted Ray inside Prism
    final r1Rad = state.refractedAngleDeg * math.pi / 180.0;
    // Inside prism, ray is bent towards normal: angle = normal1Angle - r1Rad
    final refrRayAngle = normal1Angle - r1Rad;

    // Face AC vector from A to C
    final acVector = vertexC - vertexA;
    final acAngle = math.atan2(acVector.dy, acVector.dx);
    final normal2Angle = acAngle + math.pi / 2; // Normal pointing out-right

    // Intersect refracted ray from I1 along refrRayAngle with line segment AC
    final emPoint = _intersectRayWithSegment(
      incPoint,
      Offset(incPoint.dx + 500 * math.cos(refrRayAngle), incPoint.dy + 500 * math.sin(refrRayAngle)),
      vertexA,
      vertexC,
    ) ?? Offset(prismCenterX + prismSide * 0.25, incPoint.dy + 15);

    // 5. Emergent Ray from I2 (face AC)
    final eRad = state.emergentAngleDeg * math.pi / 180.0;
    final emRayAngle = normal2Angle - eRad;
    final emRayLength = math.min(w * 0.38, 170.0);
    final emEndPoint = Offset(
      emPoint.dx + emRayLength * math.cos(emRayAngle),
      emPoint.dy + emRayLength * math.sin(emRayAngle),
    );

    // 6. Render Optical Protractor (if enabled)
    if (state.showProtractor) {
      _drawProtractor(canvas, incPoint, normal1Angle);
    }

    // 7. Render Normal Lines
    if (state.showNormalLines) {
      _drawNormalLine(canvas, incPoint, normal1Angle, 'N₁');
      _drawNormalLine(canvas, emPoint, normal2Angle, 'N₂');
      _drawAngleArcs(canvas, incPoint, normal1Angle, iRad, r1Rad);
    }

    // 8. Render Glass Prism
    _drawPrism(canvas, vertexA, vertexB, vertexC);

    // 9. Render Ray Extensions (for deviation angle D)
    if (state.showRayExtension) {
      _drawRayExtensions(canvas, incPoint, incRayAngle, emPoint, emRayAngle);
    }

    // 10. Render Light Rays (Incident, Refracted, Emergent)
    if (state.laserActive) {
      _drawLaserRay(canvas, sourcePoint, incPoint, isIncident: true);
      _drawLaserRay(canvas, incPoint, emPoint, isRefracted: true);
      _drawLaserRay(canvas, emPoint, emEndPoint, isEmergent: true);
    }

    // 11. Render Optical Pins (P1, P2 on incident ray; P3, P4 on emergent ray)
    if (state.showOpticalPins) {
      final pinP1 = sourcePoint + (incPoint - sourcePoint) * 0.30;
      final pinP2 = sourcePoint + (incPoint - sourcePoint) * 0.75;
      final pinP3 = emPoint + (emEndPoint - emPoint) * 0.28;
      final pinP4 = emPoint + (emEndPoint - emPoint) * 0.75;

      _drawOpticalPin(canvas, pinP1, 'P₁', const Color(0xFFEF4444));
      _drawOpticalPin(canvas, pinP2, 'P₂', const Color(0xFFEF4444));
      _drawOpticalPin(canvas, pinP3, 'P₃', const Color(0xFF3B82F6));
      _drawOpticalPin(canvas, pinP4, 'P₄', const Color(0xFF3B82F6));
    }

    // 12. Render Laser Box Emitter Source
    _drawLaserSourceBox(canvas, sourcePoint, incRayAngle);
  }

  // ---------------------------------------------------------------------------
  // Drawing Board & Paper Background
  // ---------------------------------------------------------------------------
  void _drawDrawingBoard(Canvas canvas, Size size) {
    // Softwood drawing board boundary
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(16),
    );

    final boardPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(boardRect, boardPaint);

    // Board wood border
    final boardBorder = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(boardRect, boardBorder);

    // White Drawing Sheet
    final sheetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
      const Radius.circular(10),
    );

    final sheetPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(sheetRect, sheetPaint);

    // Subtle paper grid pattern
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFE2E8F0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double x = 30; x < size.width - 30; x += 30) {
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), gridPaint);
    }
    for (double y = 30; y < size.height - 30; y += 30) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
    }

    // 4 Corner Sheet Pins
    _drawBoardThumbPin(canvas, const Offset(30, 30));
    _drawBoardThumbPin(canvas, Offset(size.width - 30, 30));
    _drawBoardThumbPin(canvas, Offset(30, size.height - 30));
    _drawBoardThumbPin(canvas, Offset(size.width - 30, size.height - 30));
  }

  void _drawBoardThumbPin(Canvas canvas, Offset pos) {
    final pinHead = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawCircle(pos, 4.5, pinHead);
    final pinShine = Paint()..color = Colors.white;
    canvas.drawCircle(pos + const Offset(-1, -1), 1.5, pinShine);
  }

  // ---------------------------------------------------------------------------
  // Equilateral Glass Prism Rendering
  // ---------------------------------------------------------------------------
  void _drawPrism(Canvas canvas, Offset pA, Offset pB, Offset pC) {
    final path = Path()
      ..moveTo(pA.dx, pA.dy)
      ..lineTo(pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..close();

    // Glass body fill with refractive refraction gradient
    final prismFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF38BDF8).withValues(alpha: 0.22),
                const Color(0xFF818CF8).withValues(alpha: 0.12),
                const Color(0xFF0284C7).withValues(alpha: 0.28),
              ]
            : [
                const Color(0xFFE0F2FE).withValues(alpha: 0.65),
                const Color(0xFFBAE6FD).withValues(alpha: 0.45),
                const Color(0xFFE0E7FF).withValues(alpha: 0.55),
              ],
      ).createShader(path.getBounds())
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, prismFill);

    // Polished Glass Edges
    final prismBorder = Paint()
      ..color = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.8) : const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, prismBorder);

    // Vertex labels A, B, C
    _drawText(canvas, 'A (60°)', Offset(pA.dx, pA.dy - 18), isAccent: true);
    _drawText(canvas, 'B', Offset(pB.dx - 14, pB.dy + 4));
    _drawText(canvas, 'C', Offset(pC.dx + 14, pC.dy + 4));
  }

  // ---------------------------------------------------------------------------
  // Laser Light Ray Rendering
  // ---------------------------------------------------------------------------
  void _drawLaserRay(
    Canvas canvas,
    Offset start,
    Offset end, {
    bool isIncident = false,
    bool isRefracted = false,
    bool isEmergent = false,
  }) {
    final rayColor = isRefracted
        ? const Color(0xFFF59E0B) // Amber inside glass
        : (isEmergent ? const Color(0xFF10B981) : const Color(0xFF06B6D4)); // Cyan/Emerald

    // 1. Soft optical glow
    final glowPaint = Paint()
      ..color = rayColor.withValues(alpha: isDark ? 0.35 : 0.25)
      ..strokeWidth = isRefracted ? 6.0 : 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, glowPaint);

    // 2. Sharp Core Beam
    final corePaint = Paint()
      ..color = isDark ? Colors.white : rayColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, corePaint);

    // 3. Direction Arrowhead
    final mid = start + (end - start) * 0.55;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    _drawArrowhead(canvas, mid, angle, rayColor);
  }

  void _drawArrowhead(Canvas canvas, Offset pos, double angle, Color color) {
    const arrowLen = 9.0;
    final p1 = Offset(pos.dx - arrowLen * math.cos(angle - 0.5), pos.dy - arrowLen * math.sin(angle - 0.5));
    final p2 = Offset(pos.dx - arrowLen * math.cos(angle + 0.5), pos.dy - arrowLen * math.sin(angle + 0.5));

    final arrowPath = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);
  }

  // ---------------------------------------------------------------------------
  // Optical Target Pins Rendering
  // ---------------------------------------------------------------------------
  void _drawOpticalPin(Canvas canvas, Offset pos, String label, Color headColor) {
    // Pin Shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawOval(Rect.fromCenter(center: pos + const Offset(2, 3), width: 7, height: 4), shadowPaint);

    // Steel Needle point
    final needlePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(pos, pos + const Offset(0, -6), needlePaint);

    // Spherical Plastic Head
    final headPaint = Paint()..color = headColor;
    canvas.drawCircle(pos + const Offset(0, -7), 4.5, headPaint);

    // Highlight
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos + const Offset(-1, -8.5), 1.3, shinePaint);

    // Pin Label (e.g. P1)
    _drawText(
      canvas,
      label,
      pos + const Offset(0, 10),
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textColor: headColor,
    );
  }

  // ---------------------------------------------------------------------------
  // Normal Lines & Angle Arcs
  // ---------------------------------------------------------------------------
  void _drawNormalLine(Canvas canvas, Offset pos, double normalAngle, String label) {
    const normalLen = 65.0;
    final p1 = Offset(pos.dx + normalLen * math.cos(normalAngle), pos.dy + normalLen * math.sin(normalAngle));
    final p2 = Offset(pos.dx - normalLen * math.cos(normalAngle), pos.dy - normalLen * math.sin(normalAngle));

    final normalPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8).withValues(alpha: 0.75) : const Color(0xFF64748B)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    _drawDashedLine(canvas, p1, p2, normalPaint, 5, 4);

    _drawText(canvas, label, p1 + Offset(math.cos(normalAngle) * 10, math.sin(normalAngle) * 10), fontSize: 10);
  }

  void _drawAngleArcs(Canvas canvas, Offset incPoint, double normalAngle, double iRad, double r1Rad) {
    // Incident angle arc (theta_i)
    final arcPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const arcRadius = 32.0;
    final arcRect = Rect.fromCircle(center: incPoint, radius: arcRadius);
    // Arc starts from normalAngle towards ray angle
    canvas.drawArc(arcRect, normalAngle, -iRad, false, arcPaint);

    // Label: i = 45.0°
    final labelAngle = normalAngle - iRad / 2;
    final labelOffset = incPoint + Offset(math.cos(labelAngle) * 44, math.sin(labelAngle) * 44);
    _drawText(
      canvas,
      'i = ${state.incidentAngleDeg.toStringAsFixed(0)}°',
      labelOffset,
      fontSize: 10,
      textColor: const Color(0xFF06B6D4),
    );

    // Refracted angle arc (theta_r)
    final rArcPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const rArcRadius = 24.0;
    final rArcRect = Rect.fromCircle(center: incPoint, radius: rArcRadius);
    canvas.drawArc(rArcRect, normalAngle - math.pi, r1Rad, false, rArcPaint);

    final rLabelAngle = normalAngle - math.pi + r1Rad / 2;
    final rLabelOffset = incPoint + Offset(math.cos(rLabelAngle) * 36, math.sin(rLabelAngle) * 36);
    _drawText(
      canvas,
      'r = ${state.refractedAngleDeg.toStringAsFixed(0)}°',
      rLabelOffset,
      fontSize: 9.5,
      textColor: const Color(0xFFF59E0B),
    );
  }

  // ---------------------------------------------------------------------------
  // Protractor Overlay
  // ---------------------------------------------------------------------------
  void _drawProtractor(Canvas canvas, Offset center, double normalAngle) {
    const pRadius = 75.0;

    final basePaint = Paint()
      ..color = (isDark ? const Color(0xFF0284C7) : const Color(0xFF38BDF8)).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pRadius, basePaint);

    final rimPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, pRadius, rimPaint);

    // Degree ticks
    final tickPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF64748B).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    for (int deg = 0; deg <= 90; deg += 10) {
      final rad = normalAngle - deg * math.pi / 180.0;
      final inner = center + Offset(math.cos(rad) * (pRadius - (deg % 30 == 0 ? 8 : 4)), math.sin(rad) * (pRadius - (deg % 30 == 0 ? 8 : 4)));
      final outer = center + Offset(math.cos(rad) * pRadius, math.sin(rad) * pRadius);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // Ray Extensions & Deviation Angle D
  // ---------------------------------------------------------------------------
  void _drawRayExtensions(Canvas canvas, Offset incPoint, double incRayAngle, Offset emPoint, double emRayAngle) {
    final extPaint = Paint()
      ..color = isDark ? const Color(0xFFE2E8F0).withValues(alpha: 0.4) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Forward straight line from incidence point I1
    final incForwardEnd = incPoint + Offset(math.cos(incRayAngle - math.pi) * 140, math.sin(incRayAngle - math.pi) * 140);
    _drawDashedLine(canvas, incPoint, incForwardEnd, extPaint, 4, 4);

    // Backward line from emergent point I2
    final emBackEnd = emPoint - Offset(math.cos(emRayAngle) * 130, math.sin(emRayAngle) * 130);
    _drawDashedLine(canvas, emPoint, emBackEnd, extPaint, 4, 4);

    // Deviation angle badge near intersection
    final dAngle = state.deviationAngleDeg;
    final dPos = emPoint + Offset(math.cos(emRayAngle) * 45, math.sin(emRayAngle) * 45 - 20);
    _drawText(
      canvas,
      'D = ${dAngle.toStringAsFixed(1)}°',
      dPos,
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      textColor: const Color(0xFFEC4899),
    );
  }

  // ---------------------------------------------------------------------------
  // Laser Box Source Emitter
  // ---------------------------------------------------------------------------
  void _drawLaserSourceBox(Canvas canvas, Offset pos, double rayAngle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rayAngle - math.pi);

    final boxRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-14, -10, 28, 20),
      const Radius.circular(4),
    );

    final boxFill = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(boxRect, boxFill);

    final boxBorder = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(boxRect, boxBorder);

    // Laser Aperture Slit
    final aperture = Paint()..color = const Color(0xFF06B6D4);
    canvas.drawCircle(const Offset(14, 0), 3.0, aperture);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Utility Methods
  // ---------------------------------------------------------------------------
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dashWidth, double dashSpace) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);
    double currentDist = 0.0;

    while (currentDist < dist) {
      final segEnd = math.min(currentDist + dashWidth, dist);
      canvas.drawLine(
        Offset(p1.dx + currentDist * math.cos(angle), p1.dy + currentDist * math.sin(angle)),
        Offset(p1.dx + segEnd * math.cos(angle), p1.dy + segEnd * math.sin(angle)),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  Offset? _intersectRayWithSegment(Offset r1, Offset r2, Offset s1, Offset s2) {
    final dx12 = r2.dx - r1.dx;
    final dy12 = r2.dy - r1.dy;
    final dx34 = s2.dx - s1.dx;
    final dy34 = s2.dy - s1.dy;

    final denom = dx12 * dy34 - dy12 * dx34;
    if (denom.abs() < 1e-6) return null;

    final t = ((s1.dx - r1.dx) * dy34 - (s1.dy - r1.dy) * dx34) / denom;
    final u = -((r1.dx - s1.dx) * dy12 - (r1.dy - s1.dy) * dx12) / denom;

    if (t >= 0 && u >= 0 && u <= 1.0) {
      return Offset(r1.dx + t * dx12, r1.dy + t * dy12);
    }
    return null;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    Color? textColor,
    bool isAccent = false,
  }) {
    final effectiveColor = textColor ?? (isAccent ? const Color(0xFF0284C7) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)));

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: effectiveColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant OpticsBenchPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
