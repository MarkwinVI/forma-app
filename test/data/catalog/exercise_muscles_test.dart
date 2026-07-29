import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/home/program_day_items.dart';

/// Muscle groups are per exercise and cover the whole sheet — both the skill
/// trees and the general library.
void main() {
  final everything = ExerciseCatalog.everything();

  group('coverage', () {
    test('every exercise names at least one group', () {
      final bare = everything
          .where((exercise) => exercise.muscles.isEmpty)
          .map((exercise) => exercise.id);
      expect(bare, isEmpty);
    });

    test('both halves are covered, not just one', () {
      expect(everything.where((e) => e.isLibrary), hasLength(637));
      expect(everything.where((e) => !e.isLibrary), hasLength(136));
      for (final exercise in everything) {
        expect(exercise.muscles, isNotEmpty, reason: exercise.id);
      }
    });

    test('no exercise invents a group outside the list', () {
      const known = {...kExerciseMuscleGroups};
      for (final exercise in everything) {
        for (final group in exercise.muscles) {
          expect(known, contains(group), reason: '${exercise.id}: $group');
        }
      }
    });

    test('no group is listed twice for one exercise', () {
      for (final exercise in everything) {
        expect(exercise.muscles.toSet(), hasLength(exercise.muscles.length),
            reason: exercise.id);
      }
    });

    test("'Other' is a last resort, not a dumping ground", () {
      final other =
          everything.where((exercise) => exercise.muscles.contains('Other'));
      expect(other, isEmpty);
    });

    test('every group in the list is actually used by something', () {
      final used = {for (final e in everything) ...e.muscles};
      final unused = kExerciseMuscleGroups
          .where((group) => group != 'Other' && !used.contains(group));
      expect(unused, isEmpty);
    });
  });

  group('folding to the weekly volume chart', () {
    test('the chart still reads in its own six groups', () {
      expect(kProgramMuscleGroups, hasLength(6));
      for (final exercise in everything) {
        for (final group
            in ProgramSessionPlan.coarseMusclesFor(exercise.muscles)) {
          expect(kProgramMuscleGroups, contains(group), reason: exercise.id);
        }
      }
    });

    test('lats, traps and both backs all count as back', () {
      expect(
        ProgramSessionPlan.coarseMusclesFor(
          ['Lats', 'Upper back', 'Lower back', 'Traps'],
        ),
        ['Back'],
      );
    });

    test('cardio is not volume for any muscle', () {
      expect(ProgramSessionPlan.coarseMusclesFor(['Cardio']), isEmpty);
    });

    test('a lifting exercise always folds to something', () {
      final liftable =
          everything.where((e) => !e.muscles.every((g) => g == 'Cardio'));
      for (final exercise in liftable) {
        expect(ProgramSessionPlan.coarseMusclesFor(exercise.muscles), isNotEmpty,
            reason: exercise.id);
      }
    });
  });
}
