import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/titration_state.dart';

/// The titration bench, drawn like the lab welcome table and the website's
/// bench: glass with reflections, a metal retort stand, labelled reagent
/// bottles and a white tile, on a light lab table under a tiled wall.
///
/// The bench is laid out in a 700 x 380 box, scaled evenly to fit and sat on
/// the bottom of the canvas; the wall and the table run the full width.
class TitrationBenchPainter extends CustomPainter {
  final TitrationState state;
  final bool isDark;
  final double animationValue;

  TitrationBenchPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 0.0,
  });

  static const double _buretteX = 352;
  static const double _buretteTop = 42; // liquid surface at 0.00 mL
  static const double _buretteScale = 140 / 50; // px per mL
  static const double _buretteBottom = 192;
  static const double _jetTip = 226;

  static const Color _naoh = Color(0xD9BADCF5);
  static const Color _hcl = Color(0xCCFDE6AA);
  static const Color _glassEdge = Color(0xFF86A0B6);
  static const Color _ink = Color(0xFF1F2933);

  static const List<Color> _glassColors = [
    Color(0xBFDCEBF7),
    Color(0xD9FFFFFF),
    Color(0x59CFE3F3),
    Color(0x8CFFFFFF),
    Color(0xB3B9D3E8),
  ];
  static const List<double> _glassStops = [0, 0.18, 0.45, 0.85, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 700.0, size.height / 380.0);
    final dx = (size.width - 700 * scale) / 2;
    final dy = size.height - 380 * scale;

    _drawWall(canvas, size, scale);

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    // The table reaches both edges of the canvas, past the 700-wide box.
    _drawTable(canvas, -dx / scale, (size.width - dx) / scale);
    _drawReagentBottles(canvas);
    _drawRetortStand(canvas);
    _drawBurette(canvas);
    _drawConicalFlask(canvas);
    _drawDelivery(canvas);
    _drawIndicatorDropper(canvas);
    _drawPipette(canvas);
    _drawWasteBeaker(canvas);
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Shared paints
  // ---------------------------------------------------------------------------

  Paint _glass(Rect r) => Paint()
    ..shader = const LinearGradient(colors: _glassColors, stops: _glassStops).createShader(r);

  Paint _metal(Rect r) => Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF6E7B88), Color(0xFFEEF2F5), Color(0xFFA3AEB9), Color(0xFF55616D)],
      stops: [0, 0.3, 0.6, 1],
    ).createShader(r);

  Paint _metalV(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEEF2F5), Color(0xFFA3AEB9), Color(0xFF5F6B77)],
    ).createShader(r);

  Paint _iron(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4A5562), Color(0xFF1F2731)],
    ).createShader(r);

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..style = PaintingStyle.stroke;

  void _shadow(Canvas canvas, Offset c, double rx, double ry) {
    final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      r,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x4D0B1A2A), Color(0x000B1A2A)]).createShader(r),
    );
  }

  void _text(Canvas canvas, String s, Offset center, double size, Color color, {FontWeight weight = FontWeight.w700}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ---------------------------------------------------------------------------
  // Room
  // ---------------------------------------------------------------------------

  void _drawWall(Canvas canvas, Size size, double scale) {
    final line = Paint()
      ..color = isDark ? const Color(0x1294A3B8) : const Color(0x10184E78)
      ..strokeWidth = 1;
    final step = 26 * scale;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  void _drawTable(Canvas canvas, double left, double right) {
    final top = Rect.fromLTRB(left, 318, right, 342);
    canvas.drawRect(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F6F9), Color(0xFFD2DBE4)],
        ).createShader(top),
    );
    canvas.drawRect(Rect.fromLTRB(left, 318, right, 319.5), Paint()..color = const Color(0xE6FFFFFF));
    final edge = Rect.fromLTRB(left, 342, right, 380);
    canvas.drawRect(
      edge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DAEBF), Color(0xFF6F8399)],
        ).createShader(edge),
    );
  }

  // ---------------------------------------------------------------------------
  // Reagents
  // ---------------------------------------------------------------------------

  void _drawReagentBottles(Canvas canvas) {
    _drawBottle(canvas, x: 40, label: 'NaOH', sub: '0.10 M', stripe: const Color(0xFF2F7FD1), liquid: _naoh);
    _drawBottle(canvas, x: 100, label: 'HCl', sub: 'unknown', stripe: const Color(0xFFE2B13C), liquid: _hcl);
    if (!(state.currentStepIndex == 3 && state.indicatorStep >= 1)) {
      _drawIndicatorBottle(canvas);
    }
  }

  void _drawBottle(Canvas canvas,
      {required double x, required String label, required String sub, required Color stripe, required Color liquid}) {
    canvas.save();
    canvas.translate(x, 236);
    _shadow(canvas, const Offset(21, 82), 26, 3);
    final neck = RRect.fromRectAndRadius(const Rect.fromLTWH(14, -20, 14, 10), const Radius.circular(3));
    canvas.drawRRect(neck, _glass(neck.outerRect));
    canvas.drawRRect(neck, _stroke(const Color(0xFF8EA8BE), 1.2));
    final stopper = RRect.fromRectAndRadius(const Rect.fromLTWH(11, -24, 20, 6), const Radius.circular(3));
    canvas.drawRRect(stopper, Paint()..color = const Color(0xFFE9EEF3));
    canvas.drawRRect(stopper, _stroke(const Color(0xFF8C9BAA), 1));
    final body = Path()
      ..moveTo(14, -10)
      ..lineTo(28, -10)
      ..lineTo(28, -2)
      ..quadraticBezierTo(42, 2, 42, 14)
      ..lineTo(42, 74)
      ..quadraticBezierTo(42, 82, 34, 82)
      ..lineTo(8, 82)
      ..quadraticBezierTo(0, 82, 0, 74)
      ..lineTo(0, 14)
      ..quadraticBezierTo(0, 2, 14, -2)
      ..close();
    canvas.drawPath(body, _glass(const Rect.fromLTWH(0, -10, 42, 92)));
    final fill = Path()
      ..moveTo(2, 30)
      ..lineTo(40, 30)
      ..lineTo(40, 74)
      ..quadraticBezierTo(40, 80, 34, 80)
      ..lineTo(8, 80)
      ..quadraticBezierTo(2, 80, 2, 74)
      ..close();
    canvas.drawPath(fill, Paint()..color = liquid);
    canvas.drawPath(body, _stroke(_glassEdge, 1.5));
    final labelRect = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 34, 34, 28), const Radius.circular(2));
    canvas.drawRRect(labelRect, Paint()..color = const Color(0xFFFDFDFB));
    canvas.drawRRect(labelRect, _stroke(const Color(0xFFC9D2DB), 0.8));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 34, 34, 5), const Radius.circular(1.5)), Paint()..color = stripe);
    _text(canvas, label, const Offset(21, 47), 8.5, _ink);
    _text(canvas, sub, const Offset(21, 56), 6, const Color(0xFF52606D), weight: FontWeight.w400);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 4, 3, 66), const Radius.circular(1.5)),
        Paint()..color = const Color(0xB3FFFFFF));
    canvas.restore();
  }

  void _drawIndicatorBottle(Canvas canvas) {
    canvas.save();
    canvas.translate(166, 256);
    _shadow(canvas, const Offset(13, 62), 18, 2.5);
    final teat = Path()
      ..moveTo(9, -12)
      ..lineTo(9, -22)
      ..quadraticBezierTo(9, -28, 13, -28)
      ..quadraticBezierTo(17, -28, 17, -22)
      ..lineTo(17, -12)
      ..close();
    canvas.drawPath(teat, Paint()..color = const Color(0xFF1F2731));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, -12, 14, 8), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2E3640));
    final body = Path()
      ..moveTo(8, -4)
      ..lineTo(18, -4)
      ..lineTo(18, 2)
      ..quadraticBezierTo(26, 6, 26, 14)
      ..lineTo(26, 56)
      ..quadraticBezierTo(26, 62, 20, 62)
      ..lineTo(6, 62)
      ..quadraticBezierTo(0, 62, 0, 56)
      ..lineTo(0, 14)
      ..quadraticBezierTo(0, 6, 8, 2)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF8A5A1F));
    canvas.drawPath(body, _stroke(const Color(0xFF5C3A12), 1.2));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 22, 20, 22), const Radius.circular(1.5)),
        Paint()..color = const Color(0xFFFDFDFB));
    _text(canvas, 'phenol-', const Offset(13, 29), 5.5, _ink);
    _text(canvas, 'phthalein', const Offset(13, 36), 5.5, _ink);
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Stand, burette and delivery
  // ---------------------------------------------------------------------------

  void _drawRetortStand(Canvas canvas) {
    _shadow(canvas, const Offset(330, 321), 86, 5);
    const base = Rect.fromLTWH(250, 306, 160, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(3)), _iron(base));
    canvas.drawRect(const Rect.fromLTWH(252, 306, 156, 2), Paint()..color = const Color(0xFF6B7784));
    const rod = Rect.fromLTWH(296, 24, 8, 284);
    canvas.drawRRect(RRect.fromRectAndRadius(rod, const Radius.circular(3)), _metal(rod));
    const boss = Rect.fromLTWH(290, 54, 20, 20);
    canvas.drawRRect(RRect.fromRectAndRadius(boss, const Radius.circular(3)), _iron(boss));
    const arm = Rect.fromLTWH(310, 60, 30, 7);
    canvas.drawRRect(RRect.fromRectAndRadius(arm, const Radius.circular(2)), _metalV(arm));
    const clamp = Rect.fromLTWH(336, 52, 32, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(clamp, const Radius.circular(5)), _iron(clamp));
    // White tile under the flask
    final tile = RRect.fromRectAndRadius(const Rect.fromLTWH(306, 300, 92, 6), const Radius.circular(1.5));
    canvas.drawRRect(tile, Paint()..color = Colors.white);
    canvas.drawRRect(tile, _stroke(const Color(0xFFC5D0DA), 1));
  }

  void _drawBurette(Canvas canvas) {
    const tube = Rect.fromLTWH(_buretteX - 8, 30, 16, 166);
    final tubeR = RRect.fromRectAndRadius(tube, const Radius.circular(4));
    canvas.drawRRect(tubeR, _glass(tube));

    final liquidTop = _buretteTop + state.volumeDelivered.clamp(0.0, 50.0) * _buretteScale;
    if (state.buretteFilled && liquidTop < _buretteBottom) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(_buretteX - 6, liquidTop, _buretteX + 6, _buretteBottom + 4), const Radius.circular(1.5)),
        Paint()..color = _naoh,
      );
      final meniscus = Path()
        ..moveTo(_buretteX - 6, liquidTop)
        ..quadraticBezierTo(_buretteX, liquidTop + 3.5, _buretteX + 6, liquidTop);
      canvas.drawPath(meniscus, _stroke(const Color(0xFF5E8FB8), 1.2));
    }
    canvas.drawRRect(tubeR, _stroke(const Color(0xFF8EA8BE), 1.5));

    // Scale: a long mark and number every 10 mL, short marks every 2 mL.
    final major = Paint()
      ..color = const Color(0xFF2E3B48)
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = const Color(0xB32E3B48)
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 25; i++) {
      final y = 45 + i * 5.6;
      if (i % 5 == 0) {
        canvas.drawLine(Offset(_buretteX - 8, y), Offset(_buretteX - 1, y), major);
        final tp = TextPainter(
          text: TextSpan(
            text: '${i * 2}',
            style: TextStyle(fontSize: 8, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(_buretteX - 12 - tp.width, y - tp.height / 2));
      } else {
        canvas.drawLine(Offset(_buretteX - 8, y), Offset(_buretteX - 4, y), minor);
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(_buretteX - 5, 34, 2.5, 158), const Radius.circular(1.2)),
        Paint()..color = const Color(0xBFFFFFFF));

    // The tap (stopcock) and the jet
    const tapBody = Rect.fromLTWH(_buretteX - 9, 196, 18, 14);
    final tapBodyR = RRect.fromRectAndRadius(tapBody, const Radius.circular(3));
    canvas.drawRRect(tapBodyR, _glass(tapBody));
    canvas.drawRRect(tapBodyR, _stroke(const Color(0xFF8EA8BE), 1.5));
    final open = state.stopcockState != StopcockState.closed && state.stopcockState != StopcockState.paused;
    double angle = 0;
    if (state.stopcockState == StopcockState.flow) {
      angle = math.pi / 2;
    } else if (state.stopcockState == StopcockState.slow || state.stopcockState == StopcockState.single) {
      angle = math.pi / 4;
    }
    canvas.save();
    canvas.translate(_buretteX, 203);
    canvas.rotate(angle);
    final handle = RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -3, 32, 6), const Radius.circular(3));
    canvas.drawRRect(handle, Paint()..color = open ? const Color(0xFFBFE0F7) : const Color(0xFFF4F7FA));
    canvas.drawRRect(handle, _stroke(const Color(0xFF8C9BAA), 1));
    canvas.restore();
    final jet = Path()
      ..moveTo(_buretteX - 4, 210)
      ..lineTo(_buretteX - 1.5, _jetTip)
      ..lineTo(_buretteX + 1.5, _jetTip)
      ..lineTo(_buretteX + 4, 210)
      ..close();
    canvas.drawPath(jet, _glass(jet.getBounds()));
    canvas.drawPath(jet, _stroke(const Color(0xFF8EA8BE), 1.2));
  }

  /// Liquid surface in the flask, in the flask's own coordinates (0 to 80).
  double _flaskLevel() => 76 - (math.min(state.flaskVolume, 40.0) / 25) * 30;

  Offset get _flaskOrigin => state.flaskPositioned ? const Offset(312, 220) : const Offset(440, 238);

  void _drawDelivery(Canvas canvas) {
    final surfaceY = _flaskOrigin.dy + _flaskLevel();
    if (state.stopcockState == StopcockState.flow) {
      canvas.drawLine(
        const Offset(_buretteX, _jetTip),
        Offset(_buretteX, surfaceY),
        Paint()
          ..color = _naoh
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    } else if (state.isDropFalling ||
        state.stopcockState == StopcockState.slow ||
        state.stopcockState == StopcockState.single) {
      // A drop falls from the jet to the surface, over and over.
      final t = (animationValue * 3) % 1.0;
      final y = _jetTip + 4 + t * math.max(0.0, surfaceY - _jetTip - 4);
      final drop = Path()
        ..moveTo(_buretteX, y - 5)
        ..quadraticBezierTo(_buretteX + 3.2, y + 0.5, _buretteX, y + 2.5)
        ..quadraticBezierTo(_buretteX - 3.2, y + 0.5, _buretteX, y - 5)
        ..close();
      canvas.drawPath(drop, Paint()..color = _naoh);
      canvas.drawPath(drop, _stroke(const Color(0xFF8EB4D4), 0.8));
    }
  }

  // ---------------------------------------------------------------------------
  // Flask
  // ---------------------------------------------------------------------------

  Path get _flaskPath => Path()
    ..moveTo(33, 0)
    ..lineTo(47, 0)
    ..lineTo(47, 24)
    ..lineTo(73, 66)
    ..quadraticBezierTo(79, 80, 66, 80)
    ..lineTo(14, 80)
    ..quadraticBezierTo(1, 80, 7, 66)
    ..lineTo(33, 24)
    ..close();

  void _drawConicalFlask(Canvas canvas) {
    final origin = _flaskOrigin;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (state.isSwirling) {
      canvas.translate(40, 80);
      canvas.rotate(math.sin(animationValue * math.pi * 6) * 0.08);
      canvas.translate(-40, -80);
    }
    _shadow(canvas, const Offset(40, 81), 40, 3);
    final path = _flaskPath;
    canvas.drawPath(path, _glass(const Rect.fromLTWH(0, 0, 80, 80)));

    if (state.flaskVolume > 0) {
      final level = _flaskLevel();
      canvas.save();
      canvas.clipPath(path);
      final liquid = Rect.fromLTRB(0, level, 80, 82);
      // a faint tint so a colourless solution still shows
      canvas.drawRect(liquid, Paint()..color = const Color(0x59BED4E6));
      canvas.drawRect(liquid, Paint()..color = _flaskColor(state.flaskColorStage));
      canvas.drawRect(Rect.fromLTWH(0, level - 0.5, 80, 1.5), Paint()..color = const Color(0xCC8EA8BE));
      canvas.drawRect(Rect.fromLTWH(0, level + 1, 80, 1.2), Paint()..color = const Color(0x99FFFFFF));
      canvas.restore();
      if (state.flaskRipple) {
        canvas.drawOval(Rect.fromCenter(center: Offset(40, level), width: 28, height: 7), _stroke(const Color(0xFF8EB4D4), 1.5));
      }
    }

    canvas.drawPath(path, _stroke(_glassEdge, 1.8));
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 0), width: 16, height: 4), _stroke(_glassEdge, 1.4));
    canvas.drawLine(
      const Offset(31, 30),
      const Offset(12, 64),
      Paint()
        ..color = const Color(0xB3FFFFFF)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  Color _flaskColor(FlaskColorStage stage) {
    switch (stage) {
      case FlaskColorStage.colourless:
        return const Color(0x44F0F9FF);
      case FlaskColorStage.pinkFlash:
        return const Color(0xAAFBCFE8);
      case FlaskColorStage.permanentPalePink:
        return const Color(0xDDF472B6);
      case FlaskColorStage.darkMagenta:
        return const Color(0xF0DB2777);
    }
  }

  // ---------------------------------------------------------------------------
  // Pipette, dropper and beaker
  // ---------------------------------------------------------------------------

  void _drawPipette(Canvas canvas) {
    if (state.currentStepIndex != 2 || state.pipetteStep < 2) {
      _drawPipetteOnBench(canvas);
      return;
    }
    final overFlask = state.pipetteStep >= 5;
    canvas.save();
    canvas.translate(overFlask ? 470 : 111, 120);

    if (state.isTransferringLiquid && overFlask) {
      canvas.drawLine(
        const Offset(10, 168),
        Offset(10, 118 + _flaskLevel()),
        Paint()
          ..color = _hcl
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Pipette filler (rubber bulb)
    final squeezing = state.isDrawingLiquid;
    final bulb = Rect.fromCenter(center: const Offset(10, 15), width: squeezing ? 16 : 22, height: squeezing ? 30 : 26);
    canvas.drawOval(
      bulb,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFF87171), Color(0xFF991B1B)],
        ).createShader(bulb),
    );
    canvas.drawOval(bulb, _stroke(const Color(0xFF7F1D1D), 1));
    canvas.drawRect(const Rect.fromLTWH(7, 26, 6, 8), Paint()..color = const Color(0xFF55616D));

    final stem = Path()
      ..addRect(const Rect.fromLTWH(7, 34, 6, 40))
      ..moveTo(7, 74)
      ..lineTo(2, 85)
      ..quadraticBezierTo(0, 100, 2, 115)
      ..lineTo(7, 126)
      ..lineTo(7, 162)
      ..lineTo(9, 168)
      ..lineTo(11, 168)
      ..lineTo(13, 162)
      ..lineTo(13, 126)
      ..lineTo(18, 115)
      ..quadraticBezierTo(20, 100, 18, 85)
      ..lineTo(13, 74)
      ..close();
    canvas.drawPath(stem, _glass(const Rect.fromLTWH(0, 34, 20, 134)));

    if (state.pipetteVolume > 0) {
      final level = 165 - (state.pipetteVolume / 25.0).clamp(0.0, 1.0) * 115;
      canvas.save();
      canvas.clipPath(stem);
      canvas.drawRect(Rect.fromLTRB(0, level, 20, 168), Paint()..color = _hcl);
      canvas.restore();
    }
    canvas.drawPath(stem, _stroke(_glassEdge, 1));

    final full = state.pipetteVolume >= 25.0;
    canvas.drawLine(const Offset(5, 50), const Offset(15, 50),
        Paint()
          ..color = full ? const Color(0xFF3D7AB0) : const Color(0xFF55616D)
          ..strokeWidth = full ? 2 : 1.2);
    final tp = TextPainter(
      text: TextSpan(
        text: '25.0 mL',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: full ? const Color(0xFF3D7AB0) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(22, 50 - tp.height / 2));
    canvas.restore();
  }

  void _drawPipetteOnBench(Canvas canvas) {
    canvas.save();
    canvas.translate(528, 300);
    _shadow(canvas, const Offset(54, 17), 56, 2.5);
    final bulb = Rect.fromCenter(center: const Offset(10, 8), width: 22, height: 16);
    canvas.drawOval(
      bulb,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFF87171), Color(0xFF991B1B)],
        ).createShader(bulb),
    );
    final body = Path()
      ..moveTo(20, 6)
      ..lineTo(44, 6)
      ..quadraticBezierTo(52, 1, 64, 2)
      ..quadraticBezierTo(76, 3, 80, 6)
      ..lineTo(108, 6)
      ..lineTo(110, 8)
      ..lineTo(108, 10)
      ..lineTo(80, 10)
      ..quadraticBezierTo(76, 13, 64, 14)
      ..quadraticBezierTo(52, 15, 44, 10)
      ..lineTo(20, 10)
      ..close();
    canvas.drawPath(body, _glass(const Rect.fromLTWH(20, 2, 90, 12)));
    canvas.drawPath(body, _stroke(_glassEdge, 1));
    canvas.restore();
  }

  void _drawIndicatorDropper(Canvas canvas) {
    if (!(state.currentStepIndex == 3 && state.indicatorStep >= 1)) return;
    canvas.save();
    canvas.translate(468, 150);
    final teat = Path()
      ..moveTo(6, 12)
      ..lineTo(6, 0)
      ..quadraticBezierTo(6, -10, 12, -10)
      ..quadraticBezierTo(18, -10, 18, 0)
      ..lineTo(18, 12)
      ..close();
    canvas.drawPath(teat, Paint()..color = const Color(0xFF1F2731));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 12, 16, 6), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2E3640));
    final tube = Path()
      ..moveTo(8, 18)
      ..lineTo(16, 18)
      ..lineTo(16, 46)
      ..lineTo(13, 60)
      ..lineTo(11, 60)
      ..lineTo(8, 46)
      ..close();
    canvas.drawPath(tube, _glass(const Rect.fromLTWH(8, 18, 8, 42)));
    canvas.drawPath(tube, _stroke(_glassEdge, 1.2));
    if (state.isDroppingIndicator) {
      final t = (animationValue * 3) % 1.0;
      final y = 66 + t * 10;
      final drop = Path()
        ..moveTo(12, y - 4)
        ..quadraticBezierTo(15, y + 1.5, 12, y + 3.5)
        ..quadraticBezierTo(9, y + 1.5, 12, y - 4)
        ..close();
      canvas.drawPath(drop, Paint()..color = const Color(0xF2F0F0EB));
      canvas.drawPath(drop, _stroke(const Color(0xFF9AA5B1), 0.8));
    }
    canvas.restore();
  }

  void _drawWasteBeaker(Canvas canvas) {
    canvas.save();
    canvas.translate(646, 262);
    _shadow(canvas, const Offset(22, 56), 26, 3);
    final body = Path()
      ..moveTo(2, 0)
      ..lineTo(42, 0)
      ..lineTo(40, 6)
      ..lineTo(40, 50)
      ..quadraticBezierTo(40, 56, 34, 56)
      ..lineTo(10, 56)
      ..quadraticBezierTo(4, 56, 4, 50)
      ..lineTo(4, 6)
      ..close();
    canvas.drawPath(body, _glass(const Rect.fromLTWH(2, 0, 40, 56)));
    canvas.drawRect(const Rect.fromLTWH(5, 34, 34, 20), Paint()..color = const Color(0x8CDCE6EE));
    canvas.drawPath(body, _stroke(_glassEdge, 1.5));
    final marks = _stroke(const Color(0xB355616D), 0.8);
    for (final y in [14.0, 24.0, 34.0, 44.0]) {
      canvas.drawLine(Offset(y % 20 == 4 ? 32 : 30, y), Offset(36, y), marks);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TitrationBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
