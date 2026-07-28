import 'exercise_model.dart';

class SkillCategoryBranch {
  final String id;
  final String label;
  final int lane;
  final bool isRecommended;

  const SkillCategoryBranch({
    required this.id,
    required this.label,
    required this.lane,
    this.isRecommended = false,
  });
}

class SkillCategoryUnlockRequirement {
  final String exerciseId;
  final String message;
  final String ctaLabel;
  final String targetSkillCategoryId;

  const SkillCategoryUnlockRequirement({
    required this.exerciseId,
    required this.message,
    required this.ctaLabel,
    required this.targetSkillCategoryId,
  });
}

class SkillCategory {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final ExerciseCategory track;
  final String defaultTrainingPathId;
  final List<SkillCategoryBranch> branches;
  final Map<String, List<String>> trainingPaths;
  final SkillCategoryUnlockRequirement? unlockRequirement;

  /// Whether the tree is offered in the Skills tab. A program can train a
  /// category that is not a skill to chase — the loaded leg lifts are one
  /// exercise each, with nothing to browse.
  final bool isBrowsable;

  const SkillCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.track,
    required this.defaultTrainingPathId,
    required this.branches,
    this.trainingPaths = const {},
    this.unlockRequirement,
    this.isBrowsable = true,
  });

  /// Whether this tree is still behind its unlock requirement — the gating
  /// exercise has not been mastered yet. Trees without a requirement are
  /// always open.
  bool isLockedFor(Map<String, ExerciseStatus> progressMap) {
    final requirement = unlockRequirement;
    if (requirement == null) return false;
    return progressMap[requirement.exerciseId] != ExerciseStatus.mastered;
  }

  /// Exercise ids for a branch. The `main` (Foundation) branch of some
  /// categories has no explicit path — every specialised branch shares the
  /// same opening steps instead — so it falls back to the longest common
  /// prefix of all branch paths.
  List<String> pathFor(String branchId) {
    final direct = trainingPaths[branchId];
    if (direct != null) return direct;
    if (branchId != 'main' || trainingPaths.isEmpty) return const [];

    final paths = trainingPaths.values.toList();
    final prefix = <String>[];
    for (var index = 0;; index++) {
      if (paths.any((path) => path.length <= index)) break;
      final exerciseId = paths.first[index];
      if (paths.any((path) => path[index] != exerciseId)) break;
      prefix.add(exerciseId);
    }
    return prefix;
  }
}
