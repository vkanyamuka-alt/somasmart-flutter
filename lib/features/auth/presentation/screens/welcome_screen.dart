import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

/// Official SomaSmart Welcome & Onboarding Screen.
///
/// Designed to match the official design reference:
/// 1. Upper Photo Section (~44-46% height): Hero student photograph with
///    top-right "A Brighter Future Starts Here" headline and gold accent bar.
/// 2. Wave Transition: Subtle, elegant flowing light-blue curves connecting the photo into the lower section.
/// 3. Lower Content Section:
///    - Centered SomaSmart branding ([S Logo] + "SomaSmart")
///    - Value proposition headline: "O-level & A-level notes, Videos, practical simulations and AI tutor."
///    - Gold accent line
///    - Supporting tagline: "Study smarter. Go further with SomaSmart."
///    - 4 Feature Pillars: Comprehensive Notes, Videos, Practical Simulations, AI Tutor Support
///    - Primary Action: Prominent "Get Started ->" button routing to Login/Sign Up.
///
/// NOTE: The Welcome Screen is strictly styled in Light Theme regardless of the global app theme.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isSw = lang == 'sw';
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Balanced portrait hero image region (~36-38% of viewport height)
    final photoHeight = (screenHeight * 0.37).clamp(240.0, 310.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background soft ambient waves & subtle corner accents
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundAmbientPainter(),
            ),
          ),

          // Scrollable content wrapper for responsiveness
          SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --------------------------------------------------------
                  // 1. UPPER PHOTO SECTION (~36-38% of viewport)
                  // --------------------------------------------------------
                  SizedBox(
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Main Student Hero Photograph
                        Image.asset(
                          'assets/images/welcome_student.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.0, -0.18),
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),

                        // Top-Right Soft Legibility Gradient
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 90,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.70),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top-Right Headline ("A Brighter Future Starts Here")
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 10.0,
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isSw
                                        ? 'Mustakabali\nMzuri Unaanzia\nHapa'
                                        : 'A Brighter\nFuture Starts\nHere',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      color: Color(0xFF0F294A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 26,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Layered Decorative Transition Waves at Bottom of Photo
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 44,
                          child: CustomPaint(
                            painter: _HeroWaveTransitionPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------------------
                  // 2. LOWER CONTENT SECTION (Cohesive, balanced layout)
                  // --------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // 1. Centered SomaSmart Branding ([S Logo] SomaSmart)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'S',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Soma',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF0B2545),
                                  ),
                                ),
                                Text(
                                  'Smart',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 2. Main Feature Text
                        Text(
                          isSw
                              ? 'Muhtasari wa masomo ya O-Level na A-Level, Video,\nmajaribio ya maabara na mwalimu wa AI.'
                              : 'O-level & A-level notes, Videos,\npractical simulations and AI tutor.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            height: 1.30,
                            letterSpacing: -0.3,
                            color: Color(0xFF0A2540),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 3. Gold Brand Accent Bar
                        Container(
                          width: 36,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. Supporting Tagline
                        Text(
                          isSw
                              ? 'Jifunze kwa ufanisi. Fika mbali na SomaSmart.'
                              : 'Study smarter. Go further with SomaSmart.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 5. 4 Feature Pillars Row with Subtle Dividers
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                            vertical: 2.0,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pillar 1: Notes
                              Expanded(
                                child: _buildFeaturePillar(
                                  icon: Icons.menu_book_rounded,
                                  iconColor: const Color(0xFF0284C7),
                                  bgColor: const Color(0xFFE0F2FE),
                                  label: isSw
                                      ? 'Muhtasari\nwa Masomo'
                                      : 'Comprehensive\nNotes',
                                ),
                              ),
                              _buildPillarDivider(),

                              // Pillar 2: Videos
                              Expanded(
                                child: _buildFeaturePillar(
                                  icon: Icons.play_arrow_rounded,
                                  iconColor: const Color(0xFFD97706),
                                  bgColor: const Color(0xFFFEF3C7),
                                  label: isSw ? 'Video' : 'Videos',
                                ),
                              ),
                              _buildPillarDivider(),

                              // Pillar 3: Practicals
                              Expanded(
                                child: _buildFeaturePillar(
                                  icon: Icons.science_rounded,
                                  iconColor: const Color(0xFF9333EA),
                                  bgColor: const Color(0xFFF3E8FF),
                                  label: isSw
                                      ? 'Majaribio ya\nMaabara'
                                      : 'Practical\nSimulations',
                                ),
                              ),
                              _buildPillarDivider(),

                              // Pillar 4: AI Tutor
                              Expanded(
                                child: _buildFeaturePillar(
                                  icon: Icons.psychology_rounded,
                                  iconColor: const Color(0xFF16A34A),
                                  bgColor: const Color(0xFFDCFCE7),
                                  label: isSw
                                      ? 'Msaada wa\nMwalimu wa AI'
                                      : 'AI Tutor\nSupport',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 6. Primary Action: "Get Started ->" ("Anza Sasa ->")
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(
                                      onboardingCompletedProvider.notifier)
                                  .completeOnboarding();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppColors.primary
                                  .withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isSw ? 'Anza Sasa' : 'Get Started',
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget rendering a single feature pillar item
  Widget _buildFeaturePillar({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  /// Subtle vertical divider between pillars
  Widget _buildPillarDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.only(top: 3),
      color: const Color(0xFFE2E8F0),
    );
  }
}

/// Custom painter rendering multi-layered organic flowing waves
/// between the photo section and the lower content area.
class _HeroWaveTransitionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Back wave layer (soft translucent blue)
    final paintBack = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final pathBack = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.05,
        size.width * 0.65,
        size.height * 0.70,
        size.width,
        size.height * 0.25,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(pathBack, paintBack);

    // 2. Front wave layer (seamless transition into white background)
    final paintFront = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pathFront = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.85,
        size.width * 0.70,
        size.height * 0.30,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(pathFront, paintFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter rendering ambient background soft bubbles and bottom wave
class _BackgroundAmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Left ambient soft circle
    final paintCircleLeft = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(0, size.height * 0.58),
      36,
      paintCircleLeft,
    );

    // Right ambient soft circle
    final paintCircleRight = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width + 10, size.height * 0.52),
      44,
      paintCircleRight,
    );

    // Bottom soft decorative curve
    final paintBottom = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final pathBottom = Path()
      ..moveTo(0, size.height - 28)
      ..cubicTo(
        size.width * 0.35,
        size.height - 48,
        size.width * 0.65,
        size.height - 12,
        size.width,
        size.height - 36,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
