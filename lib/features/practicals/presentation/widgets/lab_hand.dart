import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A student's hand that does each action on the bench, so learners see how
/// the apparatus is handled: it carries a flask to the tile, squeezes a
/// dropper, pushes in the plug key, holds the bob aside and lets it go, then
/// leaves. Drawn as a real right hand seen from the back, with knuckles,
/// nails, skin creases and the white cuff of a lab coat, in a frame where the
/// point it touches is (0, 0). The website draws the same hand
/// (components/laboratory/apparatus/Hand.jsx). Poses:
///   point - index finger out, arm from below (pressing a button or a plug)
///   pinch - index finger and thumb meeting at (0, 0), arm from below
///           (a pin, a clip, a bob, a dropper bulb)
///   grip  - fingers wrapped round something upright at (0, 0), arm from the
///           right (a flask neck, a pipette stem)
enum HandPose { point, pinch, grip }

/// Draws the hand and its motions. Every motion takes `t`, the milliseconds
/// since the student's action started it (from [LabHandRuns.since]); with
/// `t` null nothing moves: [move] and [letGo] draw nothing, [rest] draws the
/// hand in place and [carry] only the object.
class LabHand {
  LabHand._();

  static const _skin = Color(0xFF9A6342);
  static const _edge = Color(0xFF5A3520);
  static const _light = Color(0xFFC08A66);
  static const _crease = Color(0xFF5E3820);
  static const _nail = Color(0xFFE3BBA5);
  static const _nailEdge = Color(0xFFB8876C);
  static const _sleeveEdge = Color(0xFFB9C4CF);
  static const _sleeveColors = [Color(0xFFD5DDE5), Color(0xFFFFFFFF), Color(0xFFEEF2F6), Color(0xFFC3CDD7)];
  static const _sleeveStops = [0.0, 0.35, 0.7, 1.0];

  // ---------------------------------------------------------------------------
  // The hand at rest
  // ---------------------------------------------------------------------------

  /// The hand in [pose] touching [at], turned by [rotate] degrees and drawn
  /// [scale] times its natural size (about 50 x 90 bench units).
  static void paint(Canvas canvas, HandPose pose,
      {Offset at = Offset.zero, double rotate = 0, double scale = 1, double opacity = 1}) {
    if (opacity <= 0) return;
    final bounds = _bounds[pose]!;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (opacity < 1) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)));
    }
    // A soft shadow on the bench, offset down and right as the wall light falls.
    canvas.save();
    canvas.translate(1, 2);
    canvas.rotate(rotate * math.pi / 180);
    canvas.scale(scale);
    canvas.saveLayer(
      bounds,
      Paint()
        ..colorFilter = const ColorFilter.mode(Color(0x400F1E2D), BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
    );
    _shape(canvas, pose);
    canvas.restore();
    canvas.restore();
    canvas.rotate(rotate * math.pi / 180);
    canvas.scale(scale);
    _shape(canvas, pose);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Motions (the website's .lab-hand-* keyframes in globals.css)
  // ---------------------------------------------------------------------------

  /// The hand comes in at [from] (or just below and right of [to]), moves to
  /// [to], presses briefly and goes away, [delay] ms after the action.
  /// [holding] draws what the hand carries (a dropper, a splint) with the
  /// touching point at (0, 0), so it moves with the hand.
  static void move(Canvas canvas, double? t,
      {required Offset to,
      Offset? from,
      HandPose pose = HandPose.pinch,
      double rotate = 0,
      double scale = 1,
      double duration = 1300,
      double delay = 0,
      void Function(Canvas canvas)? holding}) {
    if (t == null) return;
    final p = (t - delay) / duration;
    if (p < 0 || p >= 1) return;
    final start = from ?? to + Offset(34, 44) * scale;
    final frames = [
      _Key(0, start, 0),
      _Key(0.15, start, 1),
      _Key(0.45, to, 1),
      _Key(0.55, to + Offset(-1, 2) * scale, 1),
      _Key(0.72, to, 1),
      _Key(1, start, 0),
    ];
    final k = _at(frames, p, Curves.easeInOut);
    _drawWith(canvas, pose, k.$1, rotate, scale, k.$2, holding);
  }

  /// A hand resting at [at] (squeezing a dropper, holding the bob aside). It
  /// slides in from [enter] away over 450 ms, [delay] ms after [t] starts.
  static void rest(Canvas canvas, double? t,
      {required Offset at,
      HandPose pose = HandPose.pinch,
      double rotate = 0,
      double scale = 1,
      Offset enter = const Offset(0, -24),
      double delay = 0,
      void Function(Canvas canvas)? holding}) {
    var pos = at;
    var opacity = 1.0;
    if (t != null) {
      final p = (t - delay) / 450;
      if (p < 0) return;
      if (p < 1) {
        final f = Curves.easeOut.transform(p);
        pos = at + enter * scale * (1 - f);
        opacity = f;
      }
    }
    _drawWith(canvas, pose, pos, rotate, scale, opacity, holding);
  }

  /// The hand lets go at [at] and moves away over 700 ms.
  static void letGo(Canvas canvas, double? t,
      {required Offset at, HandPose pose = HandPose.pinch, double rotate = 0, double scale = 1, void Function(Canvas canvas)? holding}) {
    if (t == null) return;
    final p = t / 700;
    if (p < 0 || p >= 1) return;
    final f = Curves.easeIn.transform(p);
    _drawWith(canvas, pose, at + Offset(36, 30) * scale * f, rotate, scale, 1 - f, holding);
  }

  /// [draw] paints the carried object where it ends up; the hand brings it
  /// in from [offset] away holding it at [grip], and leaves once it is in
  /// place. With [t] null only the object is drawn.
  static void carry(Canvas canvas, double? t,
      {required Offset offset,
      required Offset grip,
      required void Function() draw,
      HandPose pose = HandPose.grip,
      double rotate = 0,
      double scale = 1,
      double duration = 1500}) {
    if (t == null || t >= duration) {
      draw();
      return;
    }
    final p = (t / duration).clamp(0.0, 1.0);
    final shift = p < 0.6 ? offset * (1 - Curves.easeInOut.transform(p / 0.6)) : Offset.zero;
    canvas.save();
    canvas.translate(shift.dx, shift.dy);
    draw();
    final away = p <= 0.68 ? 0.0 : Curves.easeIn.transform((p - 0.68) / 0.32);
    paint(canvas, pose, at: grip + Offset(40, 36) * scale * away, rotate: rotate, scale: scale, opacity: 1 - away);
    canvas.restore();
  }

  /// 0 before [delay] ms, rising to 1 over [fade] ms: for apparatus that
  /// shows once the hand has put it down (an optical pin pushed in).
  static double appear(double? t, double delay, {double fade = 200}) {
    if (t == null) return 1;
    return ((t - delay) / fade).clamp(0.0, 1.0);
  }

  static void _drawWith(Canvas canvas, HandPose pose, Offset pos, double rotate, double scale, double opacity,
      void Function(Canvas canvas)? holding) {
    if (opacity <= 0) return;
    if (holding != null) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      if (opacity < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
      holding(canvas);
      if (opacity < 1) canvas.restore();
      canvas.restore();
    }
    paint(canvas, pose, at: pos, rotate: rotate, scale: scale, opacity: opacity);
  }

  static (Offset, double) _at(List<_Key> frames, double p, Curve curve) {
    for (int i = 1; i < frames.length; i++) {
      final a = frames[i - 1];
      final b = frames[i];
      if (p <= b.at) {
        final f = curve.transform(((p - a.at) / (b.at - a.at)).clamp(0.0, 1.0));
        return (Offset.lerp(a.pos, b.pos, f)!, a.opacity + (b.opacity - a.opacity) * f);
      }
    }
    return (frames.last.pos, frames.last.opacity);
  }

  // ---------------------------------------------------------------------------
  // The drawing
  // ---------------------------------------------------------------------------

  static final Map<HandPose, Rect> _bounds = {
    HandPose.point: const Rect.fromLTRB(-30, -10, 60, 200),
    HandPose.pinch: const Rect.fromLTRB(-20, -10, 70, 190),
    HandPose.grip: const Rect.fromLTRB(-25, -40, 160, 40),
  };

  static void _shape(Canvas canvas, HandPose pose) {
    switch (pose) {
      case HandPose.point:
        _curledFingers(canvas);
        _backOfHand(canvas);
        _sleeveUp(canvas);
        // thumb tucked along the side
        _finger(canvas, _thumbPoint, 10, nail: const [-10.4, 48.5, -6], creases: const [[-8.6, 58, 40]]);
        _finger(canvas, _indexPoint, 10.4, nail: const [0, 6.4, 0], creases: const [[0.2, 18, 0], [0.4, 29, 0]]);
      case HandPose.pinch:
        // drawn with the fingertips meeting at (-8, 11), then moved so that is (0, 0)
        canvas.save();
        canvas.translate(8, -11);
        _curledFingers(canvas);
        _backOfHand(canvas);
        _sleeveUp(canvas);
        _finger(canvas, _thumbPinch, 10.4, nail: const [-9.8, 17.5, 16], creases: const [[-13, 42, 4]]);
        _finger(canvas, _indexPinch, 10, nail: const [-5.6, 9.6, -50], creases: const [[0.6, 29, 0], [-1.6, 16.5, -30]]);
        canvas.restore();
      case HandPose.grip:
        _grip(canvas);
    }
  }

  static final _thumbPoint = _svg('M-2,70 Q-11.5,61 -10.5,46');
  static final _indexPoint = _svg('M0.5,42 L0,5');
  static final _thumbPinch = _svg('M-3,70 Q-14,58 -13,40 Q-12.5,27 -9.5,16');
  static final _indexPinch = _svg('M1,41 L0.6,25 Q0,15 -6.5,9');
  static final _curled = [
    (_svg('M29,50 L29.5,41.5'), 8.6, const [29.5, 43.5, 0.0]),
    (_svg('M20.5,48 L21,37.5'), 9.6, const [21.0, 40.0, 0.0]),
    (_svg('M11,47 L11.4,35.5'), 10.0, const [11.4, 38.0, 0.0]),
  ];
  static final _back = _svg('M-5.5,41 C-9,50 -9,60 -5,70 C-2.5,76 -0.5,81 0,90 L28,90 C29,81 32,74 34.5,66 '
      'C36.5,58 35.5,50 33.5,45 C31,41.5 6,38 -5.5,41 Z');
  static final _tendons = _svg('M1,47 Q6,62 10,78 M11,48 Q13,62 14.5,78 M20.5,49 Q19.5,62 19,78 M28.5,51 Q25,64 23,78');
  static final _sleeve = _svg('M-10,80 L39,80 L46,190 L-17,190 Z');
  static final _cuff = _svg('M-10.5,79 L39.5,79 L41,94 L-12,94 Z');
  static final _sleeveFolds = _svg('M-4,104 Q4,118 0,140 M31,100 Q27,120 34,150');
  static final _palm = _svg('M10,-21 C20,-25 32,-23 40,-19 L48,-17 L48,18 L40,19 C30,22 18,22 10,18 C5,10 5,-12 10,-21 Z');
  static final _sleeveSide = _svg('M44,-21 L150,-27 L150,27 L44,21 Z');
  static final _cuffSide = _svg('M43,-22 L58,-23 L58,23 L43,22 Z');
  static final _sideFolds = _svg('M70,-18 Q86,-12 104,-20 M68,14 Q90,8 112,18');
  static final _gripFingers = [
    // wrapped round the front, little finger lowest
    (_svg('M13,13.5 L-6,14.5'), 8.4, const [[3.0, 14.0, 90.0]]),
    (_svg('M13,5 L-9,5.6'), 9.2, const [[4.0, 5.3, 90.0], [-3.0, 5.5, 90.0]]),
    (_svg('M13,-4 L-10,-3.8'), 9.6, const [[4.0, -3.9, 90.0], [-3.5, -3.8, 90.0]]),
    (_svg('M13,-13 L-8.5,-13'), 9.4, const [[4.0, -13.0, 90.0], [-2.5, -13.0, 90.0]]),
  ];
  static final _gripThumb = _svg('M24,-17 Q10,-24 -4,-22');

  /// Skin lit from the upper left (the website's `skin` gradient).
  static Paint _skinFill(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment(-1, -1),
      end: Alignment(1, -0.5),
      colors: [Color(0xFF7A4A2E), Color(0xFFA56C4A), Color(0xFFB17654), Color(0xFF8E5A3B), Color(0xFF6A3F27)],
      stops: [0, 0.3, 0.5, 0.8, 1],
    ).createShader(r);

  /// The white lab-coat sleeve: shaded across (`sleeve`) or, for an arm from
  /// the side, down (`sleeveH`).
  static Paint _sleeveFill(Rect r, {bool across = true}) => Paint()
    ..shader = LinearGradient(
      begin: across ? Alignment.centerLeft : Alignment.topCenter,
      end: across ? Alignment.centerRight : Alignment.bottomCenter,
      colors: _sleeveColors,
      stops: _sleeveStops,
    ).createShader(r);

  static Paint _line(Color c, double w, {double opacity = 1}) => Paint()
    ..color = c.withValues(alpha: opacity)
    ..strokeWidth = w
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// A finger drawn along [path] (base to tip), [w] thick: a darker edge, the
  /// skin, a soft highlight down its length, creases at the joints and a nail
  /// at the tip. [nail] is [x, y, angle] (0 = pointing up), [creases] the same.
  static void _finger(Canvas canvas, Path path, double w, {List<double>? nail, List<List<double>> creases = const []}) {
    canvas.drawPath(path, _line(_edge, w + 1.4));
    canvas.drawPath(path, _line(_skin, w));
    canvas.drawPath(path, _line(_light, w * 0.3, opacity: 0.45));
    for (final c in creases) {
      canvas.save();
      canvas.translate(c[0], c[1]);
      canvas.rotate(c[2] * math.pi / 180);
      final crease = Path()
        ..moveTo(-w * 0.32, 0)
        ..quadraticBezierTo(0, w * 0.12, w * 0.32, 0);
      canvas.drawPath(crease, _line(_crease, 0.7, opacity: 0.6));
      canvas.restore();
    }
    if (nail != null) {
      canvas.save();
      canvas.translate(nail[0], nail[1]);
      canvas.rotate(nail[2] * math.pi / 180);
      final n = Path()
        ..moveTo(-w * 0.3, w * 0.42)
        ..cubicTo(-w * 0.33, -w * 0.1, -w * 0.2, -w * 0.36, 0, -w * 0.36)
        ..cubicTo(w * 0.2, -w * 0.36, w * 0.33, -w * 0.1, w * 0.3, w * 0.42)
        ..quadraticBezierTo(0, w * 0.52, -w * 0.3, w * 0.42)
        ..close();
      canvas.drawPath(n, Paint()..color = _nail);
      canvas.drawPath(n, _line(_nailEdge, 0.6));
      final shine = Path()
        ..moveTo(-w * 0.12, w * 0.25)
        ..quadraticBezierTo(-w * 0.15, -w * 0.12, 0, -w * 0.2);
      canvas.drawPath(shine, _line(const Color(0xFFFFFFFF), 0.9, opacity: 0.6));
      canvas.restore();
    }
  }

  /// Middle, ring and little fingers curled under, seen as their bent joints.
  static void _curledFingers(Canvas canvas) {
    for (final (path, w, crease) in _curled) {
      _finger(canvas, path, w, creases: [crease]);
    }
  }

  /// The back of the hand from the knuckles to the wrist, for point and pinch.
  static void _backOfHand(Canvas canvas) {
    canvas.drawPath(_back, _skinFill(_back.getBounds()));
    canvas.drawPath(_back, _line(_edge, 0.7));
    // knuckles and the tendons running back from them
    final knuckle = Paint()..color = _light.withValues(alpha: 0.4);
    for (final k in const [Offset(0.5, 43), Offset(11, 43.5), Offset(20.5, 45), Offset(29, 47.5)]) {
      canvas.drawOval(Rect.fromCenter(center: k, width: 7.2, height: 4.4), knuckle);
    }
    canvas.drawPath(_tendons, _line(_light, 1.4, opacity: 0.18));
  }

  /// The lab-coat sleeve over the wrist, going off below.
  static void _sleeveUp(Canvas canvas) {
    canvas.drawPath(_sleeve, _sleeveFill(_sleeve.getBounds()));
    canvas.drawPath(_sleeve, _line(_sleeveEdge, 0.8));
    canvas.drawPath(_cuff, _sleeveFill(_cuff.getBounds()));
    canvas.drawPath(_cuff, _line(_sleeveEdge, 0.9));
    _dashes(canvas, const Offset(-11.5, 91), const Offset(40.6, 91));
    canvas.drawCircle(const Offset(33, 86.5), 2, Paint()..color = const Color(0xFFE6EBF0));
    canvas.drawCircle(const Offset(33, 86.5), 2, _line(_sleeveEdge, 0.6));
    canvas.drawPath(_sleeveFolds, _line(_sleeveEdge, 0.8, opacity: 0.7));
  }

  static void _grip(Canvas canvas) {
    canvas.drawPath(_palm, _skinFill(_palm.getBounds()));
    canvas.drawPath(_palm, _line(_edge, 0.7));
    canvas.drawPath(_sleeveSide, _sleeveFill(_sleeveSide.getBounds(), across: false));
    canvas.drawPath(_sleeveSide, _line(_sleeveEdge, 0.8));
    canvas.drawPath(_cuffSide, _sleeveFill(_cuffSide.getBounds(), across: false));
    canvas.drawPath(_cuffSide, _line(_sleeveEdge, 0.9));
    _dashes(canvas, const Offset(55.5, -23), const Offset(55.5, 23));
    canvas.drawPath(_sideFolds, _line(_sleeveEdge, 0.8, opacity: 0.7));
    for (final (path, w, creases) in _gripFingers) {
      _finger(canvas, path, w, creases: creases);
    }
    // thumb over the top
    _finger(canvas, _gripThumb, 9.6, nail: const [-2.6, -22.2, -98], creases: const [[9, -21.5, 80]]);
  }

  /// The stitching along the cuff: 1.6 on, 1.4 off.
  static void _dashes(Canvas canvas, Offset a, Offset b) {
    final paint = Paint()
      ..color = _sleeveEdge
      ..strokeWidth = 0.6;
    final len = (b - a).distance;
    final d = (b - a) / len;
    for (double s = 0; s < len; s += 3) {
      canvas.drawLine(a + d * s, a + d * math.min(s + 1.6, len), paint);
    }
  }

  /// A path from SVG path data using absolute M, L, Q, C and Z, as the
  /// website's Hand.jsx writes them, so the two hands stay the same shape.
  static Path _svg(String d) {
    final tokens = RegExp(r'[MLQCZ]|-?\d*\.?\d+').allMatches(d).map((m) => m.group(0)!).toList();
    final path = Path();
    var i = 0;
    var cmd = 'M';
    double n() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      if (RegExp(r'^[MLQCZ]$').hasMatch(tokens[i])) cmd = tokens[i++];
      switch (cmd) {
        case 'M':
          path.moveTo(n(), n());
          cmd = 'L';
        case 'L':
          path.lineTo(n(), n());
        case 'Q':
          path.quadraticBezierTo(n(), n(), n(), n());
        case 'C':
          path.cubicTo(n(), n(), n(), n(), n(), n());
        case 'Z':
          path.close();
      }
    }
    return path;
  }
}

class _Key {
  final double at;
  final Offset pos;
  final double opacity;
  const _Key(this.at, this.pos, this.opacity);
}

/// Keeps time for a bench's hands. A screen makes one, calls [watch] in
/// build with each value a hand reacts to (the tap setting, the number of
/// cells, whether the flask is on the tile), and passes it to its bench
/// painter, which reads [since] and repaints while a hand is moving. A hand
/// plays when the student does something, never when the bench first appears
/// (the first value seen only sets the baseline), and not at all while the
/// phone asks for reduced motion (set [enabled] from
/// `MediaQuery.disableAnimationsOf`).
class LabHandRuns extends ChangeNotifier {
  LabHandRuns(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  bool enabled = true;
  final Map<String, Object?> _seen = {};
  final Map<String, Object?> _previous = {};
  final Map<String, Duration> _started = {};
  Duration _base = Duration.zero;
  Duration _now = Duration.zero;

  /// The longest a hand takes, after which time stops ticking.
  static const Duration _longest = Duration(milliseconds: 5000);

  /// Notes [value] for [key]; when it differs from the last value seen, the
  /// hand for [key] starts.
  void watch(String key, Object? value) {
    if (!_seen.containsKey(key)) {
      _seen[key] = value;
      return;
    }
    if (_seen[key] == value) return;
    _previous[key] = _seen[key];
    _seen[key] = value;
    if (!enabled) {
      _started.remove(key);
      return;
    }
    _started[key] = _now;
    if (!_ticker.isActive) {
      _base = _now;
      _ticker.start();
    }
  }

  /// Milliseconds since the hand for [key] last started, or null if it has
  /// not (or the student's phone asks for reduced motion).
  double? since(String key) {
    final s = _started[key];
    if (s == null) return null;
    return (_now - s).inMicroseconds / 1000;
  }

  /// The value [key] had before its last change, so a painter can tell which
  /// of several pieces the student has just moved.
  Object? previous(String key) => _previous[key];

  void _tick(Duration elapsed) {
    _now = _base + elapsed;
    notifyListeners();
    if (_started.values.every((s) => _now - s > _longest)) _ticker.stop();
  }

  @visibleForTesting
  bool get isTicking => _ticker.isActive;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// A bench drawing with the student's hand, for screens that do not keep
/// their own [LabHandRuns]: it watches the values in [watch] (key -> value)
/// and builds the bench [painter] with the runs.
class LabHandPaint extends StatefulWidget {
  final Map<String, Object?> watch;
  final CustomPainter Function(LabHandRuns hands) painter;
  final Size size;

  const LabHandPaint({super.key, required this.watch, required this.painter, this.size = Size.zero});

  @override
  State<LabHandPaint> createState() => _LabHandPaintState();
}

class _LabHandPaintState extends State<LabHandPaint> with SingleTickerProviderStateMixin {
  late final LabHandRuns _hands = LabHandRuns(this);

  @override
  void dispose() {
    _hands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _hands.enabled = !MediaQuery.disableAnimationsOf(context);
    widget.watch.forEach(_hands.watch);
    return CustomPaint(size: widget.size, painter: widget.painter(_hands));
  }
}
