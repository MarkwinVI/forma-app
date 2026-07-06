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

  // Home redesign palette (graphite surfaces + green/blue signals)
  static const Color bgBase       = Color(0xFF111114);
  static const Color surfaceCard  = Color(0xFF1C1C20);
  static const Color surfaceChip  = Color(0xFF29292E);
  static const Color surfaceTrack = Color(0xFF3A3A40);
  static const Color textStrong   = Color(0xFFF7F7F8);
  static const Color textMid      = Color(0xFFA0A1A9);
  static const Color textFaint    = Color(0xFF66676E);
  static const Color signalGreen  = Color(0xFF3FD07E);
  static const Color signalBlue   = Color(0xFF4C8DFF);
  static const Color startOrange  = Color(0xFFFC5200);
}
