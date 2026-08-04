import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/exercise_coaching_catalog.dart';
import 'package:forma_app/data/catalog/exercise_id_migration.dart';
import 'package:forma_app/data/catalog/exercise_library_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';

/// Both halves of the exercise sheet, and the line between them: the skill
/// trees, which are stepped through, and the library, which is not.
void main() {
  final steps = ExerciseCatalog.all();
  final library = ExerciseLibraryCatalog.all();

  group('what the sheet became', () {
    test('every tree step and every library movement is here', () {
      expect(steps, hasLength(137));
      expect(library, hasLength(489));
      expect(ExerciseCatalog.everything(), hasLength(137 + 489));
    });

    test('picking lists a movement once, as the step performed with it', () {
      final searchable = ExerciseCatalog.searchable();
      final performedWith = steps.map((step) => step.libraryId).toSet();

      expect(performedWith, hasLength(110));
      expect(searchable, hasLength(137 + 489 - 110));
      expect(
        searchable.where((e) => e.isLibrary && performedWith.contains(e.id)),
        isEmpty,
        reason: 'the step stands for the movement it is performed with',
      );
    });

    test('a bench dip is one result, not the step and its movement', () {
      expect(
        ExerciseCatalog.searchable().where((e) => e.name == 'Bench Dip'),
        hasLength(1),
      );
      expect(
        ExerciseCatalog.everything().where((e) => e.name == 'Bench Dip'),
        hasLength(2),
        reason: 'both still exist — the step and the movement behind it',
      );
    });

    test('a step is a step and a movement is a movement', () {
      expect(steps.any((exercise) => exercise.isLibrary), isFalse);
      expect(library.every((exercise) => exercise.isLibrary), isTrue);
    });

    test('no id is claimed by both halves', () {
      final stepIds = steps.map((exercise) => exercise.id).toSet();
      expect(library.where((e) => stepIds.contains(e.id)), isEmpty);
    });

    test('every step is performed with a movement that exists', () {
      for (final step in steps) {
        expect(step.libraryId, isNotEmpty, reason: step.id);
        expect(ExerciseLibraryCatalog.findById(step.libraryId), isNotNull,
            reason: '${step.id} -> ${step.libraryId}');
      }
    });

    test('steps that share a movement share its coaching', () {
      final rungs =
          steps.where((s) => s.libraryId == 'pull_up_weighted').toList();
      expect(rungs, hasLength(7));
      final coaching = rungs.map(ExerciseCoachingCatalog.forExercise).toSet();
      expect(coaching, hasLength(1));
      expect(coaching.first, isNotNull);
    });
  });

  group('the trees hold together', () {
    // The steps are generated from the skill-tree sheet; the categories are
    // written by hand. A branch renamed in one and not the other would leave
    // steps on a branch the tree has never heard of.
    test('every step sits on a branch its tree declares', () {
      for (final step in steps) {
        final category = SkillCategoryCatalog.findById(step.skillCategoryId);
        if (category == null) continue;
        expect(
          category.branches.map((branch) => branch.id),
          contains(step.branchId),
          reason: step.id,
        );
      }
    });

    test('a forked tree has a foundation with steps on it', () {
      for (final id in ['pullups', 'rows', 'pushups', 'squat', 'dips']) {
        final category = SkillCategoryCatalog.findById(id)!;
        expect(category.foundationBranchId, 'foundation', reason: id);
        expect(category.pathFor('foundation'), isNotEmpty, reason: id);
        // A selection stored before the rename still resolves to the same
        // steps, so nobody's saved program points at nothing.
        expect(category.pathFor('main'), category.pathFor('foundation'),
            reason: id);
      }
    });

    test('every step names the step before it, and it exists', () {
      final ids = steps.map((exercise) => exercise.id).toSet();
      for (final step in steps) {
        for (final previous in step.prerequisiteIds) {
          expect(ids, contains(previous), reason: '${step.id} -> $previous');
        }
      }
    });

    test('every branch path is made of real steps', () {
      final ids = steps.map((exercise) => exercise.id).toSet();
      for (final category in SkillCategoryCatalog.all()) {
        for (final entry in category.trainingPaths.entries) {
          expect(entry.value, isNotEmpty, reason: '${category.id}/${entry.key}');
          for (final id in entry.value) {
            expect(ids, contains(id), reason: '${category.id}/${entry.key}');
          }
        }
      }
    });

    test('a path runs in order, each step following the last', () {
      for (final category in SkillCategoryCatalog.all()) {
        for (final entry in category.trainingPaths.entries) {
          final path = entry.value;
          for (var i = 1; i < path.length; i++) {
            expect(
              ExerciseCatalog.findById(path[i])!.prerequisiteIds,
              [path[i - 1]],
              reason: '${category.id}/${entry.key} at $i',
            );
          }
        }
      }
    });

    test('no library movement leaked into a tree', () {
      final libraryIds = library.map((exercise) => exercise.id).toSet();
      for (final category in SkillCategoryCatalog.all()) {
        for (final path in category.trainingPaths.values) {
          expect(path.where(libraryIds.contains), isEmpty);
        }
      }
    });
  });

  group('how a step advances', () {
    test('only the barbell lifts are open-ended', () {
      expect(
        steps.where((e) => e.isLoaded).map((e) => e.id),
        unorderedEquals(['barbell_squat_barbell_squat', 'hinge_romanian_deadlift']),
      );
    });

    test('a weighted rung carries the load it is a rung for', () {
      final rung = ExerciseCatalog.findById('pullups_weighted_pull_up_150')!;
      expect(rung.weightFormula, contains('user_bodyweight'));
      expect(rung.isLoaded, isFalse, reason: 'a rung has a next rung');
    });

    test('holds are timed and reps are not', () {
      expect(ExerciseCatalog.findById('core_plank')!.isTimed, isTrue);
      expect(ExerciseCatalog.findById('planche_full_planche_hold')!.isTimed,
          isTrue);
      expect(ExerciseCatalog.findById('pullups_pull_up')!.isTimed, isFalse);
    });

    test('every library movement is loaded, being outside the progressions',
        () {
      expect(library.every((exercise) => exercise.isLoaded), isTrue);
    });
  });

  group('what a movement works', () {
    test('the two muscle columns stay apart', () {
      final bench = ExerciseCatalog.findById('bench_press_barbell')!;
      expect(bench.primaryMuscles, ['Chest']);
      expect(bench.secondaryMuscles, contains('Triceps'));
    });

    test('a muscle is never both primary and secondary', () {
      for (final exercise in ExerciseCatalog.everything()) {
        for (final muscle in exercise.secondaryMuscles) {
          expect(exercise.primaryMuscles, isNot(contains(muscle)),
              reason: '${exercise.id} lists $muscle twice');
        }
      }
    });

    test('muscles reads as primary first, then secondary', () {
      for (final exercise in ExerciseCatalog.everything()) {
        expect(
          exercise.muscles,
          [...exercise.primaryMuscles, ...exercise.secondaryMuscles],
          reason: exercise.id,
        );
      }
    });
  });

  group('what a movement is measured in', () {
    test('a barbell lift carries weight and a bodyweight movement does not',
        () {
      expect(ExerciseCatalog.findById('bench_press_barbell')!.isWeighted,
          isTrue);
      expect(ExerciseCatalog.findById('squat_barbell')!.isWeighted, isTrue);
      expect(ExerciseCatalog.findById('ab_scissors')!.isWeighted, isFalse);
      expect(ExerciseCatalog.findById('core_plank')!.isWeighted, isFalse);
    });

    test('a weighted rung is weighted, and the step below it is not', () {
      expect(
        ExerciseCatalog.findById('pullups_weighted_pull_up_150')!.isWeighted,
        isTrue,
      );
      expect(ExerciseCatalog.findById('pullups_pull_up')!.isWeighted, isFalse);
    });

    // The sheet's fourth type: a hold that is also loaded, so it sets both
    // flags and its row shows TIME and KG together.
    test('a loaded hold is timed and weighted at once', () {
      final sled = ExerciseCatalog.findById('sled_push')!;
      expect(sled.isTimed, isTrue);
      expect(sled.isWeighted, isTrue);
    });

    test('a step is measured the way the movement it is performed with is',
        () {
      for (final step in steps) {
        final movement = ExerciseCatalog.findById(step.libraryId);
        if (movement == null) continue;
        expect(
          step.isWeighted,
          movement.isWeighted,
          reason: '${step.id} vs ${movement.id}',
        );
      }
    });
  });

  group('ids that were already written down', () {
    test('every old id still resolves to a step', () {
      final ids = steps.map((exercise) => exercise.id).toSet();
      for (final old in ExerciseIdMigration.renamedIds) {
        expect(ids, contains(ExerciseIdMigration.resolve(old)), reason: old);
      }
    });

    test('an id that was never renamed is left alone', () {
      expect(ExerciseIdMigration.resolve('pullups_pull_up'), 'pullups_pull_up');
      expect(ExerciseIdMigration.resolve('bench_press_barbell'),
          'bench_press_barbell');
    });

    test('stored progress is re-keyed onto the steps it meant', () {
      final moved = ExerciseIdMigration.resolveKeys(
        const {'pull_up': ExerciseStatus.mastered},
      );
      expect(moved, {'pullups_pull_up': ExerciseStatus.mastered});
    });
  });
}
