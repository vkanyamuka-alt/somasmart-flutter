import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Unified scientific apparatus thumbnail widget for SomaSmart Simulation Laboratory.
/// Adheres strictly to the Royal Scholar Blue (#0058BE) / Slate design language.
class PracticalThumbnailWidget extends StatelessWidget {
  final String thumbnailType;
  final double size;
  final bool isDark;

  const PracticalThumbnailWidget({
    super.key,
    required this.thumbnailType,
    this.size = 84,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final strokeColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;
    final secondaryStroke = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final fluidFill = isDark
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.primary.withValues(alpha: 0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CustomPaint(
          size: Size(size, size),
          painter: _ApparatusPainter(
            type: thumbnailType.toLowerCase(),
            strokeColor: strokeColor,
            secondaryStroke: secondaryStroke,
            fluidFill: fluidFill,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _ApparatusPainter extends CustomPainter {
  final String type;
  final Color strokeColor;
  final Color secondaryStroke;
  final Color fluidFill;
  final bool isDark;

  _ApparatusPainter({
    required this.type,
    required this.strokeColor,
    required this.secondaryStroke,
    required this.fluidFill,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mainPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinPaint = Paint()
      ..color = secondaryStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fluidFill
      ..style = PaintingStyle.fill;

    if (type.contains('titration')) {
      _paintTitration(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('circuit') || type.contains('ohm')) {
      _paintOhmsLaw(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('microscope')) {
      _paintMicroscope(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('pendulum')) {
      _paintPendulum(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('optics') || type.contains('prism')) {
      _paintOptics(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('osmosis')) {
      _paintOsmosis(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('reaction') || type.contains('rate')) {
      _paintReactionRates(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else if (type.contains('gas')) {
      _paintGasPrep(canvas, w, h, mainPaint, thinPaint, fillPaint);
    } else {
      _paintDefaultFlask(canvas, w, h, mainPaint, thinPaint, fillPaint);
    }
  }

  // 1. Acid-Base Titration: Stand + Burette with graduations + Conical Flask
  void _paintTitration(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Retort Stand Base & Rod
    canvas.drawLine(Offset(w * 0.20, h * 0.88), Offset(w * 0.45, h * 0.88), thin);
    canvas.drawLine(Offset(w * 0.28, h * 0.88), Offset(w * 0.28, h * 0.15), thin);
    // Clamp
    canvas.drawLine(Offset(w * 0.28, h * 0.35), Offset(w * 0.52, h * 0.35), thin);

    // Burette Tube
    final burette = Rect.fromCenter(center: Offset(w * 0.52, h * 0.38), width: w * 0.10, height: h * 0.46);
    canvas.drawRRect(RRect.fromRectAndRadius(burette, const Radius.circular(2)), main);
    // Burette graduations
    for (int i = 1; i <= 4; i++) {
      final y = h * 0.22 + (i * h * 0.06);
      canvas.drawLine(Offset(w * 0.48, y), Offset(w * 0.54, y), thin);
    }
    // Stopcock
    canvas.drawCircle(Offset(w * 0.52, h * 0.63), 2.5, main);
    canvas.drawLine(Offset(w * 0.52, h * 0.63), Offset(w * 0.52, h * 0.70), main);

    // Conical Flask below
    final flaskPath = Path()
      ..moveTo(w * 0.45, h * 0.72)
      ..lineTo(w * 0.59, h * 0.72)
      ..lineTo(w * 0.56, h * 0.76)
      ..lineTo(w * 0.72, h * 0.88)
      ..lineTo(w * 0.32, h * 0.88)
      ..lineTo(w * 0.48, h * 0.76)
      ..close();

    final liquidPath = Path()
      ..moveTo(w * 0.39, h * 0.83)
      ..lineTo(w * 0.65, h * 0.83)
      ..lineTo(w * 0.72, h * 0.88)
      ..lineTo(w * 0.32, h * 0.88)
      ..close();

    canvas.drawPath(liquidPath, fill);
    canvas.drawPath(flaskPath, main);
  }

  // 2. Ohm's Law: Circuit loop + DC cell + Resistor + Ammeter + Voltmeter
  void _paintOhmsLaw(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Outer Circuit Rectangle
    final r = Rect.fromLTRB(w * 0.16, h * 0.20, w * 0.84, h * 0.80);
    // Draw top wire with DC battery
    canvas.drawLine(Offset(r.left, r.top), Offset(w * 0.42, r.top), main);
    canvas.drawLine(Offset(w * 0.58, r.top), Offset(r.right, r.top), main);
    // Battery plates
    canvas.drawLine(Offset(w * 0.44, h * 0.13), Offset(w * 0.44, h * 0.27), main); // Long positive
    canvas.drawLine(Offset(w * 0.50, h * 0.16), Offset(w * 0.50, h * 0.24), thin); // Short negative
    canvas.drawLine(Offset(w * 0.56, h * 0.13), Offset(w * 0.56, h * 0.27), main);

    // Right Wire with Ammeter (A)
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, h * 0.40), main);
    canvas.drawCircle(Offset(r.right, h * 0.50), w * 0.10, fill);
    canvas.drawCircle(Offset(r.right, h * 0.50), w * 0.10, main);
    _drawText(canvas, 'A', Offset(r.right - 4.5, h * 0.50 - 6), strokeColor, 10);
    canvas.drawLine(Offset(r.right, h * 0.60), Offset(r.right, r.bottom), main);

    // Bottom wire with Resistor box
    canvas.drawLine(Offset(r.right, r.bottom), Offset(w * 0.66, r.bottom), main);
    final resistorRect = Rect.fromCenter(center: Offset(w * 0.50, r.bottom), width: w * 0.28, height: h * 0.12);
    canvas.drawRect(resistorRect, fill);
    canvas.drawRect(resistorRect, main);
    canvas.drawLine(Offset(w * 0.34, r.bottom), Offset(r.left, r.bottom), main);

    // Left wire
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left, r.top), main);
  }

  // 3. Microscope: Eyepiece + Body Tube + Objective + Stage + Base
  void _paintMicroscope(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Base
    final baseRect = Rect.fromLTRB(w * 0.22, h * 0.84, w * 0.78, h * 0.90);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(3)), main);

    // Curved Arm
    final armPath = Path()
      ..moveTo(w * 0.65, h * 0.84)
      ..cubicTo(w * 0.78, h * 0.65, w * 0.78, h * 0.40, w * 0.55, h * 0.30);
    canvas.drawPath(armPath, main);

    // Stage (with slide)
    canvas.drawLine(Offset(w * 0.25, h * 0.62), Offset(w * 0.68, h * 0.62), main);
    final slideRect = Rect.fromCenter(center: Offset(w * 0.46, h * 0.60), width: w * 0.22, height: h * 0.03);
    canvas.drawRect(slideRect, fill);
    canvas.drawRect(slideRect, thin);

    // Objective Lens
    final objRect = Rect.fromCenter(center: Offset(w * 0.46, h * 0.52), width: w * 0.10, height: h * 0.12);
    canvas.drawRect(objRect, fill);
    canvas.drawRect(objRect, main);

    // Revolving Nosepiece
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.46, h * 0.44), width: w * 0.18, height: h * 0.08), 0, math.pi, false, main);

    // Eyepiece Tube
    final tubePath = Path()
      ..moveTo(w * 0.41, h * 0.44)
      ..lineTo(w * 0.51, h * 0.44)
      ..lineTo(w * 0.43, h * 0.18)
      ..lineTo(w * 0.33, h * 0.18)
      ..close();
    canvas.drawPath(tubePath, main);

    // Top Eyepiece
    final eyeRect = Rect.fromCenter(center: Offset(w * 0.38, h * 0.15), width: w * 0.16, height: h * 0.05);
    canvas.drawRRect(RRect.fromRectAndRadius(eyeRect, const Radius.circular(2)), main);
  }

  // 4. Simple Pendulum: Stand + Thread + Bob + Dashed Sweep Arc
  void _paintPendulum(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Top Support Beam
    canvas.drawLine(Offset(w * 0.18, h * 0.16), Offset(w * 0.82, h * 0.16), main);
    // Vertical Stand
    canvas.drawLine(Offset(w * 0.22, h * 0.16), Offset(w * 0.22, h * 0.88), thin);
    canvas.drawLine(Offset(w * 0.14, h * 0.88), Offset(w * 0.30, h * 0.88), thin);

    // Pivot Point
    final pivot = Offset(w * 0.52, h * 0.16);
    canvas.drawCircle(pivot, 3, main);

    // Deflected Pendulum Line
    final bobPos = Offset(w * 0.68, h * 0.68);
    canvas.drawLine(pivot, bobPos, main);

    // Pendulum Bob
    canvas.drawCircle(bobPos, w * 0.11, fill);
    canvas.drawCircle(bobPos, w * 0.11, main);

    // Rest Center Line (Dashed)
    canvas.drawLine(pivot, Offset(w * 0.52, h * 0.72), thin);

    // Motion Arc
    final arcRect = Rect.fromCenter(center: pivot, width: (bobPos.dy - pivot.dy) * 2, height: (bobPos.dy - pivot.dy) * 2);
    canvas.drawArc(arcRect, math.pi * 0.40, math.pi * 0.20, false, thin);
  }

  // 5. Refraction & Prism: Triangular Prism + Incident & Refracted Rays
  void _paintOptics(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Glass Prism Triangle
    final prismPath = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.82, h * 0.78)
      ..lineTo(w * 0.18, h * 0.78)
      ..close();
    canvas.drawPath(prismPath, fill);
    canvas.drawPath(prismPath, main);

    // Incident Ray (Entering left face)
    canvas.drawLine(Offset(w * 0.06, h * 0.44), Offset(w * 0.32, h * 0.53), main);
    // Arrow on incident ray
    _drawRayArrow(canvas, Offset(w * 0.06, h * 0.44), Offset(w * 0.32, h * 0.53), strokeColor);

    // Refracted Ray inside prism
    canvas.drawLine(Offset(w * 0.32, h * 0.53), Offset(w * 0.64, h * 0.58), thin);

    // Emerging Dispersed Rays (Exiting right face)
    canvas.drawLine(Offset(w * 0.64, h * 0.58), Offset(w * 0.94, h * 0.48), main);
    canvas.drawLine(Offset(w * 0.64, h * 0.58), Offset(w * 0.94, h * 0.68), thin);
  }

  // 6. Osmosis: Test Tube Rack + Boiling Tubes + Sucrose Solution + Potato Cylinder
  void _paintOsmosis(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Tube Rack base & top bar
    canvas.drawLine(Offset(w * 0.12, h * 0.86), Offset(w * 0.88, h * 0.86), thin);
    canvas.drawLine(Offset(w * 0.12, h * 0.40), Offset(w * 0.88, h * 0.40), thin);

    // Tube 1
    _paintBoilingTube(canvas, w * 0.32, h, 0.24, 0.82, w * 0.14, main, thin, fill, potatoHeight: 0.12);
    // Tube 2 (Central focus)
    _paintBoilingTube(canvas, w * 0.52, h, 0.20, 0.82, w * 0.16, main, thin, fill, potatoHeight: 0.16);
    // Tube 3
    _paintBoilingTube(canvas, w * 0.72, h, 0.24, 0.82, w * 0.14, main, thin, fill, potatoHeight: 0.10);
  }

  void _paintBoilingTube(
    Canvas canvas,
    double cx,
    double h,
    double topFrac,
    double bottomFrac,
    double width,
    Paint main,
    Paint thin,
    Paint fill, {
    double potatoHeight = 0.12,
  }) {
    final tubeRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(cx - width / 2, h * topFrac, cx + width / 2, h * bottomFrac),
      bottomLeft: Radius.circular(width / 2),
      bottomRight: Radius.circular(width / 2),
    );

    // Fluid level
    final fluidRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(cx - width / 2, h * (topFrac + 0.16), cx + width / 2, h * bottomFrac),
      bottomLeft: Radius.circular(width / 2),
      bottomRight: Radius.circular(width / 2),
    );
    canvas.drawRRect(fluidRect, fill);

    // Potato cylinder inside
    final potato = Rect.fromCenter(
      center: Offset(cx, h * (bottomFrac - potatoHeight / 2 - 0.02)),
      width: width * 0.55,
      height: h * potatoHeight,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(potato, const Radius.circular(2)), main);

    canvas.drawRRect(tubeRect, main);
  }

  // 7. Reaction Rates: Conical Flask over Disappearing Cross "X"
  void _paintReactionRates(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Bold Disappearing Cross "X" below flask base
    final xPaint = Paint()
      ..color = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(w * 0.32, h * 0.72), Offset(w * 0.68, h * 0.90), xPaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.72), Offset(w * 0.32, h * 0.90), xPaint);

    // Conical Flask Outline
    final flaskPath = Path()
      ..moveTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.58, h * 0.18)
      ..lineTo(w * 0.54, h * 0.35)
      ..lineTo(w * 0.78, h * 0.78)
      ..lineTo(w * 0.22, h * 0.78)
      ..lineTo(w * 0.46, h * 0.35)
      ..close();

    final fluidPath = Path()
      ..moveTo(w * 0.34, h * 0.58)
      ..lineTo(w * 0.66, h * 0.58)
      ..lineTo(w * 0.78, h * 0.78)
      ..lineTo(w * 0.22, h * 0.78)
      ..close();

    canvas.drawPath(fluidPath, fill);
    canvas.drawPath(flaskPath, main);

    // Precipitate Turbidity Dots
    for (int i = 0; i < 6; i++) {
      final dx = w * (0.36 + (i % 3) * 0.14);
      final dy = h * (0.64 + (i ~/ 3) * 0.08);
      canvas.drawCircle(Offset(dx, dy), 1.8, thin);
    }
  }

  // 8. Gas Preparation: Reaction Flask + Thistle Funnel + Delivery Tube + Gas Jar
  void _paintGasPrep(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    // Reaction Flask (Left)
    final flask = Path()
      ..moveTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.36, h * 0.42)
      ..lineTo(w * 0.34, h * 0.52)
      ..lineTo(w * 0.48, h * 0.82)
      ..lineTo(w * 0.12, h * 0.82)
      ..lineTo(w * 0.26, h * 0.52)
      ..close();
    canvas.drawPath(flask, fill);
    canvas.drawPath(flask, main);

    // Thistle Funnel going into flask
    canvas.drawLine(Offset(w * 0.27, h * 0.22), Offset(w * 0.27, h * 0.74), thin);
    final funnelTop = Path()
      ..moveTo(w * 0.22, h * 0.18)
      ..lineTo(w * 0.32, h * 0.18)
      ..lineTo(w * 0.27, h * 0.24)
      ..close();
    canvas.drawPath(funnelTop, main);

    // Delivery Tube from flask to Gas Jar
    final delivery = Path()
      ..moveTo(w * 0.33, h * 0.44)
      ..lineTo(w * 0.33, h * 0.32)
      ..lineTo(w * 0.72, h * 0.32)
      ..lineTo(w * 0.72, h * 0.50);
    canvas.drawPath(delivery, main);

    // Inverted Gas Jar (Right)
    final jar = Path()
      ..moveTo(w * 0.62, h * 0.86)
      ..lineTo(w * 0.62, h * 0.42)
      ..lineTo(w * 0.82, h * 0.42)
      ..lineTo(w * 0.82, h * 0.86);
    canvas.drawPath(jar, main);
  }

  // Fallback: Clean Erlenmeyer Flask
  void _paintDefaultFlask(Canvas canvas, double w, double h, Paint main, Paint thin, Paint fill) {
    final flaskPath = Path()
      ..moveTo(w * 0.40, h * 0.20)
      ..lineTo(w * 0.60, h * 0.20)
      ..lineTo(w * 0.56, h * 0.38)
      ..lineTo(w * 0.80, h * 0.82)
      ..lineTo(w * 0.20, h * 0.82)
      ..lineTo(w * 0.44, h * 0.38)
      ..close();

    final fluidPath = Path()
      ..moveTo(w * 0.32, h * 0.60)
      ..lineTo(w * 0.68, h * 0.60)
      ..lineTo(w * 0.80, h * 0.82)
      ..lineTo(w * 0.20, h * 0.82)
      ..close();

    canvas.drawPath(fluidPath, fill);
    canvas.drawPath(flaskPath, main);
  }

  void _drawRayArrow(Canvas canvas, Offset p1, Offset p2, Color color) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final arrowLength = 5.0;
    final pA = Offset(mid.dx - arrowLength * math.cos(angle - math.pi / 6), mid.dy - arrowLength * math.sin(angle - math.pi / 6));
    final pB = Offset(mid.dx - arrowLength * math.cos(angle + math.pi / 6), mid.dy - arrowLength * math.sin(angle + math.pi / 6));

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(mid, pA, arrowPaint);
    canvas.drawLine(mid, pB, arrowPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ApparatusPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.isDark != isDark;
  }
}
