import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'soma_icon_data.dart';

/// SomaSmart's own Ask me mark, the same one the website draws. Subjects have
/// no icons. Lines use [color] (default: the icon theme colour), the
/// accent is filled gold.
class SomaIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const SomaIcon(this.name, {super.key, this.size = 24, this.color});

  /// The SVG for one icon, with the colours filled in.
  static String svg(String name, Color ink, {Color accent = AppColors.brandGold}) {
    final icon = somaIconPaths[name] ?? somaIconPaths['ask']!;
    final inkHex = _hex(ink);
    final b = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="$inkHex" stroke-width="$somaIconStroke" stroke-linecap="round" stroke-linejoin="round">',
    );
    for (final d in icon.faint) {
      b.write('<path d="$d" stroke-opacity="0.35"/>');
    }
    for (final d in icon.accent) {
      b.write('<path d="$d" fill="${_hex(accent)}" stroke="none"/>');
    }
    for (final d in icon.line) {
      b.write('<path d="$d"/>');
    }
    b.write('</svg>');
    return b.toString();
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? AppColors.primary;
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.string(svg(name, ink), width: size, height: size),
    );
  }
}
