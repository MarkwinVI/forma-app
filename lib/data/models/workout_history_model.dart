class PastWorkout {
  final String id;
  final String title;
  final String sessionType;
  final DateTime startedAt;
  final DateTime loggedAt;
  final List<PastWorkoutExercise> exercises;

  const PastWorkout({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.startedAt,
    required this.loggedAt,
    required this.exercises,
  });

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.setCount);

  int get totalReps =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalReps);

  int get totalTimedSeconds => exercises.fold(
        0,
        (sum, exercise) => sum + exercise.totalTimedSeconds,
      );
}

class PastWorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int setCount;
  final int totalReps;
  final int totalTimedSeconds;
  final List<PastWorkoutSet> sets;

  const PastWorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.setCount,
    required this.totalReps,
    required this.totalTimedSeconds,
    required this.sets,
  });

  bool get isTimed => totalTimedSeconds > 0 && totalReps == 0;
}

class PastWorkoutSet {
  final int number;
  final int value;
  final bool isTimed;

  const PastWorkoutSet({
    required this.number,
    required this.value,
    required this.isTimed,
  });
}
