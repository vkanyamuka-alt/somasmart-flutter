import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

/// Welcome screen shown after the splash, before sign-in.
///
/// Layout adapts to the screen:
/// * phones (portrait): photo on top (~45% of the height, less on short
///   screens) fading into the page, then headline, subtitle and four feature
///   icons; "Get Started" stays near the bottom with a "Log in" link under it.
///   On very short screens the content scrolls instead of overflowing.
/// * tablets / landscape: photo on the left, content on the right.
/// Always light, whatever the app theme.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.value = 1.0;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go(String route) async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) context.go(route);
  }

  /// Fade + rise for one piece of content, between [begin] and [end] of the intro.
  Widget _reveal(double begin, double end, Widget child, {double rise = 18}) {
    final t = CurvedAnimation(parent: _c, curve: Interval(begin, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(offset: Offset(0, rise * (1 - t.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = ref.watch(languageProvider) == 'sw';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > box.maxHeight && box.maxWidth >= 600;
            return wide ? _wideLayout(box, isSw) : _portraitLayout(box, isSw);
          },
        ),
      ),
    );
  }

  Widget _portraitLayout(BoxConstraints box, bool isSw) {
    final h = box.maxHeight;
    final compact = h < 700;
    final tablet = box.maxWidth >= 600;
    // Taller screens give the photo more room so the page does not feel empty.
    final heroShare = compact ? 0.38 : (h > 900 ? 0.50 : 0.45);
    final heroHeight = (h * heroShare).clamp(210.0, 600.0);

    return Column(
      children: [
        SizedBox(
          height: heroHeight,
          child: _hero(isSw, fadeToBottom: true, wideFrame: box.maxWidth / heroHeight > 1.4),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, inner) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: inner.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _content(isSw, compact: compact, scale: tablet ? 1.18 : 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wideLayout(BoxConstraints box, bool isSw) {
    return Row(
      children: [
        Expanded(child: _hero(isSw, fadeToBottom: false)),
        Expanded(
          child: SafeArea(
            left: false,
            child: LayoutBuilder(
              builder: (context, inner) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: inner.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _content(isSw, compact: box.maxHeight < 500, showBrand: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Photo with the brand chip and language switch over it.
  Widget _hero(bool isSw, {required bool fadeToBottom, bool wideFrame = false}) {
    final zoom = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic));
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: zoom,
          builder: (context, child) => Opacity(
            opacity: zoom.value,
            child: Transform.scale(scale: 1.08 - 0.08 * zoom.value, child: child),
          ),
          child: Image.asset(
            'assets/images/welcome_hero_portrait.jpg',
            fit: BoxFit.cover,
            // A wide, short frame crops top and bottom: aim higher to keep the face whole.
            alignment: Alignment(-0.15, wideFrame ? -0.75 : -0.35),
            errorBuilder: (context, error, stackTrace) => const ColoredBox(color: AppColors.primarySoft),
          ),
        ),
        // Light wash at the top so the chips stay readable on any crop.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),
        if (fadeToBottom)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  // Shrinks instead of overflowing on narrow screens or large text.
                  if (fadeToBottom)
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _BrandChip(),
                      ),
                    ),
                  const Spacer(),
                  _LanguageSwitch(
                    isSw: isSw,
                    onChanged: (code) => ref.read(languageProvider.notifier).setLanguage(code),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(bool isSw, {required bool compact, bool showBrand = false, double scale = 1.0}) {
    final headlineSize = (compact ? 25.0 : 29.0) * scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: compact ? 8 : 14),
        if (showBrand) ...[
          _reveal(0.10, 0.45, const _BrandChip(plain: true)),
          const SizedBox(height: 18),
        ],
        _reveal(
          0.20,
          0.60,
          Text(
            isSw ? 'Mustakabali mzuri\nunaanzia hapa' : 'A brighter future\nstarts here',
            style: TextStyle(
              fontSize: headlineSize,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.6,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _reveal(
          0.28,
          0.64,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.brandGold, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 12),
        _reveal(
          0.32,
          0.70,
          Text(
            isSw
                ? 'Muhtasari wa O-Level na A-Level, video, majaribio ya maabara na mwalimu wa AI, mahali pamoja.'
                : 'O-level and A-level notes, videos, practical simulations and an AI tutor, all in one place.',
            style: TextStyle(
              fontSize: (compact ? 14.5 : 15.5) * scale,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ),
        SizedBox(height: compact ? 18 : 26),
        _features(isSw, compact: compact, scale: scale),
        SizedBox(height: compact ? 20 : 28),
        const Spacer(),
        _reveal(
          0.60,
          1.00,
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              key: const Key('welcome-get-started'),
              onPressed: () => _go('/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSw ? 'Anza Sasa' : 'Get Started',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          rise: 28,
        ),
        const SizedBox(height: 6),
        _reveal(
          0.70,
          1.00,
          Center(
            child: TextButton(
              key: const Key('welcome-login'),
              onPressed: () => _go('/login'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14.5, color: AppColors.lightTextSecondary),
                  children: [
                    TextSpan(text: isSw ? 'Una akaunti tayari? ' : 'Already have an account? '),
                    TextSpan(
                      text: isSw ? 'Ingia' : 'Log in',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 12),
      ],
    );
  }

  Widget _features(bool isSw, {required bool compact, double scale = 1.0}) {
    final items = [
      (Icons.menu_book_rounded, isSw ? 'Muhtasari\nwa masomo' : 'Study\nnotes'),
      (Icons.play_circle_outline_rounded, isSw ? 'Video\nza masomo' : 'Video\nlessons'),
      (Icons.science_outlined, isSw ? 'Majaribio\nya maabara' : 'Practical\nsimulations'),
      (Icons.psychology_outlined, isSw ? 'Mwalimu\nwa AI' : 'AI\ntutor'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _reveal(
              0.40 + i * 0.07,
              0.75 + i * 0.06,
              _Feature(icon: items[i].$1, label: items[i].$2, compact: compact, scale: scale),
            ),
          ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final double scale;
  const _Feature({required this.icon, required this.label, required this.compact, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final circle = (compact ? 46.0 : 52.0) * scale;
    return Column(
      children: [
        Container(
          width: circle,
          height: circle,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: circle * 0.48),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: (compact ? 11.5 : 12.5) * scale,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  final bool plain;
  const _BrandChip({this.plain = false});

  @override
  Widget build(BuildContext context) {
    const word = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', width: 28, height: 28),
        const SizedBox(width: 8),
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Soma', style: word.copyWith(color: AppColors.primaryDark)),
          TextSpan(text: 'Smart', style: word.copyWith(color: AppColors.brandGold)),
        ])),
      ],
    );
    if (plain) return row;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: row,
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  final bool isSw;
  final ValueChanged<String> onChanged;
  const _LanguageSwitch({required this.isSw, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String code, String label, bool active) => GestureDetector(
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('sw', 'SW', isSw), option('en', 'EN', !isSw)],
      ),
    );
  }
}
