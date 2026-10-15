import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PendulumBenchPainter extends CustomPainter {
  final double lengthCm; // 20.0 to 100.0 cm
  final double angleDeg; // Live deflection angle in degrees
  final bool isOscillating;
  final bool isDark;
  final String? inspectedItemKey;

  const PendulumBenchPainter({
    required this.lengthCm,
    required this.angleDeg,
    required this.isOscillating,
    required this.isDark,
    this.inspectedItemKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Lab Bench Background Surface & Grid
    _drawLabBench(canvas, size, w, h);

    // 2. Draw Retort Stand & Base
    _drawRetortStand(canvas, size, w, h);

    // 3. Draw Metre Rule alongside
    _drawMetreRule(canvas, size, w, h);

    // 4. Draw Clamp, Bosshead & Split Cork Suspension
    _drawSuspensionMechanism(canvas, size, w, h);

    // 5. Draw Protractor / Small-Angle Guide Arc
    _drawProtractorGuide(canvas, size, w, h);

    // 6. Draw Pendulum Thread & Brass Bob
    _drawPendulum(canvas, size, w, h);
  }

  void _drawLabBench(Canvas canvas, Size size, double w, double h) {
    final benchTopY = h * 0.88;

    // Bench tabletop fill
    final benchPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(0, benchTopY, w, h - benchTopY));

    canvas.drawRect(Rect.fromLTWH(0, benchTopY, w, h - benchTopY), benchPaint);

    // Bench edge highlight line
    final edgePaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, benchTopY), Offset(w, benchTopY), edgePaint);

    // Subtle perspective grid lines on bench
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double x = 20; x < w; x += 30) {
      canvas.drawLine(Offset(x, benchTopY), Offset(x - 15, h), gridPaint);
    }
  }

  void _drawRetortStand(Canvas canvas, Size size, double w, double h) {
    final standBaseX = w * 0.38;
    final benchTopY = h * 0.88;
    final rodX = standBaseX + 35;
    final topY = h * 0.08;

    final isStandInspected = inspectedItemKey == 'stand';

    // Cast-iron Stand Base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(standBaseX + 15, benchTopY - 7),
        width: 130,
        height: 14,
      ),
      const Radius.circular(3),
    );

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isStandInspected
            ? [const Color(0xFF06B6D4), const Color(0xFF0284C7)]
            : (isDark
                ? [const Color(0xFF475569), const Color(0xFF1E293B)]
                : [const Color(0xFF64748B), const Color(0xFF334155)]),
      ).createShader(baseRect.outerRect);

    canvas.drawRRect(baseRect, basePaint);

    // Stainless Steel Retort Rod
    final rodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? [const Color(0xFF94A3B8), const Color(0xFFE2E8F0), const Color(0xFF64748B)]
            : [const Color(0xFFCBD5E1), const Color(0xFFF8FAFC), const Color(0xFF94A3B8)],
      ).createShader(Rect.fromLTWH(rodX - 4, topY, 8, benchTopY - topY - 7));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rodX - 4, topY, 8, benchTopY - topY - 7),
        const Radius.circular(3),
      ),
      rodPaint,
    );
  }

  void _drawMetreRule(Canvas canvas, Size size, double w, double h) {
    final ruleX = w * 0.16;
    final pivotY = h * 0.15;
    final maxBobY = h * 0.82;
    final ruleHeight = maxBobY - pivotY + 20;

    final isRuleInspected = inspectedItemKey == 'ruler';

    // Metre Rule Body (Wood / Acrylic)
    final ruleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(ruleX, pivotY - 10, 26, ruleHeight),
      const Radius.circular(2),
    );

    final rulePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isRuleInspected
            ? [const Color(0xFFFDE047), const Color(0xFFEAB308)]
            : (isDark
                ? [const Color(0xFFD97706).withValues(alpha: 0.8), const Color(0xFFB45309).withValues(alpha: 0.9)]
                : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]),
      ).createShader(ruleRect.outerRect);

    canvas.drawRRect(ruleRect, rulePaint);

    // Rule border
    final borderPaint = Paint()
      ..color = (isDark ? const Color(0xFF92400E) : const Color(0xFFD97706)).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(ruleRect, borderPaint);

    // Graduation ticks (0 to 100 cm scale mapped to height)
    final tickPaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int cm = 0; cm <= 100; cm += 10) {
      final fraction = cm / 100.0;
      final tickY = pivotY + (maxBobY - pivotY) * fraction;

      // Major tick
      canvas.drawLine(Offset(ruleX + 16, tickY), Offset(ruleX + 26, tickY), tickPaint);

      // Minor tick at 5cm
      if (cm < 100) {
        final midY = pivotY + (maxBobY - pivotY) * (fraction + 0.05);
        canvas.drawLine(Offset(ruleX + 20, midY), Offset(ruleX + 26, midY), tickPaint);
      }

      // Numbers
      if (cm % 20 == 0) {
        textPainter.text = TextSpan(
          text: '$cm',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(ruleX + 2, tickY - 5));
      }
    }

    // Indicator measuring arrow pointing from suspension cork to bob center
    final currentBobFraction = lengthCm / 100.0;
    final currentBobY = pivotY + (maxBobY - pivotY) * currentBobFraction;

    final measureLinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(ruleX + 28, pivotY), Offset(w * 0.58, pivotY), measureLinePaint);
    canvas.drawLine(Offset(ruleX + 28, currentBobY), Offset(w * 0.58, currentBobY), measureLinePaint);

    // Dimension line with arrowheads
    canvas.drawLine(Offset(ruleX + 32, pivotY), Offset(ruleX + 32, currentBobY), measureLinePaint);

    // Badge label showing length in cm
    textPainter.text = TextSpan(
      text: 'L = ${lengthCm.toStringAsFixed(1)} cm',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        backgroundColor: Colors.transparent,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(ruleX + 36, (pivotY + currentBobY) / 2 - 6));
  }

  void _drawSuspensionMechanism(Canvas canvas, Size size, double w, double h) {
    final rodX = w * 0.38 + 35;
    final pivotX = w * 0.60;
    final pivotY = h * 0.15;

    // Bosshead clamp on rod
    final clampRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(rodX, pivotY), width: 18, height: 16),
      const Radius.circular(3),
    );
    final clampPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    canvas.drawRRect(clampRect, clampPaint);

    // Horizontal Support Arm extending to pivot
    final armPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF94A3B8), const Color(0xFF475569)]
            : [const Color(0xFFCBD5E1), const Color(0xFF64748B)],
      ).createShader(Rect.fromLTWH(rodX, pivotY - 3, pivotX - rodX + 6, 6));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rodX, pivotY - 3, pivotX - rodX + 6, 6),
        const Radius.circular(2),
      ),
      armPaint,
    );

    // Split Cork suspension jaws gripping the thread
    final corkPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pivotX, pivotY + 2), width: 12, height: 10),
        const Radius.circular(2),
      ),
      corkPaint,
    );

    // Center pivot point dot
    final pivotDotPaint = Paint()..color = isDark ? Colors.white : Colors.black87;
    canvas.drawCircle(Offset(pivotX, pivotY), 2.5, pivotDotPaint);
  }

  void _drawProtractorGuide(Canvas canvas, Size size, double w, double h) {
    final pivotX = w * 0.60;
    final pivotY = h * 0.15;
    const arcRadius = 45.0;

    final arcPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw reference arc (from -15° to +15° in radians)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(pivotX, pivotY), radius: arcRadius),
      math.pi / 2 - 0.25,
      0.50,
      false,
      arcPaint,
    );

    // Dotted vertical equilibrium line (0°)
    final eqPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    for (double dy = 0; dy < arcRadius + 15; dy += 6) {
      canvas.drawLine(Offset(pivotX, pivotY + dy), Offset(pivotX, pivotY + dy + 3), eqPaint);
    }
  }

  void _drawPendulum(Canvas canvas, Size size, double w, double h) {
    final pivotX = w * 0.60;
    final pivotY = h * 0.15;
    final maxBobY = h * 0.82;

    // Pixel length of the thread on screen
    final visualLength = (maxBobY - pivotY) * (lengthCm / 100.0);

    // Angular position in radians
    final rad = (angleDeg * math.pi) / 180.0;

    // Bob center coordinate
    final bobX = pivotX + visualLength * math.sin(rad);
    final bobY = pivotY + visualLength * math.cos(rad);

    final isThreadInspected = inspectedItemKey == 'thread';
    final isBobInspected = inspectedItemKey == 'bob';

    // 1. Inextensible Nylon Thread
    final threadPaint = Paint()
      ..color = isThreadInspected
          ? const Color(0xFF06B6D4)
          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(pivotX, pivotY), Offset(bobX, bobY), threadPaint);

    // 2. Ambient Shadow under the Bob on the bench
    final benchTopY = h * 0.88;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final shadowScale = 1.0 - (benchTopY - bobY) / h * 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bobX, benchTopY),
        width: 28 * shadowScale.clamp(0.4, 1.2),
        height: 8 * shadowScale.clamp(0.4, 1.2),
      ),
      shadowPaint,
    );

    // 3. Pendulum Bob (Solid Brass Sphere with Specular Highlight)
    const bobRadius = 15.0;

    // Suspension ring
    final ringPaint = Paint()
      ..color = const Color(0xFFCA8A04)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(bobX, bobY - bobRadius - 2), 3.5, ringPaint);

    // Bob body gradient
    final bobPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: isBobInspected
            ? [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFF0369A1)]
            : [
                const Color(0xFFFEF08A), // Light brass highlight
                const Color(0xFFEAB308), // Metallic brass yellow
                const Color(0xFFCA8A04), // Darker brass
                const Color(0xFF713F12), // Deep shadow rim
              ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(bobX, bobY), radius: bobRadius));

    canvas.drawCircle(Offset(bobX, bobY), bobRadius, bobPaint);

    // Crisp metallic rim stroke
    final bobRimPaint = Paint()
      ..color = const Color(0xFF854D0E).withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(bobX, bobY), bobRadius, bobRimPaint);

    // Specular shine dot
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(bobX - 4.5, bobY - 5), 2.8, shinePaint);
  }

  @override
  bool shouldRepaint(covariant PendulumBenchPainter oldDelegate) {
    return oldDelegate.lengthCm != lengthCm ||
        oldDelegate.angleDeg != angleDeg ||
        oldDelegate.isOscillating != isOscillating ||
        oldDelegate.isDark != isDark ||
        oldDelegate.inspectedItemKey != inspectedItemKey;
  }
}
