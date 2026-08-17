import '../models/exercise_model.dart';
import '../models/exercise_progress_model.dart';
import 'supabase_service.dart';

/// One exercise's opening position, as program setup writes it: a status,
/// and the target it opens on where the standard ladder target is not it.
typedef StartingPosition = ({
  ExerciseStatus status,
  int? targetSets,
  int? targetValue,
  double? targetWeightKg,
});

class ProgressService {
  final _client = SupabaseService.client;

  Future<List<ExerciseProgress>> fetchAll(String userId) async {
    final data = await _client
        .from('user_exercise_progress')
        .select()
        .eq('user_id', userId);
    return (data as List)
        .map((m) => ExerciseProgress.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(
    String userId,
    String exerciseId,
    ExerciseStatus status,
  ) async {
    // onConflict must name the (user_id, exercise_id) unique key — the
    // default conflict target is the primary key `id`, which is freshly
    // generated per call and turns updates into duplicate-key errors.
    // Target columns are absent from the payload, so an existing row keeps
    // its current incremental target.
    await _client.from('user_exercise_progress').upsert(
      {
        'user_id': userId,
        'exercise_id': exerciseId,
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,exercise_id',
    );
  }

  /// Writes several exercises' starting positions — status and target
  /// together, in one statement.
  ///
  /// One statement on purpose: a program's starting position is written as a
  /// whole or not at all. When it was written row by row, a failure partway
  /// left the written rows behind, and the retry — which skips exercises that
  /// already have a row — silently dropped everything after the failure.
  Future<void> upsertStartingPositions(
    String userId,
    Map<String, StartingPosition> positions,
  ) async {
    if (positions.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    await _client.from('user_exercise_progress').upsert(
      [
        // Every row carries every column — a bulk write must be uniform, and
        // these are fresh rows, so a null target is simply "not set yet".
        for (final entry in positions.entries)
          {
            'user_id': userId,
            'exercise_id': entry.key,
            'status': entry.value.status.name,
            'current_target_sets': entry.value.targetSets,
            'current_target_value': entry.value.targetValue,
            'current_target_weight_kg': entry.value.targetWeightKg,
            'updated_at': now,
          },
      ],
      onConflict: 'user_id,exercise_id',
    );
  }

  /// Turns auto progression on or off for one accessory. Status and target
  /// are absent from the payload, so an existing row keeps both; a fresh row
  /// gets the database default status ('inactive'), which is what an
  /// accessory has always had — nothing about a library movement is
  /// activated or mastered.
  Future<void> setAutoProgression(
    String userId,
    String exerciseId, {
    required bool enabled,
  }) async {
    await _client.from('user_exercise_progress').upsert(
      {
        'user_id': userId,
        'exercise_id': exerciseId,
        'auto_progression': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,exercise_id',
    );
  }

  /// Writes the current incremental target for an exercise. Status is absent
  /// from the payload, so an existing row keeps its status; a fresh row gets
  /// the database default ('inactive'). [targetWeightKg] is only written when
  /// given, so a bodyweight target never clears a stored working weight.
  Future<void> upsertTarget(
    String userId,
    String exerciseId, {
    required int targetSets,
    required int targetValue,
    double? targetWeightKg,
  }) async {
    await _client.from('user_exercise_progress').upsert(
      {
        'user_id': userId,
        'exercise_id': exerciseId,
        'current_target_sets': targetSets,
        'current_target_value': targetValue,
        if (targetWeightKg != null) 'current_target_weight_kg': targetWeightKg,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,exercise_id',
    );
  }
}
