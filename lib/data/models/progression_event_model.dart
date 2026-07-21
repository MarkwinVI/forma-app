enum ProgressionEventKind {
  /// The exercise's incremental target was raised (valueFrom → valueTo).
  targetIncrease,

  /// The exercise reached its mastery target (valueTo, over targetSets sets).
  mastered,

  /// The exercise became the new current move in its path, unlocked by
  /// mastering [ProgressionEvent.relatedExerciseId]. valueTo is its starting
  /// target.
  activated,

  /// A new best single-set value (valueFrom = previous best, valueTo = new).
  personalBest,
}

extension ProgressionEventKindX on ProgressionEventKind {
  String get dbValue {
    switch (this) {
      case ProgressionEventKind.targetIncrease:
        return 'target_increase';
      case ProgressionEventKind.mastered:
        return 'mastered';
      case ProgressionEventKind.activated:
        return 'activated';
      case ProgressionEventKind.personalBest:
        return 'personal_best';
    }
  }

  static ProgressionEventKind? fromDbValue(String value) {
    switch (value) {
      case 'target_increase':
        return ProgressionEventKind.targetIncrease;
      case 'mastered':
        return ProgressionEventKind.mastered;
      case 'activated':
        return ProgressionEventKind.activated;
      case 'personal_best':
        return ProgressionEventKind.personalBest;
    }
    return null;
  }
}

/// A progression change earned by one saved workout — the unit of the
/// "what changed" feed, achievements, and deletion rollback.
class ProgressionEvent {
  final String id;
  final String? workoutSessionId;
  final String exerciseId;
  final String? trackId;
  final ProgressionEventKind kind;
  final int? valueFrom;
  final int? valueTo;
  final int? targetSets;
  final String? relatedExerciseId;
  final DateTime createdAt;
  final DateTime? seenAt;

  const ProgressionEvent({
    required this.id,
    required this.exerciseId,
    required this.kind,
    required this.createdAt,
    this.workoutSessionId,
    this.trackId,
    this.valueFrom,
    this.valueTo,
    this.targetSets,
    this.relatedExerciseId,
    this.seenAt,
  });

  bool get isSeen => seenAt != null;

  static ProgressionEvent? fromMap(Map<String, dynamic> map) {
    final kind = ProgressionEventKindX.fromDbValue(map['kind'] as String);
    if (kind == null) return null;

    return ProgressionEvent(
      id: map['id'] as String,
      workoutSessionId: map['workout_session_id'] as String?,
      exerciseId: map['exercise_id'] as String,
      trackId: map['track_id'] as String?,
      kind: kind,
      valueFrom: map['value_from'] as int?,
      valueTo: map['value_to'] as int?,
      targetSets: map['target_sets'] as int?,
      relatedExerciseId: map['related_exercise_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      seenAt: map['seen_at'] == null
          ? null
          : DateTime.parse(map['seen_at'] as String).toLocal(),
    );
  }
}

/// A progression event before it is written — everything except the
/// database-generated id/created_at and the per-user columns.
class ProgressionEventInput {
  final String exerciseId;
  final String? trackId;
  final ProgressionEventKind kind;
  final int? valueFrom;
  final int? valueTo;
  final int? targetSets;
  final String? relatedExerciseId;

  const ProgressionEventInput({
    required this.exerciseId,
    required this.kind,
    this.trackId,
    this.valueFrom,
    this.valueTo,
    this.targetSets,
    this.relatedExerciseId,
  });
}
