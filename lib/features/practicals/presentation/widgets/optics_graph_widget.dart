import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/optics_state.dart';

/// Interactive Canvas-drawn Graph widget for the Refraction practical,
/// plotting sin(i) on the Y-axis against sin(r) on the X-axis to find
/// the refractive index n = Gradient m.
class OpticsGraphWidget extends StatelessWidget {
  final OpticsState state;
  final bool isDark;
  final bool isSwahili;

  const OpticsGraphWidget({
    super.key,
    required this.state,
    required this.isDark,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final slope = state.regressionSlope;
    final expN = state.experimentalRefractiveIndex;
    final err = state.percentageError;

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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Grafu ya sin(i) dhidi ya sin(r)' : 'Graph of sin(i) against sin(r)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isSwahili
                            ? 'Sheria ya Snell: sin(i) = n · sin(r)'
                            : 'Snell’s Law: sin(i) = n · sin(r)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Text(
                  'm = ${slope.toStringAsFixed(3)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Canvas Graph Plotter
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _SinISinRGraphPainter(
                trials: state.recordedTrials,
                slope: slope,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Formula & Slope Analysis Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calculate_outlined, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Uchambuzi wa Mteremko na Kielezo (n):' : 'Slope & Refractive Index Analysis:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Gradient m = Δsin(i) / Δsin(r) = n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSwahili
                            ? 'Matokeo: n = ${expN.toStringAsFixed(3)} (Halisi: 1.500, Kosa: ${err.toStringAsFixed(2)}%)'
                            : 'Experimental: n = ${expN.toStringAsFixed(3)} (Accepted: 1.500, Error: ${err.toStringAsFixed(2)}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
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

class _SinISinRGraphPainter extends CustomPainter {
  final List<OpticsTrial> trials;
  final double slope;
  final bool isDark;

  _SinISinRGraphPainter({
    required this.trials,
    required this.slope,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 42.0;
    const bottomPadding = 32.0;
    const topPadding = 16.0;
    const rightPadding = 20.0;

    final plotWidth = size.width - leftPadding - rightPadding;
    final plotHeight = size.height - topPadding - bottomPadding;

    const maxX = 0.70; // sin(r) max approx 0.65
    const maxY = 1.00; // sin(i) max approx 0.95

    double toScreenX(double x) => leftPadding + (x / maxX) * plotWidth;
    double toScreenY(double y) => topPadding + plotHeight - (y / maxY) * plotHeight;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    for (double x = 0.1; x <= maxX; x += 0.1) {
      final sx = toScreenX(x);
      canvas.drawLine(Offset(sx, topPadding), Offset(sx, topPadding + plotHeight), gridPaint);
      _drawLabel(canvas, x.toStringAsFixed(1), Offset(sx, topPadding + plotHeight + 10));
    }

    for (double y = 0.2; y <= maxY; y += 0.2) {
      final sy = toScreenY(y);
      canvas.drawLine(Offset(leftPadding, sy), Offset(leftPadding + plotWidth, sy), gridPaint);
      _drawLabel(canvas, y.toStringAsFixed(1), Offset(leftPadding - 18, sy));
    }

    // Axes
    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)
      ..strokeWidth = 1.6;

    // Y Axis (sin i)
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + plotHeight),
      axisPaint,
    );
    // X Axis (sin r)
    canvas.drawLine(
      Offset(leftPadding, topPadding + plotHeight),
      Offset(leftPadding + plotWidth, topPadding + plotHeight),
      axisPaint,
    );

    // Axis Labels
    _drawLabel(canvas, '0.0', Offset(leftPadding - 10, topPadding + plotHeight + 10));
    _drawLabel(canvas, 'sin(i)', Offset(leftPadding - 4, topPadding - 8), isAxisTitle: true);
    _drawLabel(canvas, 'sin(r)', Offset(leftPadding + plotWidth - 10, topPadding + plotHeight + 20), isAxisTitle: true);

    // Best-fit Line: y = slope * x through (0,0)
    final linePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final xEnd = math.min(maxX, maxY / (slope > 0 ? slope : 1.5));
    final yEnd = slope * xEnd;

    canvas.drawLine(
      Offset(toScreenX(0), toScreenY(0)),
      Offset(toScreenX(xEnd), toScreenY(yEnd)),
      linePaint,
    );

    // Experimental Data Points
    for (final trial in trials) {
      final px = toScreenX(trial.sinR);
      final py = toScreenY(trial.sinI);

      final pointFill = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawCircle(Offset(px, py), 5.5, pointFill);

      final pointRing = Paint()
        ..color = const Color(0xFF78350F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(px, py), 5.5, pointRing);

      // Coordinate callout
      _drawLabel(
        canvas,
        '(${trial.sinR.toStringAsFixed(2)}, ${trial.sinI.toStringAsFixed(2)})',
        Offset(px + 14, py - 6),
        isPointTag: true,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, {bool isAxisTitle = false, bool isPointTag = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isPointTag
              ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309))
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          fontSize: isAxisTitle ? 10.5 : (isPointTag ? 9.0 : 9.5),
          fontWeight: isAxisTitle || isPointTag ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SinISinRGraphPainter oldDelegate) {
    return oldDelegate.trials != trials || oldDelegate.slope != slope || oldDelegate.isDark != isDark;
  }
}
