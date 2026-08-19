import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The unit weights are shown and typed in. Kilograms stay the canonical
/// stored unit everywhere; pounds exist only at the display edge.
enum WeightUnit { kg, lb }

extension WeightUnitX on WeightUnit {
  /// The suffix weights are written with — "60kg", "132.3lbs".
  String get suffix => this == WeightUnit.kg ? 'kg' : 'lbs';

  String get dbValue => this == WeightUnit.kg ? 'kg' : 'lb';
}

/// One app-wide weight unit, chosen once (program setup or the profile's
/// bodyweight editor) and remembered. Every surface that prints or reads a
/// weight goes through this service, so flipping the unit flips the app.
class WeightUnitService {
  static const _prefsKey = 'weight_unit';
  static const double kgPerLb = 0.45359237;

  /// The current unit; listen to repaint when it changes.
  static final ValueNotifier<WeightUnit> notifier =
      ValueNotifier(WeightUnit.kg);

  static WeightUnit get unit => notifier.value;

  /// Restores the remembered unit. Called once at startup, before any
  /// weight is rendered.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsKey) == 'lb') {
        notifier.value = WeightUnit.lb;
      }
    } catch (_) {
      // Fall back to kilograms; the next explicit choice persists again.
    }
  }

  static Future<void> set(WeightUnit value) async {
    notifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, value.dbValue);
    } catch (_) {
      // The in-memory unit is already switched; persistence is best-effort.
    }
  }

  /// A stored kilogram value in the display unit.
  static double toDisplay(double kg) =>
      unit == WeightUnit.lb ? kg / kgPerLb : kg;

  /// A typed display-unit value back to canonical kilograms.
  static double toKg(double display) =>
      unit == WeightUnit.lb ? display * kgPerLb : display;

  /// The number as the app writes weights: converted to the display unit,
  /// whole numbers whole, anything else with one decimal. No suffix.
  static String displayText(double kg) {
    final value = toDisplay(kg);
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }

  /// "60kg" / "132.3lbs" — number and suffix, no space.
  static String label(double kg) => '${displayText(kg)}${unit.suffix}';
}
