import 'package:flutter/material.dart';

/// Design tokens for SomaSmart's academic color system.
class AppColors {
  AppColors._();

  // Primary brand colours, measured from the logo (same palette as the web):
  // navy #184E78 for actions, deep navy for headings, gold #DB9E3D sparingly.
  static const Color primary = Color(0xFF184E78);
  static const Color primaryLight = Color(0xFF3D7AB0);
  static const Color primaryDark = Color(0xFF123B5B);
  static const Color primaryGlow = Color(0x33184E78);
  static const Color primarySoft = Color(0xFFE8EFF6);
  static const Color brandGold = Color(0xFFDB9E3D);
  static const Color brandGoldSoft = Color(0xFFFBF3E4);
  
  // Hero Section Special Tones
  static const Color heroNavyDark = Color(0xFF0B1A36);
  static const Color heroBannerBgLight = Color(0xFFEDF3FA);
  static const Color heroBannerBgDark = Color(0xFF0E1726);

  // Secondary / Academic Accents
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentGold = brandGold;
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color danger = error;
  static const Color dangerBg = errorBg;
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color info = Color(0xFF38BDF8);

  // Dark Theme Palette
  static const Color darkBgBase = Color(0xFF090D16);
  static const Color darkBgSurface = Color(0xFF0F172A);
  static const Color darkBgContainer = Color(0xFF1E293B);
  static const Color darkBgContainerHigh = Color(0xFF334155);
  static const Color darkBorder = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)
  static const Color darkBorderSubtle = Color(0x0FFFFFFF); // rgba(255, 255, 255, 0.06)
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette
  static const Color lightBgBase = Color(0xFFF8FAFC);
  static const Color lightBgSurface = Color(0xFFFFFFFF);
  static const Color lightBgContainer = Color(0xFFF1F5F9);
  static const Color lightBgContainerHigh = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0x1A0F172A); // rgba(15, 23, 42, 0.1)
  static const Color lightBorderSubtle = Color(0x0F0F172A);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Glassmorphic Overlays (Restrained)
  static const Color darkGlassBg = Color(0xCC0F172A); // 80% opacity
  static const Color lightGlassBg = Color(0xCCFFFFFF);
}
