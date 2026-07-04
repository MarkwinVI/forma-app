import 'package:flutter/material.dart';

/// Global color palette — use these instead of hardcoding hex values.
///
/// Matches the polished Forma design language: tonal elevation on a near-black
/// background, one warm accent, soft status tints instead of hard borders.
class AppColors {
  AppColors._();

  // Backgrounds — tonal elevation steps
  static const Color bg = Color(0xFF111114);
  static const Color surface = Color(0xFF1C1C20);
  static const Color surface2 = Color(0xFF29292E);

  // Hairlines / dividers
  static const Color divider = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color cardHighlight =
      Color(0x0BFFFFFF); // rgba(255,255,255,0.045)

  // Text
  static const Color textPrimary = Color(0xFFF7F7F8);
  static const Color textSecondary = Color(0xFFA0A1A9);
  static const Color textMuted = Color(0xFF66676E);

  // Accent
  static const Color accentPrimary = Color(0xFF3D7BFF);
  static const Color accentBright = Color(0xFF3D7BFF);
  static const Color accentSoft = Color(0x223D7BFF);
  static const Color accentGlow = Color(0x3A3D7BFF);

  // Status
  static const Color green = Color(0xFF3FD07E);
  static const Color greenSoft = Color(0x213FD07E); // rgba(63,208,126,0.13)
  static const Color amber = Color(0xFFE9B43D);
  static const Color amberSoft = Color(0x21E9B43D); // rgba(233,180,61,0.13)

  // Legacy aliases — older screens reference these names.
  static const Color bgPrimary = bg;
  static const Color bgSecondary = bg;
  static const Color bgTertiary = surface;

  static const Color borderPrimary = divider;
  static const Color borderSecondary = divider;

  static const Color progressBg = surface2;
  static const Color progressFill = accentPrimary;
}
