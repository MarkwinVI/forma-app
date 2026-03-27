import 'package:flutter/material.dart';

/// Global color palette — use these instead of hardcoding hex values.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgPrimary   = Color(0xFF252323);
  static const Color bgSecondary = Color(0xFF09090B);
  static const Color bgTertiary  = Color(0xFF18181B);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9F9FA9);
  static const Color textMuted     = Color(0xFF71717B);

  // Accent
  static const Color accentPrimary = Color(0xFFFF6900);
  static const Color accentBright  = Color(0xFFFF8904);

  // Borders
  static const Color borderPrimary   = Color(0xFF27272A);
  static const Color borderSecondary = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)

  // Progress
  static const Color progressBg   = Color(0xFF1A1A1E);
  static const Color progressFill = Color(0xFFFF6900);
}
