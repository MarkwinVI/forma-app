import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';

/// Default set/rep prescriptions shared by the home screen and live workout.

bool isTimedExercise(Exercise exercise) {
  final name = exercise.name.toLowerCase();
  final description = exercise.description.toLowerCase();

  return name.contains('hold') ||
      name.contains('hang') ||
      name.contains('plank') ||
      name.contains('lever') ||
      name.contains('handstand') ||
      description.contains('for time');
}

int defaultSetCount(TrainingRecommendationItem item) {
  switch (item.exercise.programSection) {
    case ExerciseProgramSection.warmup:
      return 2;
    case ExerciseProgramSection.skillWork:
      return 3;
    case ExerciseProgramSection.mainExercises:
      return item.exercise.difficulty >= 4 ? 4 : 3;
    case ExerciseProgramSection.coolDown:
      return 2;
  }
}

int defaultTargetForExercise(Exercise exercise) {
  if (isTimedExercise(exercise)) {
    if (exercise.difficulty <= 1) return 30;
    if (exercise.difficulty <= 3) return 20;
    return 12;
  }

  if (exercise.difficulty <= 1) return 12;
  if (exercise.difficulty <= 3) return 8;
  return 5;
}

int defaultTarget(TrainingRecommendationItem item) {
  return defaultTargetForExercise(item.exercise);
}

String difficultyLabel(int difficulty) {
  if (difficulty <= 1) return 'Beginner';
  if (difficulty <= 3) return 'Intermediate';
  return 'Advanced';
}
