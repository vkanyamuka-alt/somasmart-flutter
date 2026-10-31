import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';

// The lab welcome: a lab table under a tiled wall, then an O-Level / A-Level
// switch and one bench per subject. The lab is a learning screen, so it stays
// in English whatever language the app is set to.

const _labWallLight = Color(0xFFEEF3F8);
const _labWallDark = Color(0xFF0F2134);
const _tableTop = [Color(0xFFF3F6F9), Color(0xFFD2DBE4)];
const _tableEdge = [Color(0xFF9DAEBF), Color(0xFF6F8399)];

class _Bench {
  final PracticalSubject subject;
  final String name;
  final String picture;

  const _Bench(this.subject, this.name, this.picture);
}

// One bench per subject, shown by its apparatus and name.
const _benches = [
  _Bench(PracticalSubject.chemistry, 'Chemistry', 'assets/images/lab_chemistry.png'),
  _Bench(PracticalSubject.physics, 'Physics', 'assets/images/lab_physics.png'),
  _Bench(PracticalSubject.biology, 'Biology', 'assets/images/lab_biology.png'),
];

class PracticalLevelScreen extends ConsumerStatefulWidget {
  const PracticalLevelScreen({super.key});

  @override
  ConsumerState<PracticalLevelScreen> createState() => _PracticalLevelScreenState();
}

class _PracticalLevelScreenState extends ConsumerState<PracticalLevelScreen> {
  PracticalLevel _level = PracticalLevel.oLevel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabHero(isDark: isDark, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _LevelSwitch(
                  level: _level,
                  isDark: isDark,
                  onChanged: (level) => setState(() => _level = level),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_level == PracticalLevel.oLevel) ...[
              Text('Choose a subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 12),
              for (final bench in _benches) ...[
                _BenchCard(
                  bench: bench,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => context.push('/practical/o-level/${bench.subject.id}'),
                ),
                const SizedBox(height: 10),
              ],
            ] else
              _ALevelComing(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onShowOLevel: () => setState(() => _level = PracticalLevel.oLevel),
              ),
          ],
        ),
      ),
    );
  }
}

class _LabHero extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _LabHero({required this.isDark, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final wall = isDark ? _labWallDark : _labWallLight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: wall,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _TilePainter(isDark ? const Color(0x0F9CC3E4) : const Color(0x0F184E78)),
          child: Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to the',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SomaSmart Simulation Laboratory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Do your school science practicals on screen: titrate an acid, focus a microscope, '
                        'time a pendulum. Each one follows the NECTA syllabus.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // The drawing is never wider than 860; the table under it
                    // runs the full width of the panel.
                    final imageWidth = math.min(constraints.maxWidth, 860.0);
                    final tableHeight = imageWidth * 62 / 1200;
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: imageWidth * 480 / 1200,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(left: 0, right: 0, bottom: 0, height: tableHeight, child: const _TableBand()),
                          Image.asset(
                            'assets/images/lab_bench.png',
                            width: imageWidth,
                            fit: BoxFit.fitWidth,
                            semanticLabel:
                                'A lab table with a burette over a conical flask, test tubes in a rack, a microscope, '
                                'a Bunsen burner, a pendulum, a stopwatch and an ammeter',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The lab table front: a light worktop over a darker edge, in the drawing's
/// proportions (36 and 26 of 62 units).
class _TableBand extends StatelessWidget {
  const _TableBand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 36,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _tableTop),
            ),
          ),
        ),
        Expanded(
          flex: 26,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _tableEdge),
            ),
          ),
        ),
      ],
    );
  }
}

class _TilePainter extends CustomPainter {
  final Color color;

  _TilePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TilePainter oldDelegate) => oldDelegate.color != color;
}

class _LevelSwitch extends StatelessWidget {
  final PracticalLevel level;
  final bool isDark;
  final ValueChanged<PracticalLevel> onChanged;

  const _LevelSwitch({required this.level, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    Widget option(PracticalLevel value, String name) {
      final selected = level == value;
      final color = selected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onChanged(value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: color)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          option(PracticalLevel.oLevel, 'O-Level'),
          const SizedBox(width: 2),
          option(PracticalLevel.aLevel, 'A-Level'),
        ],
      ),
    );
  }
}

class _BenchCard extends StatelessWidget {
  final _Bench bench;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _BenchCard({
    required this.bench,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkBgSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              _BenchPicture(asset: bench.picture, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(bench.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// A close-up of the subject's apparatus standing on a strip of the same table.
class _BenchPicture extends StatelessWidget {
  final String asset;
  final bool isDark;

  const _BenchPicture({required this.asset, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // The close-ups are 460 units tall; the table takes the bottom 62.
    const height = 84.0;
    const tableHeight = height * 62 / 460;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        height: height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: ColoredBox(color: isDark ? _labWallDark : _labWallLight)),
            const Positioned(left: 0, right: 0, bottom: 0, height: tableHeight, child: _TableBand()),
            Image.asset(asset, height: height, fit: BoxFit.fitHeight, excludeFromSemantics: true),
          ],
        ),
      ),
    );
  }
}

class _ALevelComing extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onShowOLevel;

  const _ALevelComing({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onShowOLevel,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.science_outlined, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            'A-Level practicals are on the way',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Chemistry, physics and biology practicals for Forms 5 and 6 are being built. '
            'The O-Level practicals are open now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onShowOLevel,
            style: FilledButton.styleFrom(backgroundColor: accent, minimumSize: const Size(0, 44)),
            child: const Text('Show O-Level practicals'),
          ),
        ],
      ),
    );
  }
}
