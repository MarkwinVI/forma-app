import '../models/exercise_model.dart';
import '../models/exercise_progress_model.dart';
import 'supabase_service.dart';

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
