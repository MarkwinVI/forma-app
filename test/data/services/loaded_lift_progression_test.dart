import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/progression_suggestion_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';

void main() {
  final barbellSquat = ExerciseCatalog.findById('barbell_squat')!;
  final pushUp = ExerciseCatalog.findById('push_up')!;

  ExerciseProgress progressAt({
    required int value,
    double? weightKg = 70,
    int sets = 3,
    ExerciseStatus status = ExerciseStatus.active,
  }) {
    return ExerciseProgress(
      exerciseId: 'barbell_squat',
      status: status,
      updatedAt: DateTime(2026, 7, 29),
      currentTargetSets: sets,
      currentTargetValue: value,
      currentTargetWeightKg: weightKg,
    );
  }

  SessionProgressionOutcome outcomeFor({
    required Exercise exercise,
    required int volume,
    ExerciseProgress? progress,
  }) {
    return ExerciseProgressionService.computeSessionOutcome(
      results: [SessionExerciseResult(exercise: exercise, volume: volume)],
      progressRows: progress == null ? const {} : {exercise.id: progress},
    );
  }

  group('a loaded lift proposes instead of advancing', () {
    test('hitting 3 × 5 suggests 3 × 6 on the same bar', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 15,
        progress: progressAt(value: 5),
      );

      expect(outcome.targetChanges, isEmpty);
      expect(outcome.statusChanges, isEmpty);

      final suggestion = outcome.suggestions.single;
      expect(suggestion.kind, ProgressionSuggestionKind.repIncrease);
      expect((suggestion.fromValue, suggestion.toValue), (5, 6));
      expect((suggestion.fromWeightKg, suggestion.toWeightKg), (70, 70));
    });

    test('hitting the top of the rep range suggests +10 kg back at 5 reps',
        () {
      final suggestion = outcomeFor(
        exercise: barbellSquat,
        volume: 24,
        progress: progressAt(value: 8),
      ).suggestions.single;

      expect(suggestion.kind, ProgressionSuggestionKind.loadIncrease);
      expect((suggestion.fromValue, suggestion.toValue), (8, 5));
      expect((suggestion.fromWeightKg, suggestion.toWeightKg), (70, 80));
    });

    test('overshooting the top of the range still only adds one increment',
        () {
      final suggestion = outcomeFor(
        exercise: barbellSquat,
        volume: 60,
        progress: progressAt(value: 8),
      ).suggestions.single;

      expect(suggestion.toWeightKg, 80);
      expect(suggestion.toValue, 5);
    });

    test('missing the target proposes nothing', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 12,
        progress: progressAt(value: 5),
      );

      expect(outcome.suggestions, isEmpty);
      expect(outcome.isEmpty, isTrue);
    });

    test('a loaded lift is never mastered, however much is logged', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 200,
        progress: progressAt(value: 8),
      );

      expect(outcome.statusChanges, isEmpty);
      expect(outcome.suggestions.single.kind,
          ProgressionSuggestionKind.loadIncrease);
    });

    test('a lift with no reported weight still climbs its reps', () {
      final suggestion = outcomeFor(
        exercise: barbellSquat,
        volume: 15,
        progress: progressAt(value: 5, weightKg: null),
      ).suggestions.single;

      expect(suggestion.toValue, 6);
      expect(suggestion.toWeightKg, isNull);
    });

    test('bodyweight exercises are untouched by the rule', () {
      final outcome = outcomeFor(exercise: pushUp, volume: 24);

      expect(outcome.suggestions, isEmpty);
      expect(outcome.statusChanges['push_up'], ExerciseStatus.mastered);
    });
  });

  group('the whole climb', () {
    test('5 → 6 → 7 → 8 → heavier, and around again', () {
      var progress = progressAt(value: 5);
      final steps = <String>[];

      for (var session = 0; session < 5; session++) {
        final target = ExerciseProgressionService.currentTargetForExercise(
          barbellSquat,
          progress: progress,
        );
        final suggestion = ExerciseProgressionService.suggestionForLoadedLift(
          exercise: barbellSquat,
          progress: progress,
          volume: target.volume,
        )!;
        steps.add('${suggestion.sets}×${suggestion.toValue}'
            '@${suggestion.toWeightKg}');
        // The user approves each one.
        progress = progress.copyWith(
          currentTargetValue: suggestion.toValue,
          currentTargetWeightKg: suggestion.toWeightKg,
        );
      }

      expect(steps, [
        '3×6@70.0',
        '3×7@70.0',
        '3×8@70.0',
        '3×5@80.0',
        '3×6@80.0',
      ]);
    });
  });
}
