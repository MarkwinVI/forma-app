import 'package:flutter/material.dart';

import '../widgets/type_led.dart';
import 'app_colors.dart';

/// The app's real type scale, as a [TextTheme] so new code can reach it
/// through `Theme.of(context).textTheme` instead of another literal: display
/// 34/800 with tight tracking, title 21/800, body 16 and 15, label 13.5/700,
/// and the mono eyebrow (labelSmall) from [monoStyle].
final TextTheme formaTextTheme = TextTheme(
  displayLarge: const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.02,
    height: 1.06,
    color: AppColors.textPrimary,
  ),
  displayMedium: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.96,
    height: 1.05,
    color: AppColors.textPrimary,
  ),
  headlineMedium: const TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.54,
    color: AppColors.textPrimary,
  ),
  titleLarge: const TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.42,
    height: 1.15,
    color: AppColors.textPrimary,
  ),
  titleMedium: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.36,
    color: AppColors.textPrimary,
  ),
  bodyLarge: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
    color: AppColors.textPrimary,
  ),
  // bodyMedium is what an unstyled Text falls back to, so it stays primary;
  // the secondary colour is applied where a line is meant to step back.
  bodyMedium: const TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
  ),
  bodySmall: const TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  ),
  labelLarge: const TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  ),
  labelMedium: monoStyle(size: 11.5, letterSpacing: 1),
  labelSmall: monoStyle(),
);
