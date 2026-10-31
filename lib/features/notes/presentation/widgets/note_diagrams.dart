import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Notes can hold diagrams as fenced blocks, the same as on the web:
///
/// ```somasmart-circuit
/// { "title": "...", "components": [...], "wires": [...] }
/// ```
///
/// The web draws them interactively. Here circuits and geometry are drawn as
/// still pictures from the same data and images are shown; any other kind
/// shows a card with its title. The raw data is never shown to the student.

/// A piece of a note: plain markdown, or one diagram block.
sealed class NoteSegment {
  const NoteSegment();
}

class NoteMarkdown extends NoteSegment {
  final String text;
  const NoteMarkdown(this.text);
}

class NoteDiagramBlock extends NoteSegment {
  /// "circuit", "geometry", "image", ... (the part after `somasmart-`).
  final String type;

  /// The parsed JSON config, or null when it isn't valid JSON.
  final Map<String, dynamic>? config;
  const NoteDiagramBlock(this.type, this.config);

  String? get title => config?['title']?.toString();
}

final _blockPattern = RegExp(
  r'^[ \t]*```somasmart-([\w-]+)[^\n]*\r?\n([\s\S]*?)\r?\n[ \t]*```[ \t]*$',
  multiLine: true,
);

/// Splits note text into markdown and diagram blocks, in order.
List<NoteSegment> splitNoteContent(String content) {
  final segments = <NoteSegment>[];
  var last = 0;
  for (final m in _blockPattern.allMatches(content)) {
    final before = content.substring(last, m.start);
    if (before.trim().isNotEmpty) segments.add(NoteMarkdown(before));
    Map<String, dynamic>? config;
    try {
      final decoded = jsonDecode(m.group(2)!);
      if (decoded is Map<String, dynamic>) config = decoded;
    } catch (_) {}
    segments.add(NoteDiagramBlock(m.group(1)!, config));
    last = m.end;
  }
  final rest = content.substring(last);
  if (rest.trim().isNotEmpty) segments.add(NoteMarkdown(rest));
  return segments;
}

/// One diagram block, framed once, full width.
class NoteDiagram extends StatelessWidget {
  final NoteDiagramBlock block;
  final String lang;

  const NoteDiagram({super.key, required this.block, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final config = block.config;
    final ink = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final strong = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final src = config?['src']?.toString().trim() ?? '';
    if (block.type == 'image' && src.startsWith('http')) {
      return NoteImage(
        src: src,
        alt: config?['alt']?.toString() ?? '',
        caption: config?['caption']?.toString() ?? '',
        width: config?['width']?.toString() ?? '100%',
        lang: lang,
      );
    }

    Widget? drawing;
    if (config != null && block.type == 'circuit' && (config['components'] is List || config['wires'] is List)) {
      drawing = _canvas(config, CircuitPainter(config, ink: ink, strong: strong, muted: muted));
    } else if (config != null && block.type == 'geometry' && config['shapes'] is List) {
      drawing = _canvas(config, GeometryPainter(config, ink: ink, muted: muted, grid: border));
    }

    final title = block.title ?? (lang == 'sw' ? 'Mchoro' : 'Diagram');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(_iconFor(block.type), size: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: strong),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          if (drawing != null)
            Padding(padding: const EdgeInsets.all(8), child: drawing)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                lang == 'sw'
                    ? 'Mchoro huu wa maingiliano unaonekana kwenye tovuti ya SomaSmart.'
                    : 'This interactive diagram is shown on the SomaSmart website.',
                style: TextStyle(fontSize: 13, height: 1.4, color: ink),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _canvas(Map<String, dynamic> config, CustomPainter painter) {
    final w = _num(config['width'], 500);
    final h = _num(config['height'], 350);
    return AspectRatio(
      aspectRatio: w / h,
      child: CustomPaint(painter: painter, size: Size.infinite),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'circuit':
        return Icons.bolt_rounded;
      case 'geometry':
        return Icons.change_history_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.insights_rounded;
    }
  }
}

/// An image added with the admin's Insert > Image, set like a figure in a
/// book (as on the website): the picture on the page with no frame, at the
/// width the admin chose, and its caption underneath.
class NoteImage extends StatelessWidget {
  final String src;
  final String alt;
  final String caption;

  /// "100%", "60%", "320px" or "320"; anything else means full width.
  final String width;
  final String lang;

  const NoteImage({
    super.key,
    required this.src,
    this.alt = '',
    this.caption = '',
    this.width = '100%',
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Widget picture = Image.network(
      src,
      fit: BoxFit.contain,
      semanticLabel: alt.isNotEmpty ? alt : (caption.isNotEmpty ? caption : null),
      // Space with a small spinner until the first frame arrives.
      frameBuilder: (context, child, frame, sync) => sync || frame != null
          ? child
          : const SizedBox(
              height: 160,
              child: Center(
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
      errorBuilder: (context, error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          lang == 'sw' ? 'Picha haikuweza kupakuliwa' : 'The image could not load',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: muted),
        ),
      ),
    );

    final w = width.trim();
    final percent = RegExp(r'^(\d+(?:\.\d+)?)%$').firstMatch(w);
    final pixels = RegExp(r'^(\d+(?:\.\d+)?)(px)?$').firstMatch(w);
    if (percent != null) {
      final f = (double.parse(percent[1]!) / 100).clamp(0.1, 1.0);
      picture = FractionallySizedBox(widthFactor: f, child: picture);
    } else if (pixels != null) {
      picture = ConstrainedBox(constraints: BoxConstraints(maxWidth: double.parse(pixels[1]!)), child: picture);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          picture,
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: secondary),
              ),
            ),
        ],
      ),
    );
  }
}

double _num(dynamic v, double fallback) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? fallback;

Offset _pt(dynamic p) => p is List && p.length >= 2 ? Offset(_num(p[0], 0), _num(p[1], 0)) : Offset.zero;

Color _hex(dynamic v, Color fallback) {
  final s = v?.toString().replaceFirst('#', '') ?? '';
  if (s.length != 6) return fallback;
  final n = int.tryParse(s, radix: 16);
  return n == null ? fallback : Color(0xFF000000 | n);
}

void _text(Canvas c, String text, Offset at, Color color,
    {double size = 12, FontWeight weight = FontWeight.w700, bool center = true}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  // SVG text sits on its baseline; put the painter's box above it.
  final dx = center ? at.dx - tp.width / 2 : at.dx;
  tp.paint(c, Offset(dx, at.dy - tp.height * 0.8));
}

/// Scales the config's own coordinate space (its width × height) to the box.
abstract class _ViewBoxPainter extends CustomPainter {
  final Map<String, dynamic> config;
  _ViewBoxPainter(this.config);

  void paintView(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    final w = _num(config['width'], 500);
    final h = _num(config['height'], 350);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / w, size.height / h);
    paintView(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ViewBoxPainter old) => old.config != config;
}

// ---------------------------------------------------------------------------
// Circuits (same symbols and layout as the web CircuitRenderer)
// ---------------------------------------------------------------------------
class CircuitPainter extends _ViewBoxPainter {
  final Color ink;
  final Color strong;
  final Color muted;

  CircuitPainter(super.config, {required this.ink, required this.strong, required this.muted});

  static const _on = Color(0xFF10B981);
  static const _off = Color(0xFFEF4444);
  static const _lamp = Color(0xFFF59E0B);

  List<Map<String, dynamic>> get _components =>
      (config['components'] as List? ?? []).whereType<Map<String, dynamic>>().toList();

  /// Closed when there is a cell and every path has a closed switch (as on the web).
  bool get _active {
    final comps = _components;
    final hasCell = comps.any((c) => c['type'] == 'battery' || c['type'] == 'cell');
    final switches = comps.where((c) => c['type'] == 'switch');
    return hasCell && (switches.isEmpty || switches.any((s) => s['closed'] == true));
  }

  @override
  void paintView(Canvas canvas) {
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final wire in (config['wires'] as List? ?? []).whereType<Map<String, dynamic>>()) {
      final pts = (wire['points'] as List? ?? []).map(_pt).toList();
      if (pts.length < 2) continue;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, wirePaint..color = _hex(wire['color'], ink));
      for (var i = 1; i < pts.length - 1; i++) {
        canvas.drawCircle(pts[i], 3.5, Paint()..color = ink);
      }
    }

    final active = _active;
    for (final comp in _components) {
      final type = comp['type']?.toString() ?? '';
      canvas.save();
      canvas.translate(_num(comp['x'], 0), _num(comp['y'], 0));
      canvas.rotate(_num(comp['rotation'], 0) * math.pi / 180);
      _symbol(canvas, type, comp, active);
      final label = comp['label']?.toString();
      if (label != null && label.isNotEmpty) {
        _text(canvas, label, Offset(0, type == 'battery' ? -30 : -22), strong);
      }
      final value = comp['value']?.toString();
      if (value != null && value.isNotEmpty && type != 'switch') {
        _text(canvas, value, Offset(0, type == 'battery' ? 35 : 28), muted, size: 10, weight: FontWeight.w500);
      }
      canvas.restore();
    }
  }

  void _symbol(Canvas c, String type, Map<String, dynamic> comp, bool active) {
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    void line(double x1, double y1, double x2, double y2, [Paint? paint]) =>
        c.drawLine(Offset(x1, y1), Offset(x2, y2), paint ?? p);

    switch (type) {
      case 'resistor':
        final path = Path()..moveTo(-30, 0);
        for (final pt in const [[-20, 0], [-17, -8], [-11, 8], [-5, -8], [1, 8], [7, -8], [13, 8], [17, -8], [20, 0], [30, 0]]) {
          path.lineTo(pt[0].toDouble(), pt[1].toDouble());
        }
        c.drawPath(path, p);
      case 'capacitor':
        line(-30, 0, -5, 0);
        line(-5, -14, -5, 14);
        line(5, -14, 5, 14);
        line(5, 0, 30, 0);
      case 'battery':
      case 'cell':
        line(-30, 0, -8, 0);
        line(-8, -16, -8, 16);
        line(-2, -8, -2, 8);
        line(4, -16, 4, 16);
        line(10, -8, 10, 8);
        line(10, 0, 30, 0);
        _text(c, '+', const Offset(-10, -18), _off, size: 12);
        _text(c, '−', const Offset(8, -18), const Color(0xFF3B82F6), size: 12);
      case 'lamp':
      case 'bulb':
        line(-30, 0, -12, 0);
        if (active) c.drawCircle(Offset.zero, 18, Paint()..color = _lamp.withValues(alpha: 0.3));
        if (active) c.drawCircle(Offset.zero, 12, Paint()..color = _lamp);
        c.drawCircle(Offset.zero, 12, p);
        final cross = Paint()
          ..color = active ? Colors.white : ink
          ..strokeWidth = 1.5;
        line(-8, -8, 8, 8, cross);
        line(8, -8, -8, 8, cross);
        line(12, 0, 30, 0);
      case 'switch':
        final open = comp['closed'] != true;
        line(-30, 0, -10, 0);
        c.drawCircle(const Offset(-10, 0), 3, Paint()..color = ink);
        line(-10, 0, open ? 8 : 10, open ? -14 : 0, Paint()
          ..color = open ? _off : _on
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
        c.drawCircle(const Offset(10, 0), 3, Paint()..color = ink);
        line(10, 0, 30, 0);
        _text(c, open ? 'OFF' : 'ON', const Offset(0, 22), open ? _off : _on, size: 10);
      case 'ammeter':
      case 'voltmeter':
        line(-30, 0, -14, 0);
        c.drawCircle(Offset.zero, 14, p);
        _text(c, type == 'ammeter' ? 'A' : 'V', const Offset(0, 6), AppColors.primaryLight, size: 14);
        line(14, 0, 30, 0);
      case 'diode':
      case 'led':
        line(-30, 0, -8, 0);
        final tri = Path()
          ..moveTo(-8, -10)
          ..lineTo(-8, 10)
          ..lineTo(8, 0)
          ..close();
        if (type == 'led' && active) c.drawPath(tri, Paint()..color = _on);
        c.drawPath(tri, p);
        line(8, -10, 8, 10);
        line(8, 0, 30, 0);
      case 'ground':
        line(0, -20, 0, 0);
        line(-16, 0, 16, 0);
        line(-10, 5, 10, 5);
        line(-4, 10, 4, 10);
      default:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -12, 40, 24), const Radius.circular(3)), p);
        _text(c, type, const Offset(0, 4), muted, size: 10, weight: FontWeight.w500);
    }
  }
}

// ---------------------------------------------------------------------------
// Geometry (same shapes and defaults as the web GeometryRenderer)
// ---------------------------------------------------------------------------
class GeometryPainter extends _ViewBoxPainter {
  final Color ink;
  final Color muted;
  final Color grid;

  GeometryPainter(super.config, {required this.ink, required this.muted, required this.grid});

  static const _defaults = {
    'point': Color(0xFF7C3AED),
    'line': Color(0xFF06B6D4),
    'ray': Color(0xFF3B82F6),
    'segment': Color(0xFF10B981),
    'circle': Color(0xFFF59E0B),
    'arc': Color(0xFFEC4899),
    'triangle': Color(0xFF8B5CF6),
    'quadrilateral': Color(0xFF14B8A6),
    'polygon': Color(0xFFF97316),
    'parallel_lines': Color(0xFF6366F1),
    'perpendicular_lines': Color(0xFFEF4444),
  };

  @override
  void paintView(Canvas canvas) {
    final w = _num(config['width'], 500);
    final h = _num(config['height'], 350);
    if (config['coordinatePlane'] == true) _plane(canvas, w, h, _num(config['gridSpacing'], 40));
    for (final shape in (config['shapes'] as List? ?? []).whereType<Map<String, dynamic>>()) {
      _shape(canvas, shape);
    }
  }

  void _plane(Canvas c, double w, double h, double spacing) {
    final ox = w / 2, oy = h / 2;
    final g = Paint()
      ..color = grid
      ..strokeWidth = 0.5;
    for (var x = ox % spacing; x <= w; x += spacing) {
      c.drawLine(Offset(x, 0), Offset(x, h), g);
    }
    for (var y = oy % spacing; y <= h; y += spacing) {
      c.drawLine(Offset(0, y), Offset(w, y), g);
    }
    final axis = Paint()
      ..color = muted
      ..strokeWidth = 1.5;
    c.drawLine(Offset(0, oy), Offset(w, oy), axis);
    c.drawLine(Offset(ox, 0), Offset(ox, h), axis);
    _text(c, 'X', Offset(w - 12, oy - 6), muted, size: 11);
    _text(c, 'Y', Offset(ox + 10, 14), muted, size: 11);
  }

  void _shape(Canvas c, Map<String, dynamic> s) {
    final type = s['type']?.toString() ?? '';
    final color = _hex(s['color'], _defaults[type] ?? const Color(0xFF7C3AED));
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _num(s['strokeWidth'], 2.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;
    final label = s['label']?.toString();
    double n(String k, double f) => _num(s[k], f);

    switch (type) {
      case 'point':
        final p = Offset(n('x', 0), n('y', 0));
        c.drawCircle(p, 6, dot);
        if (label != null) _text(c, label, p + const Offset(10, -8), color, size: 13, center: false);
      case 'segment':
      case 'line':
      case 'ray':
        var a = Offset(n('x1', 0), n('y1', 0));
        var b = Offset(n('x2', 0), n('y2', 0));
        final dir = b - a;
        final unit = dir.distance == 0 ? Offset.zero : dir / dir.distance;
        final (from, to) = switch (type) {
          'line' => (a - unit * 1000, b + unit * 1000),
          'ray' => (a, a + unit * 1000),
          _ => (a, b),
        };
        c.drawLine(from, to, stroke);
        c.drawCircle(a, 5, dot);
        c.drawCircle(b, type == 'segment' ? 5 : 4, dot);
        if (label != null || s['showDistance'] == true) {
          final dist = (b - a).distance;
          final text = '${label ?? ''}${s['showDistance'] == true ? ' (${(dist / 10).round() / 10} u)' : ''}'.trim();
          _text(c, text, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 8), color);
        }
      case 'circle':
        final center = Offset(n('cx', 0), n('cy', 0));
        final r = n('r', 50);
        if (s['fill'] != null) c.drawCircle(center, r, Paint()..color = _hex(s['fill'], color).withValues(alpha: 0.12));
        c.drawCircle(center, r, stroke);
        c.drawCircle(center, 5, dot);
        if (label != null) _text(c, label, center + Offset(0, -r - 8), color, size: 13);
      case 'arc':
        final center = Offset(n('cx', 0), n('cy', 0));
        final r = n('r', 50);
        final start = n('startAngle', 0) * math.pi / 180;
        final end = n('endAngle', 90) * math.pi / 180;
        c.drawArc(Rect.fromCircle(center: center, radius: r), start, end - start, false, stroke);
        c.drawCircle(center, 4, dot);
        if (label != null) {
          final mid = (start + end) / 2;
          _text(c, label, center + Offset((r + 12) * math.cos(mid), (r + 12) * math.sin(mid)), color, center: false);
        }
      case 'triangle':
      case 'quadrilateral':
      case 'polygon':
        final pts = (s['points'] as List? ?? []).map(_pt).toList();
        if (pts.length < 3) return;
        final path = Path()..addPolygon(pts, true);
        c.drawPath(path, Paint()..color = _hex(s['fill'], color).withValues(alpha: s['fill'] != null ? 0.15 : 0.08));
        c.drawPath(path, stroke);
        for (final p in pts) {
          c.drawCircle(p, 5, dot);
        }
        if (type == 'triangle' && pts.length == 3 && s['showAngles'] == true) {
          for (var i = 0; i < 3; i++) {
            final prev = pts[(i + 2) % 3], cur = pts[i], next = pts[(i + 1) % 3];
            final a1 = math.atan2(prev.dy - cur.dy, prev.dx - cur.dx);
            final a2 = math.atan2(next.dy - cur.dy, next.dx - cur.dx);
            var deg = ((a2 - a1) * 180 / math.pi).abs();
            if (deg > 180) deg = 360 - deg;
            final mid = (a1 + a2) / 2;
            _text(c, '${deg.round()}°', cur + Offset(12 * math.cos(mid), 12 * math.sin(mid)), color, size: 11, center: false);
          }
        }
        if (label != null) {
          final cx = pts.map((p) => p.dx).reduce((a, b) => a + b) / pts.length;
          final cy = pts.map((p) => p.dy).reduce((a, b) => a + b) / pts.length;
          _text(c, label, Offset(cx, cy + 5), color, size: 13);
        }
      case 'perpendicular_lines':
        final o = s['origin'] is List ? _pt(s['origin']) : const Offset(200, 150);
        final line = s['line'] as List?;
        final p1 = line != null && line.isNotEmpty ? _pt(line[0]) : const Offset(100, 150);
        final p2 = line != null && line.length > 1 ? _pt(line[1]) : const Offset(300, 150);
        c.drawLine(p1, p2, stroke);
        c.drawLine(o + const Offset(0, -80), o + const Offset(0, 80), stroke);
        c.drawRect(Rect.fromLTWH(o.dx, o.dy - 12, 12, 12), Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
        c.drawCircle(o, 5, dot);
        if (label != null) _text(c, '$label (⊥ 90°)', o + const Offset(16, -16), color, center: false);
      case 'parallel_lines':
        for (final y in [n('y1', 120), n('y2', 180)]) {
          c.drawLine(Offset(50, y), Offset(350, y), stroke);
          final chevron = Path()
            ..moveTo(200, y - 5)
            ..lineTo(208, y)
            ..lineTo(200, y + 5);
          c.drawPath(chevron, Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
        }
        if (label != null) _text(c, label, Offset(360, n('y1', 120) + 4), color, center: false);
    }
  }
}
