import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Official SomaSmart Splash & Startup Screen.
///
/// Features the official "S" logo mark, live "SomaSmart" typography,
/// and localized tagline with a smooth, subtle startup animation sequence.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration animationDuration;
  final Duration holdDuration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.animationDuration = const Duration(milliseconds: 1100),
    this.holdDuration = const Duration(milliseconds: 500),
    this.autoNavigate = true,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // 1. Logo fades and scales gently from 0.85 to 1.0 (0.0 -> 0.6)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Title "SomaSmart" fades and slides smoothly (0.35 -> 0.8)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tagline fades in subtly (0.55 -> 1.0)
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _startStartupSequence();
  }

  Future<void> _startStartupSequence() async {
    await _controller.forward();
    if (widget.autoNavigate) {
      await Future.delayed(widget.holdDuration);
      if (mounted) {
        try {
          final client = ref.read(supabaseClientProvider);
          final user = client.auth.currentUser;
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/welcome');
          }
        } catch (_) {
          context.go('/welcome');
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);

    final tagline = currentLang == 'sw'
        ? 'Jifunze Haraka. Elewa Zaidi.\nMudu Kila Mada.'
        : 'Learn Fast. Understand Deeply.\nMaster Every Topic.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.lightBgSurface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // 1. Official S Logo Mark
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'S',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Live "SomaSmart" Typography Wordmark
                  SlideTransition(
                    position: _titleSlideAnimation,
                    child: FadeTransition(
                      opacity: _titleFadeAnimation,
                      child: const Text(
                        'SomaSmart',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Localized Tagline
                  FadeTransition(
                    opacity: _taglineFadeAnimation,
                    child: Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.1,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Minimal Brand Footer Indicator
                  FadeTransition(
                    opacity: _taglineFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBgContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightBorderSubtle,
                        ),
                      ),
                      child: Text(
                        currentLang == 'sw'
                            ? 'Mfumo wa Kisasa wa Kujisomea'
                            : 'Modern Learning Platform',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
