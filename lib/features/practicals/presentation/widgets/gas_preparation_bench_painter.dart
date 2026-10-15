import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/gas_preparation_state.dart';

/// CustomPainter that renders the native chemical gas preparation laboratory bench
class GasPreparationBenchPainter extends CustomPainter {
  final GasPreparationState state;
  final bool isDark;
  final double animationValue;

  const GasPreparationBenchPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBenchBackground(canvas, size);
    _drawReagentSupply(canvas, size);
    _drawGeneratorFlask(canvas, size);
    _drawDeliveryTube(canvas, size);
    _drawCollectionApparatus(canvas, size);
    _drawGasTestZone(canvas, size);
  }

  void _drawBenchBackground(Canvas canvas, Size size) {
    final benchRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    canvas.drawRRect(RRect.fromRectAndRadius(benchRect, const Radius.circular(16)), bgPaint);

    final topRect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final surfacePaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(12)), surfacePaint);

    // Grid markings
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    for (double x = 20; x < size.width - 20; x += 25) {
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), gridPaint);
    }
    for (double y = 20; y < size.height - 20; y += 25) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), gridPaint);
    }

    // Bench tabletop edge line
    final edgePaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(10, size.height - 45), Offset(size.width - 10, size.height - 45), edgePaint);
  }

  void _drawReagentSupply(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Solid reactant container (Left top)
    final solidRect = Rect.fromLTWH(20, 20, 48, 55);
    final solidPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(solidRect, const Radius.circular(6)), solidPaint);

    final solidBorder = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(solidRect, const Radius.circular(6)), solidBorder);

    // Solid container contents
    if (!state.isSolidAdded) {
      final powderPaint = Paint()
        ..color = state.selectedGas == PreparedGasType.oxygen
            ? const Color(0xFF1E293B) // MnO2 black
            : (state.selectedGas == PreparedGasType.carbonDioxide
                ? const Color(0xFFF1F5F9) // CaCO3 white marble
                : const Color(0xFF94A3B8)); // Zinc grey
      canvas.drawRect(Rect.fromLTWH(24, 45, 40, 26), powderPaint);
    }

    textPainter.text = TextSpan(
      text: state.selectedGas.solidFormula,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
    textPainter.layout(maxWidth: 44);
    textPainter.paint(canvas, const Offset(23, 26));

    // 2. Liquid reactant bottle
    final liquidRect = Rect.fromLTWH(76, 20, 48, 55);
    final liquidPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(liquidRect, const Radius.circular(6)), liquidPaint);

    final liquidBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(liquidRect, const Radius.circular(6)), liquidBorder);

    textPainter.text = TextSpan(
      text: state.selectedGas.liquidFormula,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0284C7),
      ),
    );
    textPainter.layout(maxWidth: 44);
    textPainter.paint(canvas, const Offset(79, 26));
  }

  void _drawGeneratorFlask(Canvas canvas, Size size) {
    const double flaskCenterX = 70.0;
    final double flaskBaseY = size.height - 45.0;

    final glassPaint = Paint()
      ..color = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : const Color(0xFFBAE6FD).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final glassStroke = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Flask body (Flat-bottomed / Conical shape)
    final flaskPath = Path();
    flaskPath.moveTo(flaskCenterX - 14, flaskBaseY - 110); // neck left
    flaskPath.lineTo(flaskCenterX - 14, flaskBaseY - 80);
    flaskPath.lineTo(flaskCenterX - 45, flaskBaseY - 10);
    flaskPath.quadraticBezierTo(flaskCenterX - 45, flaskBaseY, flaskCenterX - 35, flaskBaseY);
    flaskPath.lineTo(flaskCenterX + 35, flaskBaseY);
    flaskPath.quadraticBezierTo(flaskCenterX + 45, flaskBaseY, flaskCenterX + 45, flaskBaseY - 10);
    flaskPath.lineTo(flaskCenterX + 14, flaskBaseY - 80);
    flaskPath.lineTo(flaskCenterX + 14, flaskBaseY - 110);
    flaskPath.close();

    canvas.drawPath(flaskPath, glassPaint);
    canvas.drawPath(flaskPath, glassStroke);

    // Rubber Stopper / Bung
    final stopperPaint = Paint()..color = const Color(0xFF475569);
    final stopperRect = Rect.fromLTWH(flaskCenterX - 13, flaskBaseY - 112, 26, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(stopperRect, const Radius.circular(2)), stopperPaint);

    // Thistle Funnel inserted through stopper down into flask
    final thistlePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Funnel top cone
    final funnelTop = Path()
      ..moveTo(flaskCenterX - 20, flaskBaseY - 145)
      ..lineTo(flaskCenterX - 6, flaskBaseY - 125)
      ..lineTo(flaskCenterX - 6, flaskBaseY - 20)
      ..moveTo(flaskCenterX - 2, flaskBaseY - 20)
      ..lineTo(flaskCenterX - 2, flaskBaseY - 125)
      ..lineTo(flaskCenterX + 12, flaskBaseY - 145)
      ..close();
    canvas.drawPath(funnelTop, thistlePaint);

    // Liquid inside thistle stem if liquid added
    if (state.isLiquidAdded) {
      final stemLiquidPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(flaskCenterX - 6, flaskBaseY - 105, 4, 85), stemLiquidPaint);
    }

    // Solid inside flask
    if (state.isSolidAdded) {
      final solidBedPaint = Paint()
        ..color = state.selectedGas == PreparedGasType.oxygen
            ? const Color(0xFF0F172A) // Black MnO2
            : (state.selectedGas == PreparedGasType.carbonDioxide
                ? const Color(0xFFE2E8F0) // White CaCO3
                : const Color(0xFF64748B)); // Zinc granules
      final solidPath = Path()
        ..moveTo(flaskCenterX - 35, flaskBaseY)
        ..quadraticBezierTo(flaskCenterX - 20, flaskBaseY - 12, flaskCenterX, flaskBaseY - 10)
        ..quadraticBezierTo(flaskCenterX + 20, flaskBaseY - 14, flaskCenterX + 35, flaskBaseY)
        ..close();
      canvas.drawPath(solidPath, solidBedPaint);
    }

    // Liquid reactant inside flask
    if (state.isLiquidAdded) {
      final liquidInsidePaint = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      final liquidPath = Path()
        ..moveTo(flaskCenterX - 40, flaskBaseY - 8)
        ..lineTo(flaskCenterX - 32, flaskBaseY - 35)
        ..lineTo(flaskCenterX + 32, flaskBaseY - 35)
        ..lineTo(flaskCenterX + 40, flaskBaseY - 8)
        ..lineTo(flaskCenterX + 35, flaskBaseY)
        ..lineTo(flaskCenterX - 35, flaskBaseY)
        ..close();
      canvas.drawPath(liquidPath, liquidInsidePaint);

      // Bubbles of effervescence
      if (state.isGenerating || state.isGasJarFull) {
        final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
        for (int i = 0; i < 14; i++) {
          final bx = flaskCenterX - 25 + (i * 4.2) + math.sin(animationValue * 6.28 + i) * 3;
          final by = flaskBaseY - 12 - ((animationValue * 30 + i * 4) % 24);
          canvas.drawCircle(Offset(bx, by), 1.5 + (i % 2), bubblePaint);
        }
      }
    }
  }

  void _drawDeliveryTube(Canvas canvas, Size size) {
    const double flaskCenterX = 70.0;
    final double flaskBaseY = size.height - 45.0;
    final double targetX = size.width > 340 ? 210.0 : 190.0;
    final double targetY = state.selectedGas == PreparedGasType.carbonDioxide
        ? flaskBaseY - 20.0
        : flaskBaseY - 15.0;

    final tubePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final tubePath = Path()
      ..moveTo(flaskCenterX + 6, flaskBaseY - 105)
      ..lineTo(flaskCenterX + 6, flaskBaseY - 130)
      ..lineTo(targetX - 25, flaskBaseY - 130);

    if (state.selectedGas == PreparedGasType.carbonDioxide) {
      // Downward delivery tube straight down into upright jar
      tubePath.lineTo(targetX, flaskBaseY - 130);
      tubePath.lineTo(targetX, targetY);
    } else {
      // Tube bends down and goes under beehive shelf in water trough
      tubePath.lineTo(targetX - 25, flaskBaseY - 25);
      tubePath.lineTo(targetX + 5, flaskBaseY - 15);
    }

    canvas.drawPath(tubePath, tubePaint);

    // Gas moving in delivery tube
    if (state.isGenerating) {
      final gasFlowPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final flowOffset = (animationValue * 20) % 20;
      canvas.drawCircle(Offset(flaskCenterX + 6, flaskBaseY - 120 - flowOffset * 0.4), 1.2, gasFlowPaint);
      canvas.drawCircle(Offset(flaskCenterX + 20 + flowOffset * 4, flaskBaseY - 130), 1.2, gasFlowPaint);
    }
  }

  void _drawCollectionApparatus(Canvas canvas, Size size) {
    final double jarX = size.width > 340 ? 210.0 : 190.0;
    final double baseY = size.height - 45.0;

    if (state.selectedGas == PreparedGasType.carbonDioxide) {
      // 1. Upright Gas Jar (Downward Delivery / Upward Displacement of Air)
      final jarRect = Rect.fromLTWH(jarX - 20, baseY - 90, 40, 90);
      final jarPaint = Paint()
        ..color = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : const Color(0xFFBAE6FD).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final jarBorder = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(RRect.fromRectAndRadius(jarRect, const Radius.circular(4)), jarPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(jarRect, const Radius.circular(4)), jarBorder);

      // Gas volume filling upright jar from bottom
      if (state.collectedVolumeMl > 0) {
        final gasHeight = (state.collectedVolumeMl / 100.0) * 82.0;
        final gasRect = Rect.fromLTWH(jarX - 18, baseY - 4 - gasHeight, 36, gasHeight);
        final co2Paint = Paint()
          ..color = const Color(0xFF94A3B8).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(gasRect, const Radius.circular(3)), co2Paint);
      }
    } else {
      // 2. Pneumatic Water Trough + Beehive Shelf + Inverted Gas Jar (Over Water)
      // Water Trough
      final troughRect = Rect.fromLTWH(jarX - 45, baseY - 45, 90, 45);
      final troughGlass = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      final troughBorder = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(RRect.fromRectAndRadius(troughRect, const Radius.circular(6)), troughGlass);
      canvas.drawRRect(RRect.fromRectAndRadius(troughRect, const Radius.circular(6)), troughBorder);

      // Water inside trough
      final waterPaint = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      final waterRect = Rect.fromLTWH(jarX - 43, baseY - 35, 86, 33);
      canvas.drawRect(waterRect, waterPaint);

      // Beehive shelf stand
      final shelfPaint = Paint()..color = const Color(0xFF64748B);
      final shelfPath = Path()
        ..moveTo(jarX - 22, baseY)
        ..lineTo(jarX - 22, baseY - 22)
        ..lineTo(jarX + 22, baseY - 22)
        ..lineTo(jarX + 22, baseY)
        ..lineTo(jarX + 10, baseY)
        ..lineTo(jarX + 10, baseY - 12)
        ..lineTo(jarX - 10, baseY - 12)
        ..lineTo(jarX - 10, baseY)
        ..close();
      canvas.drawPath(shelfPath, shelfPaint);

      // Inverted Gas Jar on Beehive Shelf
      final jarRect = Rect.fromLTWH(jarX - 18, baseY - 105, 36, 83);
      final jarPaint = Paint()
        ..color = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : const Color(0xFFBAE6FD).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final jarBorder = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(RRect.fromRectAndRadius(jarRect, const Radius.circular(4)), jarPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(jarRect, const Radius.circular(4)), jarBorder);

      // Water column inside inverted gas jar (displaced downward as gas accumulates)
      final displacementFraction = state.collectedVolumeMl / 100.0;
      final waterHeightInJar = (1.0 - displacementFraction) * 75.0;

      if (waterHeightInJar > 0) {
        final jarWaterRect = Rect.fromLTWH(jarX - 16, baseY - 22 - waterHeightInJar, 32, waterHeightInJar);
        final jarWaterPaint = Paint()
          ..color = const Color(0xFF0284C7).withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(jarWaterRect, jarWaterPaint);
      }

      // Gas bubble rising in jar during generation
      if (state.isGenerating) {
        final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
        final bubbleY = baseY - 22 - ((animationValue * 60) % 55);
        canvas.drawCircle(Offset(jarX, bubbleY), 2.5, bPaint);
      }
    }

    // Volume badge
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '${state.collectedVolumeMl.toInt()} mL',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: state.isGasJarFull ? const Color(0xFF10B981) : const Color(0xFF0284C7),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(jarX - textPainter.width / 2, baseY - 120));
  }

  void _drawGasTestZone(Canvas canvas, Size size) {
    if (!state.isTestPerformed) return;

    final double testX = size.width - 55.0;
    final double baseY = size.height - 45.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (state.selectedGas == PreparedGasType.oxygen) {
      // Oxygen Test: Glowing splint relights into flame
      final splintPaint = Paint()
        ..color = const Color(0xFF78350F)
        ..strokeWidth = 3.5;
      canvas.drawLine(Offset(testX, baseY - 10), Offset(testX - 18, baseY - 70), splintPaint);

      // Bright yellow/orange flame
      final flamePaint = Paint()..color = const Color(0xFFF59E0B);
      final flamePath = Path()
        ..moveTo(testX - 20, baseY - 70)
        ..quadraticBezierTo(testX - 28, baseY - 82 + math.sin(animationValue * 10) * 3, testX - 18, baseY - 94)
        ..quadraticBezierTo(testX - 10, baseY - 82 + math.cos(animationValue * 10) * 3, testX - 16, baseY - 70)
        ..close();
      canvas.drawPath(flamePath, flamePaint);

      final innerFlame = Paint()..color = const Color(0xFFFEF08A);
      canvas.drawCircle(Offset(testX - 18, baseY - 77), 4.0, innerFlame);

      textPainter.text = const TextSpan(
        text: '🔥 RELIGHTS!',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(testX - 35, baseY - 110));
    } else if (state.selectedGas == PreparedGasType.carbonDioxide) {
      // Carbon Dioxide Test: Limewater turns milky/cloudy
      final tubeRect = Rect.fromLTWH(testX - 25, baseY - 70, 24, 65);
      final tubeBorder = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final milkyWater = Paint()
        ..color = const Color(0xFFF1F5F9).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(6)), milkyWater);
      canvas.drawRRect(RRect.fromRectAndRadius(tubeRect, const Radius.circular(6)), tubeBorder);

      textPainter.text = const TextSpan(
        text: '☁️ MILKY',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(testX - 30, baseY - 85));
    } else {
      // Hydrogen Test: Burning splint gives a squeaky "POP"
      final splintPaint = Paint()
        ..color = const Color(0xFF78350F)
        ..strokeWidth = 3.5;
      canvas.drawLine(Offset(testX, baseY - 10), Offset(testX - 18, baseY - 70), splintPaint);

      // Pop explosion wave
      final popPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(testX - 18, baseY - 75), 10.0 + (animationValue * 6), popPaint);

      textPainter.text = const TextSpan(
        text: '💥 "POP!"',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(testX - 30, baseY - 105));
    }
  }

  @override
  bool shouldRepaint(covariant GasPreparationBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
