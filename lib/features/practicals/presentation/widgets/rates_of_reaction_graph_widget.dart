import 'package:flutter/material.dart';
import '../../data/models/rates_of_reaction_state.dart';

/// Interactive Canvas Graph Widget plotting Reaction Rate (1/t) against [Na₂S₂O₃] Concentration
class RatesOfReactionGraphWidget extends StatelessWidget {
  final RatesOfReactionState state;
  final bool isDark;
  final bool isSwahili;

  const RatesOfReactionGraphWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili
                            ? 'Grafu ya Kasi: 1/t dhidi ya [Na₂S₂O₃]'
                            : 'Rate Graph: 1/t vs [Na₂S₂O₃]',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isSwahili
                            ? 'Mteremko (k) unathibitisha kanuni ya kasi ya daraja la kwanza'
                            : 'Linear slope (k) confirms 1st-order rate law',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'k ≈ ${state.calculatedSlope.toStringAsFixed(3)} s⁻¹M⁻¹',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graph Canvas
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _RatesGraphPainter(
                state: state,
                isDark: isDark,
                isSwahili: isSwahili,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Rate Law equation badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSwahili ? 'Kanuni ya Kasi (Rate Law):' : 'Deduced Rate Law:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                Text(
                  'Rate = k · [Na₂S₂O₃]¹ (1st Order)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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

class _RatesGraphPainter extends CustomPainter {
  final RatesOfReactionState state;
  final bool isDark;
  final bool isSwahili;

  const _RatesGraphPainter({
    required this.state,
    required this.isDark,
    required this.isSwahili,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 46.0;
    const rightPadding = 16.0;
    const topPadding = 16.0;
    const bottomPadding = 32.0;

    final plotRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    // Background grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    // Y Axis: Rate (0.00 to 0.06 s^-1)
    const maxY = 0.06;
    const yTicks = [0.00, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06];
    for (final yVal in yTicks) {
      final yPos = plotRect.bottom - (yVal / maxY) * plotRect.height;
      canvas.drawLine(Offset(plotRect.left, yPos), Offset(plotRect.right, yPos), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: yVal.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(plotRect.left - textPainter.width - 6, yPos - 5));
    }

    // X Axis: Concentration [Na2S2O3] (0.00 to 0.24 M)
    const maxX = 0.24;
    const xTicks = [0.00, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24];
    for (final xVal in xTicks) {
      final xPos = plotRect.left + (xVal / maxX) * plotRect.width;
      canvas.drawLine(Offset(xPos, plotRect.top), Offset(xPos, plotRect.bottom), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: xVal.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(xPos - (textPainter.width / 2), plotRect.bottom + 6));
    }

    // Main Axes lines
    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)
      ..strokeWidth = 1.5;
    canvas.drawLine(plotRect.bottomLeft, plotRect.bottomRight, axisPaint); // X-axis
    canvas.drawLine(plotRect.bottomLeft, plotRect.topLeft, axisPaint); // Y-axis

    // Axis Labels
    final xLabel = TextPainter(
      text: TextSpan(
        text: isSwahili ? '[Na₂S₂O₃] (mol/dm³)' : '[Na₂S₂O₃] Concentration (M)',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(canvas, Offset(plotRect.center.dx - (xLabel.width / 2), size.height - 12));

    // Linear regression line of best fit (Rate = slope * [Na2S2O3])
    final slope = state.calculatedSlope;
    final lineStart = Offset(plotRect.left, plotRect.bottom);
    final xEnd = 0.22;
    final yEnd = (slope * xEnd).clamp(0.0, maxY);
    final lineEnd = Offset(
      plotRect.left + (xEnd / maxX) * plotRect.width,
      plotRect.bottom - (yEnd / maxY) * plotRect.height,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(lineStart, lineEnd, linePaint);

    // Plot experimental data points
    final completed = state.trials.where((t) => t.calculatedRate != null).toList();
    for (final trial in completed) {
      final x = trial.concentrationThio;
      final y = trial.calculatedRate!;
      final px = plotRect.left + (x / maxX) * plotRect.width;
      final py = plotRect.bottom - (y / maxY) * plotRect.height;

      // Glow / outer ring
      final glowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 7, glowPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 4.5, dotPaint);

      final dotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(px, py), 4.5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RatesGraphPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isSwahili != isSwahili;
  }
}
