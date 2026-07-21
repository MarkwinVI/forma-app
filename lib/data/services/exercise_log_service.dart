import '../catalog/exercise_catalog.dart';
import '../models/exercise_log_model.dart';
import '../models/workout_history_model.dart';
import 'supabase_service.dart';

class WorkoutExerciseLogInput {
  final String exerciseId;
  final List<ExerciseSet> sets;

  /// Whether the exercise was a skill-tree progression item at save time.
  /// Standalone/custom exercises are false and are never auto-progressed.
  final bool isProgression;

  /// Progression track the exercise was trained under (TrainingTrack
  /// dbValue). Null for standalone exercises.
  final String? trackId;

  /// Prescribed target shown to the user for this session: set count and
  /// per-set value (reps, or seconds when timed).
  final int? targetSets;
  final int? targetValue;

  const WorkoutExerciseLogInput({
    required this.exerciseId,
    required this.sets,
    this.isProgression = false,
    this.trackId,
    this.targetSets,
    this.targetValue,
  });
}

class ExerciseLogService {
  final _client = SupabaseService.client;

  Future<bool> hasAtLeastTwoLogs(String userId) async {
    final data = await _client
        .from('workout_sessions')
        .select('id')
        .eq('user_id', userId)
        .limit(2);

    return (data as List).length >= 2;
  }

  /// Number of workout sessions finished on the given local calendar date.
  /// Used to advance the program pointer only once per day.
  Future<int> countSessionsOnLocalDate(String userId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final data = await _client
        .from('workout_sessions')
        .select('id')
        .eq('user_id', userId)
        .gte('finished_at', dayStart.toUtc().toIso8601String())
        .lt('finished_at', dayEnd.toUtc().toIso8601String());

    return (data as List).length;
  }

  /// Deletes a saved workout session; its exercise logs cascade in the
  /// database (`workout_exercise_logs.workout_session_id on delete cascade`).
  Future<void> deleteWorkoutSession(String userId, String sessionId) async {
    await _client
        .from('workout_sessions')
        .delete()
        .eq('id', sessionId)
        .eq('user_id', userId);
  }

  Future<List<ExerciseLog>> fetchForExercise(
    String userId,
    String exerciseId,
  ) async {
    final data = await _client.from('workout_exercise_logs').select('''
          id,
          exercise_id,
          sets,
          total_reps,
          total_volume_kg,
          workout_sessions!inner(title, finished_at)
        ''').eq('user_id', userId).eq('exercise_id', exerciseId);

    final logs = (data as List)
        .map((m) => _exerciseLogFromWorkoutExerciseMap(
              m as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return logs;
  }

  Future<List<PastWorkout>> fetchPastWorkouts(String userId) async {
    final data = await _client.from('workout_sessions').select('''
          id,
          title,
          session_type,
          started_at,
          finished_at,
          workout_exercise_logs(
            id,
            exercise_id,
            order_index,
            sets,
            total_reps,
            total_duration_seconds,
            total_volume_kg
          )
        ''').eq('user_id', userId).order('finished_at', ascending: false);

    return (data as List)
        .map((m) => _pastWorkoutFromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Saves the session and its exercise logs; returns the new session's id
  /// (null when there was nothing to save).
  Future<String?> saveWorkoutSession({
    required String userId,
    required String title,
    required String sessionType,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<WorkoutExerciseLogInput> exercises,
  }) async {
    if (exercises.isEmpty) return null;

    final session = await _client
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'title': title,
          'session_type': sessionType,
          // Store UTC so local-date logic (workout-complete state, schedule
          // rollover) can convert back with .toLocal() reliably.
          'started_at': startedAt.toUtc().toIso8601String(),
          'finished_at': finishedAt.toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    final sessionId = session['id'] as String;

    await _client.from('workout_exercise_logs').insert([
      for (var index = 0; index < exercises.length; index++)
        {
          'workout_session_id': sessionId,
          'user_id': userId,
          'exercise_id': exercises[index].exerciseId,
          'order_index': index,
          'sets': exercises[index].sets.map((set) => set.toJson()).toList(),
          'total_reps': _totalReps(exercises[index].sets),
          'total_duration_seconds': _totalDurationSeconds(
            exercises[index].sets,
          ),
          'total_volume_kg': _totalVolumeKg(exercises[index].sets),
          'is_progression': exercises[index].isProgression,
          'track_id': exercises[index].trackId,
          'target_sets': exercises[index].targetSets,
          'target_value': exercises[index].targetValue,
        },
    ]);

    return sessionId;
  }

  /// Best single-set value (reps, or seconds when timed) the user has ever
  /// logged per exercise, optionally excluding one session — used to detect
  /// personal bests for the session being saved without counting itself.
  Future<Map<String, int>> bestSetValues(
    String userId,
    Set<String> exerciseIds, {
    String? excludeSessionId,
  }) async {
    if (exerciseIds.isEmpty) return const {};

    final data = await _client
        .from('workout_exercise_logs')
        .select('exercise_id, workout_session_id, sets')
        .eq('user_id', userId)
        .inFilter('exercise_id', exerciseIds.toList());

    final bests = <String, int>{};
    for (final row in data as List) {
      final map = row as Map<String, dynamic>;
      if (excludeSessionId != null &&
          map['workout_session_id'] == excludeSessionId) {
        continue;
      }

      final exerciseId = map['exercise_id'] as String;
      for (final rawSet in map['sets'] as List<dynamic>? ?? const []) {
        final set = ExerciseSet.fromJson(rawSet as Map<String, dynamic>);
        final value =
            set.durationSeconds > 0 ? set.durationSeconds : set.reps;
        if (value > (bests[exerciseId] ?? 0)) {
          bests[exerciseId] = value;
        }
      }
    }

    return bests;
  }

  ExerciseLog _exerciseLogFromWorkoutExerciseMap(Map<String, dynamic> map) {
    final session = map['workout_sessions'] as Map<String, dynamic>;
    final rawSets = map['sets'] as List<dynamic>? ?? [];
    final sets = rawSets
        .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
        .toList();

    return ExerciseLog(
      id: map['id'] as String,
      exerciseId: map['exercise_id'] as String,
      loggedAt: DateTime.parse(session['finished_at'] as String).toLocal(),
      sets: sets,
      totalReps: map['total_reps'] as int? ?? 0,
      totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0,
      notes: session['title'] as String?,
    );
  }

  PastWorkout _pastWorkoutFromMap(Map<String, dynamic> map) {
    final rawExercises =
        map['workout_exercise_logs'] as List<dynamic>? ?? const [];
    final exercises = rawExercises
        .map(
          (m) => _pastWorkoutExerciseFromMap(m as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return PastWorkout(
      id: map['id'] as String,
      title: map['title'] as String,
      sessionType: map['session_type'] as String,
      startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
      loggedAt: DateTime.parse(map['finished_at'] as String).toLocal(),
      exercises: exercises
          .map(
            (exercise) => PastWorkoutExercise(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              setCount: exercise.setCount,
              totalReps: exercise.totalReps,
              totalTimedSeconds: exercise.totalTimedSeconds,
              sets: exercise.sets,
            ),
          )
          .toList(),
    );
  }

  _OrderedPastWorkoutExercise _pastWorkoutExerciseFromMap(
    Map<String, dynamic> map,
  ) {
    final exerciseId = map['exercise_id'] as String;
    final exercise = ExerciseCatalog.findById(exerciseId);
    final rawSets = map['sets'] as List<dynamic>? ?? [];
    final sets = <PastWorkoutSet>[];

    for (var index = 0; index < rawSets.length; index++) {
      final set = ExerciseSet.fromJson(rawSets[index] as Map<String, dynamic>);
      final isTimed = set.durationSeconds > 0;
      sets.add(
        PastWorkoutSet(
          number: index + 1,
          value: isTimed ? set.durationSeconds : set.reps,
          isTimed: isTimed,
        ),
      );
    }

    return _OrderedPastWorkoutExercise(
      orderIndex: map['order_index'] as int? ?? 0,
      exerciseId: exerciseId,
      exerciseName: exercise?.name ?? exerciseId,
      setCount: sets.length,
      totalReps: map['total_reps'] as int? ?? 0,
      totalTimedSeconds: map['total_duration_seconds'] as int? ?? 0,
      sets: sets,
    );
  }

  int _totalReps(List<ExerciseSet> sets) {
    return sets.fold(0, (sum, set) => sum + set.reps);
  }

  int _totalDurationSeconds(List<ExerciseSet> sets) {
    return sets.fold(0, (sum, set) => sum + set.durationSeconds);
  }

  double _totalVolumeKg(List<ExerciseSet> sets) {
    return sets.fold(0, (sum, set) => sum + set.reps * set.weightKg);
  }
}

class _OrderedPastWorkoutExercise extends PastWorkoutExercise {
  final int orderIndex;

  const _OrderedPastWorkoutExercise({
    required this.orderIndex,
    required super.exerciseId,
    required super.exerciseName,
    required super.setCount,
    required super.totalReps,
    required super.totalTimedSeconds,
    required super.sets,
  });
}
