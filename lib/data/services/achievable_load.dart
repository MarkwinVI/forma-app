import '../models/exercise_model.dart';
import 'weight_unit_service.dart';

/// Turns a calculated weight into one that can actually be put on the
/// equipment. Forma never shows or prescribes a load the gym cannot make:
/// 25% of an 74 kg bodyweight is 18.6 kg, and there is no such barbell.
///
/// Every equipment type has a ladder of loads it can produce, in the unit
/// the user trains in — a kilogram gym and a pound gym have different plates,
/// so the ladder is built in the display unit and only the answer is carried
/// back to stored kilograms.
///
/// - **Barbell**: the bar, then a plate pair at a time. 20 kg + n × 2.5 kg,
///   or 45 lb + n × 5 lb.
/// - **Dumbbell**: a rack of fixed pieces. 1–10 kg by 1, then by 2; or
///   2.5–30 lb by 2.5, then by 5. Per hand.
/// - **Plates**: a belt, a stack, a kettlebell — nothing, then a plate pair
///   at a time. n × 2.5 kg, or n × 5 lb.
///
/// Snapping goes to the nearest rung. Exactly halfway rounds down, so a
/// borderline load never quietly makes a step harder than it was written.
class AchievableLoad {
  AchievableLoad._();

  static const double barbellMinKg = 20;
  static const double barbellStepKg = 2.5;
  static const double barbellMinLb = 45;
  static const double barbellStepLb = 5;

  static const double plateStepKg = 2.5;
  static const double plateStepLb = 5;

  /// Where the dumbbell rack's fine steps stop and its coarse steps begin.
  static const double dumbbellFineMaxKg = 10;
  static const double dumbbellFineStepKg = 1;
  static const double dumbbellCoarseStepKg = 2;
  static const double dumbbellFineMaxLb = 30;
  static const double dumbbellFineStepLb = 2.5;
  static const double dumbbellCoarseStepLb = 5;

  /// The nearest load the equipment can make, in stored kilograms. Nothing
  /// (zero or less) stays nothing: it means no load was stated, not that a
  /// bar should be found for it.
  static double snapKg(double weightKg, LoadType type) {
    if (weightKg <= 0) return 0;
    final want = WeightUnitService.toDisplay(weightKg);
    final ladder = _Ladder.of(type, WeightUnitService.unit);
    return WeightUnitService.toKg(ladder.nearest(want));
  }

  /// The smallest load the equipment can make above [weightKg], in stored
  /// kilograms — the next step up. From nothing, the first rung: the bar for
  /// a barbell, the lightest dumbbell, one plate pair.
  static double nextKg(double weightKg, LoadType type) {
    final have = weightKg <= 0 ? 0.0 : WeightUnitService.toDisplay(weightKg);
    final ladder = _Ladder.of(type, WeightUnitService.unit);
    return WeightUnitService.toKg(ladder.above(have));
  }
}

/// One equipment's ladder in one unit. A barbell and a plate stack are the
/// same shape — a floor, then even steps — and a dumbbell rack is that shape
/// twice over, fine steps giving way to coarse ones.
class _Ladder {
  final double min;
  final double step;

  /// Where the step size changes, for the dumbbell rack; null for a ladder
  /// whose steps never change.
  final double? coarseFrom;
  final double coarseStep;

  const _Ladder(this.min, this.step, {this.coarseFrom, this.coarseStep = 0});

  factory _Ladder.of(LoadType type, WeightUnit unit) {
    final lb = unit == WeightUnit.lb;
    switch (type) {
      case LoadType.barbell:
        return lb
            ? const _Ladder(
                AchievableLoad.barbellMinLb, AchievableLoad.barbellStepLb)
            : const _Ladder(
                AchievableLoad.barbellMinKg, AchievableLoad.barbellStepKg);
      case LoadType.plates:
        return lb
            ? const _Ladder(0, AchievableLoad.plateStepLb)
            : const _Ladder(0, AchievableLoad.plateStepKg);
      case LoadType.dumbbell:
        return lb
            ? const _Ladder(
                AchievableLoad.dumbbellFineStepLb,
                AchievableLoad.dumbbellFineStepLb,
                coarseFrom: AchievableLoad.dumbbellFineMaxLb,
                coarseStep: AchievableLoad.dumbbellCoarseStepLb,
              )
            : const _Ladder(
                AchievableLoad.dumbbellFineStepKg,
                AchievableLoad.dumbbellFineStepKg,
                coarseFrom: AchievableLoad.dumbbellFineMaxKg,
                coarseStep: AchievableLoad.dumbbellCoarseStepKg,
              );
    }
  }

  /// The rung nearest [want]; halfway rounds down.
  double nearest(double want) {
    if (want <= min) return min;
    final below = _floor(want);
    final above = _next(below);
    // A hair of float slack on the tie, so 21.25 between 20 and 22.5 reads
    // as the tie it is and rounds down.
    return (want - below) <= (above - want) + 1e-9 ? below : above;
  }

  /// The first rung strictly above [have].
  double above(double have) {
    if (have < min) return min;
    return _next(_floor(have));
  }

  /// The highest rung at or below [want], which is at least [min].
  double _floor(double want) {
    final from = coarseFrom;
    if (from != null && want >= from) {
      return from + ((want - from) / coarseStep + 1e-9).floor() * coarseStep;
    }
    return min + ((want - min) / step + 1e-9).floor() * step;
  }

  /// The rung after [rung].
  double _next(double rung) {
    final from = coarseFrom;
    if (from != null && rung >= from - 1e-9) return rung + coarseStep;
    return rung + step;
  }
}
