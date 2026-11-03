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
