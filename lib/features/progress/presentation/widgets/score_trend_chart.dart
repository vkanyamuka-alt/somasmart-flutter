import 'package:flutter/material.dart';
import 'package:somasmart_flutter/core/theme/app_colors.dart';
import 'package:somasmart_flutter/features/practice/domain/models/quiz_models.dart';

/// Score Trend Line Chart Widget.
/// Faithfully reproduces React `renderScoreChart` SVG plotting logic:
/// - Horizontal grid lines at 20%, 40%, 60%, 80%, 100%
/// - Proportional X/Y coordinate placement
/// - Shaded area below the line
/// - Smooth connected polyline with circular point markers and score badges
/// - Start/end quiz legend
class ScoreTrendChart extends StatelessWidget {
  final List<QuizAttemptModel> attempts;
  final String lang;

  const ScoreTrendChart({
    super.key,
    required this.attempts,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (attempts.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 38,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 10),
            Text(
              lang == 'sw'
                  ? 'Fanya quiz ili kuanza kuona chati hapa.'
                  : 'Take a quiz to start plotting scores here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScoreChartPainter(
              attempts: attempts,
              isDark: isDark,
              lineColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang == 'sw'
                    ? 'Jaribio la Kwanza'
                    : 'First Quiz',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              Text(
                lang == 'sw'
                    ? 'Hivi Karibuni'
                    : 'Latest Quiz',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<QuizAttemptModel> attempts;
  final bool isDark;
  final Color lineColor;

  _ScoreChartPainter({
    required this.attempts,
    required this.isDark,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 36.0;
    const double rightPadding = 20.0;
    const double topPadding = 20.0;
    const double bottomPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
    );

    // 1. Draw horizontal grid lines and Y-axis labels at 20, 40, 60, 80, 100
    const yLevels = [20, 40, 60, 80, 100];
    for (final level in yLevels) {
      final yPos = topPadding + chartHeight - (level / 100.0) * chartHeight;

      // Draw dashed horizontal line
      _drawDashedLine(
        canvas,
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      // Draw Y label
      final textSpan = TextSpan(text: '$level%', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, yPos - textPainter.height / 2),
      );
    }

    // 2. Compute Points
    final count = attempts.length;
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final score = attempts[i].score.clamp(0.0, 100.0);
      final x = count == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i / (count - 1)) * chartWidth;
      final y = topPadding + chartHeight - (score / 100.0) * chartHeight;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // 3. Draw Shaded Area Under Line
    if (points.length > 1) {
      final areaPath = Path();
      areaPath.moveTo(points.first.dx, topPadding + chartHeight);
      areaPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }

      areaPath.lineTo(points.last.dx, topPadding + chartHeight);
      areaPath.close();

      final fillPaint = Paint()
        ..color = lineColor.withValues(alpha: isDark ? 0.15 : 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, fillPaint);
    }

    // 4. Draw Polyline
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 5. Draw Markers and Score text badges
    final markerFillPaint = Paint()
      ..color = isDark ? AppColors.darkBgSurface : Colors.white
      ..style = PaintingStyle.fill;

    final markerStrokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final score = attempts[i].score.round();

      // Outer border circle
      canvas.drawCircle(pt, 5.0, markerFillPaint);
      canvas.drawCircle(pt, 5.0, markerStrokePaint);

      // Score label above dot
      final scoreSpan = TextSpan(
        text: '$score%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      );
      final scorePainter = TextPainter(
        text: scoreSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      scorePainter.paint(
        canvas,
        Offset(pt.dx - scorePainter.width / 2, pt.dy - scorePainter.height - 6),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      final endX = (startX + dashWidth).clamp(p1.dx, p2.dx);
      canvas.drawLine(Offset(startX, p1.dy), Offset(endX, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) {
    return oldDelegate.attempts != attempts ||
        oldDelegate.isDark != isDark ||
        oldDelegate.lineColor != lineColor;
  }
}
