/// What a suggestion proposes doing to a loaded lift.
enum ProgressionSuggestionKind {
  /// Same weight, one more rep per set.
  repIncrease,

  /// More weight, reps back to the bottom of the rep range.
  loadIncrease,
}

extension ProgressionSuggestionKindX on ProgressionSuggestionKind {
  String get dbValue => switch (this) {
        ProgressionSuggestionKind.repIncrease => 'rep_increase',
        ProgressionSuggestionKind.loadIncrease => 'load_increase',
      };

  static ProgressionSuggestionKind? fromDbValue(String value) {
    switch (value) {
      case 'rep_increase':
        return ProgressionSuggestionKind.repIncrease;
      case 'load_increase':
        return ProgressionSuggestionKind.loadIncrease;
    }
    return null;
  }
}

/// A change the program wants to make to a loaded lift, waiting on the user.
///
/// Barbell squats and Romanian deadlifts have no harder variation to unlock,
/// so the program cannot simply move them along the way it moves a
/// progression: adding load is the user's call — their gym, their bar, their
/// judgement of the last session. Hitting the target therefore produces a
/// suggestion, shown on the Train tab as "needs approval", and nothing is
/// written until the user approves it.
class ProgressionSuggestion {
  /// Null until the row exists — a freshly computed suggestion has no id.
  final String? id;
  final String exerciseId;
  final String? workoutSessionId;
  final ProgressionSuggestionKind kind;
  final int sets;

  /// Per-set reps now and as proposed.
  final int fromValue;
  final int toValue;

  /// Working weight now and as proposed. Null when the lift has no stored
  /// weight yet (the user never reported a maximum).
  final double? fromWeightKg;
  final double? toWeightKg;

  final DateTime? createdAt;

  const ProgressionSuggestion({
    required this.exerciseId,
    required this.kind,
    required this.sets,
    required this.fromValue,
    required this.toValue,
    this.id,
    this.workoutSessionId,
    this.fromWeightKg,
    this.toWeightKg,
    this.createdAt,
  });

  ProgressionSuggestion copyWith({String? workoutSessionId}) {
    return ProgressionSuggestion(
      id: id,
      exerciseId: exerciseId,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      kind: kind,
      sets: sets,
      fromValue: fromValue,
      toValue: toValue,
      fromWeightKg: fromWeightKg,
      toWeightKg: toWeightKg,
      createdAt: createdAt,
    );
  }

  static ProgressionSuggestion? fromMap(Map<String, dynamic> map) {
    final kind = ProgressionSuggestionKindX.fromDbValue(map['kind'] as String);
    if (kind == null) return null;

    return ProgressionSuggestion(
      id: map['id'] as String,
      exerciseId: map['exercise_id'] as String,
      workoutSessionId: map['workout_session_id'] as String?,
      kind: kind,
      sets: map['target_sets'] as int? ?? 3,
      fromValue: map['from_value'] as int? ?? 0,
      toValue: map['to_value'] as int? ?? 0,
      fromWeightKg: (map['from_weight_kg'] as num?)?.toDouble(),
      toWeightKg: (map['to_weight_kg'] as num?)?.toDouble(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'exercise_id': exerciseId,
        'workout_session_id': workoutSessionId,
        'kind': kind.dbValue,
        'target_sets': sets,
        'from_value': fromValue,
        'to_value': toValue,
        'from_weight_kg': fromWeightKg,
        'to_weight_kg': toWeightKg,
      };
}
