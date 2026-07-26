import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/features/data/workout_calendar_metrics.dart';

void main() {
  group('WorkoutCalendarMetrics', () {
    test('current streak requires the weekly goal', () {
      final metrics = WorkoutCalendarMetrics(
        weeklyGoal: 2,
        now: DateTime(2026, 6, 18),
        workouts: [
          _workout('last-1', DateTime(2026, 6, 8)),
          _workout('last-2', DateTime(2026, 6, 10)),
          _workout('this-1', DateTime(2026, 6, 15)),
        ],
      );

      expect(metrics.currentStreakWeeks, 1);
      expect(metrics.sessionsThisWeek, 1);
    });

    test('current week extends the streak once it reaches the weekly goal', () {
      final metrics = WorkoutCalendarMetrics(
        weeklyGoal: 2,
        now: DateTime(2026, 6, 18),
        workouts: [
          _workout('last-1', DateTime(2026, 6, 8)),
          _workout('last-2', DateTime(2026, 6, 10)),
          _workout('this-1', DateTime(2026, 6, 15)),
          _workout('this-2', DateTime(2026, 6, 17)),
        ],
      );

      expect(metrics.currentStreakWeeks, 2);
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
