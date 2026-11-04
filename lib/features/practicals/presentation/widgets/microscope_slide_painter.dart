import 'package:flutter/material.dart';
import '../../data/models/microscope_state.dart';
import 'lab_apparatus.dart';
import 'lab_hand.dart';

/// The slide being prepared, seen from above on a white tile: a glass slide
/// with a frosted end, the onion epidermis in a drop of water, the stain and
/// the coverslip. The student's hand lays the onion peel on the slide,
/// squeezes the dropper of stain over it and lowers the coverslip
/// ([LabHand]). Built from the shared lab kit ([LabPaint]).
class MicroscopeSlidePainter extends CustomPainter {
  final MicroscopeState state;
  final LabHandRuns? hands; // keys from [handKeys]

  MicroscopeSlidePainter({required this.state, this.hands}) : super(repaint: hands);

  /// The values the hands on this bench react to, for [LabHandPaint.watch].
  static Map<String, Object?> handKeys(MicroscopeState s) =>
      {'specimen': s.isSpecimenPlaced, 'stain': s.appliedStain, 'coverslip': s.isCoverslipMounted};

  static const double width = 360;
  static const double height = 150;

  static const _slide = Rect.fromLTWH(60, 50, 240, 58);
  static const _centre = Offset(196, 79);
  static const _edge = Color(0xFF86A0B6);

  Color get _stain => switch (state.appliedStain) {
        StainType.iodine => const Color(0x99B45309),
        StainType.methyleneBlue => const Color(0x991D4ED8),
        StainType.none => const Color(0x00000000),
      };

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintTop(canvas, size, width, height, () {
      // white tile and its shadow
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(33, 17, 300, 120), const Radius.circular(6)),
          Paint()..color = const Color(0x1F000000));
      final tile = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 14, 300, 120), const Radius.circular(6));
      canvas.drawRRect(tile, Paint()..color = Colors.white);
      canvas.drawRRect(tile, LabPaint.stroke(const Color(0xFFC5D0DA), 1));

      // the glass slide, frosted at its left end for the label
      final slide = RRect.fromRectAndRadius(_slide, const Radius.circular(2));
      canvas.drawRRect(slide, LabPaint.glass(_slide));
      canvas.drawRRect(slide, Paint()..color = const Color(0x26BAD6EC));
      canvas.drawRect(Rect.fromLTWH(_slide.left + 2, _slide.top + 2, 44, _slide.height - 4), Paint()..color = const Color(0xFFEDEFF2));
      LabPaint.text(canvas, 'onion', Offset(_slide.left + 24, _slide.center.dy), 9, const Color(0xFF52606D), weight: FontWeight.w600);
      canvas.drawRRect(slide, LabPaint.stroke(_edge, 1.2));

      if (state.isWaterDropAdded || state.isSpecimenPlaced) {
        canvas.drawOval(Rect.fromCenter(center: _centre, width: 46, height: 34), Paint()..color = const Color(0x40BED4E6));
      }
      if (state.isSpecimenPlaced) {
        LabHand.carry(canvas, hands?.since('specimen'),
            offset: const Offset(96, -44), grip: _centre + const Offset(14, -9), pose: HandPose.pinch, rotate: -20, draw: () => _drawSpecimen(canvas));
      }
      if (state.appliedStain != StainType.none) {
        canvas.drawOval(Rect.fromCenter(center: _centre, width: 50, height: 36), Paint()..color = _stain.withValues(alpha: 0.35 * _stainShown));
        // the dropper squeezed over the peel, one drop falling
        final t = hands?.since('stain');
        LabHand.move(canvas, t,
            from: _centre + const Offset(60, -70), to: _centre + const Offset(0, -34), rotate: 180, duration: 1600, holding: _dropper);
      }
      if (state.isCoverslipMounted) {
        // lowered at an angle from one side so no air bubbles are trapped
        LabHand.carry(canvas, hands?.since('coverslip'),
            offset: const Offset(70, -50), grip: _centre + const Offset(28, -6), pose: HandPose.pinch, rotate: -30, draw: () => _drawCoverslip(canvas));
      }
    });
  }

  /// The stain spreads over the peel once the dropper's drop has landed.
  double get _stainShown => LabHand.appear(hands?.since('stain'), 800, fade: 500);

  /// The onion epidermis: a thin, pale, slightly crumpled peel.
  void _drawSpecimen(Canvas canvas) {
    final peel = Path()
      ..moveTo(_centre.dx - 17, _centre.dy - 8)
      ..quadraticBezierTo(_centre.dx - 4, _centre.dy - 14, _centre.dx + 15, _centre.dy - 9)
      ..quadraticBezierTo(_centre.dx + 19, _centre.dy + 2, _centre.dx + 14, _centre.dy + 10)
      ..quadraticBezierTo(_centre.dx - 2, _centre.dy + 14, _centre.dx - 16, _centre.dy + 9)
      ..quadraticBezierTo(_centre.dx - 21, _centre.dy, _centre.dx - 17, _centre.dy - 8)
      ..close();
    canvas.drawPath(peel, Paint()..color = const Color(0x8CF5F0DC));
    if (state.appliedStain != StainType.none) canvas.drawPath(peel, Paint()..color = _stain.withValues(alpha: _stain.a * _stainShown));
    canvas.drawPath(peel, LabPaint.stroke(const Color(0x99B8A77A), 0.8));
    // the cells, faintly, as a fine grid of bricks
    final cell = LabPaint.stroke(const Color(0x40A08A55), 0.5);
    for (double y = _centre.dy - 8; y <= _centre.dy + 8; y += 4) {
      canvas.drawLine(Offset(_centre.dx - 15, y), Offset(_centre.dx + 14, y), cell);
    }
  }

  void _dropper(Canvas c) {
    // teat between finger and thumb at (0, 0), glass tube going down to the slide
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -6, 12, 14), const Radius.circular(5)), Paint()..color = const Color(0xFF1F2731));
    final tube = Path()
      ..moveTo(-3, 8)
      ..lineTo(3, 8)
      ..lineTo(3, 26)
      ..lineTo(1, 32)
      ..lineTo(-1, 32)
      ..lineTo(-3, 26)
      ..close();
    c.drawPath(tube, LabPaint.glass(const Rect.fromLTWH(-3, 8, 6, 24)));
    c.drawRect(const Rect.fromLTWH(-2, 18, 4, 9), Paint()..color = _stain.withValues(alpha: 0.9));
    c.drawPath(tube, LabPaint.stroke(_edge, 0.8));
  }

  void _drawCoverslip(Canvas canvas) {
    final r = Rect.fromCenter(center: _centre, width: 54, height: 50);
    canvas.drawRect(r, Paint()..color = const Color(0x33DCEBF7));
    canvas.drawRect(r, LabPaint.stroke(const Color(0xCC86A0B6), 1));
    canvas.drawLine(r.topLeft + const Offset(6, 6), r.topLeft + const Offset(18, 6), LabPaint.stroke(const Color(0xB3FFFFFF), 1.6));
  }

  @override
  bool shouldRepaint(covariant MicroscopeSlidePainter oldDelegate) => oldDelegate.state != state;
}

/// The microscope practical's apparatus laid out on the bench for the
/// inspect step; the one the student taps glows as active.
class MicroscopeApparatusPainter extends CustomPainter {
  final String? selected;

  const MicroscopeApparatusPainter({this.selected});

  static const List<String> ids = ['microscope', 'glass_slide', 'mounted_needle', 'onion_peel', 'iodine_dropper', 'filter_paper'];
  static const _labels = ['Microscope', 'Slide', 'Needle', 'Onion', 'Iodine', 'Filter paper'];
  static const double width = 360;
  static const double height = 104;
  static const double _slot = width / 6;

  static Rect _area(int i) => Rect.fromLTWH(i * _slot + 4, 8, _slot - 8, 80);

  @override
  void paint(Canvas canvas, Size size) {
    LabPaint.paintTop(canvas, size, width, height, () {
      final i = ids.indexOf(selected ?? '');
      if (i >= 0) LabPaint.activeGlow(canvas, _area(i).deflate(3));
      for (int k = 0; k < ids.length; k++) {
        final c = Offset(k * _slot + _slot / 2, 46);
        switch (ids[k]) {
          case 'microscope':
            _microscope(canvas, c);
          case 'glass_slide':
            final s = Rect.fromCenter(center: c, width: 46, height: 16);
            canvas.drawRect(s, LabPaint.glass(s));
            canvas.drawRect(s, LabPaint.stroke(const Color(0xFF86A0B6), 1));
            final cs = Rect.fromCenter(center: c + const Offset(6, 0), width: 14, height: 14);
            canvas.drawRect(cs, LabPaint.stroke(const Color(0xCC86A0B6), 0.8));
          case 'mounted_needle':
            canvas.drawLine(c + const Offset(-18, 14), c + const Offset(-2, -2), LabPaint.stroke(const Color(0xFFA9773F), 5)..strokeCap = StrokeCap.round);
            canvas.drawLine(c + const Offset(-2, -2), c + const Offset(16, -20), LabPaint.stroke(const Color(0xFF8C9BAA), 1.2));
          case 'onion_peel':
            final bulb = Path()
              ..moveTo(c.dx, c.dy - 22)
              ..quadraticBezierTo(c.dx + 4, c.dy - 10, c.dx + 15, c.dy - 2)
              ..quadraticBezierTo(c.dx + 20, c.dy + 16, c.dx, c.dy + 16)
              ..quadraticBezierTo(c.dx - 20, c.dy + 16, c.dx - 15, c.dy - 2)
              ..quadraticBezierTo(c.dx - 4, c.dy - 10, c.dx, c.dy - 22)
              ..close();
            canvas.drawPath(bulb, Paint()..color = const Color(0xFFC9925A));
            canvas.drawPath(bulb, LabPaint.stroke(const Color(0xFF8E5B2C), 1));
            canvas.drawLine(c + const Offset(0, -12), c + const Offset(0, 14), LabPaint.stroke(const Color(0x668E5B2C), 0.8));
          case 'iodine_dropper':
            final bottle = RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 6), width: 22, height: 26), const Radius.circular(4));
            canvas.drawRRect(bottle, Paint()..color = const Color(0xFF7A3E12));
            canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 6), width: 16, height: 9), Paint()..color = const Color(0xFFF5EBD7));
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, -12), width: 8, height: 10), const Radius.circular(3)),
                Paint()..color = const Color(0xFF1F2731));
          case 'filter_paper':
            canvas.drawCircle(c, 18, Paint()..color = Colors.white);
            canvas.drawCircle(c, 18, LabPaint.stroke(const Color(0xFFCBD5E1), 1));
        }
        LabPaint.text(canvas, _labels[k], Offset(c.dx, 80), 9, const Color(0xFF184E78), weight: FontWeight.w600);
      }
    });
  }

  /// A compound microscope from the side: base, curved arm, stage with the
  /// lamp under it, and the body tube with eyepiece and objective.
  void _microscope(Canvas canvas, Offset c) {
    const navy = Color(0xFF184E78);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 24), width: 34, height: 6), const Radius.circular(2)),
        Paint()..color = navy);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx + 10, c.dy + 21)
          ..quadraticBezierTo(c.dx + 19, c.dy + 2, c.dx + 7, c.dy - 15),
        LabPaint.stroke(navy, 5)..strokeCap = StrokeCap.round);
    canvas.drawRect(Rect.fromLTWH(c.dx - 15, c.dy + 3, 26, 3), Paint()..color = const Color(0xFF2E3640));
    canvas.drawCircle(c + const Offset(-3, 13), 2.6, Paint()..color = const Color(0xFFDB9E3D));
    canvas.drawLine(c + const Offset(0, -14), c + const Offset(7, -14), LabPaint.stroke(navy, 3));
    canvas.save();
    canvas.translate(c.dx - 1, c.dy - 12);
    canvas.rotate(-0.18);
    canvas.drawRect(const Rect.fromLTWH(-3.5, -12, 7, 20), Paint()..color = const Color(0xFFDCE3EA));
    canvas.drawRect(const Rect.fromLTWH(-3.5, -12, 7, 20), LabPaint.stroke(navy, 1));
    canvas.drawRect(const Rect.fromLTWH(-4.5, -16, 9, 4), Paint()..color = const Color(0xFF2E3640));
    canvas.drawPath(
        Path()
          ..moveTo(-3, 8)
          ..lineTo(3, 8)
          ..lineTo(2, 13)
          ..lineTo(-2, 13)
          ..close(),
        Paint()..color = const Color(0xFF2E3640));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MicroscopeApparatusPainter oldDelegate) => oldDelegate.selected != selected;
}
