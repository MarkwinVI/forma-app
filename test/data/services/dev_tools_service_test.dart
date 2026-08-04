import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/models/workout_history_model.dart';
import 'package:forma_app/data/services/dev_tools_service.dart';
import 'package:forma_app/data/services/training_schedule_service.dart';
import 'package:forma_app/features/data/workout_calendar_metrics.dart';

void main() {
  group('DevToolsService.seedDaysFor', () {
    test('seeds one session a week, so the streak reads five weeks', () {
      final cycle = TrainingScheduleService().cycleFor(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 4,
      );
      // A Wednesday — the current week is half over and must be left alone.
      final today = DateTime(2026, 7, 29);

      final days = DevToolsService.seedDaysFor(cycle: cycle, today: today);

      expect(days.length, 5);
      // Oldest first, every one on a day the program trains, none this week.
      expect(days, orderedEquals([...days]..sort()));
      for (final day in days) {
        expect(cycle[day.weekday - 1], isNot(TrainingSessionType.rest));
        expect(day.isBefore(DateTime(2026, 7, 27)), isTrue);
      }
      // One in each of the five weeks before this one.
      expect(
        days.map((day) => WorkoutCalendarMetrics.weekStartOf(day)).toSet(),
        hasLength(5),
      );

      final metrics = WorkoutCalendarMetrics(
        workouts: [for (final day in days) _workoutOn(day)],
        now: today,
      );
      expect(metrics.currentStreakWeeks, 5);
    });

    test('a program with no training day seeds nothing', () {
      final days = DevToolsService.seedDaysFor(
        cycle: List.filled(7, TrainingSessionType.rest),
        today: DateTime(2026, 7, 29),
      );

      expect(days, isEmpty);
    });
  });
}

PastWorkout _workoutOn(DateTime day) {
  final startedAt = DateTime(day.year, day.month, day.day, 17);
  return PastWorkout(
    id: 'w-${day.toIso8601String()}',
    title: 'Upper',
    sessionType: TrainingSessionType.upper.dbValue,
    startedAt: startedAt,
    loggedAt: startedAt.add(const Duration(minutes: 42)),
    exercises: const [],
  );
}
