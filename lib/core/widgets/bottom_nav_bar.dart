import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../theme/app_colors.dart';

/// Bottom navigation for the 5 core tabs, with the same labels as the web app.
class SomaSmartBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SomaSmartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSw = ref.watch(languageProvider) == 'sw';

    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: isSw ? 'Nyumbani' : 'Home',
      ),
      _NavItem(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag_rounded,
        label: isSw ? 'Duka' : 'Shop',
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: isSw ? 'Maendeleo' : 'Progress',
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: isSw ? 'Akaunti' : 'Account',
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: isSw ? 'Mipangilio' : 'Settings',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.1))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
