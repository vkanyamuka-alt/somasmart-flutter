import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/microscope_state.dart';

/// High-performance CustomPainter rendering the circular optical field of view
/// of a compound light microscope with realistic onion epidermal cell staining.
class MicroscopeViewfinderPainter extends CustomPainter {
  final MicroscopeState state;
  final bool isDark;
  final double animationValue;

  MicroscopeViewfinderPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8.0;

    // Draw outer microscope metallic barrel bezel
    final bezelPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          isDark ? const Color(0xFF0F172A) : const Color(0xFF334155),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 8.0));
    canvas.drawCircle(center, radius + 7.0, bezelPaint);

    final bezelBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius + 7.0, bezelBorderPaint);

    // Clip internal circular optical viewport
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // If illumination is OFF, render pitch black field
    if (!state.isLightOn || state.lightIntensity <= 0.0) {
      final darkPaint = Paint()..color = const Color(0xFF020617);
      canvas.drawCircle(center, radius, darkPaint);
      _drawReticle(canvas, center, radius, isLit: false);
      canvas.restore();
      return;
    }

    // 1. Draw light background condenser gradient
    final intensityFactor = (state.lightIntensity / 100.0).clamp(0.0, 1.0);
    final bool isStained = state.appliedStain != StainType.none;

    final Color lightCenterColor = isStained
        ? Color.lerp(const Color(0xFFFFFBEB), const Color(0xFFFEF3C7), intensityFactor)!
        : Color.lerp(const Color(0xFFF1F5F9), const Color(0xFFFFFFFF), intensityFactor)!;

    final Color lightEdgeColor = isStained
        ? Color.lerp(const Color(0xFF78350F), const Color(0xFF92400E), intensityFactor)!
        : Color.lerp(const Color(0xFF334155), const Color(0xFF64748B), intensityFactor)!;

    final condenserShader = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [lightCenterColor, lightEdgeColor],
      stops: const [0.4, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final lightPaint = Paint()..shader = condenserShader;
    canvas.drawCircle(center, radius, lightPaint);

    // 2. Draw specimen cells if slide is on stage
    if (state.isSlideOnStage) {
      _drawOnionCells(canvas, center, radius, isStained);
    } else {
      // Empty condenser field with faint dust specs
      _drawDustAndAperture(canvas, center, radius);
    }

    // 3. Optical vignetting and glass reflection
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, vignettePaint);

    // 4. Optical Reticle and Crosshairs
    _drawReticle(canvas, center, radius, isLit: true);

    canvas.restore();

    // Draw scale bar and magnification badge overlay
    _drawScaleBar(canvas, size, center, radius);
  }

  void _drawOnionCells(Canvas canvas, Offset center, double radius, bool isStained) {
    final sharpness = state.sharpness;
    final mag = state.selectedObjective.magnification;

    // Scale cell dimensions based on objective
    final double cellWidth = mag == 4 ? 38.0 : (mag == 10 ? 82.0 : 180.0);
    final double cellHeight = mag == 4 ? 20.0 : (mag == 10 ? 44.0 : 96.0);

    final blurOffset = (1.0 - sharpness) * 12.0;
    final strokeWidth = (mag == 4 ? 1.5 : (mag == 10 ? 2.5 : 4.0)) + blurOffset * 0.4;

    // Color definitions
    final Color cellWallColor = isStained
        ? Color.lerp(const Color(0xFF451A03), const Color(0xFF78350F), 0.5)!
        : const Color(0xFF64748B);

    final Color cytoplasmColor = isStained
        ? const Color(0xFFFDE68A).withValues(alpha: 0.40)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.25);

    final Color nucleusColor = isStained
        ? const Color(0xFF78350F).withValues(alpha: 0.85)
        : const Color(0xFF94A3B8).withValues(alpha: 0.50);

    final cellWallPaint = Paint()
      ..color = cellWallColor.withValues(alpha: sharpness.clamp(0.2, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final innerWallPaint = Paint()
      ..color = (isStained ? const Color(0xFFB45309) : const Color(0xFF94A3B8))
          .withValues(alpha: sharpness.clamp(0.15, 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth * 0.5).clamp(1.0, 3.0);

    final cytoplasmPaint = Paint()
      ..color = cytoplasmColor
      ..style = PaintingStyle.fill;

    final nucleusPaint = Paint()
      ..color = nucleusColor
      ..style = PaintingStyle.fill;

    // Render chromatic aberration fringe when out of focus
    if (sharpness < 0.75) {
      final fringePaint = Paint()
        ..color = Colors.cyan.withValues(alpha: (0.75 - sharpness) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.0;
      _drawCellGrid(canvas, center, radius, cellWidth, cellHeight, fringePaint, null, null, null, -1.5, 0);
    }

    _drawCellGrid(
      canvas,
      center,
      radius,
      cellWidth,
      cellHeight,
      cellWallPaint,
      innerWallPaint,
      cytoplasmPaint,
      nucleusPaint,
      0,
      0,
    );

    // Organelle pinpoint callouts if in high power and in focus
    if (sharpness >= 0.80 && (mag == 10 || mag == 40)) {
      _drawOrganelleHighlights(canvas, center, radius, cellWidth, cellHeight);
    }
  }

  void _drawCellGrid(
    Canvas canvas,
    Offset center,
    double radius,
    double cellW,
    double cellH,
    Paint wallPaint,
    Paint? innerWallPaint,
    Paint? cytoplasmPaint,
    Paint? nucleusPaint,
    double offsetX,
    double offsetY,
  ) {
    final cols = (radius * 2 / cellW).ceil() + 3;
    final rows = (radius * 2 / cellH).ceil() + 3;

    final startX = center.dx - (cols * cellW / 2) + offsetX + (state.stageX * 0.5);
    final startY = center.dy - (rows * cellH / 2) + offsetY + (state.stageY * 0.5);

    for (int r = 0; r < rows; r++) {
      // Stagger rows for natural brick-like plant parenchyma tissue
      final rowOffset = (r % 2 == 0) ? 0.0 : (cellW * 0.45);

      for (int c = 0; c < cols; c++) {
        final x = startX + (c * cellW) + rowOffset;
        final y = startY + (r * cellH);

        final cellRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 2, cellW - 4, cellH - 4),
          const Radius.circular(4.0),
        );

        // Cytoplasm fill
        if (cytoplasmPaint != null) {
          canvas.drawRRect(cellRect, cytoplasmPaint);
        }

        // Cell Wall primary stroke
        canvas.drawRRect(cellRect, wallPaint);

        // Secondary inner plasma membrane boundary
        if (innerWallPaint != null) {
          final innerRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 4, y + 4, cellW - 8, cellH - 8),
            const Radius.circular(3.0),
          );
          canvas.drawRRect(innerRect, innerWallPaint);
        }

        // Nucleus (eccentrically located in onion plant cells due to large central vacuole)
        if (nucleusPaint != null) {
          final nucX = x + cellW * 0.72;
          final nucY = y + cellH * 0.58;
          final nucRadius = (cellH * 0.20).clamp(2.0, 16.0);

          canvas.drawCircle(Offset(nucX, nucY), nucRadius, nucleusPaint);

          // Nucleolus center speck
          if (state.sharpness > 0.85 && state.selectedObjective.magnification >= 10) {
            final nucleolusPaint = Paint()..color = const Color(0xFF451A03);
            canvas.drawCircle(Offset(nucX, nucY), nucRadius * 0.35, nucleolusPaint);
          }
        }
      }
    }
  }

  void _drawOrganelleHighlights(
    Canvas canvas,
    Offset center,
    double radius,
    double cellW,
    double cellH,
  ) {
    if (state.identifiedOrganelleIds.isEmpty) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (state.identifiedOrganelleIds.contains('nucleus')) {
      final nucPos = Offset(center.dx + cellW * 0.22, center.dy + cellH * 0.08);
      _drawPin(canvas, nucPos, 'Nucleus / Kiini', const Color(0xFFD97706), textPainter);
    }

    if (state.identifiedOrganelleIds.contains('cell_wall')) {
      final wallPos = Offset(center.dx - cellW * 0.30, center.dy - cellH * 0.32);
      _drawPin(canvas, wallPos, 'Cell Wall / Ukuta', const Color(0xFF10B981), textPainter);
    }

    if (state.identifiedOrganelleIds.contains('cytoplasm')) {
      final cytoPos = Offset(center.dx - cellW * 0.10, center.dy + cellH * 0.15);
      _drawPin(canvas, cytoPos, 'Cytoplasm / Kioevu', const Color(0xFF38BDF8), textPainter);
    }

    if (state.identifiedOrganelleIds.contains('vacuole')) {
      final vacPos = Offset(center.dx + cellW * 0.05, center.dy - cellH * 0.12);
      _drawPin(canvas, vacPos, 'Vacuole / Kiputo', const Color(0xFFA855F7), textPainter);
    }
  }

  void _drawPin(Canvas canvas, Offset pos, String label, Color color, TextPainter tp) {
    final pinPaint = Paint()..color = color;
    canvas.drawCircle(pos, 5.0, pinPaint);

    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(pos, 9.0, haloPaint);

    // Label tag
    tp.text = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10.0,
        fontWeight: FontWeight.w700,
        backgroundColor: Colors.black.withValues(alpha: 0.75),
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx + 12.0, pos.dy - 6.0));
  }

  void _drawReticle(Canvas canvas, Offset center, double radius, {required bool isLit}) {
    final reticlePaint = Paint()
      ..color = (isLit ? Colors.black : Colors.white).withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    // Center crosshair with center clearance
    canvas.drawLine(
      Offset(center.dx - radius * 0.45, center.dy),
      Offset(center.dx - 12.0, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 12.0, center.dy),
      Offset(center.dx + radius * 0.45, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.45),
      Offset(center.dx, center.dy - 12.0),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 12.0),
      Offset(center.dx, center.dy + radius * 0.45),
      reticlePaint,
    );

    // Subtle center targeting ring
    final ringPaint = Paint()
      ..color = (isLit ? Colors.black : Colors.white).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 12.0, ringPaint);
  }

  void _drawDustAndAperture(Canvas canvas, Offset center, double radius) {
    final dustPaint = Paint()..color = const Color(0xFF94A3B8).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(center.dx - 35, center.dy + 40), 1.5, dustPaint);
    canvas.drawCircle(Offset(center.dx + 50, center.dy - 25), 2.0, dustPaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy + 65), 1.2, dustPaint);
  }

  void _drawScaleBar(Canvas canvas, Size size, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final mag = state.selectedObjective.magnification;
    final totalMag = state.totalMagnification;
    final scaleText = mag == 4 ? '200 μm' : (mag == 10 ? '100 μm' : '25 μm');
    const barWidth = 60.0;

    final barX = center.dx - barWidth / 2;
    final barY = center.dy + radius - 24.0;

    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(barX, barY), Offset(barX + barWidth, barY), barPaint);
    canvas.drawLine(Offset(barX, barY - 4), Offset(barX, barY + 4), barPaint);
    canvas.drawLine(Offset(barX + barWidth, barY - 4), Offset(barX + barWidth, barY + 4), barPaint);

    textPainter.text = TextSpan(
      text: '$scaleText ($totalMag×)',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.0,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, barY - 16.0));
  }

  @override
  bool shouldRepaint(covariant MicroscopeViewfinderPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
