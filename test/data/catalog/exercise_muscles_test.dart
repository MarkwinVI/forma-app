import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/home/program_day_items.dart';

/// Muscle groups are the sheet's own words, on every exercise in it. Nothing
/// is renamed or merged on the way in, so a term that reads wrong is a change
/// to the sheet rather than to a mapping table nobody can see.
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
      expect(everything.where((e) => e.isLibrary), hasLength(491));
      expect(everything.where((e) => !e.isLibrary), hasLength(151));
    });

    test('no exercise invents a group the sheet does not use', () {
      final known = {...kExerciseMuscleGroups};
      for (final exercise in everything) {
        for (final group in exercise.muscles) {
          expect(known, contains(group), reason: '${exercise.id}: $group');
        }
      }
    });

    test('the sections are the flat list, cut up, with no group twice', () {
      final fromSections = [
        for (final section in kExerciseMuscleGroupSections) ...section.groups,
      ];
      expect(fromSections, kExerciseMuscleGroups);
      expect(fromSections.toSet(), hasLength(fromSections.length));
      expect(
        kExerciseMuscleGroupSections.map((s) => s.title),
        ['Upper Body', 'Lower Body', 'Other'],
      );
    });

    test('every group the filter offers is used by something', () {
      final used = {for (final e in everything) ...e.muscles};
      expect(kExerciseMuscleGroups.where((g) => !used.contains(g)), isEmpty);
    });

    test('no group is listed twice for one exercise', () {
      for (final exercise in everything) {
        expect(exercise.muscles.toSet(), hasLength(exercise.muscles.length),
            reason: exercise.id);
      }
    });

    test('the sheet is quoted, not paraphrased', () {
      expect(
        ExerciseCatalog.findById('bench_press_barbell')!.muscles,
        ['Chest', 'Triceps', 'Shoulders'],
      );
      expect(
        ExerciseCatalog.findById('core_plank')!.muscles,
        ['Abdominals', 'Glutes', 'Lower Back'],
      );
    });

    test('the primary muscle leads', () {
      expect(
          ExerciseCatalog.findById('pullups_pull_up')!.muscles.first, 'Lats');
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

    test('every back muscle counts as back', () {
      expect(
        ProgramSessionPlan.coarseMusclesFor(
          ['Lats', 'Upper Back', 'Lower Back', 'Traps'],
        ),
        ['Back'],
      );
    });

    test('the neck counts as shoulders', () {
      expect(
        ProgramSessionPlan.coarseMusclesFor(['Shoulders', 'Neck']),
        ['Shoulders'],
      );
    });

    test('what is not one muscle folds to nothing', () {
      expect(
        ProgramSessionPlan.coarseMusclesFor(
          ['Full Body', 'Cardio', 'Other'],
        ),
        isEmpty,
      );
    });

    test('a lift that names a real muscle always folds to something', () {
      const notAMuscle = {'Full Body', 'Cardio', 'Other'};
      final liftable =
          everything.where((e) => !e.muscles.every(notAMuscle.contains));
      for (final exercise in liftable) {
        expect(
            ProgramSessionPlan.coarseMusclesFor(exercise.muscles), isNotEmpty,
            reason: exercise.id);
      }
    });
  });
}
