import 'package:flutter/material.dart';
import '../../features/tutor/presentation/widgets/ask_me_floating_panel.dart';
import '../theme/app_colors.dart';

/// Floating "Ask me" button: a round 52dp sparkles button, so it covers as
/// little of the page as possible (same as the web on phones). "Ask me" stays
/// its tooltip and screen-reader label. Tapping opens the SomaSmart AI panel.
class FloatingAskMeButton extends StatelessWidget {
  final VoidCallback? onTap;

  static const double size = 52;

  const FloatingAskMeButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ask me',
      child: Semantics(
        button: true,
        label: 'Ask me',
        excludeSemantics: true,
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onTap ?? () => AskMeFloatingPanel.show(context),
            customBorder: const CircleBorder(),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
