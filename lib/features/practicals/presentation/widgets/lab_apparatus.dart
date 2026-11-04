import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The lab apparatus kit: one set of realistic drawings (glass with
/// reflections, metal stands, labelled bottles, a lab table under a tiled
/// wall) that every practical's bench painter is built from, so the benches
/// look alike and nothing is drawn twice. The website draws the same pieces
/// (src/components/laboratory/apparatus/LabKit.jsx).
///
/// Benches are laid out in a 700 x 380 box with the table top at y = 318.
/// [paintScene] scales that box evenly to fit the canvas, sits it on the
/// bottom, and runs the wall and table the full width.
class LabPaint {
  LabPaint._();

  static const double tableY = 318;
  static const Color glassEdge = Color(0xFF86A0B6);
  static const Color ink = Color(0xFF1F2933);
  static const Color naoh = Color(0xD9BADCF5);
  static const Color hcl = Color(0xCCFDE6AA);
  static const Color water = Color(0x8CBED4E6);

  /// Scales the 700 x 380 bench into [size] and calls [draw] with the canvas
  /// in bench units. [draw] gets the visible left and right edges (in bench
  /// units) so pieces can reach the sides of the canvas. [cropX] and
  /// [cropWidth] show only that part of the bench, so a bench whose apparatus
  /// stands close together fills a phone screen. Nothing is drawn outside
  /// the canvas (the student's hand reaches in from its edges).
  static void paintScene(Canvas canvas, Size size, bool isDark, void Function(double left, double right) draw,
      {double cropX = 0, double cropWidth = 700}) {
    final scale = math.min(size.width / cropWidth, size.height / 380.0);
    final dx = (size.width - cropWidth * scale) / 2 - cropX * scale;
    final dy = size.height - 380 * scale;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _wall(canvas, size, scale, isDark);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    final left = -dx / scale;
    final right = (size.width - dx) / scale;
    _table(canvas, left, right);
    draw(left, right);
    canvas.restore();
  }

  /// The bench top seen from above, for circuits laid out on the table: a
  /// [width] x [height] box scaled evenly and centred in [size]. [draw] works
  /// in box units.
  static void paintTop(Canvas canvas, Size size, double width, double height, void Function() draw) {
    final scale = math.min(size.width / width, size.height / height);
    final dx = (size.width - width * scale) / 2;
    final dy = (size.height - height * scale) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFDCE3EA));
    canvas.translate(dx, dy);
    canvas.scale(scale);
    final lines = Paint()
      ..color = const Color(0x59FFFFFF)
      ..strokeWidth = 1;
    final left = -dx / scale;
    final right = (size.width - dx) / scale;
    for (double y = 23; y < height; y += 46) {
      canvas.drawLine(Offset(left, y), Offset(right, y), lines);
    }
    draw();
    canvas.restore();
  }

  /// A drawing board seen from above (ray tracing): soft wood filling the
  /// canvas with a sheet of white paper held by drawing pins, the 700 x 380
  /// box scaled evenly and centred. [draw] works in board units.
  static void paintBoard(Canvas canvas, Size size, void Function() draw) {
    final scale = math.min(size.width / 700.0, size.height / 380.0);
    final dx = (size.width - 700 * scale) / 2;
    final dy = (size.height - 380 * scale) / 2;
    final all = Offset.zero & size;
    canvas.save();
    canvas.clipRect(all);
    canvas.drawRect(all, wood(all));
    canvas.translate(dx, dy);
    canvas.scale(scale);
    const paper = Rect.fromLTWH(24, 18, 652, 344);
    canvas.drawRect(paper, Paint()..color = const Color(0xFFFDFDFB));
    canvas.drawRect(paper, stroke(const Color(0xFFD9D4C7), 1));
    for (final c in const [Offset(34, 28), Offset(666, 28), Offset(34, 352), Offset(666, 352)]) {
      final r = Rect.fromCircle(center: c, radius: 5);
      canvas.drawOval(r, radial(r, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]));
    }
    draw();
    canvas.restore();
  }

  static void _wall(Canvas canvas, Size size, double scale, bool isDark) {
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

  static void _table(Canvas canvas, double left, double right) {
    final top = Rect.fromLTRB(left, tableY, right, tableY + 24);
    canvas.drawRect(top, vertical(top, const [Color(0xFFF3F6F9), Color(0xFFD2DBE4)]));
    canvas.drawRect(Rect.fromLTRB(left, tableY, right, tableY + 1.5), Paint()..color = const Color(0xE6FFFFFF));
    final edge = Rect.fromLTRB(left, tableY + 24, right, 380);
    canvas.drawRect(edge, vertical(edge, const [Color(0xFF9DAEBF), Color(0xFF6F8399)]));
  }

  // ---------------------------------------------------------------------------
  // Materials
  // ---------------------------------------------------------------------------

  static Paint glass(Rect r) => Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xBFDCEBF7), Color(0xD9FFFFFF), Color(0x59CFE3F3), Color(0x8CFFFFFF), Color(0xB3B9D3E8)],
      stops: [0, 0.18, 0.45, 0.85, 1],
    ).createShader(r);

  static Paint metal(Rect r) => Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF6E7B88), Color(0xFFEEF2F5), Color(0xFFA3AEB9), Color(0xFF55616D)],
      stops: [0, 0.3, 0.6, 1],
    ).createShader(r);

  static Paint metalV(Rect r) => vertical(r, const [Color(0xFFEEF2F5), Color(0xFFA3AEB9), Color(0xFF5F6B77)]);
  static Paint iron(Rect r) => vertical(r, const [Color(0xFF4A5562), Color(0xFF1F2731)]);
  static Paint wood(Rect r) => vertical(r, const [Color(0xFFE3BE86), Color(0xFFC4945A)]);

  static Paint vertical(Rect r, List<Color> colors) => Paint()
    ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(r);

  static Paint radial(Rect r, List<Color> colors, {List<double>? stops}) => Paint()
    ..shader = RadialGradient(center: const Alignment(-0.3, -0.4), colors: colors, stops: stops).createShader(r);

  /// The apparatus the student has just tapped to inspect: a soft gold glow
  /// and outline round [area], so the picture shows which item is active.
  static void activeGlow(Canvas canvas, Rect area, {double radius = 8}) {
    final r = RRect.fromRectAndRadius(area.inflate(5), Radius.circular(radius));
    canvas.drawRRect(r, Paint()..color = const Color(0x26DB9E3D));
    canvas.drawRRect(
        r,
        Paint()
          ..color = const Color(0x66DB9E3D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
    canvas.drawRRect(r, stroke(const Color(0xFFDB9E3D), 2));
  }

  /// [activeGlow] following an outline, for apparatus that is not boxy.
  static void activeGlowPath(Canvas canvas, Path path) {
    canvas.drawPath(path, Paint()..color = const Color(0x26DB9E3D));
    canvas.drawPath(path, stroke(const Color(0x66DB9E3D), 10)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, stroke(const Color(0xFFDB9E3D), 2.5));
  }

  static Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..style = PaintingStyle.stroke;

  static void shadow(Canvas canvas, Offset c, double rx, double ry) {
    final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(r, Paint()..shader = const RadialGradient(colors: [Color(0x4D0B1A2A), Color(0x000B1A2A)]).createShader(r));
  }

  static void text(Canvas canvas, String s, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w700, String? fontFamily}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: weight, color: color, fontFamily: fontFamily)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ---------------------------------------------------------------------------
  // Stands and holders
  // ---------------------------------------------------------------------------

  /// Iron base on the table, a steel rod, and a boss head with an arm out to
  /// [armTo] at each height in [clampYs].
  static void retortStand(Canvas canvas,
      {required double baseX, double baseWidth = 160, required double rodX, double rodTop = 24, List<double> clampYs = const [], double armTo = 0}) {
    shadow(canvas, Offset(baseX + baseWidth / 2, tableY + 3), baseWidth / 2 + 6, 5);
    final base = Rect.fromLTWH(baseX, tableY - 12, baseWidth, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(3)), iron(base));
    canvas.drawRect(Rect.fromLTWH(baseX + 2, tableY - 12, baseWidth - 4, 2), Paint()..color = const Color(0xFF6B7784));
    final rod = Rect.fromLTWH(rodX - 4, rodTop, 8, tableY - 10 - rodTop);
    canvas.drawRRect(RRect.fromRectAndRadius(rod, const Radius.circular(3)), metal(rod));
    for (final y in clampYs) {
      final boss = Rect.fromLTWH(rodX - 10, y, 20, 20);
      canvas.drawRRect(RRect.fromRectAndRadius(boss, const Radius.circular(3)), iron(boss));
      final knob = Rect.fromCircle(center: Offset(rodX - 14, y + 10), radius: 5);
      canvas.drawOval(knob, radial(knob, const [Color(0xFFFFFFFF), Color(0xFFB7C1CB), Color(0xFF5F6B77)], stops: const [0, 0.5, 1]));
      final arm = Rect.fromLTWH(rodX + 6, y + 6, armTo - rodX - 6, 7);
      canvas.drawRRect(RRect.fromRectAndRadius(arm, const Radius.circular(2)), metalV(arm));
    }
  }

  /// Rubber-lined clamp jaws holding something [width] wide, centred at [x].
  static void clampJaws(Canvas canvas, {required double x, required double y, double width = 16, double height = 24}) {
    final r = Rect.fromLTWH(x - width / 2 - 8, y, width + 16, height);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), iron(r));
  }

  /// Split cork in clamp jaws: the fixed point a thread hangs from (its
  /// bottom, the point of suspension, is at y + 22).
  static void splitCork(Canvas canvas, {required double x, required double y}) {
    final jaws = Rect.fromLTWH(x - 14, y - 10, 28, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(jaws, const Radius.circular(4)), iron(jaws));
    final cork = Path()
      ..moveTo(x - 7, y + 8)
      ..lineTo(x + 7, y + 8)
      ..lineTo(x + 5, y + 22)
      ..lineTo(x - 5, y + 22)
      ..close();
    canvas.drawPath(cork, Paint()..color = const Color(0xFFC99A62));
    canvas.drawPath(cork, stroke(const Color(0xFF8C6420), 0.8));
    canvas.drawLine(Offset(x, y + 8), Offset(x, y + 22), stroke(const Color(0xFF8C6420), 0.8));
  }

  // ---------------------------------------------------------------------------
  // Measuring instruments
  // ---------------------------------------------------------------------------

  /// Wooden metre rule standing upright: zero at [y0], [cm] centimetres down
  /// at y0 + cm * pxPerCm. Long marks every 10 cm with numbers, short every 5.
  static void metreRule(Canvas canvas, {required double x, required double y0, required double pxPerCm, int cm = 100}) {
    final len = cm * pxPerCm;
    final body = Rect.fromLTWH(x, y0 - 4, 26, len + 8);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), wood(body));
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), stroke(const Color(0xFFA9783E), 1));
    for (int c = 0; c <= cm; c += 5) {
      final y = y0 + c * pxPerCm;
      final major = c % 10 == 0;
      canvas.drawLine(Offset(x, y), Offset(x + (major ? 9 : 5), y), stroke(const Color(0xFF3B2A14), major ? 1 : 0.7));
      if (major) {
        final tp = TextPainter(
          text: TextSpan(text: '$c', style: const TextStyle(fontSize: 7, color: Color(0xFF3B2A14))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 11, y - tp.height / 2));
      }
    }
  }

  /// Digital stopwatch standing on the table, centred at [cx]: a grey case, a
  /// green LCD showing [seconds], start and stop buttons.
  static void stopwatch(Canvas canvas, {required double cx, double seconds = 0, bool running = false}) {
    final x = cx - 34;
    const y = tableY - 72;
    shadow(canvas, Offset(cx, tableY + 2), 38, 3);
    final crown = Rect.fromLTWH(cx - 6, y - 8, 12, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(crown, const Radius.circular(3)), metal(crown));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 6, y + 6, 8, 6), const Radius.circular(2)),
        Paint()..color = running ? const Color(0xFF2F9E5B) : const Color(0xFF55616D));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 62, y + 6, 8, 6), const Radius.circular(2)),
        Paint()..color = const Color(0xFFC8392F));
    final body = Rect.fromLTWH(x, y, 68, 72);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(18)), iron(body));
    final lcd = RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, y + 16, 52, 30), const Radius.circular(4));
    canvas.drawRRect(lcd, Paint()..color = const Color(0xFFB9C9A0));
    canvas.drawRRect(lcd, stroke(const Color(0xFF5B6878), 1));
    text(canvas, seconds.toStringAsFixed(2), Offset(cx, y + 31), 14, const Color(0xFF1F2D16), fontFamily: 'monospace');
    text(canvas, 's', Offset(cx, y + 57), 7, const Color(0xFFC9D2DB), weight: FontWeight.w400);
  }

  /// Brass pendulum bob of radius [r] centred at [c].
  static void bob(Canvas canvas, Offset c, {double r = 11}) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawOval(rect, radial(rect, const [Color(0xFFFFF1C9), Color(0xFFDBA94A), Color(0xFF8C6420)], stops: const [0, 0.45, 1]));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 2, c.dy - r - 4, 4, 5), const Radius.circular(1)),
        Paint()..color = const Color(0xFF8C6420));
  }

  // ---------------------------------------------------------------------------
  // Glassware and bottles
  // ---------------------------------------------------------------------------

  /// Labelled reagent bottle standing on the table, left edge at [x] (42 wide).
  /// Its mouth is at (x + 21, tableY - 102). [stoppered] false draws it open,
  /// and [onTable] false leaves out its shadow (when it is lifted).
  static void reagentBottle(Canvas canvas,
      {required double x,
      required String label,
      String? sub,
      required Color stripe,
      required Color liquid,
      bool stoppered = true,
      bool onTable = true}) {
    canvas.save();
    canvas.translate(x, tableY - 82);
    if (onTable) shadow(canvas, const Offset(21, 82), 26, 3);
    final neck = RRect.fromRectAndRadius(const Rect.fromLTWH(14, -20, 14, 10), const Radius.circular(3));
    canvas.drawRRect(neck, glass(neck.outerRect));
    canvas.drawRRect(neck, stroke(const Color(0xFF8EA8BE), 1.2));
    if (stoppered) {
      final stopper = RRect.fromRectAndRadius(const Rect.fromLTWH(11, -24, 20, 6), const Radius.circular(3));
      canvas.drawRRect(stopper, Paint()..color = const Color(0xFFE9EEF3));
      canvas.drawRRect(stopper, stroke(const Color(0xFF8C9BAA), 1));
    }
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
    canvas.drawPath(body, glass(const Rect.fromLTWH(0, -10, 42, 92)));
    final fill = Path()
      ..moveTo(2, 30)
      ..lineTo(40, 30)
      ..lineTo(40, 74)
      ..quadraticBezierTo(40, 80, 34, 80)
      ..lineTo(8, 80)
      ..quadraticBezierTo(2, 80, 2, 74)
      ..close();
    canvas.drawPath(fill, Paint()..color = liquid);
    canvas.drawPath(body, stroke(glassEdge, 1.5));
    final labelRect = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 34, 34, 28), const Radius.circular(2));
    canvas.drawRRect(labelRect, Paint()..color = const Color(0xFFFDFDFB));
    canvas.drawRRect(labelRect, stroke(const Color(0xFFC9D2DB), 0.8));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 34, 34, 5), const Radius.circular(1.5)), Paint()..color = stripe);
    text(canvas, label, const Offset(21, 47), 8.5, ink);
    if (sub != null) text(canvas, sub, const Offset(21, 56), 6, const Color(0xFF52606D), weight: FontWeight.w400);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 4, 3, 66), const Radius.circular(1.5)),
        Paint()..color = const Color(0xB3FFFFFF));
    canvas.restore();
  }

  /// Small brown dropper bottle (indicators, stains), left edge at [x]; with
  /// [withDropper] false its dropper is out and the open neck shows.
  static void dropperBottle(Canvas canvas, {required double x, required List<String> lines, bool withDropper = true}) {
    canvas.save();
    canvas.translate(x, tableY - 62);
    shadow(canvas, const Offset(13, 62), 18, 2.5);
    if (withDropper) {
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
    }
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
    canvas.drawPath(body, stroke(const Color(0xFF5C3A12), 1.2));
    if (!withDropper) canvas.drawLine(const Offset(8, -4), const Offset(18, -4), stroke(const Color(0xFF3A2408), 1.6));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 22, 20, 22), const Radius.circular(1.5)),
        Paint()..color = const Color(0xFFFDFDFB));
    for (int i = 0; i < lines.length; i++) {
      text(canvas, lines[i], Offset(13, 29.0 + i * 7), 5.5, ink);
    }
    canvas.restore();
  }

  /// Glass beaker with its base on [y] (default the table), centred at [cx].
  /// [fill] is 0..1 of its height.
  static void beaker(Canvas canvas,
      {required double cx, double w = 44, double h = 56, double y = tableY, double fill = 0, Color liquid = water}) {
    final x = cx - w / 2;
    final top = y - h;
    shadow(canvas, Offset(cx, y + 1), w / 2 + 4, 3);
    final body = Path()
      ..moveTo(x, top)
      ..lineTo(x + w, top)
      ..lineTo(x + w - 2, top + 6)
      ..lineTo(x + w - 2, y - 6)
      ..quadraticBezierTo(x + w - 2, y, x + w - 8, y)
      ..lineTo(x + 8, y)
      ..quadraticBezierTo(x + 2, y, x + 2, y - 6)
      ..lineTo(x + 2, top + 6)
      ..close();
    canvas.drawPath(body, glass(Rect.fromLTWH(x, top, w, h)));
    if (fill > 0) {
      final level = y - 2 - (h - 10) * fill.clamp(0.0, 1.0);
      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(Rect.fromLTRB(x, level, x + w, y), Paint()..color = liquid);
      canvas.drawRect(Rect.fromLTWH(x, level, w, 1.4), Paint()..color = const Color(0x99FFFFFF));
      canvas.restore();
    }
    canvas.drawPath(body, stroke(glassEdge, 1.5));
    final marks = stroke(const Color(0xB355616D), 0.8);
    for (final f in const [0.25, 0.45, 0.65, 0.85]) {
      final my = y - h * f;
      canvas.drawLine(Offset(x + w - (f == 0.45 || f == 0.85 ? 10 : 14), my), Offset(x + w - 6, my), marks);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 5, top + 6, 2.5, h - 12), const Radius.circular(1.2)),
        Paint()..color = const Color(0xB3FFFFFF));
  }

  /// White ceramic tile, top-left at [x], [y].
  static void whiteTile(Canvas canvas, {required double x, required double y, double w = 92, double h = 6}) {
    final tile = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(1.5));
    canvas.drawRRect(tile, Paint()..color = Colors.white);
    canvas.drawRRect(tile, stroke(const Color(0xFFC5D0DA), 1));
  }

  /// The conical flask outline, drawn at the origin: neck 0-24, base at 80.
  static Path get flaskPath => Path()
    ..moveTo(33, 0)
    ..lineTo(47, 0)
    ..lineTo(47, 24)
    ..lineTo(73, 66)
    ..quadraticBezierTo(79, 80, 66, 80)
    ..lineTo(14, 80)
    ..quadraticBezierTo(1, 80, 7, 66)
    ..lineTo(33, 24)
    ..close();

  /// Liquid surface (0..80 from the top of the neck) for [volume] mL.
  static double flaskLevel(double volume) => 76 - (math.min(volume, 40.0) / 25) * 30;

  /// Conical flask (80 x 80) with its top-left at [origin]. The solution shows
  /// a faint tint even when colourless.
  static void conicalFlask(Canvas canvas, Offset origin, {double volume = 0, Color color = Colors.transparent, double tilt = 0}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (tilt != 0) {
      canvas.translate(40, 80);
      canvas.rotate(tilt);
      canvas.translate(-40, -80);
    }
    shadow(canvas, const Offset(40, 81), 40, 3);
    final path = flaskPath;
    canvas.drawPath(path, glass(const Rect.fromLTWH(0, 0, 80, 80)));
    if (volume > 0) {
      final level = flaskLevel(volume);
      canvas.save();
      canvas.clipPath(path);
      final liquid = Rect.fromLTRB(0, level, 80, 82);
      canvas.drawRect(liquid, Paint()..color = const Color(0x59BED4E6));
      canvas.drawRect(liquid, Paint()..color = color);
      canvas.drawRect(Rect.fromLTWH(0, level - 0.5, 80, 1.5), Paint()..color = const Color(0xCC8EA8BE));
      canvas.drawRect(Rect.fromLTWH(0, level + 1, 80, 1.2), Paint()..color = const Color(0x99FFFFFF));
      canvas.restore();
    }
    canvas.drawPath(path, stroke(glassEdge, 1.8));
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 0), width: 16, height: 4), stroke(glassEdge, 1.4));
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
}
