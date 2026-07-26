import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/training_schedule_service.dart';

void main() {
  group('TrainingScheduleService', () {
    final service = TrainingScheduleService();

    test('builds frequency-aware weekly cycles', () {
      expect(
        service.cycleFor(
          programType: TrainingProgramType.fullBody,
          frequencyPerWeek: 2,
        ),
        const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ],
      );

      expect(
        service
            .cycleFor(
              programType: TrainingProgramType.pushPull,
              frequencyPerWeek: 5,
            )
            .where((session) => session != TrainingSessionType.rest)
            .toList(),
        const [
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.push,
        ],
      );
    });

    test('keeps the completed workout selected for the rest of today', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.pushPull,
        frequencyPerWeek: 4,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.push,
        lastPlannedWorkoutAt: DateTime(2026, 6, 15, 18),
        now: DateTime(2026, 6, 15, 21),
      );

      expect(window.today.sessionType, TrainingSessionType.push);
      expect(window.today.isCompleted, isTrue);
      expect(window.selectedDay.isCompleted, isTrue);
    });

    test('advances to the next calendar step on the next day', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.pushPull,
        frequencyPerWeek: 4,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.push,
        lastPlannedWorkoutAt: DateTime(2026, 6, 15, 18),
        now: DateTime(2026, 6, 16, 9),
      );

      expect(window.today.sessionType, TrainingSessionType.pull);
      expect(window.today.isCompleted, isFalse);
    });

    test('marks missed training dates and shifts the whole schedule', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.pushPull,
        frequencyPerWeek: 3,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.push,
        lastPlannedWorkoutAt: DateTime(2026, 6, 15, 18),
        now: DateTime(2026, 6, 18, 9),
      );

      final wednesday = window.days.firstWhere((day) => day.date.day == 17);
      final thursday = window.today;
      final friday = window.days.firstWhere((day) => day.date.day == 19);

      expect(wednesday.sessionType, TrainingSessionType.pull);
      expect(wednesday.isMissed, isTrue);
      expect(thursday.sessionType, TrainingSessionType.pull);
      expect(thursday.isMissed, isFalse);
      expect(friday.sessionType, TrainingSessionType.rest);
    });

    test('selects a future scheduled workout without changing today', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 3,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.upper,
        selectedDate: DateTime(2026, 6, 17),
        now: DateTime(2026, 6, 15, 9),
      );

      expect(window.today.sessionType, TrainingSessionType.upper);
      expect(window.selectedDay.date, DateTime(2026, 6, 17));
      expect(window.selectedDay.sessionType, TrainingSessionType.lower);
    });

    test('swaps the pulled-forward session with the one that was due', () {
      // Mon completed Upper, so Tue is due Lower and Thu is due Upper. The
      // user trains Thursday's Upper on Tuesday instead.
      final window = service.buildWindow(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 4,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.upper,
        lastPlannedWorkoutAt: DateTime(2026, 6, 16, 19),
        lastCompletedSessionType: TrainingSessionType.upper,
        completedSessions: {
          DateTime(2026, 6, 15): TrainingSessionType.upper,
          DateTime(2026, 6, 16): TrainingSessionType.upper,
        },
        daysAfterToday: 7,
        now: DateTime(2026, 6, 16, 21),
      );

      final byDay = {for (final day in window.days) day.date.day: day};

      // Two hard days back to back is the ceiling at 4×/week, so Wednesday
      // stays recovery.
      expect(byDay[17]!.isRestDay, isTrue);
      // Thursday held the Upper that was just trained — it now holds the
      // Lower that Tuesday gave up.
      expect(byDay[18]!.sessionType, TrainingSessionType.lower);
    });

    test('moves a session trained on a rest day off its original date', () {
      // 3×/week: Mon Upper, Wed Lower, Fri Upper. The user trains Wednesday's
      // Lower on Tuesday, which was a rest day.
      final window = service.buildWindow(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 3,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.upper,
        lastPlannedWorkoutAt: DateTime(2026, 6, 16, 19),
        lastCompletedSessionType: TrainingSessionType.lower,
        completedSessions: {
          DateTime(2026, 6, 15): TrainingSessionType.upper,
          DateTime(2026, 6, 16): TrainingSessionType.lower,
        },
        daysAfterToday: 7,
        now: DateTime(2026, 6, 16, 21),
      );

      final byDay = {for (final day in window.days) day.date.day: day};

      // Wednesday no longer holds the session that was pulled forward, and
      // training two days running at 3×/week forces recovery.
      expect(byDay[17]!.isRestDay, isTrue);
      expect(byDay[18]!.sessionType, TrainingSessionType.upper);
    });

    test('never schedules more consecutive training days than the template',
        () {
      for (final frequency in [2, 3, 4, 5, 6]) {
        final ceiling = service.maxConsecutiveTrainingDays(frequency);
        final window = service.buildWindow(
          programType: TrainingProgramType.upperLower,
          frequencyPerWeek: frequency,
          currentStepIndex: 0,
          currentSessionType: TrainingSessionType.upper,
          lastPlannedWorkoutAt: DateTime(2026, 6, 16, 19),
          lastCompletedSessionType: TrainingSessionType.upper,
          // Trained every day for the last three days, whatever the plan said.
          completedSessions: {
            DateTime(2026, 6, 14): TrainingSessionType.lower,
            DateTime(2026, 6, 15): TrainingSessionType.lower,
            DateTime(2026, 6, 16): TrainingSessionType.upper,
          },
          daysAfterToday: 21,
          now: DateTime(2026, 6, 16, 21),
        );

        var run = 0;
        for (final day in window.days.where(
          (day) => day.date.isAfter(DateTime(2026, 6, 16)),
        )) {
          run = day.isRestDay ? 0 : run + 1;
          expect(
            run,
            lessThanOrEqualTo(ceiling),
            reason: '$frequency×/week exceeded its $ceiling-day ceiling',
          );
        }
      }
    });

    test('keeps A/B alternation when a much later session is pulled forward',
        () {
      final window = service.buildWindow(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 4,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.upper,
        // Next in line was Lower; the user trained an Upper from a later week.
        lastPlannedWorkoutAt: DateTime(2026, 6, 16, 19),
        lastCompletedSessionType: TrainingSessionType.upper,
        completedSessions: {
          DateTime(2026, 6, 16): TrainingSessionType.upper,
        },
        daysAfterToday: 21,
        now: DateTime(2026, 6, 16, 21),
      );

      final upcoming = window.days
          .where((day) => day.date.isAfter(DateTime(2026, 6, 16)))
          .where((day) => !day.isRestDay)
          .toList();

      expect(upcoming.first.sessionType, TrainingSessionType.lower);
      for (var i = 1; i < upcoming.length; i++) {
        expect(
          upcoming[i].sessionType,
          isNot(upcoming[i - 1].sessionType),
          reason: 'two of the same session ran back to back',
        );
      }
    });

    test('deleting an older workout leaves the upcoming plan untouched', () {
      TrainingScheduleWindow windowWith(
        Map<DateTime, TrainingSessionType> completed,
      ) {
        return service.buildWindow(
          programType: TrainingProgramType.upperLower,
          frequencyPerWeek: 4,
          currentStepIndex: 0,
          currentSessionType: TrainingSessionType.upper,
          lastPlannedWorkoutAt: DateTime(2026, 6, 15, 19),
          lastCompletedSessionType: TrainingSessionType.upper,
          completedSessions: completed,
          daysAfterToday: 7,
          now: DateTime(2026, 6, 16, 9),
        );
      }

      final before = windowWith({
        DateTime(2026, 6, 10): TrainingSessionType.lower,
        DateTime(2026, 6, 15): TrainingSessionType.upper,
      });
      // The June 10 session is deleted; the pointer still says June 15.
      final after = windowWith({
        DateTime(2026, 6, 15): TrainingSessionType.upper,
      });

      final upcomingBefore = before.days
          .where((day) => !day.date.isBefore(before.today.date))
          .map((day) => '${day.date}:${day.sessionType}')
          .toList();
      final upcomingAfter = after.days
          .where((day) => !day.date.isBefore(after.today.date))
          .map((day) => '${day.date}:${day.sessionType}')
          .toList();

      expect(upcomingAfter, upcomingBefore);
    });

    test('a deleted anchor session stops reading as completed', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.upperLower,
        frequencyPerWeek: 4,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.upper,
        lastPlannedWorkoutAt: DateTime(2026, 6, 15, 19),
        lastCompletedSessionType: TrainingSessionType.upper,
        // The pointer still points at June 15, but its workout is gone.
        completedSessions: const {},
        daysBeforeToday: 7,
        daysAfterToday: 7,
        now: DateTime(2026, 6, 16, 9),
      );

      final anchorDay = window.days.firstWhere((day) => day.date.day == 15);
      expect(anchorDay.isCompleted, isFalse);
      // ...and the plan still runs from there rather than reopening the slot.
      expect(window.today.sessionType, TrainingSessionType.lower);
    });

    test('can build a wider calendar window around today', () {
      final window = service.buildWindow(
        programType: TrainingProgramType.fullBody,
        frequencyPerWeek: 3,
        currentStepIndex: 0,
        currentSessionType: TrainingSessionType.fullBody,
        daysBeforeToday: 7,
        daysAfterToday: 7,
        now: DateTime(2026, 6, 15, 9),
      );

      expect(window.days, hasLength(15));
      expect(window.days.first.date, DateTime(2026, 6, 8));
      expect(window.today.date, DateTime(2026, 6, 15));
      expect(window.days.last.date, DateTime(2026, 6, 22));
    });
  });
}
