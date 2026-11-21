import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/forum_role.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// "Mwalimu / Teacher" (gold) or "Admin" (blue) next to a forum author's name.
class ForumRoleBadge extends ConsumerWidget {
  const ForumRoleBadge({super.key, required this.role, this.fontSize = 10});

  final String? role;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = forumRoleBadge(role, ref.watch(languageProvider));
    if (info == null) return const SizedBox.shrink();
    final isTeacher = info.kind == ForumRoleKind.teacher;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isTeacher
        ? (isDark ? AppColors.brandGold : const Color(0xFF8A5A12))
        : Colors.blue;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (isTeacher ? AppColors.brandGold : Colors.blue).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          info.label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
