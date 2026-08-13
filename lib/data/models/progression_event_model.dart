import '../catalog/exercise_id_migration.dart';

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

  /// The exercise was mastered at a fork whose branches the user's goals
  /// don't decide — the user must pick their next path themselves.
  branchChoice,

  /// A loaded lift's working weight went up (weightFrom → weightTo) and its
  /// reps went back to the bottom of the rep range (valueFrom → valueTo).
  /// Only ever written after the user approves the suggestion.
  loadIncrease,
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
      case ProgressionEventKind.branchChoice:
        return 'branch_choice';
      case ProgressionEventKind.loadIncrease:
        return 'load_increase';
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
      // 'skipped' events predate the removal of the skipped status; they are
      // no longer read, so they fall through to the unknown-kind null below.
      case 'personal_best':
        return ProgressionEventKind.personalBest;
      case 'branch_choice':
        return ProgressionEventKind.branchChoice;
      case 'load_increase':
        return ProgressionEventKind.loadIncrease;
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
  final double? weightFrom;
  final double? weightTo;
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
    this.weightFrom,
    this.weightTo,
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
      exerciseId: ExerciseIdMigration.resolve(map['exercise_id'] as String),
      trackId: map['track_id'] as String?,
      kind: kind,
      valueFrom: map['value_from'] as int?,
      valueTo: map['value_to'] as int?,
      targetSets: map['target_sets'] as int?,
      weightFrom: (map['weight_from'] as num?)?.toDouble(),
      weightTo: (map['weight_to'] as num?)?.toDouble(),
      relatedExerciseId: map['related_exercise_id'] == null
          ? null
          : ExerciseIdMigration.resolve(
              map['related_exercise_id'] as String,
            ),
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
  final double? weightFrom;
  final double? weightTo;
  final String? relatedExerciseId;

  const ProgressionEventInput({
    required this.exerciseId,
    required this.kind,
    this.trackId,
    this.valueFrom,
    this.valueTo,
    this.targetSets,
    this.weightFrom,
    this.weightTo,
    this.relatedExerciseId,
  });
}
