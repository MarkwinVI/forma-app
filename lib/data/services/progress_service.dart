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
}
