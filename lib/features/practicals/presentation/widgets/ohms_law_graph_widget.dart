import 'package:flutter/material.dart';
import '../../data/models/ohms_law_state.dart';
import '../../domain/ohms_law_engine.dart';

class OhmsLawGraphWidget extends StatelessWidget {
  final List<CircuitReading> readings;
  final bool isDarkMode;
  final bool isKiswahili;

  const OhmsLawGraphWidget({
    super.key,
    required this.readings,
    required this.isDarkMode,
    required this.isKiswahili,
  });

  @override
  Widget build(BuildContext context) {
    final slope = OhmsLawEngine.calculateExperimentalSlope(readings);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isKiswahili ? 'Grafu: Volteji (V) dhidi ya Mkondo (I)' : 'Graph: Voltage (V) against Current (I)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    readings.length >= 2
                        ? 'Slope (R) = ${slope.toStringAsFixed(2)} Ω'
                        : (isKiswahili ? 'Pima pointi ≥ 2' : 'Need ≥ 2 points'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(
                painter: _GraphPainter(
                  readings: readings,
                  isDarkMode: isDarkMode,
                  slope: slope,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  isKiswahili
                      ? 'Mteremko wa mstari mnyofu: Gradient = ΔV / ΔI = Kikinza R (10.0 Ω)'
                      : 'Straight line gradient: Slope = ΔV / ΔI = Resistance R (10.0 Ω)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<CircuitReading> readings;
  final bool isDarkMode;
  final double slope;

  _GraphPainter({
    required this.readings,
    required this.isDarkMode,
    required this.slope,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 40.0;
    const double paddingBottom = 30.0;
    const double paddingTop = 15.0;
    const double paddingRight = 15.0;

    final plotWidth = size.width - paddingLeft - paddingRight;
    final plotHeight = size.height - paddingBottom - paddingTop;

    // Max bounds for plotting: Max Current = 0.6 A, Max Voltage = 6.0 V
    const maxI = 0.6;
    const maxV = 6.0;

    // 1. Draw Grid Lines
    final gridPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 6; i++) {
      // Horizontal grid lines (Voltage)
      final y = paddingTop + plotHeight - (i / 6.0) * plotHeight;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Y-axis label (V)
      final tpV = TextPainter(
        text: TextSpan(
          text: '${i}V',
          style: TextStyle(
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tpV.layout();
      tpV.paint(canvas, Offset(paddingLeft - tpV.width - 6, y - tpV.height / 2));
    }

    for (int j = 0; j <= 6; j++) {
      // Vertical grid lines (Current)
      final x = paddingLeft + (j / 6.0) * plotWidth;
      canvas.drawLine(Offset(x, paddingTop), Offset(x, size.height - paddingBottom), gridPaint);

      // X-axis label (I)
      final currentVal = (j * 0.1).toStringAsFixed(1);
      final tpI = TextPainter(
        text: TextSpan(
          text: '${currentVal}A',
          style: TextStyle(
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tpI.layout();
      tpI.paint(canvas, Offset(x - tpI.width / 2, size.height - paddingBottom + 6));
    }

    // 2. Draw Axes
    final axisPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Y Axis
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, size.height - paddingBottom),
      axisPaint,
    );

    // X Axis
    canvas.drawLine(
      Offset(paddingLeft, size.height - paddingBottom),
      Offset(size.width - paddingRight, size.height - paddingBottom),
      axisPaint,
    );

    // 3. Draw Best-Fit Linear Regression Line if at least 2 readings
    if (readings.length >= 2) {
      final linePaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final startX = paddingLeft;
      final startY = size.height - paddingBottom; // Origin (0, 0)

      final endI = maxI;
      final endV = (endI * slope).clamp(0.0, maxV);
      final endX = paddingLeft + (endI / maxI) * plotWidth;
      final endY = paddingTop + plotHeight - (endV / maxV) * plotHeight;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    // 4. Draw Measured Data Points
    final pointPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;

    final pointGlow = Paint()
      ..color = const Color(0x66E11D48)
      ..style = PaintingStyle.fill;

    for (final r in readings) {
      final x = paddingLeft + (r.current / maxI).clamp(0.0, 1.0) * plotWidth;
      final y = paddingTop + plotHeight - (r.voltage / maxV).clamp(0.0, 1.0) * plotHeight;

      canvas.drawCircle(Offset(x, y), 7, pointGlow);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.readings != readings ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.slope != slope;
  }
}
