import 'exercise_model.dart';

class ExerciseProgress {
  final String exerciseId;
  final ExerciseStatus status;
  final DateTime updatedAt;

  /// Current incremental target on the progression ladder. Null means the
  /// target was never advanced — the app falls back to the initial ladder
  /// target (3 × 6 reps, or 3 × 10s for timed exercises).
  final int? currentTargetSets;

  /// Per-set value of the current target: reps, or seconds when timed.
  final int? currentTargetValue;

  const ExerciseProgress({
    required this.exerciseId,
    required this.status,
    required this.updatedAt,
    this.currentTargetSets,
    this.currentTargetValue,
  });

  factory ExerciseProgress.fromMap(Map<String, dynamic> map) {
    return ExerciseProgress(
      exerciseId: map['exercise_id'] as String,
      status: ExerciseStatus.values.byName(map['status'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      currentTargetSets: map['current_target_sets'] as int?,
      currentTargetValue: map['current_target_value'] as int?,
    );
  }

  ExerciseProgress copyWith({
    ExerciseStatus? status,
    int? currentTargetSets,
    int? currentTargetValue,
    DateTime? updatedAt,
  }) {
    return ExerciseProgress(
      exerciseId: exerciseId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      currentTargetSets: currentTargetSets ?? this.currentTargetSets,
      currentTargetValue: currentTargetValue ?? this.currentTargetValue,
    );
  }
}
