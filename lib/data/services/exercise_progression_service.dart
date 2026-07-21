import '../catalog/exercise_catalog.dart';
import '../catalog/skill_category_catalog.dart';
import '../models/exercise_model.dart';
import 'progress_service.dart';

/// One exercise's outcome in a saved workout session: the exercise as it was
/// logged (program section intact, so targets match what the user saw) and
/// the total volume achieved across all sets (reps, or seconds when timed).
class SessionExerciseResult {
  final Exercise exercise;
  final int volume;

  const SessionExerciseResult({required this.exercise, required this.volume});
}

/// Advances skill-path progress after a workout is saved: an exercise whose
/// session volume meets its target is marked mastered, and the next move in
/// its skill path becomes active. The target math is the single source of
/// truth shared with the dashboard ("Closest to levelling up"), so the goal
/// the user sees is the goal that advances them.
class ExerciseProgressionService {
  final _progressService = ProgressService();

  static bool isTimedExercise(Exercise exercise) {
    final name = exercise.name.toLowerCase();
    final description = exercise.description.toLowerCase();

    return name.contains('hold') ||
        name.contains('hang') ||
        name.contains('plank') ||
        name.contains('lever') ||
        name.contains('handstand') ||
        description.contains('for time');
  }

  /// Per-set target (reps, or seconds when timed).
  static int targetValueForExercise(Exercise exercise) {
    if (isTimedExercise(exercise)) {
      if (exercise.difficulty <= 1) return 30;
      if (exercise.difficulty <= 3) return 20;
      return 12;
    }

    if (exercise.difficulty <= 1) return 12;
    if (exercise.difficulty <= 3) return 8;
    return 5;
  }

  /// Prescribed set count for the section the exercise is programmed in.
  static int setCountForExercise(Exercise exercise) {
    return switch (exercise.programSection) {
      ExerciseProgramSection.warmup => 2,
      ExerciseProgramSection.skillWork => 3,
      ExerciseProgramSection.mainExercises => exercise.difficulty >= 4 ? 4 : 3,
      ExerciseProgramSection.coolDown => 2,
    };
  }

  /// Whole-session target volume: per-set target × the section's set count.
  static int targetVolumeForExercise(Exercise exercise) {
    return setCountForExercise(exercise) * targetValueForExercise(exercise);
  }

  /// Pure progression rule, separated from persistence so it is testable:
  /// returns the status changes a session's results earn. Exercises that met
  /// their target become mastered and unlock (activate) the next move in
  /// their skill path.
  static Map<String, ExerciseStatus> computeChanges({
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final changes = <String, ExerciseStatus>{};

    ExerciseStatus statusOf(String id) =>
        changes[id] ?? progressMap[id] ?? ExerciseStatus.inactive;

    for (final result in results) {
      final exercise = result.exercise;
      if (statusOf(exercise.id) == ExerciseStatus.mastered) continue;
      if (result.volume < targetVolumeForExercise(exercise)) continue;

      changes[exercise.id] = ExerciseStatus.mastered;

      final next = _nextExerciseInPath(exercise);
      if (next != null && statusOf(next.id) == ExerciseStatus.inactive) {
        changes[next.id] = ExerciseStatus.active;
      }
    }

    return changes;
  }

  /// Applies [computeChanges] and persists every change for [userId].
  /// Returns the changes so callers can update their in-memory progress map.
  Future<Map<String, ExerciseStatus>> applySessionResults({
    required String userId,
    required List<SessionExerciseResult> results,
    required Map<String, ExerciseStatus> progressMap,
  }) async {
    final changes = computeChanges(results: results, progressMap: progressMap);
    for (final entry in changes.entries) {
      await _progressService.upsert(userId, entry.key, entry.value);
    }
    return changes;
  }

  /// The move that follows [exercise] across every training path it appears
  /// in. An exercise's own skillCategoryId/branchId don't identify the path
  /// being trained (paths share prefix exercises), so all catalog paths are
  /// scanned. At a branch point — multiple distinct successors — nothing is
  /// activated: mastery alone is enough for the program to pick the next
  /// move from the user's selected branch.
  static Exercise? _nextExerciseInPath(Exercise exercise) {
    final successors = <String>{};
    for (final category in SkillCategoryCatalog.all()) {
      for (final path in category.trainingPaths.values) {
        final index = path.indexOf(exercise.id);
        if (index >= 0 && index + 1 < path.length) {
          successors.add(path[index + 1]);
        }
      }
    }
    if (successors.length != 1) return null;
    return ExerciseCatalog.findById(successors.first);
  }
}
