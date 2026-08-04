/// One skill tree the user is running as an independent progression track:
/// its active branch and whether it is currently included in the program.
/// included = false means paused — the track leaves future workouts but its
/// branch (here) and exercise statuses/targets (user_exercise_progress) are
/// retained, so resuming continues where it left off.
class SkillTrack {
  final String skillCategoryId;
  final String branchId;
  final bool included;
  final DateTime updatedAt;

  const SkillTrack({
    required this.skillCategoryId,
    required this.branchId,
    required this.included,
    required this.updatedAt,
  });

  factory SkillTrack.fromMap(Map<String, dynamic> map) {
    return SkillTrack(
      skillCategoryId: map['skill_category_id'] as String,
      branchId: map['branch_id'] as String,
      included: map['included'] as bool? ?? true,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SkillTrack copyWith({String? branchId, bool? included}) {
    return SkillTrack(
      skillCategoryId: skillCategoryId,
      branchId: branchId ?? this.branchId,
      included: included ?? this.included,
      updatedAt: DateTime.now(),
    );
  }
}
