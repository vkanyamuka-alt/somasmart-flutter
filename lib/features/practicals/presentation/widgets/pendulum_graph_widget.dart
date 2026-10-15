import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/pendulum_state.dart';

class PendulumGraphWidget extends StatelessWidget {
  final List<PendulumTrial> trials;
  final double? calculatedSlope;
  final double? calculatedGravity;
  final bool isDark;
  final bool isSwahili;

  const PendulumGraphWidget({
    super.key,
    required this.trials,
    this.calculatedSlope,
    this.calculatedGravity,
    required this.isDark,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Grafu ya T² dhidi ya L' : 'Graph of T² against L',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        isSwahili
                            ? 'Uhusiano wa moja kwa moja: T² = (4π²/g)L'
                            : 'Linear proportionality: T² = (4π²/g)L',
                        style: TextStyle(fontSize: 11.5, color: subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
              if (calculatedSlope != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'm = ${calculatedSlope!.toStringAsFixed(3)} s²/m',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Plotted Canvas
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _PendulumGraphPainter(
                trials: trials,
                slope: calculatedSlope,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Theory / Analysis Formula Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Uchambuzi wa Mteremko (Slope Analysis):' : 'Slope & Gravity Formula:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSwahili
                            ? 'Mteremko m = ΔT² / ΔL = 4π²/g  ⟹  g = 4π² / m'
                            : 'Gradient m = Δ(T²) / ΔL = 4π²/g  ⟹  g = 4π² / m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (calculatedGravity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          isSwahili
                              ? 'Thamani ya majaribio: g = ${calculatedGravity!.toStringAsFixed(2)} m/s² (Kawaida: 9.80 m/s²)'
                              : 'Experimental result: g = ${calculatedGravity!.toStringAsFixed(2)} m/s² (Accepted: 9.80 m/s²)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendulumGraphPainter extends CustomPainter {
  final List<PendulumTrial> trials;
  final double? slope;
  final bool isDark;

  const _PendulumGraphPainter({
    required this.trials,
    this.slope,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const padLeft = 45.0;
    const padRight = 20.0;
    const padTop = 15.0;
    const padBottom = 35.0;

    final plotW = w - padLeft - padRight;
    final plotH = h - padTop - padBottom;

    // Axis limits: X: L from 0.0 to 1.2 m, Y: T² from 0.0 to 5.0 s²
    const maxX = 1.2;
    const maxY = 5.0;

    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw Grid & Y-Axis Labels
    for (double yVal = 0; yVal <= maxY; yVal += 1.0) {
      final yPos = padTop + plotH * (1.0 - yVal / maxY);
      canvas.drawLine(Offset(padLeft, yPos), Offset(w - padRight, yPos), gridPaint);

      textPainter.text = TextSpan(
        text: yVal.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padLeft - textPainter.width - 6, yPos - 5));
    }

    // Draw Grid & X-Axis Labels
    for (double xVal = 0; xVal <= maxX; xVal += 0.2) {
      final xPos = padLeft + plotW * (xVal / maxX);
      canvas.drawLine(Offset(xPos, padTop), Offset(xPos, padTop + plotH), gridPaint);

      textPainter.text = TextSpan(
        text: xVal.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, padTop + plotH + 6));
    }

    // Draw Axes
    canvas.drawLine(Offset(padLeft, padTop), Offset(padLeft, padTop + plotH), axisPaint);
    canvas.drawLine(Offset(padLeft, padTop + plotH), Offset(w - padRight, padTop + plotH), axisPaint);

    // Axis Titles
    // Y-Axis Title: T² (s²)
    textPainter.text = TextSpan(
      text: 'T² (s²)',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : AppColors.heroNavyDark,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padLeft - 10, padTop - 12));

    // X-Axis Title: L (m)
    textPainter.text = TextSpan(
      text: 'Length L (m)',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : AppColors.heroNavyDark,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w - padRight - textPainter.width, padTop + plotH + 20));

    // Draw Linear Regression Line of Best Fit
    if (slope != null && slope! > 0) {
      final linePaint = Paint()
        ..color = const Color(0xFF06B6D4)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final startX = padLeft;
      final startY = padTop + plotH; // at x = 0, y = 0
      final endXVal = 1.1;
      final endYVal = (slope! * endXVal).clamp(0.0, maxY);
      final endX = padLeft + plotW * (endXVal / maxX);
      final endY = padTop + plotH * (1.0 - endYVal / maxY);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    // Plot Data Points
    final pointFillPaint = Paint()..color = const Color(0xFFEAB308);
    final pointStrokePaint = Paint()
      ..color = const Color(0xFF713F12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final trial in trials) {
      final xM = trial.lengthMeters;
      final yT2 = trial.periodSquared;

      if (xM <= maxX && yT2 <= maxY) {
        final cx = padLeft + plotW * (xM / maxX);
        final cy = padTop + plotH * (1.0 - yT2 / maxY);

        // Draw crosshair or circle
        canvas.drawCircle(Offset(cx, cy), 5.0, pointFillPaint);
        canvas.drawCircle(Offset(cx, cy), 5.0, pointStrokePaint);

        // Coordinate Label
        textPainter.text = TextSpan(
          text: '(${xM.toStringAsFixed(2)}, ${yT2.toStringAsFixed(2)})',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(cx + 6, cy - 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PendulumGraphPainter oldDelegate) {
    return oldDelegate.trials != trials ||
        oldDelegate.slope != slope ||
        oldDelegate.isDark != isDark;
  }
}
