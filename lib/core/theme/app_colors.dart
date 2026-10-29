import 'package:flutter/material.dart';

/// SomaSmart colour tokens, the same palette as the web app
/// (see `SomaSmart App/docs/DESIGN_SYSTEM.md`): logo navy for actions,
/// gold sparingly for highlights, slate neutrals and three status colours.
class AppColors {
  AppColors._();

  // Brand, measured from the logo.
  static const Color primary = Color(0xFF184E78);
  static const Color primaryLight = Color(0xFF3D7AB0);
  static const Color primaryDark = Color(0xFF123B5B);
  static const Color primaryGlow = Color(0x33184E78);
  static const Color primarySoft = Color(0xFFE8EFF6);
  static const Color brandGold = Color(0xFFDB9E3D);
  static const Color brandGoldSoft = Color(0xFFFBF3E4);

  // Hero tones
  static const Color heroNavyDark = Color(0xFF0B1A36);
  static const Color heroBannerBgLight = Color(0xFFEDF3FA);
  static const Color heroBannerBgDark = Color(0xFF0E1726);

  // Secondary accents stay within the navy family (no cyan or purple in the UI).
  static const Color secondary = Color(0xFF2F6B9A);
  static const Color accentPurple = primaryLight;
  static const Color accentGold = brandGold;

  // Status colours. Theme-independent constants, so each is a mid-tone that
  // reads on both the light and the dark background.
  static const Color success = Color(0xFF1F9254);
  static const Color successBg = Color(0x1A1F9254);
  static const Color error = Color(0xFFD1433B);
  static const Color errorBg = Color(0x1AD1433B);
  static const Color danger = error;
  static const Color dangerBg = errorBg;
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBg = Color(0x1AB7791F);
  static const Color info = primaryLight;

  // Dark theme
  static const Color darkBgBase = Color(0xFF090D16);
  static const Color darkBgSurface = Color(0xFF0F172A);
  static const Color darkBgContainer = Color(0xFF1E293B);
  static const Color darkBgContainerHigh = Color(0xFF334155);
  static const Color darkBorder = Color(0x1AFFFFFF); // white at 10%
  static const Color darkBorderSubtle = Color(0x0FFFFFFF); // white at 6%
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light theme
  static const Color lightBgBase = Color(0xFFF4F6F9);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgContainer = Color(0xFFF1F5F9);
  static const Color lightBgContainerHigh = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Overlays
  static const Color darkGlassBg = Color(0xCC0F172A); // 80% opacity
  static const Color lightGlassBg = Color(0xCCFFFFFF);
}

/// Spacing, radius and sizing tokens shared with the web design system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter on phones.
  static const double gutter = 16;

  /// Bottom padding that keeps content clear of the bottom navigation and
  /// the floating Ask me button.
  static const double bottomNavClearance = 96;
}

class AppRadius {
  AppRadius._();

  static const double tile = 10;
  static const double control = 12;
  static const double card = 16;
  static const double hero = 20;
}
