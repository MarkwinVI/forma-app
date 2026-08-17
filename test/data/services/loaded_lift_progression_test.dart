import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';

/// Loaded and weighted lifts are ordinary skill-tree steps: they climb the
/// same rep ladder as everything else and master the same way. There is no
/// ask-first path any more.
void main() {
  final barbellSquat = ExerciseCatalog.findById('barbell_squat_barbell_squat')!;
  final weightedSquat = ExerciseCatalog.findById('squat_barbell_squat')!;
  final pushUp = ExerciseCatalog.findById('pushups_push_up')!;

  ExerciseProgress progressAt(
    String exerciseId, {
    required int value,
    double? weightKg = 70,
    int sets = 3,
    ExerciseStatus status = ExerciseStatus.active,
  }) {
    return ExerciseProgress(
      exerciseId: exerciseId,
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

  group('a loaded lift follows the ordinary ladder', () {
    test('hitting 3 × 5 moves the target to 3 × 6, no approval needed', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 15,
        progress: progressAt(barbellSquat.id, value: 5),
      );

      expect(outcome.isEmpty, isFalse);
      expect(outcome.targetChanges[barbellSquat.id]?.sets, 3);
      expect(outcome.targetChanges[barbellSquat.id]?.value, 6);
      expect(outcome.statusChanges, isEmpty);
    });

    test('missing the target changes nothing', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 12,
        progress: progressAt(barbellSquat.id, value: 5),
      );

      expect(outcome.isEmpty, isTrue);
    });

    test('reaching the mastery volume masters it like any other step', () {
      final outcome = outcomeFor(
        exercise: barbellSquat,
        volume: 24,
        progress: progressAt(barbellSquat.id, value: 8),
      );

      expect(outcome.statusChanges[barbellSquat.id], ExerciseStatus.mastered);
    });

    test('the weighted squat branch climbs the same way', () {
      final outcome = outcomeFor(
        exercise: weightedSquat,
        volume: 15,
        progress: progressAt(weightedSquat.id, value: 5),
      );

      expect(outcome.targetChanges[weightedSquat.id]?.value, 6);
    });

    test('bodyweight exercises are unchanged', () {
      final outcome = outcomeFor(exercise: pushUp, volume: 24);

      expect(outcome.statusChanges['pushups_push_up'], ExerciseStatus.mastered);
    });
  });
}
