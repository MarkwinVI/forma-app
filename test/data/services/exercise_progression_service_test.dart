import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';

void main() {
  group('ExerciseProgressionService.computeChanges', () {
    // Use a real path from the catalog so the rule is tested against the
    // data the app actually ships.
    late Exercise first;
    late String secondId;

    setUpAll(() {
      final core = SkillCategoryCatalog.findById(SkillCategoryCatalog.coreId)!;
      final path = core.pathFor('l_sit');
      expect(path.length, greaterThan(1));
      first = ExerciseCatalog.findById(path.first)!;
      secondId = path[1];
    });

    test('meeting the target masters the exercise and activates the next',
        () {
      final target =
          ExerciseProgressionService.targetVolumeForExercise(first);

      final changes = ExerciseProgressionService.computeChanges(
        results: [SessionExerciseResult(exercise: first, volume: target)],
        progressMap: const {},
      );

      expect(changes[first.id], ExerciseStatus.mastered);
      expect(changes[secondId], ExerciseStatus.active);
    });

    test('falling short of the target changes nothing', () {
      final target =
          ExerciseProgressionService.targetVolumeForExercise(first);

      final changes = ExerciseProgressionService.computeChanges(
        results: [SessionExerciseResult(exercise: first, volume: target - 1)],
        progressMap: const {},
      );

      expect(changes, isEmpty);
    });

    test('an already-mastered exercise is left alone', () {
      final target =
          ExerciseProgressionService.targetVolumeForExercise(first);

      final changes = ExerciseProgressionService.computeChanges(
        results: [SessionExerciseResult(exercise: first, volume: target)],
        progressMap: {first.id: ExerciseStatus.mastered},
      );

      expect(changes, isEmpty);
    });

    test('a branch point masters the exercise but activates nothing', () {
      // pull_up has different successors per branch (weighted, close grip,
      // l-sit, one arm), so no single next move can be chosen.
      final pullUp = ExerciseCatalog.findById('pull_up')!;
      final target =
          ExerciseProgressionService.targetVolumeForExercise(pullUp);

      final changes = ExerciseProgressionService.computeChanges(
        results: [SessionExerciseResult(exercise: pullUp, volume: target)],
        progressMap: const {},
      );

      expect(changes, {pullUp.id: ExerciseStatus.mastered});
    });

    test('an already-active next exercise is not downgraded or re-written',
        () {
      final target =
          ExerciseProgressionService.targetVolumeForExercise(first);

      final changes = ExerciseProgressionService.computeChanges(
        results: [SessionExerciseResult(exercise: first, volume: target)],
        progressMap: {secondId: ExerciseStatus.active},
      );

      expect(changes[first.id], ExerciseStatus.mastered);
      expect(changes.containsKey(secondId), isFalse);
    });
  });
}
