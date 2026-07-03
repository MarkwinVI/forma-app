import '../models/exercise_log_model.dart';
import '../models/training_program_model.dart';
import 'exercise_log_service.dart';
import 'supabase_service.dart';
import 'training_program_service.dart';
import 'training_program_store_service.dart';

/// Debug-build helpers for resetting and seeding account data.
/// Only reachable from the Developer section in Settings (kDebugMode).
class DevToolsService {
  final _client = SupabaseService.client;
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  /// Wipes everything that makes this account look like an existing user:
  /// workout history, exercise progress, branch choices, and the training
  /// program itself. The auth session and `users` row are kept, so the app
  /// lands on the new-user home state.
  Future<void> resetToNewUser(String userId) async {
    // Children before parents to respect foreign keys.
    await _client.from('workout_exercise_logs').delete().eq('user_id', userId);
    await _client.from('workout_sessions').delete().eq('user_id', userId);
    await _client.from('user_exercise_progress').delete().eq('user_id', userId);
    await _client
        .from('user_progression_branches')
        .delete()
        .eq('user_id', userId);
    await _client
        .from('user_training_program_state')
        .delete()
        .eq('user_id', userId);
    await _client.from('user_training_programs').delete().eq('user_id', userId);
  }

  /// Seeds five completed workouts spread across the last 30 days
  /// (oldest ~29 days ago, newest yesterday), with rep counts ramping up
  /// so trend and momentum UIs have something to show.
  Future<void> generateSampleWorkouts(String userId) async {
    final logic = await _trainingProgramStoreService.fetchProgramLogic(userId);
    final programType =
        logic?.program.programType ?? TrainingProgramType.fullBody;
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...?logic?.branchSelections,
    };

    final trainingDays = _trainingProgramStoreService
        .scheduleCycleFor(programType: programType)
        .where((session) => session != TrainingSessionType.rest)
        .toList();

    final today = DateTime.now();
    for (var index = 0; index < 5; index++) {
      final daysAgo = 29 - index * 7;
      final sessionType = trainingDays[index % trainingDays.length];
      final recommendation = _trainingProgramService.buildToday(
        progressMap: const {},
        programType: programType,
        sessionType: sessionType,
        branchSelections: branchSelections,
      );
      if (recommendation.items.isEmpty) continue;

      final startedAt = DateTime(today.year, today.month, today.day, 17)
          .subtract(Duration(days: daysAgo));
      final finishedAt = startedAt.add(const Duration(minutes: 42));

      await _exerciseLogService.saveWorkoutSession(
        userId: userId,
        title: recommendation.sessionLabel,
        sessionType: sessionType.dbValue,
        startedAt: startedAt,
        finishedAt: finishedAt,
        exercises: [
          for (final item in recommendation.items)
            WorkoutExerciseLogInput(
              exerciseId: item.exercise.id,
              sets: List.filled(3, ExerciseSet(reps: 6 + index)),
            ),
        ],
      );
    }
  }
}
