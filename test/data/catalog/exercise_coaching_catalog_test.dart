import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/exercise_coaching_catalog.dart';

/// The exercise sheet is the source of truth for what the detail view says,
/// and for which movements are held rather than counted. Both are checked
/// here: coverage, so no exercise falls back to generic pattern advice by
/// accident, and the timed/loaded reading, which is inferred from the name
/// and so can be changed by a rename that looks harmless.
void main() {
  final catalog = ExerciseCatalog.all();

  group('coaching coverage', () {
    test('every exercise in the catalog has its own coaching', () {
      final missing = catalog
          .where((exercise) => ExerciseCoachingCatalog.findById(exercise.id) == null)
          .map((exercise) => exercise.id)
          .toList();
      expect(missing, isEmpty);
    });

    test('no coaching entry outlives the exercise it describes', () {
      final ids = catalog.map((exercise) => exercise.id).toSet();
      expect(
        ExerciseCoachingCatalog.coveredIds.where((id) => !ids.contains(id)),
        isEmpty,
      );
    });

    test('each entry carries steps, checks and a demo', () {
      for (final exercise in catalog) {
        final coaching = ExerciseCoachingCatalog.findById(exercise.id)!;
        expect(coaching.howTo.length, greaterThanOrEqualTo(3),
            reason: '${exercise.id} needs at least three steps');
        expect(coaching.formChecks.length, greaterThanOrEqualTo(2),
            reason: '${exercise.id} needs at least two form checks');
        expect(coaching.videoUrl, startsWith('https://www.youtube.com/watch?v='),
            reason: '${exercise.id} has no YouTube demo');
        expect(coaching.imageUrl, startsWith('https://'),
            reason: '${exercise.id} has no still');
      }
    });

    test('steps read as instructions, not as a wall of prose', () {
      for (final exercise in catalog) {
        for (final step in ExerciseCoachingCatalog.findById(exercise.id)!.howTo) {
          expect(step.length, lessThanOrEqualTo(110),
              reason: '${exercise.id} has a step too long to read as a bullet');
          expect(step, endsWith('.'), reason: '${exercise.id} has an unfinished step');
        }
      }
    });
  });

  group('timed and loaded, read from the name', () {
    /// The holds. Renaming one out of this list changes how it is logged —
    /// seconds become reps — so the list is spelled out rather than derived.
    const timedIds = {
      'arch_hang',
      'tuck_front_lever_rows_hold',
      'planche_lean_just_past',
      'planche_lean_moderate',
      'planche_lean_far_past',
      'tuck_planche_lean',
      'foot_supported_l_sit',
      'plank',
      'l_sit_tuck',
      'plank_60s',
      'advanced_tuck_l_sit',
      'one_arm_one_leg_plank',
      'l_sit',
      'straddle_l_sit',
      'v_sit',
    };

    /// The two open-ended barbell lifts. Everything else is a progression.
    const loadedIds = {'barbell_squat', 'romanian_deadlift'};

    test('exactly the holds are timed', () {
      final timed = catalog
          .where((exercise) => exercise.isTimed)
          .map((exercise) => exercise.id)
          .toSet();
      expect(timed, timedIds);
    });

    test('exactly the barbell lifts are loaded', () {
      final loaded = catalog
          .where((exercise) => exercise.isLoaded)
          .map((exercise) => exercise.id)
          .toSet();
      expect(loaded, loadedIds);
    });

    test('a movement is not both held and loaded', () {
      expect(
        catalog.where((exercise) => exercise.isTimed && exercise.isLoaded),
        isEmpty,
      );
    });
  });
}
