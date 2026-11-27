import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'card_surface.dart';

/// Building blocks for Settings and other grouped screens.
/// They mirror the web components described in docs/DESIGN_SYSTEM.md.

/// Uppercase muted label above a group of cards or rows.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }
}

/// Square-ish tile holding an icon, tinted with the brand's soft navy.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool danger;
  const IconTile(this.icon, {super.key, this.size = 38, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = danger ? AppColors.error : (isDark ? AppColors.primaryLight : AppColors.primary);
    final Color bg = danger
        ? AppColors.errorBg
        : (isDark ? AppColors.primaryLight.withValues(alpha: 0.14) : AppColors.primarySoft);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Icon(icon, size: size * 0.52, color: fg),
    );
  }
}

/// A labelled group of rows inside one card, as in the web Settings page.
class SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const SettingsGroup({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(height: 1, thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(divider);
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl - 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          CardSurface(padding: EdgeInsets.zero, child: Column(children: rows)),
        ],
      ),
    );
  }
}

/// One settings row: icon tile, title, optional subtitle, then a chevron or a control.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = danger ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          child: Row(
            children: [
              IconTile(icon, size: 34, danger: danger),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null && showChevron && onTap != null) Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
