import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Clean academic tag/badge for subjects, forms, and status indicators.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isFilled;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.primaryLight;
    final fgColor = textColor ?? baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? baseColor : baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFilled ? baseColor : baseColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: isFilled ? Colors.white : fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isFilled ? Colors.white : fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
