import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/progression_event_model.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/home/widgets/today_workout_card.dart';

void main() {
  group('leveledUpExerciseIds', () {
    ProgressionEvent activation(
      String exerciseId, {
      required DateTime at,
      int? valueFrom,
    }) {
      return ProgressionEvent(
        id: '$exerciseId-$at',
        exerciseId: exerciseId,
        kind: ProgressionEventKind.activated,
        createdAt: at,
        relatedExerciseId: 'previous',
        valueFrom: valueFrom,
      );
    }

    PastWorkout workout(List<String> exerciseIds, {required DateTime at}) {
      return PastWorkout(
        id: 'w-$at',
        title: 'Pull',
        sessionType: 'pull',
        startedAt: at,
        loggedAt: at,
        exercises: [
          for (final id in exerciseIds)
            PastWorkoutExercise(
              exerciseId: id,
              exerciseName: id,
              setCount: 3,
              totalReps: 18,
              totalTimedSeconds: 0,
              sets: const [],
            ),
        ],
      );
    }

    final day1 = DateTime(2026, 8, 10);
    final day2 = DateTime(2026, 8, 12);
    final day3 = DateTime(2026, 8, 14);

    test('an exercise the program stepped up onto is tagged until trained', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_a'], at: day1)
        ],
      );
      expect(ids, {'pull_b'});
    });

    test('training the exercise once, after the step up, retires the tag', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_a'], at: day1),
          workout(['pull_b'], at: day3),
        ],
      );
      expect(ids, isEmpty);
    });

    test('a log from before the step up does not count', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2)],
        pastWorkouts: [
          workout(['pull_b'], at: day1)
        ],
      );
      expect(ids, {'pull_b'});
    });

    test('a step from another tree wears New rather than Lvl up', () {
      final tags = TodayWorkoutContent.rowTags(
        activations: [
          ProgressionEvent(
            id: 'handoff',
            exerciseId: 'handstand_pushups_pike_push_up',
            kind: ProgressionEventKind.activated,
            createdAt: day2,
            relatedExerciseId: 'dips_parallel_bar_dips',
          ),
          ProgressionEvent(
            id: 'step',
            exerciseId: 'dips_parallel_bar_dips',
            kind: ProgressionEventKind.activated,
            createdAt: day2,
            relatedExerciseId: 'dips_dip_negatives',
          ),
        ],
        pastWorkouts: const [],
      );
      expect(tags['handstand_pushups_pike_push_up'], TodayRowTag.newTree);
      expect(tags['dips_parallel_bar_dips'], TodayRowTag.levelUp);
    });

    test('a manual fast-forward is not a level up', () {
      final ids = TodayWorkoutContent.leveledUpExerciseIds(
        activations: [activation('pull_b', at: day2, valueFrom: 6)],
        pastWorkouts: const [],
      );
      expect(ids, isEmpty);
    });
  });
}
