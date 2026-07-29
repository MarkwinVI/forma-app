import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/exercise_coaching_catalog.dart';
import 'package:forma_app/data/catalog/exercise_library_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/home/program_day_items.dart';

/// The general exercise library is loggable but outside the trees. The line
/// between the two is the thing worth testing: search has to cross it, and
/// progression has to not.
void main() {
  group('what is in the library', () {
    test('the library is the sheet\'s general catalogue', () {
      expect(ExerciseLibraryCatalog.all().length, 637);
    });

    test('a barbell bench press can be found', () {
      final found = ExerciseCatalog.everything()
          .where((exercise) => exercise.name == 'Barbell Bench Press');
      expect(found, hasLength(1));
      expect(found.first.category, ExerciseCategory.horizontalPush);
    });

    test('no id is claimed by both halves', () {
      final treeIds = ExerciseCatalog.all().map((e) => e.id).toSet();
      final clashes =
          ExerciseLibraryCatalog.all().where((e) => treeIds.contains(e.id));
      expect(clashes, isEmpty);
    });

    test('every library movement carries its coaching', () {
      for (final exercise in ExerciseLibraryCatalog.all()) {
        final coaching = ExerciseCoachingCatalog.findById(exercise.id);
        expect(coaching, isNotNull, reason: '${exercise.id} has no coaching');
        expect(coaching!.howTo, isNotEmpty);
        expect(coaching.formChecks, isNotEmpty);
        expect(coaching.videoUrl, startsWith('https://www.youtube.com/watch?v='));
      }
    });
  });

  group('the line between library and trees', () {
    test('all() is still only the tree steps', () {
      expect(ExerciseCatalog.all(), hasLength(136));
      expect(ExerciseCatalog.all().any((e) => e.isLibrary), isFalse);
    });

    test('everything() is both halves', () {
      expect(ExerciseCatalog.everything(), hasLength(136 + 637));
    });

    test('a library movement resolves by id, so a logged set reads back', () {
      final exercise =
          ExerciseCatalog.findById('Barbell_Bench_Press_-_Medium_Grip');
      expect(exercise, isNotNull);
      expect(exercise!.isLibrary, isTrue);
    });

    test('no library movement is in a tree or a progression', () {
      for (final exercise in ExerciseLibraryCatalog.all()) {
        expect(exercise.skillCategoryId, isEmpty);
        expect(exercise.prerequisiteIds, isEmpty);
      }
      final libraryIds = ExerciseLibraryCatalog.all().map((e) => e.id).toSet();
      for (final category in SkillCategoryCatalog.all()) {
        for (final path in category.trainingPaths.values) {
          expect(path.where(libraryIds.contains), isEmpty);
        }
      }
    });

    test('accessory work never becomes a skill tree of its own', () {
      expect(
        SkillCategoryCatalog.browsable().map((category) => category.id),
        isNot(contains(ExerciseCategory.other.id)),
      );
    });
  });

  group('how a library movement advances', () {
    test('it is loaded, so it asks rather than mastering itself', () {
      for (final exercise in ExerciseLibraryCatalog.all()) {
        expect(exercise.isLoaded, isTrue, reason: exercise.id);
      }
    });

    test('a library hold is still counted in seconds', () {
      final plank = ExerciseCatalog.findById('Plank');
      expect(plank, isNotNull);
      expect(plank!.isTimed, isTrue);
    });
  });

  group('muscles', () {
    test('an isolation lift names the one muscle it isolates', () {
      final curl = ExerciseCatalog.findById('Barbell_Curl');
      expect(curl, isNotNull);
      expect(ProgramSessionPlan.musclesForExercise(curl!), ['Biceps']);
    });

    test('a compound lift names everything it recruits', () {
      final bench =
          ExerciseCatalog.findById('Barbell_Bench_Press_-_Medium_Grip')!;
      expect(
        ProgramSessionPlan.musclesForExercise(bench),
        containsAll(['Chest', 'Triceps', 'Shoulders']),
      );
    });

    test('a tree step names its own muscles, not its pattern\'s', () {
      final pullUp = ExerciseCatalog.findById('pull_up')!;
      expect(
        ProgramSessionPlan.musclesForExercise(pullUp),
        ['Lats', 'Upper back', 'Biceps', 'Forearms', 'Core'],
      );
    });

    test('steady-state work reads as cardio', () {
      final bike = ExerciseCatalog.findById('Bicycling')!;
      expect(ProgramSessionPlan.musclesForExercise(bike), contains('Cardio'));
    });
  });
}
