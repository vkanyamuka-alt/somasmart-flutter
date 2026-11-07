import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/env.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import 'auth_layout.dart';

/// "or" divider + "Continue with Google", shown under the phone sign-in and
/// sign-up forms. Hidden in builds without GOOGLE_WEB_CLIENT_ID.
class GoogleSignInSection extends ConsumerWidget {
  /// Shows an error from Google on the screen's own error banner.
  final ValueChanged<String?> onError;

  /// Builds without a client ID show nothing; tests can force the section on.
  final bool? enabledOverride;

  const GoogleSignInSection({super.key, required this.onError, this.enabledOverride});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    onError(null);
    final lang = ref.read(languageProvider);
    final result = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!context.mounted || result.cancelled) return;
    if (result.isSuccess) {
      context.go(result.needsProfile ? '/complete-profile' : '/home');
    } else {
      final error = ref.read(authControllerProvider).error ?? result.errorMessage;
      onError(AuthController.getLocalizedErrorMessage(error, lang));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(enabledOverride ?? Env.googleSignInConfigured)) return const SizedBox.shrink();

    final isSw = ref.watch(languageProvider) == 'sw';
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Column(
      children: [
        const SizedBox(height: 18),
        AuthDivider(isSw ? 'au' : 'or'),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            key: const Key('google-sign-in'),
            onPressed: isLoading ? null : () => _continue(context, ref),
            style: OutlinedButton.styleFrom(
              // Google's rules: white button, grey outline, the "G" unchanged.
              // The sign-in screens are always light.
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GoogleMarkPainter())),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    isSw ? 'Endelea na Google' : 'Continue with Google',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Google's multicolour "G", drawn as four arcs and the crossbar (no image
/// asset or extra package needed).
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(center: Offset(s / 2, s / 2), radius: (s - stroke) / 2);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = 3.14159265 / 180;
    canvas.drawArc(rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335))); // red, top
    canvas.drawArc(rect, -140 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05))); // yellow, left
    canvas.drawArc(rect, 130 * deg, -95 * deg, false, arc(const Color(0xFF34A853))); // green, bottom
    canvas.drawArc(rect, 35 * deg, -35 * deg, false, arc(const Color(0xFF4285F4))); // blue, right
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
