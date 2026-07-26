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
