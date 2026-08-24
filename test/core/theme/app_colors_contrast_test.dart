import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/theme/app_colors.dart';

/// WCAG relative luminance and contrast ratio, so the palette's small text
/// (the 10–11pt mono eyebrows set in textMuted) is held to 4.5:1 on every
/// surface it appears on.
double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _channel(color.r) +
    0.7152 * _channel(color.g) +
    0.0722 * _channel(color.b);

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const surfaces = {
    'bg': AppColors.bg,
    'surface': AppColors.surface,
    'surface2': AppColors.surface2,
  };

  for (final entry in surfaces.entries) {
    test('textMuted reads at 4.5:1 or better on ${entry.key}', () {
      expect(
        contrastRatio(AppColors.textMuted, entry.value),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('textSecondary reads at 4.5:1 or better on ${entry.key}', () {
      expect(
        contrastRatio(AppColors.textSecondary, entry.value),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('the muted step stays clearly quieter than the secondary one', () {
    expect(
      contrastRatio(AppColors.textMuted, AppColors.bg),
      lessThan(contrastRatio(AppColors.textSecondary, AppColors.bg)),
    );
  });

  test('white on the accent clears 3:1, the floor for 16pt bold CTAs', () {
    expect(
      contrastRatio(Colors.white, AppColors.accentPrimary),
      greaterThanOrEqualTo(3),
    );
  });
}
