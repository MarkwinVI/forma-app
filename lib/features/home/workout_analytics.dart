import '../../data/models/training_program_model.dart';
import '../../data/services/exercise_progression_service.dart';
import 'completed_workout_model.dart';

/// The properties `workout_finished` and `workout_abandoned` share, so the
/// two events line up column for column: what was planned, what was done, and
/// how long it took. Built from a [CompletedWorkout] because that is the one
/// object both the finish screen and the discard path can produce.
Map<String, Object> workoutOutcomeProperties(
  CompletedWorkout workout, {
  String? sessionId,
}) {
  var plannedSets = 0;
  var plannedReps = 0;
  for (final exerciseEntry in workout.exercises) {
    final sets = exerciseEntry.targetSets ??
        ExerciseProgressionService.setCountForExercise(exerciseEntry.exercise);
    final value = exerciseEntry.targetValue ??
        ExerciseProgressionService.targetValueForExercise(
          exerciseEntry.exercise,
        );
    plannedSets += sets;
    if (!exerciseEntry.isTimed) plannedReps += sets * value;
  }

  return {
    if (sessionId != null) 'workout_id': sessionId,
    if (workout.analyticsId != null) 'workout_client_id': workout.analyticsId!,
    'session_type': workout.sessionType.dbValue,
    'duration_seconds': workout.totalDuration.inSeconds,
    'exercise_count': workout.exercises.length,
    'completed_sets': workout.totalSets,
    'planned_sets': plannedSets,
    'completed_reps': workout.totalReps,
    'planned_reps': plannedReps,
    if (workout.totalTimedSeconds > 0)
      'completed_timed_seconds': workout.totalTimedSeconds,
  };
}
