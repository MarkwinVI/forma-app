class ExerciseSet {
  final int reps;
  final int durationSeconds;
  final double weightKg;
  final String? notes;

  const ExerciseSet({
    this.reps = 0,
    this.durationSeconds = 0,
    this.weightKg = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        if (reps > 0) 'reps': reps,
        if (durationSeconds > 0) 'duration_seconds': durationSeconds,
        'weight_kg': weightKg,
        if (notes != null) 'notes': notes,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        reps: json['reps'] as int? ?? 0,
        durationSeconds: json['duration_seconds'] as int? ?? 0,
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );
}

class ExerciseLog {
  final String id;
  final String exerciseId;
  final DateTime loggedAt;
  final List<ExerciseSet> sets;
  final int totalReps;
  final double totalVolumeKg;
  final String? notes;

  const ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.loggedAt,
    required this.sets,
    required this.totalReps,
    required this.totalVolumeKg,
    this.notes,
  });

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    final rawSets = map['sets'] as List<dynamic>? ?? [];
    final sets = rawSets
        .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
        .toList();
    return ExerciseLog(
      id: map['id'] as String,
      exerciseId: map['exercise_id'] as String,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      sets: sets,
      totalReps: map['total_reps'] as int? ?? 0,
      totalVolumeKg: (map['total_volume_kg'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'exercise_id': exerciseId,
        'logged_at': loggedAt.toIso8601String(),
        'sets': sets.map((s) => s.toJson()).toList(),
        'total_reps': totalReps,
        'total_volume_kg': totalVolumeKg,
        if (notes != null) 'notes': notes,
      };
}
