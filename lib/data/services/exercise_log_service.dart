import '../catalog/exercise_catalog.dart';
import '../models/exercise_log_model.dart';
import '../models/workout_history_model.dart';
import 'supabase_service.dart';

class WorkoutExerciseLogInput {
  final String exerciseId;
  final List<ExerciseSet> sets;

  const WorkoutExerciseLogInput({
    required this.exerciseId,
    required this.sets,
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

  Future<void> saveWorkoutSession({
    required String userId,
    required String title,
    required String sessionType,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<WorkoutExerciseLogInput> exercises,
  }) async {
    if (exercises.isEmpty) return;

    final session = await _client
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'title': title,
          'session_type': sessionType,
          'started_at': startedAt.toIso8601String(),
          'finished_at': finishedAt.toIso8601String(),
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
        },
    ]);
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
      loggedAt: DateTime.parse(session['finished_at'] as String),
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
      startedAt: DateTime.parse(map['started_at'] as String),
      loggedAt: DateTime.parse(map['finished_at'] as String),
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
