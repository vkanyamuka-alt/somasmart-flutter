import 'package:flutter/material.dart';
import '../../data/models/osmosis_state.dart';

/// Interactive Canvas Graph Widget plotting % Change in Mass against Sucrose Concentration
class OsmosisGraphWidget extends StatelessWidget {
  final OsmosisState state;
  final bool isDark;
  final bool isSwahili;

  const OsmosisGraphWidget({
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili
                            ? 'Grafu: % Mabadiliko ya Uzito dhidi ya Ukolezi'
                            : 'Graph: % Mass Change vs Concentration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isSwahili
                            ? 'Mteremko unaonyesha eneo la msawazo (Isotonic point)'
                            : 'Curve intersection marks the tissue isotonic point',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: Text(
                  'C_iso ≈ ${state.calculatedIsotonicConcentration} M',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: CustomPaint(
              painter: _OsmosisGraphPainter(
                samples: state.samples,
                isDark: isDark,
                isSwahili: isSwahili,
                isotonicPoint: state.calculatedIsotonicConcentration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmosisGraphPainter extends CustomPainter {
  final List<PotatoSample> samples;
  final bool isDark;
  final bool isSwahili;
  final double isotonicPoint;

  _OsmosisGraphPainter({
    required this.samples,
    required this.isDark,
    required this.isSwahili,
    required this.isotonicPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 46.0;
    const bottomPadding = 36.0;
    const topPadding = 16.0;
    const rightPadding = 20.0;

    final graphWidth = size.width - leftPadding - rightPadding;
    final graphHeight = size.height - topPadding - bottomPadding;

    // Y Range: +20% to -25% (total range = 45%)
    const minY = -25.0;
    const maxY = 20.0;
    const rangeY = maxY - minY;

    // X Range: 0.0 M to 0.8 M (or up to 0.9 M)
    const minX = 0.0;
    const maxX = 0.9;
    const rangeX = maxX - minX;

    double mapX(double x) => leftPadding + ((x - minX) / rangeX) * graphWidth;
    double mapY(double y) => topPadding + ((maxY - y) / rangeY) * graphHeight;

    final zeroY = mapY(0.0);

    // 1. Grid Lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    // Y grid ticks (-20, -10, 0, 10, 20)
    for (double yVal = -20.0; yVal <= 20.0; yVal += 10.0) {
      final yPos = mapY(yVal);
      canvas.drawLine(Offset(leftPadding, yPos), Offset(size.width - rightPadding, yPos), gridPaint);

      final label = yVal > 0 ? '+$yVal' : '$yVal';
      _drawText(canvas, '$label%', Offset(leftPadding - 8, yPos - 6), isDark, isAlignRight: true);
    }

    // X grid ticks (0.0, 0.2, 0.4, 0.6, 0.8 M)
    for (double xVal = 0.0; xVal <= 0.81; xVal += 0.2) {
      final xPos = mapX(xVal);
      canvas.drawLine(Offset(xPos, topPadding), Offset(xPos, topPadding + graphHeight), gridPaint);
      _drawText(canvas, '${xVal.toStringAsFixed(1)}M', Offset(xPos - 12, topPadding + graphHeight + 6), isDark);
    }

    // 2. Bold Zero Line (0% Mass Change)
    final zeroPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(leftPadding, zeroY), Offset(size.width - rightPadding, zeroY), zeroPaint);

    // Zero Line Label
    _drawText(
      canvas,
      isSwahili ? '0% Msawazo (Isotonic)' : '0% Equilibrium Line',
      Offset(size.width - rightPadding - 100, zeroY - 14),
      isDark,
      color: const Color(0xFF0284C7),
      isBold: true,
      fontSize: 9,
    );

    // 3. Axes
    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(leftPadding, topPadding), Offset(leftPadding, topPadding + graphHeight), axisPaint);
    canvas.drawLine(Offset(leftPadding, topPadding + graphHeight), Offset(size.width - rightPadding, topPadding + graphHeight), axisPaint);

    // 4. Best Fit Regression Line
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(mapX(0.0), mapY(samples.first.percentChange));
    final endPoint = Offset(mapX(0.8), mapY(samples.last.percentChange));
    canvas.drawLine(startPoint, endPoint, linePaint);

    // 5. Plotted Sample Points
    for (final sample in samples) {
      final px = mapX(sample.concentration);
      final py = mapY(sample.percentChange);

      final pointFill = Paint()
        ..color = sample.percentChange >= 0 ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;

      final pointBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(px, py), 5.5, pointFill);
      canvas.drawCircle(Offset(px, py), 5.5, pointBorder);

      // Coordinate Label
      final sign = sample.percentChange >= 0 ? '+' : '';
      final coordText = '(${sample.concentration}M, $sign${sample.percentChange.toStringAsFixed(1)}%)';
      final labelY = sample.percentChange >= 0 ? py - 16 : py + 8;
      _drawText(canvas, coordText, Offset(px - 28, labelY), isDark, fontSize: 8.5, isBold: true);
    }

    // 6. Highlighted Isotonic Point Marker (Crossing 0%)
    final isoX = mapX(isotonicPoint);
    final isoY = mapY(0.0);

    final isoMarkerPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final isoBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(isoX, isoY), 7.0, isoMarkerPaint);
    canvas.drawCircle(Offset(isoX, isoY), 7.0, isoBorder);

    _drawText(
      canvas,
      '★ C_iso = ${isotonicPoint.toStringAsFixed(2)}M',
      Offset(isoX - 35, isoY + 10),
      isDark,
      color: const Color(0xFFEF4444),
      isBold: true,
      fontSize: 9.5,
    );

    // X and Y Axis Titles
    _drawText(
      canvas,
      isSwahili ? 'Ukolezi wa Sukari (M)' : 'Sucrose Concentration (M)',
      Offset(size.width / 2 - 40, size.height - 12),
      isDark,
      isBold: true,
      fontSize: 9.5,
    );

    _drawText(
      canvas,
      isSwahili ? '% Mabadiliko' : '% Mass Change',
      const Offset(2, 4),
      isDark,
      isBold: true,
      fontSize: 9.5,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    bool isDark, {
    Color? color,
    bool isBold = false,
    bool isAlignRight = false,
    double fontSize = 9.0,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: isAlignRight ? TextAlign.right : TextAlign.left,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _OsmosisGraphPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isotonicPoint != isotonicPoint;
  }
}
