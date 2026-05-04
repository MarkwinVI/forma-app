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
  });
}
