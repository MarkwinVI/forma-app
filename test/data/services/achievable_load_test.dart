import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/services/achievable_load.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';
import 'package:forma_app/data/services/program_start_service.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';

/// Forma never shows or prescribes a load the gym cannot make. Every
/// calculated weight — a bodyweight-percentage rung, an auto-progression
/// step — is snapped to what the equipment can actually hold before anyone
/// sees it.
void main() {
  setUp(() => WeightUnitService.notifier.value = WeightUnit.kg);

  group('a barbell', () {
    test('starts at the bar and climbs a plate pair at a time', () {
      expect(AchievableLoad.snapKg(18.6, LoadType.barbell), 20);
      expect(AchievableLoad.snapKg(21.5, LoadType.barbell), 22.5);
      expect(AchievableLoad.snapKg(40, LoadType.barbell), 40);
      expect(AchievableLoad.snapKg(41, LoadType.barbell), 40);
      expect(AchievableLoad.snapKg(41.5, LoadType.barbell), 42.5);
    });

    test('exactly halfway rounds down', () {
      // 21.25 sits between 20 and 22.5; the lighter one keeps the step from
      // getting harder than it was written.
      expect(AchievableLoad.snapKg(21.25, LoadType.barbell), 20);
    });

    test('the next step up is one plate pair', () {
      expect(AchievableLoad.nextKg(40, LoadType.barbell), 42.5);
      // Between rungs, the next rung — not "this plus a pair".
      expect(AchievableLoad.nextKg(41, LoadType.barbell), 42.5);
      // From nothing, the bar.
      expect(AchievableLoad.nextKg(0, LoadType.barbell), 20);
    });

    test('in pounds it is a 45 lb bar climbing by 5', () {
      WeightUnitService.notifier.value = WeightUnit.lb;
      const kgPerLb = WeightUnitService.kgPerLb;

      // 18.6 kg is 41 lb — under the bar.
      expect(AchievableLoad.snapKg(18.6, LoadType.barbell),
          closeTo(45 * kgPerLb, 1e-9));
      // 100 lb is a rung; 102 lb is not, and 100 is nearer than 105.
      expect(AchievableLoad.snapKg(102 * kgPerLb, LoadType.barbell),
          closeTo(100 * kgPerLb, 1e-9));
      expect(AchievableLoad.nextKg(100 * kgPerLb, LoadType.barbell),
          closeTo(105 * kgPerLb, 1e-9));
    });
  });

  group('a dumbbell rack', () {
    test('climbs by one kilogram to ten, then by two', () {
      expect(AchievableLoad.nextKg(8, LoadType.dumbbell), 9);
      expect(AchievableLoad.nextKg(10, LoadType.dumbbell), 12);
      expect(AchievableLoad.nextKg(12, LoadType.dumbbell), 14);
      expect(AchievableLoad.snapKg(11, LoadType.dumbbell), 10);
      expect(AchievableLoad.snapKg(11.5, LoadType.dumbbell), 12);
      // The lightest piece from nothing.
      expect(AchievableLoad.nextKg(0, LoadType.dumbbell), 1);
    });

    test('in pounds it climbs by 2.5 to 30, then by 5', () {
      WeightUnitService.notifier.value = WeightUnit.lb;
      const kgPerLb = WeightUnitService.kgPerLb;

      expect(AchievableLoad.nextKg(25 * kgPerLb, LoadType.dumbbell),
          closeTo(27.5 * kgPerLb, 1e-9));
      expect(AchievableLoad.nextKg(30 * kgPerLb, LoadType.dumbbell),
          closeTo(35 * kgPerLb, 1e-9));
    });
  });

  group('plates on a belt or a stack', () {
    test('start at nothing and climb by a plate pair', () {
      expect(AchievableLoad.snapKg(12, LoadType.plates), 12.5);
      expect(AchievableLoad.snapKg(1, LoadType.plates), 0);
      expect(AchievableLoad.snapKg(1.25, LoadType.plates), 0);
      expect(AchievableLoad.snapKg(1.3, LoadType.plates), 2.5);
      expect(AchievableLoad.nextKg(0, LoadType.plates), 2.5);
      expect(AchievableLoad.nextKg(10, LoadType.plates), 12.5);
    });
  });

  test('nothing stays nothing — zero is no load stated, not a load to find',
      () {
    expect(AchievableLoad.snapKg(0, LoadType.barbell), 0);
    expect(AchievableLoad.snapKg(-3, LoadType.dumbbell), 0);
  });

  group('a bodyweight-percentage rung', () {
    final squat25 = ExerciseCatalog.findById('squat_barbell_plus_25')!;
    final squat50 = ExerciseCatalog.findById('squat_barbell_plus_50')!;

    test('asks for a load the bar can hold', () {
      // 74.4 × 0.25 = 18.6 → the bar.
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(squat25, 74.4),
        20,
      );
      // 86 × 0.25 = 21.5 → 22.5.
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(squat25, 86),
        22.5,
      );
      // 85 × 0.25 = 21.25 → halfway, and down.
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(squat25, 85),
        20,
      );
    });

    test('a light user finds two rungs on the same bar', () {
      // 40 kg: a quarter is 10, half is 20 — both the empty bar.
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(squat25, 40),
        20,
      );
      expect(
        ExerciseProgressionService.requiredExternalWeightKg(squat50, 40),
        20,
      );
    });
  });

  group('two rungs that resolve to one load', () {
    final category =
        SkillCategoryCatalog.findById(SkillCategoryCatalog.squatId)!;
    final path = category.pathFor('weighted');
    final squat25 = ExerciseCatalog.findById('squat_barbell_plus_25')!;

    ExerciseProgress rowFor(String id, ExerciseStatus status) {
      return ExerciseProgress(
        exerciseId: id,
        status: status,
        updatedAt: DateTime(2026, 8, 17),
      );
    }

    test('mastering the first proves the second and trains the third', () {
      // A 40 kg user: 25% and 50% are both the bar; 75% is 30 kg.
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: squat25,
            // Past the default mastery volume of 3 × 12.
            volume: 40,
            sets: const [SessionSetResult(value: 14, weightKg: 20)],
          ),
        ],
        progressRows: {
          for (var i = 0; i < path.indexOf(squat25.id); i++)
            path[i]: rowFor(path[i], ExerciseStatus.mastered),
          squat25.id: rowFor(squat25.id, ExerciseStatus.active),
        },
        activeBranchByCategory: {category.id: 'weighted'},
        bodyweightKg: 40,
      );

      expect(outcome.statusChanges['squat_barbell_plus_25'],
          ExerciseStatus.mastered);
      expect(outcome.statusChanges['squat_barbell_plus_50'],
          ExerciseStatus.mastered);
      expect(outcome.statusChanges['squat_barbell_plus_75'],
          ExerciseStatus.active);
      // The proved rung was never trained, so rollback returns it to where
      // it was: untouched.
      expect(outcome.previousStatuses['squat_barbell_plus_50'],
          ExerciseStatus.inactive);
      // And nothing was "activated" that was never the thing to train.
      expect(outcome.activationsByMastered['squat_barbell_plus_25'], isNull);
      expect(outcome.activationsByMastered['squat_barbell_plus_50'],
          'squat_barbell_plus_75');
    });

    test('a heavier user proves nothing extra', () {
      // 80 kg: 25% is the bar, 50% is 40 kg. Only the next rung activates.
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: squat25,
            volume: 40,
            sets: const [SessionSetResult(value: 14, weightKg: 20)],
          ),
        ],
        progressRows: {squat25.id: rowFor(squat25.id, ExerciseStatus.active)},
        activeBranchByCategory: {category.id: 'weighted'},
        bodyweightKg: 80,
      );

      expect(outcome.statusChanges['squat_barbell_plus_50'],
          ExerciseStatus.active);
      expect(
          outcome.statusChanges.containsKey('squat_barbell_plus_75'), isFalse);
    });

    test('a blank start opens on the last rung the bar covers', () {
      // A 40 kg user with no squat max: 25% and 50% are both the empty bar,
      // so the program opens on 50% — the first rung that is not the same
      // lift twice — with 25% behind it.
      final index = ProgramStartPlanner.weightedStartIndex(
        path: path,
        oneRepMaxKg: null,
        bodyweightKg: 40,
        blankStartsOnBar: true,
      );

      expect(path[index], 'squat_barbell_plus_50');
    });
  });
}
