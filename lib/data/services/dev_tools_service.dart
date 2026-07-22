import '../models/exercise_log_model.dart';
import '../models/exercise_model.dart';
import '../models/exercise_progress_model.dart';
import '../models/training_program_model.dart';
import 'exercise_log_service.dart';
import 'exercise_progression_service.dart';
import 'progress_service.dart';
import 'skill_track_service.dart';
import 'supabase_service.dart';
import 'training_program_service.dart';
import 'training_program_store_service.dart';

/// Helpers for resetting and seeding account data.
/// Reachable from the Developer section in Settings (all builds, for now).
class DevToolsService {
  final _client = SupabaseService.client;
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();
  final _progressService = ProgressService();
  final _progressionService = ExerciseProgressionService();

  /// Wipes everything that makes this account look like an existing user:
  /// workout history, exercise progress, branch choices, and the training
  /// program itself. The auth session and `users` row are kept, so the app
  /// lands on the new-user home state.
  Future<void> resetToNewUser(String userId) async {
    // Children before parents to respect foreign keys.
    await _client.from('progression_events').delete().eq('user_id', userId);
    await _client.from('user_skill_tracks').delete().eq('user_id', userId);
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

  /// Volume ramp for the five seeded sessions, as a share of each exercise's
  /// target. The last two hit 100%, so early path exercises get mastered and
  /// the progression (skill tree, "closest to levelling up") visibly moves.
  static const _sessionRamp = [0.6, 0.75, 0.9, 1.0, 1.0];

  /// Seeds five completed workouts spread across the last 30 days
  /// (oldest ~29 days ago, newest yesterday). Volumes ramp toward each
  /// exercise's target and the same auto-progression as a real workout runs
  /// after every session, so exercises master and paths advance just like
  /// they would from real training.
  Future<void> generateSampleWorkouts(String userId) async {
    final logic = await _trainingProgramStoreService.fetchProgramLogic(userId);
    final programType =
        logic?.program.programType ?? TrainingProgramType.fullBody;
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...?logic?.branchSelections,
    };
    final rawSessionItems =
        logic?.program.variationRules['session_items_v1'];
    final sessionItemsConfig = rawSessionItems is Map
        ? Map<String, dynamic>.from(rawSessionItems)
        : const <String, dynamic>{};

    final progressEntries = await _progressService.fetchAll(userId);
    final progressRows = {
      for (final entry in progressEntries) entry.exerciseId: entry,
    };
    final progressMap = {
      for (final entry in progressEntries) entry.exerciseId: entry.status,
    };
    final masteryTargets =
        logic?.masteryTargets ?? MasteryTargetSettings.defaults;
    final skillTracks = await SkillTrackService().getOrSeed(
      userId,
      laneSelections: branchSelections,
      goalSkillIds: logic?.program.setupGoalIds ?? const [],
    );

    final trainingDays = _trainingProgramStoreService
        .scheduleCycleFor(programType: programType)
        .where((session) => session != TrainingSessionType.rest)
        .toList();

    final today = DateTime.now();
    for (var index = 0; index < _sessionRamp.length; index++) {
      final daysAgo = 29 - index * 7;
      final sessionType = trainingDays[index % trainingDays.length];
      final recommendation = _trainingProgramService.buildToday(
        progressMap: progressMap,
        programType: programType,
        sessionType: sessionType,
        branchSelections: branchSelections,
        sessionItemsConfig: sessionItemsConfig,
        skillTracks: skillTracks,
      );
      if (recommendation.items.isEmpty) continue;

      final startedAt = DateTime(today.year, today.month, today.day, 17)
          .subtract(Duration(days: daysAgo));
      final finishedAt = startedAt.add(const Duration(minutes: 42));

      final results = <SessionExerciseResult>[];
      final exercises = <WorkoutExerciseLogInput>[];
      for (final item in recommendation.items) {
        final progress = progressRows[item.exercise.id];
        final prescribed = item.isProgression
            ? ExerciseProgressionService.currentTargetForExercise(
                item.exercise,
                progress: progress,
                masterySettings: masteryTargets,
              )
            : ExerciseTarget(
                sets: ExerciseProgressionService.setCountForExercise(
                  item.exercise,
                ),
                value: ExerciseProgressionService.targetValueForExercise(
                  item.exercise,
                ),
              );
        // Ramp toward the mastery volume so the final full-volume sessions
        // actually master exercises and the progression visibly moves.
        final rampTarget = item.isProgression
            ? ExerciseProgressionService.masteryTargetForExercise(
                item.exercise,
                progress: progress,
                masterySettings: masteryTargets,
              ).volume
            : prescribed.volume;
        final volume = (rampTarget * _sessionRamp[index]).round();
        if (item.isProgression) {
          results.add(
            SessionExerciseResult(
              exercise: item.exercise,
              volume: volume,
              trackId: item.track.dbValue,
            ),
          );
        }
        exercises.add(
          WorkoutExerciseLogInput(
            exerciseId: item.exercise.id,
            sets: _splitIntoSets(
              volume,
              isTimed:
                  ExerciseProgressionService.isTimedExercise(item.exercise),
            ),
            isProgression: item.isProgression,
            trackId: item.track.dbValue,
            targetSets: prescribed.sets,
            targetValue: prescribed.value,
          ),
        );
      }

      final sessionId = await _exerciseLogService.saveWorkoutSession(
        userId: userId,
        title: recommendation.sessionLabel,
        sessionType: sessionType.dbValue,
        startedAt: startedAt,
        finishedAt: finishedAt,
        exercises: exercises,
      );
      if (sessionId == null) continue;

      // Same rule as a real workout: met targets climb the ladder or master
      // the exercise, so the next seeded session trains the next move.
      final outcome = await _progressionService.applySessionResults(
        userId: userId,
        sessionId: sessionId,
        results: results,
        progressRows: progressRows,
        masterySettings: masteryTargets,
        activeBranchByCategory: {
          for (final track in skillTracks)
            track.skillCategoryId: track.branchId,
        },
        goalSkillIds: logic?.program.setupGoalIds ?? const [],
      );
      final now = DateTime.now();
      for (final entry in outcome.statusChanges.entries) {
        progressMap[entry.key] = entry.value;
        progressRows[entry.key] = (progressRows[entry.key] ??
                ExerciseProgress(
                  exerciseId: entry.key,
                  status: entry.value,
                  updatedAt: now,
                ))
            .copyWith(status: entry.value, updatedAt: now);
      }
      for (final entry in outcome.targetChanges.entries) {
        progressRows[entry.key] = (progressRows[entry.key] ??
                ExerciseProgress(
                  exerciseId: entry.key,
                  status: ExerciseStatus.inactive,
                  updatedAt: now,
                ))
            .copyWith(
          currentTargetSets: entry.value.sets,
          currentTargetValue: entry.value.value,
          updatedAt: now,
        );
      }
    }
  }

  /// Splits a session volume into three sets whose values sum to [volume].
  List<ExerciseSet> _splitIntoSets(int volume, {required bool isTimed}) {
    const setCount = 3;
    final base = volume ~/ setCount;
    final remainder = volume - base * setCount;
    return [
      for (var i = 0; i < setCount; i++)
        isTimed
            ? ExerciseSet(durationSeconds: base + (i < remainder ? 1 : 0))
            : ExerciseSet(reps: base + (i < remainder ? 1 : 0)),
    ];
  }
}
