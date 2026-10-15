import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Official reusable SomaSmart Logo widget.
///
/// Combines the official "S" logo mark asset with live Flutter typography for "SomaSmart".
/// Supports both mark-only and full mark+text configurations, customizable size,
/// and automatic light/dark theme adaptation.
class SomaSmartLogo extends StatelessWidget {
  /// The width and height of the S logo mark icon.
  final double size;

  /// Whether to display the "SomaSmart" live text next to the logo mark.
  final bool showText;

  /// Optional custom font size for the "SomaSmart" wordmark.
  final double? fontSize;

  /// Optional custom text color override.
  final Color? textColor;

  /// Spacing in logical pixels between the logo mark and the wordmark text.
  final double spacing;

  /// Horizontal alignment / layout axis size.
  final MainAxisSize mainAxisSize;

  const SomaSmartLogo({
    super.key,
    this.size = 34,
    this.showText = true,
    this.fontSize,
    this.textColor,
    this.spacing = 10,
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Convenience constructor for showing only the official S logo mark.
  const SomaSmartLogo.markOnly({
    super.key,
    this.size = 34,
  })  : showText = false,
        fontSize = null,
        textColor = null,
        spacing = 0,
        mainAxisSize = MainAxisSize.min;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final logoMark = Image.asset(
      'assets/images/logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        child: Center(
          child: Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.48,
            ),
          ),
        ),
      ),
    );

    if (!showText) {
      return logoMark;
    }

    final resolvedFontSize = fontSize ?? (size >= 32 ? 20.0 : size * 0.58);
    final resolvedTextColor = textColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoMark,
        SizedBox(width: spacing),
        Text(
          'SomaSmart',
          style: TextStyle(
            fontSize: resolvedFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: resolvedTextColor,
          ),
        ),
      ],
    );
  }
}
