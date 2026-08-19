import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/exercise_log_model.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/home/live_workout_view.dart';

Exercise _exercise({bool isTimed = false, bool isWeighted = false}) => Exercise(
      id: 'x',
      category: ExerciseCategory.verticalPull,
      name: 'X',
      description: 'X',
      difficulty: 1,
      treeOrder: 0,
      isTimed: isTimed,
      isWeighted: isWeighted,
    );

void main() {
  group('previousSetLabel', () {
    test('a loaded lift reads as its weight against its reps — no unit, the column head has it', () {
      expect(
        previousSetLabel(
          _exercise(isWeighted: true),
          const ExerciseSet(reps: 8, weightKg: 60),
        ),
        '60×8',
      );
    });

    test('a half-plate keeps its decimal', () {
      expect(
        previousSetLabel(
          _exercise(isWeighted: true),
          const ExerciseSet(reps: 5, weightKg: 62.5),
        ),
        '62.5×5',
      );
    });

    test('bodyweight reps are a count on their own', () {
      expect(
        previousSetLabel(_exercise(), const ExerciseSet(reps: 12)),
        '12',
      );
    });

    test('a loaded hold carries its weight against its seconds', () {
      expect(
        previousSetLabel(
          _exercise(isTimed: true, isWeighted: true),
          const ExerciseSet(durationSeconds: 40, weightKg: 20),
        ),
        '20×00:40',
      );
    });

    test('a hold reads as mm:ss', () {
      expect(
        previousSetLabel(
          _exercise(isTimed: true),
          const ExerciseSet(durationSeconds: 30),
        ),
        '00:30',
      );
    });

    test('an exercise never logged reads as a dash', () {
      expect(previousSetLabel(_exercise(), null), '–');
    });

    test('an empty set reads as a dash rather than a zero', () {
      expect(previousSetLabel(_exercise(), const ExerciseSet()), '–');
    });
  });
}
