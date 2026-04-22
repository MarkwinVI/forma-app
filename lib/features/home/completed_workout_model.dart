import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';

class CompletedWorkout {
  final String sessionLabel;
  final TrainingSessionType sessionType;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<CompletedWorkoutExercise> exercises;

  const CompletedWorkout({
    required this.sessionLabel,
    required this.sessionType,
    required this.startedAt,
    required this.finishedAt,
    required this.exercises,
  });

  String get historyTitle {
    switch (sessionType) {
      case TrainingSessionType.fullBody:
        return 'Full Body';
      case TrainingSessionType.push:
        return 'Push';
      case TrainingSessionType.pull:
        return 'Pull';
      case TrainingSessionType.upper:
        return 'Upper';
      case TrainingSessionType.lower:
        return 'Lower';
      case TrainingSessionType.rest:
        return 'Rest';
    }
  }

  Duration get totalDuration => finishedAt.difference(startedAt);

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  int get totalReps =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalReps);

  int get totalTimedSeconds => exercises.fold(
        0,
        (sum, exercise) => sum + exercise.totalTimedSeconds,
      );
}

class CompletedWorkoutExercise {
  final TrainingRecommendationItem item;
  final List<CompletedWorkoutSet> sets;

  const CompletedWorkoutExercise({
    required this.item,
    required this.sets,
  });

  Exercise get exercise => item.exercise;
  ExerciseStatus get status => item.status;
  TrainingTrack get track => item.track;

  bool get isTimed => sets.any((set) => set.isTimed);

  int get totalReps =>
      sets.where((set) => !set.isTimed).fold(0, (sum, set) => sum + set.value);

  int get totalTimedSeconds =>
      sets.where((set) => set.isTimed).fold(0, (sum, set) => sum + set.value);
}

class CompletedWorkoutSet {
  final int number;
  final int value;
  final bool isTimed;

  const CompletedWorkoutSet({
    required this.number,
    required this.value,
    required this.isTimed,
  });
}
