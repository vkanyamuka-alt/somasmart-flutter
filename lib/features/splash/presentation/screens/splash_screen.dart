import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Official SomaSmart splash screen.
///
/// Intro (about 1.9 s): the logo springs in with a slight turn while a soft
/// navy halo grows behind it, a gold ring draws itself around the logo, then
/// the "SomaSmart" wordmark rises and the tagline fades in. While the app
/// decides where to go, the logo breathes gently and the ring turns slowly.
/// Honors the system "reduce motion" setting.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration animationDuration;
  final Duration holdDuration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.animationDuration = const Duration(milliseconds: 1900),
    this.holdDuration = const Duration(milliseconds: 600),
    this.autoNavigate = true,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _idle;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoTurn;
  late final Animation<double> _halo;
  late final Animation<double> _ring;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: widget.animationDuration);
    _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    CurvedAnimation curve(double begin, double end, Curve c) =>
        CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: c));

    _logoScale = Tween<double>(begin: 0.45, end: 1.0).animate(curve(0.0, 0.45, Curves.easeOutBack));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(curve(0.0, 0.25, Curves.easeOut));
    _logoTurn = Tween<double>(begin: -0.18, end: 0.0).animate(curve(0.0, 0.45, Curves.easeOutCubic));
    _halo = Tween<double>(begin: 0.0, end: 1.0).animate(curve(0.05, 0.55, Curves.easeOutCubic));
    _ring = Tween<double>(begin: 0.0, end: 1.0).animate(curve(0.20, 0.70, Curves.easeInOutCubic));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(curve(0.48, 0.80, Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(curve(0.48, 0.85, Curves.easeOutCubic));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(curve(0.68, 1.0, Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduce motion: show the finished frame straight away.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _intro.value = 1.0;
      _finish();
    } else {
      _intro.forward().whenComplete(() {
        if (mounted) _idle.repeat(reverse: true);
        _finish();
      });
    }
  }

  Future<void> _finish() async {
    if (!widget.autoNavigate) return;
    await Future.delayed(widget.holdDuration);
    if (!mounted) return;
    try {
      final client = ref.read(supabaseClientProvider);
      context.go(client.auth.currentUser != null ? '/home' : '/welcome');
    } catch (_) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = ref.watch(languageProvider) == 'sw';
    final size = MediaQuery.sizeOf(context);
    // Scale with the screen: small phones get a smaller mark, tablets a larger one.
    final logoSize = (size.shortestSide * 0.26).clamp(84.0, 132.0);
    final ringSize = logoSize * 1.55;

    final tagline = isSw
        ? 'Jifunze Haraka. Elewa Zaidi.\nMudu Kila Mada.'
        : 'Learn Fast. Understand Deeply.\nMaster Every Topic.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _idle]),
            builder: (context, _) {
              final breathe = 1.0 + 0.03 * Curves.easeInOut.transform(_idle.value);
              return SizedBox(
                width: double.infinity,
                child: Column(
                children: [
                  const Spacer(flex: 5),
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft navy halo
                        Transform.scale(
                          scale: 0.55 + 0.45 * _halo.value,
                          child: Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.07 * _halo.value),
                            ),
                          ),
                        ),
                        // Gold ring drawing itself, then turning slowly
                        Transform.rotate(
                          angle: _idle.isAnimating ? _idle.value * 0.6 : 0,
                          child: CustomPaint(
                            size: Size.square(ringSize * 0.86),
                            painter: _RingPainter(progress: _ring.value),
                          ),
                        ),
                        // Logo mark
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.rotate(
                            angle: _logoTurn.value,
                            child: Transform.scale(
                              scale: _logoScale.value * breathe,
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => _LogoFallback(size: logoSize),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SlideTransition(
                    position: _titleSlide,
                    child: Opacity(
                      opacity: _titleFade.value,
                      child: const _Wordmark(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 6),
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Text(
                      isSw ? 'Mfumo wa Kisasa wa Kujisomea' : 'Modern Learning Platform',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "Soma" in navy, "Smart" in gold, as on the welcome screen.
class _Wordmark extends StatelessWidget {
  final double fontSize;
  const _Wordmark({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.6);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Soma', style: base.copyWith(color: AppColors.primaryDark)),
        TextSpan(text: 'Smart', style: base.copyWith(color: AppColors.brandGold)),
      ]),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final double size;
  const _LogoFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size * 0.22)),
      child: Center(
        child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.5)),
      ),
    );
  }
}

/// A gold arc that draws from the top, clockwise, as [progress] goes 0 → 1,
/// with a faint full track underneath.
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    final stroke = size.width * 0.028;
    final arcRect = rect.deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.brandGold.withValues(alpha: 0.14 * progress);
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandGold;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress * 0.92, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
