import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'card_surface.dart';

/// Building blocks shared by the dashboard, Settings and other grouped screens.
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

/// Dashboard feature card: icon tile, title, one-line description, chevron.
/// [compact] is the phone tile: icon, title and arrow in one row, as on the
/// web's phone layout.
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool compact;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.compact = false,
  });

  FeatureCard asCompact() =>
      FeatureCard(key: key, icon: icon, title: title, description: description, onTap: onTap, compact: true);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (compact) {
      return Semantics(
        button: true,
        label: title,
        excludeSemantics: true,
        child: CardSurface(
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m - 2, AppSpacing.m - 2, AppSpacing.m - 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              children: [
                IconTile(icon, size: 36),
                const SizedBox(width: AppSpacing.s + 2),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 16, color: isDark ? AppColors.primaryLight : AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: CardSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.m + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays out feature cards two per row (three on wide screens), with every
/// card in a row the same height.
class FeatureGrid extends StatelessWidget {
  final List<FeatureCard> cards;
  const FeatureGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += columns) {
          final rowCards = cards.sublist(i, (i + columns).clamp(0, cards.length));
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.m - 2),
                  Expanded(child: c < rowCards.length ? rowCards[c] : const SizedBox()),
                ],
              ],
            ),
          ));
          if (i + columns < cards.length) rows.add(const SizedBox(height: AppSpacing.m - 2));
        }
        return Column(children: rows);
      },
    );
  }
}

/// Status pill: dot and label on a soft tint.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
