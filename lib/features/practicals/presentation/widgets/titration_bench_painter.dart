import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/titration_state.dart';

class TitrationBenchPainter extends CustomPainter {
  final TitrationState state;
  final bool isDark;
  final double animationValue;

  TitrationBenchPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate space mapping (700 x 380 standard virtual bench)
    final scaleX = size.width / 700.0;
    final scaleY = size.height / 380.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    _drawBenchSurface(canvas);
    _drawRetortStand(canvas);
    _drawWhiteTile(canvas);
    _drawReagentBottles(canvas);
    _drawBurette(canvas);
    _drawPipette(canvas);
    _drawIndicatorDropper(canvas);
    _drawConicalFlask(canvas);

    canvas.restore();
  }

  void _drawBenchSurface(Canvas canvas) {
    final benchPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 320, 660, 45),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, benchPaint);
    canvas.drawRRect(rrect, borderPaint);

    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(20, 326), const Offset(680, 326), linePaint);
  }

  void _drawRetortStand(Canvas canvas) {
    final standBasePaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    final standBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF475569)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final baseRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(260, 310, 120, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(baseRRect, standBasePaint);
    canvas.drawRRect(baseRRect, standBorderPaint);

    // Vertical Rod
    final rodPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    final rodRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(316, 40, 8, 270),
      const Radius.circular(2),
    );
    canvas.drawRRect(rodRRect, rodPaint);

    // Burette Clamp
    final clampPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF475569)
      ..style = PaintingStyle.fill;
    final clampRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(312, 110, 30, 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(clampRRect, clampPaint);

    final armPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(332, 116), const Offset(352, 116), armPaint);
  }

  void _drawWhiteTile(Canvas canvas) {
    final tilePaint = Paint()
      ..color = isDark ? const Color(0xFFF8FAFC) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final tileStroke = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final tileRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(280, 305, 80, 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(tileRRect, tilePaint);
    canvas.drawRRect(tileRRect, tileStroke);
  }

  void _drawReagentBottles(Canvas canvas) {
    // 1. NaOH Bottle (x: 50, y: 240)
    _drawBottle(
      canvas: canvas,
      x: 50,
      y: 240,
      width: 36,
      height: 70,
      accentColor: const Color(0xFF06B6D4),
      label: 'NaOH',
      fillColor: const Color(0x3306B6D4),
    );

    // 2. HCl Bottle (x: 105, y: 240)
    _drawBottle(
      canvas: canvas,
      x: 105,
      y: 240,
      width: 36,
      height: 70,
      accentColor: const Color(0xFFF59E0B),
      label: 'HCl',
      fillColor: const Color(0x33F59E0B),
    );

    // 3. Phenolphthalein Bottle (x: 160, y: 250)
    if (!(state.currentStepIndex == 3 && state.indicatorStep >= 1)) {
      _drawBottle(
        canvas: canvas,
        x: 160,
        y: 250,
        width: 26,
        height: 55,
        accentColor: const Color(0xFFEC4899),
        label: 'IND',
        fillColor: const Color(0x33EC4899),
      );
    }
  }

  void _drawBottle({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double height,
    required Color accentColor,
    required String label,
    required Color fillColor,
  }) {
    final bodyPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, strokePaint);

    // Cap
    final capPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final capRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + (width - 16) / 2, y - 8, 16, 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(capRRect, capPaint);

    // Label card
    final labelBg = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.fill;
    final labelRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 3, y + 20, width - 6, 20),
      const Radius.circular(2),
    );
    canvas.drawRRect(labelRRect, labelBg);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: accentColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(x + (width - textPainter.width) / 2, y + 20 + (20 - textPainter.height) / 2),
    );
  }

  void _drawBurette(Canvas canvas) {
    const buretteX = 346.0;
    const buretteY = 40.0;
    const buretteW = 12.0;
    const buretteH = 200.0;

    // Glass Tube
    final glassPaint = Paint()
      ..color = isDark ? const Color(0x2238BDF8) : const Color(0x33E0F2FE)
      ..style = PaintingStyle.fill;
    final glassStroke = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final tubeRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(buretteX, buretteY, buretteW, buretteH),
      const Radius.circular(3),
    );
    canvas.drawRRect(tubeRRect, glassPaint);

    // Liquid inside Burette (Cyan NaOH)
    if (state.buretteFilled) {
      final liquidFillRatio = (state.volumeDelivered / 50.0).clamp(0.0, 1.0);
      final topY = buretteY + 2 + liquidFillRatio * 180.0;
      final liquidHeight = math.max(0.0, (buretteY + buretteH - 5) - topY);

      if (liquidHeight > 0) {
        final liquidPaint = Paint()
          ..color = const Color(0xBB38BDF8)
          ..style = PaintingStyle.fill;
        final liquidRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(buretteX + 2, topY, buretteW - 4, liquidHeight),
          const Radius.circular(1),
        );
        canvas.drawRRect(liquidRRect, liquidPaint);
      }
    }

    canvas.drawRRect(tubeRRect, glassStroke);

    // Graduations
    final markPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 5; i++) {
      final markY = buretteY + 5 + i * 36.0;
      canvas.drawLine(Offset(buretteX, markY), Offset(buretteX + 6, markY), markPaint);

      final markText = TextPainter(
        text: TextSpan(
          text: '${i * 10}',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 7.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      markText.paint(canvas, Offset(buretteX - markText.width - 2, markY - markText.height / 2));
    }

    // Stopcock Valve (at y: 244)
    final valveColor = (state.stopcockState != StopcockState.closed && state.stopcockState != StopcockState.paused)
        ? const Color(0xFF06B6D4)
        : const Color(0xFFEF4444);

    final valvePaint = Paint()
      ..color = valveColor
      ..style = PaintingStyle.fill;
    final valveStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(const Offset(352, 244), 8, valvePaint);
    canvas.drawCircle(const Offset(352, 244), 8, valveStroke);

    // Stopcock Handle Angle
    canvas.save();
    canvas.translate(352, 244);
    double rotationAngle = 0.0;
    if (state.stopcockState == StopcockState.flow) {
      rotationAngle = math.pi / 2; // 90 deg (Vertical/Open)
    } else if (state.stopcockState == StopcockState.slow || state.stopcockState == StopcockState.single) {
      rotationAngle = math.pi / 4; // 45 deg (Throttled)
    }
    canvas.rotate(rotationAngle);
    final handleLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -6), const Offset(0, 6), handleLine);
    canvas.restore();

    // Stream or Drops Delivery
    if (state.stopcockState == StopcockState.flow) {
      final streamPaint = Paint()
        ..color = const Color(0xEE38BDF8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(352, 252), const Offset(352, 285), streamPaint);
    } else if (state.isDropFalling || state.stopcockState == StopcockState.slow || state.stopcockState == StopcockState.single) {
      final dropPaint = Paint()
        ..color = const Color(0xF038BDF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(352, state.dropY), 3, dropPaint);
    }
  }

  void _drawPipette(Canvas canvas) {
    if (state.currentStepIndex != 2) return;

    final isAboveFlask = state.pipetteStep >= 5;
    final startX = isAboveFlask ? 460.0 : 112.0;
    final startY = 120.0;

    // Suction Bulb
    final bulbPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final bulbStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bulbRx = state.isDrawingLiquid ? 8.0 : 11.0;
    final bulbRy = state.isDrawingLiquid ? 15.0 : 13.0;
    canvas.drawOval(Rect.fromCenter(center: Offset(startX + 10, startY + 15), width: bulbRx * 2, height: bulbRy * 2), bulbPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(startX + 10, startY + 15), width: bulbRx * 2, height: bulbRy * 2), bulbStroke);

    // Pipette Glass Stem & Bulb
    final glassPaint = Paint()
      ..color = isDark ? const Color(0x2238BDF8) : const Color(0x33E0F2FE)
      ..style = PaintingStyle.fill;
    final glassStroke = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(startX + 7, startY + 34, 6, 40), glassPaint);
    canvas.drawRect(Rect.fromLTWH(startX + 7, startY + 34, 6, 40), glassStroke);

    // Liquid in Pipette (Amber HCl)
    if (state.pipetteVolume > 0) {
      final liquidH = (state.pipetteVolume / 25.0) * 115.0;
      final liquidPaint = Paint()
        ..color = const Color(0xC0F59E0B)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(startX + 8, startY + 165 - liquidH, 4, liquidH), liquidPaint);
    }

    // Pipette Body Path
    final path = Path()
      ..moveTo(startX + 7, startY + 74)
      ..lineTo(startX + 2, startY + 85)
      ..quadraticBezierTo(startX, startY + 100, startX + 2, startY + 115)
      ..lineTo(startX + 7, startY + 126)
      ..lineTo(startX + 7, startY + 165)
      ..lineTo(startX + 13, startY + 165)
      ..lineTo(startX + 13, startY + 126)
      ..lineTo(startX + 18, startY + 115)
      ..quadraticBezierTo(startX + 20, startY + 100, startX + 18, startY + 85)
      ..lineTo(startX + 13, startY + 74)
      ..close();
    canvas.drawPath(path, glassPaint);
    canvas.drawPath(path, glassStroke);

    // Transfer stream
    if (state.isTransferringLiquid && isAboveFlask) {
      final streamPaint = Paint()
        ..color = const Color(0xEEF59E0B)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(startX + 10, startY + 165), Offset(startX + 10, startY + 180), streamPaint);
    }
  }

  void _drawIndicatorDropper(Canvas canvas) {
    if (state.currentStepIndex == 3 && state.indicatorStep >= 1) {
      const dropX = 468.0;
      const dropY = 150.0;

      final dropperPaint = Paint()
        ..color = const Color(0x40EC4899)
        ..style = PaintingStyle.fill;
      final dropperStroke = Paint()
        ..color = const Color(0xFFEC4899)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(dropX, dropY, 24, 46),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, dropperPaint);
      canvas.drawRRect(rrect, dropperStroke);

      final tipPath = Path()
        ..moveTo(dropX + 8, dropY + 46)
        ..lineTo(dropX + 16, dropY + 46)
        ..lineTo(dropX + 12, dropY + 60)
        ..close();
      canvas.drawPath(tipPath, Paint()..color = const Color(0xFFEC4899));

      if (state.isDroppingIndicator) {
        final dropPaint = Paint()..color = const Color(0xFFEC4899);
        canvas.drawCircle(const Offset(dropX + 12, dropY + 65), 3, dropPaint);
      }
    }
  }

  void _drawConicalFlask(Canvas canvas) {
    final flaskX = state.flaskPositioned ? 312.0 : 440.0;
    const flaskY = 230.0;

    canvas.save();
    canvas.translate(flaskX + 40, flaskY + 75);
    if (state.isSwirling) {
      // Bounce / tilt swirling oscillation
      canvas.rotate(math.sin(animationValue * math.pi * 6) * 0.08);
    }
    canvas.translate(-40, -75);

    // Flask Glass Path
    final flaskPath = Path()
      ..moveTo(32, 0)
      ..lineTo(48, 0)
      ..lineTo(48, 25)
      ..lineTo(75, 70)
      ..cubicTo(78, 75, 72, 80, 65, 80)
      ..lineTo(15, 80)
      ..cubicTo(8, 80, 2, 75, 5, 70)
      ..lineTo(32, 25)
      ..close();

    final glassPaint = Paint()
      ..color = isDark ? const Color(0x18FFFFFF) : const Color(0x33F8FAFC)
      ..style = PaintingStyle.fill;
    final glassStroke = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Liquid inside Flask
    if (state.flaskVolume > 0) {
      final fillRatio = (state.flaskVolume / 50.0).clamp(0.0, 1.0);
      final liquidTopY = 75.0 - fillRatio * 30.0;
      final liquidWidthDelta = fillRatio * 28.0;

      final liquidPath = Path()
        ..moveTo(40 - liquidWidthDelta, liquidTopY)
        ..lineTo(40 + liquidWidthDelta, liquidTopY)
        ..lineTo(65, 75)
        ..lineTo(15, 75)
        ..close();

      final liquidColor = _getFlaskColor(state.flaskColorStage);
      canvas.drawPath(liquidPath, Paint()..color = liquidColor);

      // Meniscus line
      final meniscusPaint = Paint()
        ..color = const Color(0x9938BDF8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(40 - liquidWidthDelta, liquidTopY),
        Offset(40 + liquidWidthDelta, liquidTopY),
        meniscusPaint,
      );

      // Ripple effect
      if (state.flaskRipple) {
        final ripplePaint = Paint()
          ..color = const Color(0xAA38BDF8)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(40, liquidTopY), width: 22, height: 6),
          ripplePaint,
        );
      }
    }

    canvas.drawPath(flaskPath, glassPaint);
    canvas.drawPath(flaskPath, glassStroke);

    canvas.restore();
  }

  Color _getFlaskColor(FlaskColorStage stage) {
    switch (stage) {
      case FlaskColorStage.colourless:
        return const Color(0x44F0F9FF); // Clear transparent
      case FlaskColorStage.pinkFlash:
        return const Color(0xAAFBCFE8); // Temporary pink flash
      case FlaskColorStage.permanentPalePink:
        return const Color(0xDDF472B6); // Permanent pale pink
      case FlaskColorStage.darkMagenta:
        return const Color(0xF0DB2777); // Dark magenta overshot
    }
  }

  @override
  bool shouldRepaint(covariant TitrationBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
