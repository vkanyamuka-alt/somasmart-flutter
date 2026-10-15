import 'package:flutter/material.dart';

/// Renders a high-clarity academic tablet illustration displaying an educational
/// plant cell diagram with clean vector geometry, anatomical labels, and O-level Biology header.
class PlantCellTabletWidget extends StatelessWidget {
  final double? width;
  final double? height;

  const PlantCellTabletWidget({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Tablet Kickstand (behind on the right)
          Positioned(
            right: 0,
            bottom: 4,
            top: 24,
            width: 14,
            child: Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()..setEntry(1, 0, -0.15),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Tablet Body
          Positioned(
            left: 2,
            right: 10,
            top: 2,
            bottom: 2,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark Slate/Charcoal Bezel
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Tablet Screen Mini Top Bar: "← O-level   ✦ Biology   ···"
                      Container(
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 0.7,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 8,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 2),
                            Text(
                              'O-level',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                                height: 1,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.auto_awesome,
                              size: 6.5,
                              color: Color(0xFF0058BE),
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Biology',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0058BE),
                                height: 1,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '···',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                                height: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Plant Cell Diagram Canvas
                      const Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _PlantCellDiagramPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the academic Plant Cell diagram with labels
class _PlantCellDiagramPainter extends CustomPainter {
  const _PlantCellDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Center area for the cell body
    final cellCenter = Offset(w * 0.52, h * 0.52);
    final cellRadiusX = w * 0.22;
    final cellRadiusY = h * 0.36;

    // 1. Draw Cytoplasm & Cell Wall (Polygonal rounded shape)
    final cellPath = Path();
    final points = [
      Offset(cellCenter.dx - cellRadiusX * 0.95, cellCenter.dy - cellRadiusY * 0.75),
      Offset(cellCenter.dx - cellRadiusX * 0.2, cellCenter.dy - cellRadiusY * 1.0),
      Offset(cellCenter.dx + cellRadiusX * 0.8, cellCenter.dy - cellRadiusY * 0.85),
      Offset(cellCenter.dx + cellRadiusX * 1.0, cellCenter.dy + cellRadiusY * 0.2),
      Offset(cellCenter.dx + cellRadiusX * 0.7, cellCenter.dy + cellRadiusY * 0.95),
      Offset(cellCenter.dx - cellRadiusX * 0.3, cellCenter.dy + cellRadiusY * 1.0),
      Offset(cellCenter.dx - cellRadiusX * 1.0, cellCenter.dy + cellRadiusY * 0.6),
    ];

    cellPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      cellPath.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    cellPath.close();

    // Fill Cytoplasm
    final cytoplasmPaint = Paint()
      ..color = const Color(0xFFF0FDF4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cellPath, cytoplasmPaint);

    // Thick Outer Cell Wall
    final cellWallPaint = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(cellPath, cellWallPaint);

    // Inner Cell Membrane Border
    final cellMembranePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(cellPath, cellMembranePaint);

    // 2. Large Central Vacuole (pale blue)
    final vacuolePath = Path();
    final vCenter = Offset(cellCenter.dx - cellRadiusX * 0.2, cellCenter.dy + cellRadiusY * 0.1);
    final vPoints = [
      Offset(vCenter.dx - cellRadiusX * 0.45, vCenter.dy - cellRadiusY * 0.5),
      Offset(vCenter.dx + cellRadiusX * 0.15, vCenter.dy - cellRadiusY * 0.6),
      Offset(vCenter.dx + cellRadiusX * 0.4, vCenter.dy - cellRadiusY * 0.1),
      Offset(vCenter.dx + cellRadiusX * 0.3, vCenter.dy + cellRadiusY * 0.6),
      Offset(vCenter.dx - cellRadiusX * 0.35, vCenter.dy + cellRadiusY * 0.55),
    ];
    vacuolePath.moveTo(vPoints[0].dx, vPoints[0].dy);
    for (int i = 0; i < vPoints.length; i++) {
      final p1 = vPoints[i];
      final p2 = vPoints[(i + 1) % vPoints.length];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      vacuolePath.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    vacuolePath.close();

    final vacuolePaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;
    final vacuoleBorderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(vacuolePath, vacuolePaint);
    canvas.drawPath(vacuolePath, vacuoleBorderPaint);

    // 3. Nucleus (Purple Spherical with darker nucleolus)
    final nucleusCenter = Offset(cellCenter.dx + cellRadiusX * 0.45, cellCenter.dy - cellRadiusY * 0.25);
    final nucleusRadius = cellRadiusX * 0.32;

    final nucleusPaint = Paint()
      ..color = const Color(0xFFDDD6FE)
      ..style = PaintingStyle.fill;
    final nucleusBorderPaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(nucleusCenter, nucleusRadius, nucleusPaint);
    canvas.drawCircle(nucleusCenter, nucleusRadius, nucleusBorderPaint);

    // Nucleolus
    final nucleolusPaint = Paint()
      ..color = const Color(0xFF7E22CE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(nucleusCenter.dx - 1.5, nucleusCenter.dy + 1),
      nucleusRadius * 0.42,
      nucleolusPaint,
    );

    // 4. Chloroplasts (Green ovals with inner grana lines)
    _drawChloroplast(canvas, Offset(cellCenter.dx - cellRadiusX * 0.65, cellCenter.dy - cellRadiusY * 0.4), 0.3);
    _drawChloroplast(canvas, Offset(cellCenter.dx - cellRadiusX * 0.55, cellCenter.dy + cellRadiusY * 0.55), -0.2);
    _drawChloroplast(canvas, Offset(cellCenter.dx + cellRadiusX * 0.5, cellCenter.dy + cellRadiusY * 0.65), 0.5);

    // 5. Mitochondria (Orange/Amber sausage shape with cristae)
    _drawMitochondrion(canvas, Offset(cellCenter.dx + cellRadiusX * 0.55, cellCenter.dy + cellRadiusY * 0.15), -0.4);

    // 6. Educational Scientific Labels with Pointer Lines
    _drawCallout(
      canvas: canvas,
      target: Offset(cellCenter.dx - cellRadiusX * 0.88, cellCenter.dy - cellRadiusY * 0.6),
      text: 'Cell wall',
      isLeft: true,
      textOffset: Offset(w * 0.04, h * 0.20),
    );

    _drawCallout(
      canvas: canvas,
      target: Offset(cellCenter.dx - cellRadiusX * 0.82, cellCenter.dy - cellRadiusY * 0.2),
      text: 'Cell membrane',
      isLeft: true,
      textOffset: Offset(w * 0.04, h * 0.38),
    );

    _drawCallout(
      canvas: canvas,
      target: Offset(cellCenter.dx - cellRadiusX * 0.4, cellCenter.dy - cellRadiusY * 0.2),
      text: 'Cytoplasm',
      isLeft: true,
      textOffset: Offset(w * 0.04, h * 0.56),
    );

    _drawCallout(
      canvas: canvas,
      target: Offset(cellCenter.dx - cellRadiusX * 0.55, cellCenter.dy + cellRadiusY * 0.55),
      text: 'Chloroplast',
      isLeft: true,
      textOffset: Offset(w * 0.04, h * 0.74),
    );

    _drawCallout(
      canvas: canvas,
      target: nucleusCenter,
      text: 'Nucleus',
      isLeft: false,
      textOffset: Offset(w * 0.96, h * 0.22),
    );

    _drawCallout(
      canvas: canvas,
      target: Offset(vCenter.dx + cellRadiusX * 0.2, vCenter.dy + cellRadiusY * 0.2),
      text: 'Vacuole',
      isLeft: false,
      textOffset: Offset(w * 0.96, h * 0.46),
    );

    _drawCallout(
      canvas: canvas,
      target: Offset(cellCenter.dx + cellRadiusX * 0.55, cellCenter.dy + cellRadiusY * 0.15),
      text: 'Mitochondrion',
      isLeft: false,
      textOffset: Offset(w * 0.96, h * 0.72),
    );
  }

  void _drawChloroplast(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final bgPaint = Paint()
      ..color = const Color(0xFFBBF7D0)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final rect = Rect.fromCenter(center: Offset.zero, width: 13, height: 7);
    canvas.drawOval(rect, bgPaint);
    canvas.drawOval(rect, strokePaint);

    // Internal grana lines
    final linePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawLine(const Offset(-3, -2), const Offset(-3, 2), linePaint);
    canvas.drawLine(const Offset(0, -2.5), const Offset(0, 2.5), linePaint);
    canvas.drawLine(const Offset(3, -2), const Offset(3, 2), linePaint);

    canvas.restore();
  }

  void _drawMitochondrion(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final bgPaint = Paint()
      ..color = const Color(0xFFFED7AA)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final rect = Rect.fromCenter(center: Offset.zero, width: 12, height: 6.5);
    canvas.drawOval(rect, bgPaint);
    canvas.drawOval(rect, strokePaint);

    // Folded cristae inner lines
    final cristaePaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final cristaePath = Path()
      ..moveTo(-3.5, 0)
      ..lineTo(-2, -1.5)
      ..lineTo(0, 1.5)
      ..lineTo(2, -1.5)
      ..lineTo(3.5, 0);
    canvas.drawPath(cristaePath, cristaePaint);

    canvas.restore();
  }

  void _drawCallout({
    required Canvas canvas,
    required Offset target,
    required String text,
    required bool isLeft,
    required Offset textOffset,
  }) {
    // 1. Render text with TextPainter to measure width
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 5.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
        fontFamily: 'Roboto',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textPos = isLeft
        ? Offset(textOffset.dx, textOffset.dy - textPainter.height / 2)
        : Offset(textOffset.dx - textPainter.width, textOffset.dy - textPainter.height / 2);

    textPainter.paint(canvas, textPos);

    // 2. Draw pointer line
    final linePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final lineStart = isLeft
        ? Offset(textPos.dx + textPainter.width + 1.5, textOffset.dy)
        : Offset(textPos.dx - 1.5, textOffset.dy);

    final elbow = Offset(
      isLeft ? lineStart.dx + (target.dx - lineStart.dx) * 0.4 : lineStart.dx - (lineStart.dx - target.dx) * 0.4,
      lineStart.dy,
    );

    final linePath = Path()
      ..moveTo(lineStart.dx, lineStart.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(target.dx, target.dy);

    canvas.drawPath(linePath, linePaint);

    // Small dot at target
    final dotPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(target, 0.9, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PlantCellDiagramPainter oldDelegate) => false;
}
