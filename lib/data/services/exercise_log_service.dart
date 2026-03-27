import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_log_model.dart';
import 'supabase_service.dart';

class ExerciseLogService {
  final _client = SupabaseService.client;

  Future<List<ExerciseLog>> fetchForExercise(
    String userId,
    String exerciseId,
  ) async {
    final data = await _client
        .from('exercise_logs')
        .select()
        .eq('user_id', userId)
        .eq('exercise_id', exerciseId)
        .order('logged_at', ascending: false);
    return (data as List)
        .map((m) => ExerciseLog.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> logWorkout(
    String userId,
    String exerciseId,
    List<ExerciseSet> sets, {
    String? notes,
  }) async {
    final totalReps = sets.fold<int>(0, (sum, s) => sum + s.reps);
    final totalVolumeKg =
        sets.fold<double>(0, (sum, s) => sum + s.reps * s.weightKg);

    await _client.from('exercise_logs').insert({
      'user_id': userId,
      'exercise_id': exerciseId,
      'logged_at': DateTime.now().toIso8601String(),
      'sets': sets.map((s) => s.toJson()).toList(),
      'total_reps': totalReps,
      'total_volume_kg': totalVolumeKg,
      if (notes != null) 'notes': notes,
    });
  }
}
