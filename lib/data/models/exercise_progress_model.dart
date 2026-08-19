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

  /// Working weight for the loaded lifts (barbell squat, Romanian deadlift),
  /// and for an accessory Forma progresses. Null for everything trained at
  /// bodyweight.
  final double? currentTargetWeightKg;

  /// Whether Forma manages this accessory's reps and weight. Null is the
  /// default and reads as on — the flag is only written when the user turns
  /// auto progression off, and it says nothing about exercises that cannot
  /// have it in the first place.
  final bool? autoProgression;

  const ExerciseProgress({
    required this.exerciseId,
    required this.status,
    required this.updatedAt,
    this.currentTargetSets,
    this.currentTargetValue,
    this.currentTargetWeightKg,
    this.autoProgression,
  });

  factory ExerciseProgress.fromMap(Map<String, dynamic> map) {
    return ExerciseProgress(
      exerciseId: map['exercise_id'] as String,
      // 'skipped' predates the migration that retired it; it read as cleared,
      // so a row the migration has not converted yet reads as mastered.
      status: map['status'] == 'skipped'
          ? ExerciseStatus.mastered
          : ExerciseStatus.values.byName(map['status'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      currentTargetSets: map['current_target_sets'] as int?,
      currentTargetValue: map['current_target_value'] as int?,
      currentTargetWeightKg:
          (map['current_target_weight_kg'] as num?)?.toDouble(),
      autoProgression: map['auto_progression'] as bool?,
    );
  }

  ExerciseProgress copyWith({
    ExerciseStatus? status,
    int? currentTargetSets,
    int? currentTargetValue,
    double? currentTargetWeightKg,
    bool? autoProgression,
    DateTime? updatedAt,
  }) {
    return ExerciseProgress(
      exerciseId: exerciseId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      currentTargetSets: currentTargetSets ?? this.currentTargetSets,
      currentTargetValue: currentTargetValue ?? this.currentTargetValue,
      currentTargetWeightKg:
          currentTargetWeightKg ?? this.currentTargetWeightKg,
      autoProgression: autoProgression ?? this.autoProgression,
    );
  }
}
