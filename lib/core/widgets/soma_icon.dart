import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'soma_icon_data.dart';

/// SomaSmart's own drawings (subjects and the Ask me mark), the same ones the
/// website draws. Lines use [color] (default: the icon theme colour), the
/// accent is filled gold.
class SomaIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const SomaIcon(this.name, {super.key, this.size = 24, this.color});

  /// The SVG for one icon, with the colours filled in.
  static String svg(String name, Color ink, {Color accent = AppColors.brandGold}) {
    final icon = somaIconPaths[name] ?? somaIconPaths['default']!;
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

/// Which drawing a subject uses, from its id, key or English/Swahili name.
/// Matches subjectIconKey() on the website (src/lib/subjects.js).
String subjectIconKey(String? subject) {
  if (subject == null || subject.isEmpty) return 'default';
  final s = subject.toLowerCase().replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ').trim();
  return _subjectIconById[subject] ?? _subjectIconByName[s] ?? 'default';
}

const _subjectIconById = {
  '1': 'mathematics',
  '8b5e28a5-d8cf-4351-a982-1df3e0cf5581': 'mathematics',
  '2': 'physics',
  'c4a631bf-9d0a-42c2-8411-9f9361ad22f0': 'physics',
  '3': 'chemistry',
  'a5e01df3-8f0a-493e-bc5d-6c1f2ea8b21c': 'chemistry',
  '4': 'biology',
  '58d0421e-1f7c-473d-bd83-aa1e8f25b290': 'biology',
  '5': 'kiswahili',
  'fb4e29c8-d1ff-4841-b0db-e3a2410a8d67': 'kiswahili',
  '6': 'english',
  '24e0b04a-4712-4c6e-821f-e8b84fb68d99': 'english',
  '7': 'history',
  'ad06c3c5-9276-47b2-a4e9-913a1a6bf961': 'history',
  '8': 'geography',
  'ef4ef667-27ea-47c1-8414-0e6ef37d16ba': 'geography',
  '9': 'civics',
  '068e1a17-b769-42b7-84fe-19a9d28c31cb': 'civics',
  '10': 'economics',
  '11': 'commerce',
  '12': 'basic_applied_mathematics',
  '13': 'general_studies',
};

const _subjectIconByName = {
  'mathematics': 'mathematics', 'maths': 'mathematics', 'math': 'mathematics', 'hisabati': 'mathematics',
  'calculator': 'mathematics',
  'physics': 'physics', 'fizikia': 'physics', 'atom': 'physics',
  'chemistry': 'chemistry', 'kemia': 'chemistry', 'flask': 'chemistry',
  'biology': 'biology', 'biolojia': 'biology', 'dna': 'biology',
  'english': 'english', 'english language': 'english', 'kiingereza': 'english', 'languages': 'english',
  'kiswahili': 'kiswahili',
  'history': 'history', 'historia': 'history',
  'geography': 'geography', 'jiografia': 'geography', 'globe': 'geography',
  'civics': 'civics', 'uraia': 'civics',
  'economics': 'economics', 'uchumi': 'economics', 'trendingup': 'economics',
  'commerce': 'commerce', 'biashara': 'commerce', 'shoppingbag': 'commerce',
  'basic_applied_mathematics': 'basic_applied_mathematics', 'basic applied mathematics': 'basic_applied_mathematics',
  'bam': 'basic_applied_mathematics', 'hisabati ya tahasusi': 'basic_applied_mathematics',
  'filespreadsheet': 'basic_applied_mathematics',
  'general_studies': 'general_studies', 'general studies': 'general_studies',
  'stadi za kazi/maarifa': 'general_studies', 'compass': 'general_studies',
};
