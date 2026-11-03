import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/osmosis_state.dart';
import 'lab_hand.dart';

/// Interactive Canvas CustomPainter for the Osmosis in Potato Tissues
/// Virtual Laboratory Bench. The student's hand cuts each cylinder with the
/// cork borer, puts it on the balance pan, drops it into its tube and blots
/// it on filter paper ([LabHand]).
class OsmosisBenchPainter extends CustomPainter {
  final OsmosisState state;
  final bool isDark;
  final double animationValue; // 0.0 to 1.0 for water flux pulse
  final LabHandRuns? hands; // keys from [handKeys]

  OsmosisBenchPainter({
    required this.state,
    required this.isDark,
    required this.animationValue,
    this.hands,
  }) : super(repaint: hands);

  /// The values the hands on this bench react to, for [LabHandPaint.watch]:
  /// one flag per sample, so the hand goes to the ones just done.
  static Map<String, Object?> handKeys(OsmosisState s) => {
        'cut': _flags(s, (x) => x.isPrepared),
        'balance': s.balanceOccupiedBySampleId,
        'immerse': _flags(s, (x) => x.isImmersed),
        'blot': _flags(s, (x) => x.isBlotted),
      };

  static String _flags(OsmosisState s, bool Function(PotatoSample) on) => s.samples.map((x) => on(x) ? '1' : '0').join();

  /// The samples whose flag for [key] has just come on.
  List<int> _justDone(String key, String now) {
    final before = hands?.previous(key);
    if (before is! String || before.length != now.length) return const [];
    return [for (int i = 0; i < now.length; i++) if (now[i] == '1' && before[i] == '0') i];
  }

  static const double _hand = 0.55;
  static const double _handGap = 650; // ms between one cylinder and the next

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawLabBackground(canvas, w, h);
    _drawTableBench(canvas, w, h);
    _drawTestTubeRackAndTubes(canvas, w, h);
    _drawDigitalBalance(canvas, w, h);
    _drawCuttingTileOrFilterPaper(canvas, w, h);
    _drawHands(canvas, w, h);
    canvas.restore();
  }

  void _drawHands(Canvas canvas, double w, double h) {
    Offset tileItem(int i) => Offset(w * 0.05 + (i + 1) * (w * 0.90 / 6.0), h * 0.78 + h * 0.18 * 0.65);
    Offset tubeMouth(int i) => Offset(w * 0.05 + (i + 0.8) * (w * 0.58 / (state.samples.length + 0.5)), h * 0.35 - 22);
    // The cork borer pushed down into the potato on the tile.
    final cut = _justDone('cut', _flags(state, (x) => x.isPrepared));
    for (int k = 0; k < cut.length; k++) {
      LabHand.move(canvas, hands?.since('cut'),
          to: tileItem(cut[k]) + const Offset(0, -22), pose: HandPose.grip, scale: _hand, duration: 1100, delay: k * _handGap,
          holding: _corkBorer);
    }
    // A cylinder dropped into its tube of sucrose solution.
    final dropped = _justDone('immerse', _flags(state, (x) => x.isImmersed));
    for (int k = 0; k < dropped.length; k++) {
      LabHand.move(canvas, hands?.since('immerse'),
          to: tubeMouth(dropped[k]), rotate: 180, scale: _hand, duration: 1100, delay: k * _handGap,
          holding: (c) => c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 2, 10, 16), const Radius.circular(3)),
              Paint()..color = const Color(0xFFF59E0B)));
    }
    // Each cylinder pressed dry between filter paper, the finger coming in
    // from the side so it shows above the bench edge and off the rack.
    final blotted = _justDone('blot', _flags(state, (x) => x.isBlotted));
    for (int k = 0; k < blotted.length; k++) {
      LabHand.move(canvas, hands?.since('blot'),
          from: tileItem(blotted[k]) + const Offset(30, -4), to: tileItem(blotted[k]) + const Offset(4, 0),
          pose: HandPose.point, rotate: -90, scale: _hand, duration: 1000, delay: k * _handGap);
    }
  }

  /// A brass cork borer: T-handle above the fist, the cutting tube below it.
  void _corkBorer(Canvas c) {
    final metal = Paint()..color = const Color(0xFFB08D3C);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -30, 22, 5), const Radius.circular(2)), metal);
    c.drawRect(const Rect.fromLTWH(-3, -26, 6, 50), metal);
    c.drawRect(const Rect.fromLTWH(-1.2, -26, 2.4, 50), Paint()..color = const Color(0x66FFFFFF));
  }

  /// 1. Laboratory Environment Background & Grid
  void _drawLabBackground(Canvas canvas, double w, double h) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle wall tile grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  /// 2. Laboratory Table Bench
  void _drawTableBench(Canvas canvas, double w, double h) {
    final benchY = h * 0.70;

    // Bench Surface
    final benchPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, benchY, w, h - benchY));
    canvas.drawRect(Rect.fromLTWH(0, benchY, w, h - benchY), benchPaint);

    // Bench Edge Highlight
    final edgePaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : AppColors.primary).withValues(alpha: 0.4)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, benchY), Offset(w, benchY), edgePaint);
  }

  /// 3. Wooden Test Tube Rack and 5 Boiling Tubes (A to E)
  void _drawTestTubeRackAndTubes(Canvas canvas, double w, double h) {
    final rackLeft = w * 0.05;
    final rackWidth = w * 0.58;
    final rackY = h * 0.35;
    final rackHeight = h * 0.38;

    // Wooden Rack Back Support
    final woodPaint = Paint()
      ..color = isDark ? const Color(0xFF78350F) : const Color(0xFFB45309);
    final woodShadow = Paint()
      ..color = isDark ? const Color(0xFF451A03) : const Color(0xFF92400E);

    // Bottom Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rackLeft - 6, rackY + rackHeight - 12, rackWidth + 12, 16),
        const Radius.circular(4),
      ),
      woodShadow,
    );

    // Intermediate Shelf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rackLeft - 4, rackY + rackHeight * 0.45, rackWidth + 8, 10),
        const Radius.circular(3),
      ),
      woodPaint,
    );

    // Top Shelf with holes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rackLeft - 4, rackY, rackWidth + 8, 10),
        const Radius.circular(3),
      ),
      woodPaint,
    );

    // Side Uprights
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rackLeft - 8, rackY - 4, 8, rackHeight + 6), const Radius.circular(3)),
      woodShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rackLeft + rackWidth, rackY - 4, 8, rackHeight + 6), const Radius.circular(3)),
      woodShadow,
    );

    // 5 Boiling Tubes
    final tubeCount = state.samples.length;
    final tubeSpacing = rackWidth / (tubeCount + 0.5);

    // a cylinder that has just been dropped in shows once its hand lets go
    final dropped = _justDone('immerse', _flags(state, (x) => x.isImmersed));
    for (int i = 0; i < tubeCount; i++) {
      final sample = state.samples[i];
      final k = dropped.indexOf(i);
      final tubeCenterX = rackLeft + (i + 0.8) * tubeSpacing;
      final tubeWidth = 24.0;
      final tubeTopY = rackY - 20;
      final tubeBottomY = rackY + rackHeight - 10;
      final tubeHeight = tubeBottomY - tubeTopY;

      _drawSingleBoilingTube(
        canvas: canvas,
        centerX: tubeCenterX,
        topY: tubeTopY,
        width: tubeWidth,
        height: tubeHeight,
        sample: sample,
        isSelected: i == state.activeSampleIndex,
        cylinderShown: k < 0 ? 1 : LabHand.appear(hands?.since('immerse'), k * _handGap + 500),
      );
    }
  }

  /// Draw an individual boiling tube with meniscus, liquid tint, potato cylinder, and flux animation
  void _drawSingleBoilingTube({
    required Canvas canvas,
    required double centerX,
    required double topY,
    required double width,
    required double height,
    required PotatoSample sample,
    required bool isSelected,
    double cylinderShown = 1,
  }) {
    final rect = Rect.fromLTWH(centerX - width / 2, topY, width, height);
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(width / 2),
      bottomRight: Radius.circular(width / 2),
      topLeft: const Radius.circular(2),
      topRight: const Radius.circular(2),
    );

    // Liquid Colors based on sucrose concentration
    final liquidTopY = topY + height * 0.35;
    final liquidHeight = height * 0.65;
    final liquidRect = Rect.fromLTWH(centerX - width / 2 + 1.5, liquidTopY, width - 3, liquidHeight);
    final liquidRRect = RRect.fromRectAndCorners(
      liquidRect,
      bottomLeft: Radius.circular(width / 2 - 1.5),
      bottomRight: Radius.circular(width / 2 - 1.5),
    );

    // Color gradient for solution
    Color topCol, botCol;
    if (sample.concentration == 0.0) {
      topCol = const Color(0x6638BDF8); // Distilled water
      botCol = const Color(0x990284C7);
    } else if (sample.concentration <= 0.2) {
      topCol = const Color(0x6606B6D4); // Dilute sucrose
      botCol = const Color(0x990891B2);
    } else if (sample.concentration <= 0.4) {
      topCol = const Color(0x6610B981); // Near isotonic
      botCol = const Color(0x99059669);
    } else if (sample.concentration <= 0.6) {
      topCol = const Color(0x66F59E0B); // Concentrated sucrose
      botCol = const Color(0x99D97706);
    } else {
      topCol = const Color(0x66F97316); // High sucrose
      botCol = const Color(0x99EA580C);
    }

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        colors: [topCol, botCol],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(liquidRect);
    canvas.drawRRect(liquidRRect, liquidPaint);

    // Liquid Meniscus curve
    final meniscusPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.blueGrey).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, liquidTopY), width: width - 3, height: 6),
      0,
      math.pi,
      false,
      meniscusPaint,
    );

    // Potato cylinder inside the tube if immersed
    if (sample.isImmersed && cylinderShown > 0) {
      if (cylinderShown < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, cylinderShown));
      final cylinderWidth = (sample.concentration <= 0.2 ? 14.0 : (sample.concentration >= 0.6 ? 9.0 : 11.5));
      final cylinderHeight = (sample.concentration <= 0.2 ? 34.0 : (sample.concentration >= 0.6 ? 26.0 : 30.0));
      final cylinderCenterY = liquidTopY + liquidHeight * 0.55;

      final potatoRect = Rect.fromCenter(
        center: Offset(centerX, cylinderCenterY),
        width: cylinderWidth,
        height: cylinderHeight,
      );

      final potatoPaint = Paint()
        ..shader = LinearGradient(
          colors: sample.concentration <= 0.2
              ? [const Color(0xFFFDE68A), const Color(0xFFD97706)] // Turgid pale gold
              : (sample.concentration >= 0.6
                  ? [const Color(0xFFB45309), const Color(0xFF78350F)] // Plasmolysed amber
                  : [const Color(0xFFFCD34D), const Color(0xFFB45309)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(potatoRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(potatoRect, const Radius.circular(3)),
        potatoPaint,
      );

      // Water Flux Animated Arrows during Incubation or Immersion
      if (state.isIncubating || sample.isImmersed) {
        _drawOsmoticFluxArrows(canvas, centerX, cylinderCenterY, cylinderWidth, sample.concentration);
      }
      if (cylinderShown < 1) canvas.restore();
    }

    // Glass Tube Outline & Highlights
    final glassPaint = Paint()
      ..color = isSelected
          ? const Color(0xFF38BDF8)
          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    canvas.drawRRect(rrect, glassPaint);

    // Glass Rim Lip
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, topY), width: width + 4, height: 4), const Radius.circular(2)),
      glassPaint,
    );

    // Glass Shininess Reflection streak
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(centerX - width / 3, topY + 8), Offset(centerX - width / 3, topY + height - 12), shinePaint);

    // Tube Identification Label Badge
    _drawTubeLabelBadge(canvas, centerX, topY + height + 6, sample, isSelected);
  }

  /// Animated arrows illustrating net direction of osmotic water movement
  void _drawOsmoticFluxArrows(Canvas canvas, double cx, double cy, double cylinderW, double conc) {
    final arrowPaint = Paint()
      ..color = conc <= 0.2 ? const Color(0xFF38BDF8) : (conc >= 0.6 ? const Color(0xFFEF4444) : const Color(0xFF10B981))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pulse = math.sin(animationValue * 2 * math.pi) * 3;

    if (conc <= 0.2) {
      // Net Endosmosis: Water moves IN from solution to potato tissue
      final leftX = cx - cylinderW / 2 - 5 - pulse;
      final rightX = cx + cylinderW / 2 + 5 + pulse;
      canvas.drawLine(Offset(leftX, cy), Offset(cx - cylinderW / 2 + 1, cy), arrowPaint);
      canvas.drawLine(Offset(rightX, cy), Offset(cx + cylinderW / 2 - 1, cy), arrowPaint);
    } else if (conc >= 0.6) {
      // Net Exosmosis: Water moves OUT from potato tissue to hypertonic solution
      final leftX = cx - cylinderW / 2 - 6 - pulse;
      final rightX = cx + cylinderW / 2 + 6 + pulse;
      canvas.drawLine(Offset(cx - cylinderW / 2 + 1, cy), Offset(leftX, cy), arrowPaint);
      canvas.drawLine(Offset(cx + cylinderW / 2 - 1, cy), Offset(rightX, cy), arrowPaint);
    } else {
      // Near Isotonic equilibrium: Small bidirectional flux
      canvas.drawLine(Offset(cx - 3, cy - 6), Offset(cx + 3, cy - 6), arrowPaint);
      canvas.drawLine(Offset(cx + 3, cy + 6), Offset(cx - 3, cy + 6), arrowPaint);
    }
  }

  /// Tube Identification Badge (e.g. A: 0.0M)
  void _drawTubeLabelBadge(Canvas canvas, double cx, double y, PotatoSample sample, bool isSelected) {
    final textSpan = TextSpan(
      text: '${sample.id}\n${sample.concentration}M',
      style: TextStyle(
        color: isSelected ? const Color(0xFF38BDF8) : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
        fontSize: 9,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        height: 1.1,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, y));
  }

  /// 4. Digital Electronic Balance (Right Side)
  void _drawDigitalBalance(Canvas canvas, double w, double h) {
    final balanceX = w * 0.68;
    final balanceY = h * 0.42;
    final balanceW = w * 0.28;
    final balanceH = h * 0.32;

    // Balance Body Casing
    final bodyRect = Rect.fromLTWH(balanceX, balanceY, balanceW, balanceH);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect);

    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)), bodyPaint);

    final borderPaint = Paint()
      ..color = (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)), borderPaint);

    // Stainless Steel Pan
    final panW = balanceW * 0.75;
    final panH = 8.0;
    final panRect = Rect.fromCenter(center: Offset(balanceX + balanceW / 2, balanceY - 2), width: panW, height: panH);
    final panPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark ? [const Color(0xFF94A3B8), const Color(0xFF64748B)] : [Colors.white, const Color(0xFF94A3B8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(panRect);
    canvas.drawRRect(RRect.fromRectAndRadius(panRect, const Radius.circular(3)), panPaint);

    // Potato cylinder on balance pan if occupied
    if (state.balanceOccupiedBySampleId != null) {
      final potatoRect = Rect.fromCenter(
        center: Offset(balanceX + balanceW / 2, balanceY - 14),
        width: 14,
        height: 20,
      );
      final potatoPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFB45309)],
        ).createShader(potatoRect);
      // put on the pan by the hand
      LabHand.carry(canvas, hands?.since('balance'),
          offset: Offset(-w * 0.22, -24), grip: potatoRect.topCenter, pose: HandPose.pinch, rotate: 180, scale: _hand,
          draw: () => canvas.drawRRect(RRect.fromRectAndRadius(potatoRect, const Radius.circular(3)), potatoPaint));
    }

    // LCD Display Window (Glowing Blue / Dark Slate)
    final lcdRect = Rect.fromLTWH(balanceX + 10, balanceY + balanceH * 0.35, balanceW - 20, balanceH * 0.40);
    final lcdPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFF0C4A6E);
    canvas.drawRRect(RRect.fromRectAndRadius(lcdRect, const Radius.circular(4)), lcdPaint);

    // Live LCD Mass Text
    final displayMass = state.balanceDisplay.toStringAsFixed(2);
    final lcdText = TextSpan(
      text: '$displayMass g',
      style: const TextStyle(
        color: Color(0xFF38BDF8),
        fontSize: 14,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
      ),
    );
    final lcdPainter = TextPainter(
      text: lcdText,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    lcdPainter.layout();
    lcdPainter.paint(canvas, Offset(balanceX + balanceW / 2 - lcdPainter.width / 2, balanceY + balanceH * 0.45));

    // Balance Brand Label
    final brandSpan = TextSpan(
      text: 'DIGITAL PRECISION 0.01g',
      style: TextStyle(
        color: isDark ? Colors.white38 : const Color(0xFF64748B),
        fontSize: 6.5,
        fontWeight: FontWeight.w700,
      ),
    );
    final brandPainter = TextPainter(text: brandSpan, textDirection: TextDirection.ltr);
    brandPainter.layout();
    brandPainter.paint(canvas, Offset(balanceX + balanceW / 2 - brandPainter.width / 2, balanceY + balanceH * 0.15));
  }

  /// 5. Cutting Tile or Filter Paper Station
  void _drawCuttingTileOrFilterPaper(Canvas canvas, double w, double h) {
    final tileX = w * 0.05;
    final tileY = h * 0.78;
    final tileW = w * 0.90;
    final tileH = h * 0.18;

    final isStep5 = state.step == OsmosisStep.blotFinalWeighing;

    // Station Container
    final stationRect = Rect.fromLTWH(tileX, tileY, tileW, tileH);
    final stationPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(stationRect, const Radius.circular(8)), stationPaint);

    final stationBorder = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(stationRect, const Radius.circular(8)), stationBorder);

    // Station Header
    final title = isStep5 ? '📄 Filter Paper Blotting Station' : '🔪 Ceramic Cutting Tile & Cork Borer';
    final span = TextSpan(
      text: title,
      style: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(tileX + 12, tileY + 6));

    // 5 Cylinder Prep/Blot indicators
    final itemSpacing = tileW / 6.0;
    for (int i = 0; i < state.samples.length; i++) {
      final sample = state.samples[i];
      final itemCX = tileX + (i + 1) * itemSpacing;
      final itemCY = tileY + tileH * 0.65;

      // Miniature potato strip
      final isDone = isStep5 ? sample.isBlotted : sample.isPrepared;
      final col = isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

      final pRect = Rect.fromCenter(center: Offset(itemCX, itemCY), width: 14, height: 18);
      final pPaint = Paint()..color = col;
      canvas.drawRRect(RRect.fromRectAndRadius(pRect, const Radius.circular(3)), pPaint);

      // Label under strip
      final labelSpan = TextSpan(
        text: sample.id,
        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
      );
      final lp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr);
      lp.layout();
      lp.paint(canvas, Offset(itemCX - lp.width / 2, itemCY - lp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant OsmosisBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
