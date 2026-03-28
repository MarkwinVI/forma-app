import 'exercise_model.dart';

class ExerciseProgress {
  final String exerciseId;
  final ExerciseStatus status;
  final DateTime updatedAt;

  const ExerciseProgress({
    required this.exerciseId,
    required this.status,
    required this.updatedAt,
  });

  factory ExerciseProgress.fromMap(Map<String, dynamic> map) {
    return ExerciseProgress(
      exerciseId: map['exercise_id'] as String,
      status: ExerciseStatus.values.byName(map['status'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
