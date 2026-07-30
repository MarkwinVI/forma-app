import '../models/exercise_model.dart';
import 'exercise_coaching.dart';
import 'exercise_library_catalog.dart';

/// Where a screen goes to ask what a movement is and how it is done.
///
/// Coaching belongs to the movement, not to the step: the seven weighted
/// pull-up rungs are one exercise performed at seven loads, and they share a
/// single how-to, form check and demo. So a step is asked about by the
/// movement it is performed with, not by its own id.
class ExerciseCoachingCatalog {
  ExerciseCoachingCatalog._();

  /// Coaching for an exercise, or null where the sheet has none yet. Callers
  /// fall back to the movement pattern's generic advice.
  static ExerciseCoaching? forExercise(Exercise exercise) =>
      ExerciseLibraryCatalog.coachingFor(
        exercise.libraryId.isEmpty ? exercise.id : exercise.libraryId,
      );

  /// Coaching by library movement id, for callers holding an id rather than
  /// an exercise.
  static ExerciseCoaching? findById(String libraryId) =>
      ExerciseLibraryCatalog.coachingFor(libraryId);
}
