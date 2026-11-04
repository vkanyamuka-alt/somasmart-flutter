import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/titration_state.dart';
import 'lab_apparatus.dart';
import 'lab_hand.dart';

/// The titration bench, built from the shared lab apparatus kit
/// ([LabPaint]): reagent bottles, a retort stand holding the burette over a
/// conical flask on a white tile, the pipette and the indicator dropper. The
/// student's hand lifts the NaOH bottle and pours it through a funnel into
/// the burette, squeezes the pipette filler, carries the pipette to the acid
/// and over the flask and back, brings the dropper over the flask and
/// squeezes it for each drop of indicator, carries the flask onto the tile
/// and turns the tap ([LabHand]). The item being inspected glows. The same
/// bench is drawn on the website (TitrationBench.jsx).
class TitrationBenchPainter extends CustomPainter {
  final TitrationState state;
  final bool isDark;
  final double animationValue;
  final LabHandRuns? hands; // keys from [handKeys]

  TitrationBenchPainter({
    required this.state,
    required this.isDark,
    this.animationValue = 0.0,
    this.hands,
  }) : super(repaint: hands);

  /// Where the pipette is: lying on the bench, in the HCl bottle or over the flask.
  static String pipettePlace(TitrationState s) {
    if (s.currentStepIndex != 2 || s.pipetteStep < 2) return 'bench';
    return s.pipetteStep >= 5 ? 'flask' : 'bottle';
  }

  static bool _showDropper(TitrationState s) => s.currentStepIndex == 3 && s.indicatorStep >= 1;

  /// The values the hands on this bench react to, for [LabHandRuns.watch].
  static Map<String, Object?> handKeys(TitrationState s) => {
        'fill': s.buretteFilled,
        'tap': s.stopcockState,
        'flask': s.flaskPositioned,
        'pipette': pipettePlace(s),
        'filler': s.isDrawingLiquid || s.isTransferringLiquid,
        'dropper': _showDropper(s),
        'drop': s.indicatorDropsCount,
      };

  /// Where each inspectable item stands on the bench (scene units), for the
  /// glow and for taps on the bench.
  static const Map<String, Rect> inspectAreas = {
    'naoh': Rect.fromLTWH(36, 208, 50, 112),
    'hcl': Rect.fromLTWH(96, 208, 50, 112),
    'indicator': Rect.fromLTWH(160, 246, 36, 74),
    'burette': Rect.fromLTWH(_buretteX - 14, 26, 28, 204),
    'flask': Rect.fromLTWH(436, 234, 88, 86),
    'pipette': Rect.fromLTWH(524, 294, 120, 24),
    'tile': Rect.fromLTWH(304, 296, 96, 12),
  };

  /// The inspectable item under [p], a point in a bench painted at [size].
  static String? itemAt(Offset p, Size size) {
    final scale = math.min(size.width / 700, size.height / 380);
    final q = Offset((p.dx - (size.width - 700 * scale) / 2) / scale, (p.dy - (size.height - 380 * scale)) / scale);
    for (final e in inspectAreas.entries) {
      if (e.value.inflate(8).contains(q)) return e.key;
    }
    return null;
  }

  static const double _buretteX = 352;
  static const double _buretteTop = 42; // liquid surface at 0.00 mL
  static const double _buretteScale = 140 / 50; // px per mL
  static const double _buretteBottom = 192;
  static const double _jetTip = 226;

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintScene(canvas, size, isDark, (left, right) {
      if (_fillTime == null) _naohBottle(canvas, x: 40);
      LabPaint.reagentBottle(canvas, x: 100, label: 'HCl', sub: 'unknown', stripe: const Color(0xFFE2B13C), liquid: LabPaint.hcl);
      LabPaint.dropperBottle(canvas, x: 166, lines: const ['phenol-', 'phthalein'], withDropper: _dropperOut == null);
      LabPaint.retortStand(canvas, baseX: 250, rodX: 300, clampYs: const [54], armTo: 340);
      LabPaint.clampJaws(canvas, x: _buretteX, y: 52);
      LabPaint.whiteTile(canvas, x: 306, y: 300);
      _drawBurette(canvas);
      _drawBuretteFill(canvas);
      LabHand.carry(canvas, state.flaskPositioned ? hands?.since('flask') : null,
          offset: const Offset(128, 18), grip: const Offset(354, 236), draw: () => _drawConicalFlask(canvas));
      _drawDelivery(canvas);
      _drawIndicatorDropper(canvas);
      _drawPipette(canvas);
      LabHand.move(canvas, hands?.since('tap'),
          from: const Offset(420, 236), to: const Offset(367, 201), rotate: -90, duration: 1100);
      LabPaint.beaker(canvas, cx: 668, w: 40, h: 56, fill: 0.35, liquid: const Color(0x8CDCE6EE));
      final inspected = state.currentStepIndex == 0 ? inspectAreas[state.selectedInspectItemKey] : null;
      if (inspected != null) LabPaint.activeGlow(canvas, inspected);
    });
  }

  void _naohBottle(Canvas canvas, {required double x, bool stoppered = true, bool onTable = true}) =>
      LabPaint.reagentBottle(canvas,
          x: x,
          label: 'NaOH',
          sub: '0.10 M',
          stripe: const Color(0xFF2F7FD1),
          liquid: LabPaint.naoh,
          stoppered: stoppered,
          onTable: onTable);

  // Filling the burette (ms after "Fill"): the hand lifts the bottle to the
  // funnel, pours while the level rises to 0.00 mL, and puts it back.
  static const double _lifted = 800, _poured = 2600, _back = 3400, _gone = 3700;

  /// Time since the burette was filled while the pour is still playing.
  double? get _fillTime {
    final t = hands?.since('fill');
    return state.buretteFilled && t != null && t < _gone ? t : null;
  }

  /// How far up the burette the NaOH has come while it is poured in (0 to 1).
  double get _fillLevel {
    final t = _fillTime;
    return t == null ? 1 : ((t - _lifted - 100) / (_poured - _lifted - 100)).clamp(0.0, 1.0);
  }

  void _drawBuretteFill(Canvas canvas) {
    final t = _fillTime;
    if (t == null) return;
    // a small funnel in the top of the burette
    final funnel = Path()
      ..moveTo(_buretteX - 13, -4)
      ..lineTo(_buretteX + 13, -4)
      ..lineTo(_buretteX + 3, 16)
      ..lineTo(_buretteX + 3, 40)
      ..lineTo(_buretteX - 3, 40)
      ..lineTo(_buretteX - 3, 16)
      ..close();
    canvas.drawPath(funnel, LabPaint.glass(funnel.getBounds()));
    canvas.drawPath(funnel, LabPaint.stroke(LabPaint.glassEdge, 1.2));
    // its stopper lies on the table while the bottle is open
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48, LabPaint.tableY - 6, 20, 6), const Radius.circular(3)),
        Paint()..color = const Color(0xFFE9EEF3));

    // the bottle's mouth goes from the table to just above the funnel, tipped over
    const rest = Offset(61, LabPaint.tableY - 102);
    const pour = Offset(_buretteX + 18, -8);
    final f = t < _lifted
        ? Curves.easeInOut.transform(t / _lifted)
        : t < _poured
            ? 1.0
            : 1 - Curves.easeInOut.transform(((t - _poured) / (_back - _poured)).clamp(0.0, 1.0));
    final mouth = Offset.lerp(rest, pour, f)!;
    final turn = -1.75 * f;
    canvas.save();
    canvas.translate(mouth.dx, mouth.dy);
    canvas.rotate(turn);
    canvas.translate(-21, 20 - (LabPaint.tableY - 82));
    _naohBottle(canvas, x: 0, stoppered: false, onTable: f == 0);
    canvas.restore();

    if (t > _lifted && t < _poured) {
      final stream = Paint()
        ..color = LabPaint.naoh
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(mouth + const Offset(-1, 2), const Offset(_buretteX + 2, 8), stream);
      canvas.drawLine(const Offset(_buretteX, 16), const Offset(_buretteX, 40), stream..strokeWidth = 2);
    }

    // the hand holds the bottle round its middle and leaves once it is back
    final grip = mouth + Offset(-64 * math.sin(turn), 64 * math.cos(turn));
    final away = ((t - _back) / (_gone - _back)).clamp(0.0, 1.0);
    final shown = (t / 200).clamp(0.0, 1.0) * (1 - away);
    LabHand.paint(canvas, HandPose.grip, at: grip + const Offset(40, 36) * away, scale: 0.85, opacity: shown);
  }

  void _drawBurette(Canvas canvas) {
    const tube = Rect.fromLTWH(_buretteX - 8, 30, 16, 166);
    final tubeR = RRect.fromRectAndRadius(tube, const Radius.circular(4));
    canvas.drawRRect(tubeR, LabPaint.glass(tube));

    final fullTop = _buretteTop + state.volumeDelivered.clamp(0.0, 50.0) * _buretteScale;
    final liquidTop = _buretteBottom + 4 - (_buretteBottom + 4 - fullTop) * _fillLevel;
    if (state.buretteFilled && _fillLevel > 0 && liquidTop < _buretteBottom) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(_buretteX - 6, liquidTop, _buretteX + 6, _buretteBottom + 4), const Radius.circular(1.5)),
        Paint()..color = LabPaint.naoh,
      );
      final meniscus = Path()
        ..moveTo(_buretteX - 6, liquidTop)
        ..quadraticBezierTo(_buretteX, liquidTop + 3.5, _buretteX + 6, liquidTop);
      canvas.drawPath(meniscus, LabPaint.stroke(const Color(0xFF5E8FB8), 1.2));
    }
    canvas.drawRRect(tubeR, LabPaint.stroke(const Color(0xFF8EA8BE), 1.5));

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
    canvas.drawRRect(tapBodyR, LabPaint.glass(tapBody));
    canvas.drawRRect(tapBodyR, LabPaint.stroke(const Color(0xFF8EA8BE), 1.5));
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
    canvas.drawRRect(handle, LabPaint.stroke(const Color(0xFF8C9BAA), 1));
    canvas.restore();
    final jet = Path()
      ..moveTo(_buretteX - 4, 210)
      ..lineTo(_buretteX - 1.5, _jetTip)
      ..lineTo(_buretteX + 1.5, _jetTip)
      ..lineTo(_buretteX + 4, 210)
      ..close();
    canvas.drawPath(jet, LabPaint.glass(jet.getBounds()));
    canvas.drawPath(jet, LabPaint.stroke(const Color(0xFF8EA8BE), 1.2));
  }

  /// Liquid surface in the flask, in the flask's own coordinates (0 to 80).
  double _flaskLevel() => LabPaint.flaskLevel(state.flaskVolume);

  Offset get _flaskOrigin => state.flaskPositioned ? const Offset(312, 220) : const Offset(440, 238);

  void _drawDelivery(Canvas canvas) {
    final surfaceY = _flaskOrigin.dy + _flaskLevel();
    if (state.stopcockState == StopcockState.flow) {
      canvas.drawLine(
        const Offset(_buretteX, _jetTip),
        Offset(_buretteX, surfaceY),
        Paint()
          ..color = LabPaint.naoh
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
      canvas.drawPath(drop, Paint()..color = LabPaint.naoh);
      canvas.drawPath(drop, LabPaint.stroke(const Color(0xFF8EB4D4), 0.8));
    }
  }

  void _drawConicalFlask(Canvas canvas) {
    final origin = _flaskOrigin;
    final tilt = state.isSwirling ? math.sin(animationValue * math.pi * 6) * 0.08 : 0.0;
    LabPaint.conicalFlask(canvas, origin, volume: state.flaskVolume, color: _flaskColor(state.flaskColorStage), tilt: tilt);
    if (state.flaskVolume > 0 && state.flaskRipple) {
      canvas.drawOval(
        Rect.fromCenter(center: origin + Offset(40, _flaskLevel()), width: 28, height: 7),
        LabPaint.stroke(const Color(0xFF8EB4D4), 1.5),
      );
    }
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

  void _drawPipette(Canvas canvas) {
    final place = pipettePlace(state);
    final from = hands?.previous('pipette');
    final moved = hands?.since('pipette');
    if (place == 'bench') {
      // put back on the bench after use
      final back = from == 'flask' || from == 'bottle';
      LabHand.carry(canvas, back ? moved : null,
          offset: Offset(from == 'flask' ? -108 : -467, -118), grip: const Offset(590, 306), draw: () => _drawPipetteOnBench(canvas));
      return;
    }
    final overFlask = place == 'flask';
    if (overFlask) {
      LabHand.carry(canvas, moved,
          offset: const Offset(-359, 0), grip: const Offset(480, 166), draw: () => _drawPipetteUpright(canvas, overFlask));
    } else {
      // picked up from the bench and stood in the acid
      LabHand.carry(canvas, from == 'bench' ? moved : null,
          offset: const Offset(467, 118), grip: const Offset(121, 166), draw: () => _drawPipetteUpright(canvas, overFlask));
    }
    // A finger and thumb squeeze the filler to draw liquid up or let it run out.
    final filling = overFlask ? state.isTransferringLiquid : state.isDrawingLiquid;
    if (filling) {
      LabHand.rest(canvas, hands?.since('filler'), at: Offset(overFlask ? 480 : 121, 124), rotate: 180);
    }
  }

  void _drawPipetteUpright(Canvas canvas, bool overFlask) {
    canvas.save();
    canvas.translate(overFlask ? 470 : 111, 120);

    if (state.isTransferringLiquid && overFlask) {
      canvas.drawLine(
        const Offset(10, 168),
        Offset(10, 118 + _flaskLevel()),
        Paint()
          ..color = LabPaint.hcl
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
    canvas.drawOval(bulb, LabPaint.stroke(const Color(0xFF7F1D1D), 1));
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
    canvas.drawPath(stem, LabPaint.glass(const Rect.fromLTWH(0, 34, 20, 134)));

    if (state.pipetteVolume > 0) {
      final level = 165 - (state.pipetteVolume / 25.0).clamp(0.0, 1.0) * 115;
      canvas.save();
      canvas.clipPath(stem);
      canvas.drawRect(Rect.fromLTRB(0, level, 20, 168), Paint()..color = LabPaint.hcl);
      canvas.restore();
    }
    canvas.drawPath(stem, LabPaint.stroke(LabPaint.glassEdge, 1));

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
    LabPaint.shadow(canvas, const Offset(54, 17), 56, 2.5);
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
    canvas.drawPath(body, LabPaint.glass(const Rect.fromLTWH(20, 2, 90, 12)));
    canvas.drawPath(body, LabPaint.stroke(LabPaint.glassEdge, 1));
    canvas.restore();
  }

  static const double _dropperMs = 900;

  /// How far the dropper is out of its bottle towards the flask, 0 to 1:
  /// brought over the flask for the indicator step, put back after it. Null
  /// while it is in the bottle.
  double? get _dropperOut {
    final t = hands?.since('dropper');
    if (_showDropper(state)) return t == null ? 1.0 : Curves.easeInOut.transform((t / _dropperMs).clamp(0.0, 1.0));
    if (t == null || t >= _dropperMs || hands?.previous('dropper') != true) return null;
    return 1 - Curves.easeInOut.transform(t / _dropperMs);
  }

  void _drawIndicatorDropper(Canvas canvas) {
    final f = _dropperOut;
    if (f == null) return;
    final out = _showDropper(state);
    // The teat is squeezed while a drop comes out, and briefly for each drop.
    final dropAt = hands?.since('drop');
    final squeezing = out && (state.isDroppingIndicator || (dropAt != null && dropAt < 450));
    // brought out of its bottle to above the flask, held by the teat, and back
    final t = hands?.since('dropper');
    final off = const Offset(-304, 96) * (1 - f);
    canvas.save();
    canvas.translate(468 + off.dx, 150 + off.dy);
    final teat = squeezing
        ? (Path()
          ..moveTo(7.5, 12)
          ..lineTo(7.5, 2)
          ..quadraticBezierTo(7.5, -6, 12, -6)
          ..quadraticBezierTo(16.5, -6, 16.5, 2)
          ..lineTo(16.5, 12)
          ..close())
        : (Path()
          ..moveTo(6, 12)
          ..lineTo(6, 0)
          ..quadraticBezierTo(6, -10, 12, -10)
          ..quadraticBezierTo(18, -10, 18, 0)
          ..lineTo(18, 12)
          ..close());
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
    canvas.drawPath(tube, LabPaint.glass(const Rect.fromLTWH(8, 18, 8, 42)));
    canvas.drawPath(tube, LabPaint.stroke(LabPaint.glassEdge, 1.2));
    if (out && state.isDroppingIndicator) {
      final t = (animationValue * 3) % 1.0;
      final y = 66 + t * 10;
      final drop = Path()
        ..moveTo(12, y - 4)
        ..quadraticBezierTo(15, y + 1.5, 12, y + 3.5)
        ..quadraticBezierTo(9, y + 1.5, 12, y - 4)
        ..close();
      canvas.drawPath(drop, Paint()..color = const Color(0xF2F0F0EB));
      canvas.drawPath(drop, LabPaint.stroke(const Color(0xFF9AA5B1), 0.8));
    }
    canvas.restore();
    LabHand.paint(canvas, HandPose.pinch, at: Offset(480, squeezing ? 144 : 140) + off, rotate: 180,
        opacity: t == null ? 1 : (out ? t / 200 : (_dropperMs - t) / 200).clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant TitrationBenchPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
