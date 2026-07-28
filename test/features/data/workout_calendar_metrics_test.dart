import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/data/workout_calendar_metrics.dart';

void main() {
  group('WorkoutCalendarMetrics', () {
    test('one session carries a week', () {
      // Thursday Jun 18. One workout last week, one this week.
      final metrics = WorkoutCalendarMetrics(
        now: DateTime(2026, 6, 18),
        workouts: [
          _workout('last', DateTime(2026, 6, 10)),
          _workout('this', DateTime(2026, 6, 15)),
        ],
      );

      expect(metrics.currentStreakWeeks, 2);
      expect(metrics.sessionsThisWeek, 1);
    });

    test('a single session in the first week is already a one-week streak', () {
      final metrics = WorkoutCalendarMetrics(
        now: DateTime(2026, 6, 18),
        workouts: [_workout('this', DateTime(2026, 6, 15))],
      );

      expect(metrics.currentStreakWeeks, 1);
    });

    test('an untrained current week does not break the streak yet', () {
      final metrics = WorkoutCalendarMetrics(
        now: DateTime(2026, 6, 18),
        workouts: [
          _workout('two-back', DateTime(2026, 6, 2)),
          _workout('last', DateTime(2026, 6, 10)),
        ],
      );

      expect(metrics.currentStreakWeeks, 2);
    });

    test('a skipped week ends the streak', () {
      final metrics = WorkoutCalendarMetrics(
        now: DateTime(2026, 6, 18),
        workouts: [
          _workout('three-back', DateTime(2026, 5, 27)),
          // Nothing in the week of Jun 1.
          _workout('last', DateTime(2026, 6, 10)),
          _workout('this', DateTime(2026, 6, 15)),
        ],
      );

      expect(metrics.currentStreakWeeks, 2);
      expect(metrics.bestStreakWeeks, 2);
    });

    test('no sessions at all is no streak', () {
      final metrics = WorkoutCalendarMetrics(
        now: DateTime(2026, 6, 18),
        workouts: const [],
      );

      expect(metrics.currentStreakWeeks, 0);
      expect(metrics.bestStreakWeeks, 0);
    });
  });
}

PastWorkout _workout(String id, DateTime loggedAt) {
  return PastWorkout(
    id: id,
    title: id,
    sessionType: 'full_body',
    startedAt: loggedAt,
    loggedAt: loggedAt,
    exercises: const [],
  );
}
