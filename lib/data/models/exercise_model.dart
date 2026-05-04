enum ExerciseCategory {
  verticalPull,
  verticalPush,
  horizontalPull,
  horizontalPush,
  squat,
  hinge,
  core,
  skill,
}

extension ExerciseCategoryX on ExerciseCategory {
  String get id {
    switch (this) {
      case ExerciseCategory.verticalPull:
        return 'vertical_pull';
      case ExerciseCategory.verticalPush:
        return 'vertical_push';
      case ExerciseCategory.horizontalPull:
        return 'horizontal_pull';
      case ExerciseCategory.horizontalPush:
        return 'horizontal_push';
      case ExerciseCategory.squat:
        return 'squat';
      case ExerciseCategory.hinge:
        return 'hinge';
      case ExerciseCategory.core:
        return 'core';
      case ExerciseCategory.skill:
        return 'skill';
    }
  }

  String get label {
    switch (this) {
      case ExerciseCategory.verticalPull:
        return 'Vertical Pull';
      case ExerciseCategory.verticalPush:
        return 'Vertical Push';
      case ExerciseCategory.horizontalPull:
        return 'Horizontal Pull';
      case ExerciseCategory.horizontalPush:
        return 'Horizontal Push';
      case ExerciseCategory.squat:
        return 'Squat';
      case ExerciseCategory.hinge:
        return 'Hinge';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.skill:
        return 'Skill';
    }
  }
}

enum ExerciseStatus { inactive, active, mastered }

enum ExerciseProgramSection {
  warmup,
  skillWork,
  mainExercises,
  coolDown,
}

extension ExerciseProgramSectionX on ExerciseProgramSection {
  String get label {
    switch (this) {
      case ExerciseProgramSection.warmup:
        return 'Warmup';
      case ExerciseProgramSection.skillWork:
        return 'Skill work';
      case ExerciseProgramSection.mainExercises:
        return 'Main exercises';
      case ExerciseProgramSection.coolDown:
        return 'Cool down';
    }
  }
}

class Exercise {
  final String id;
  final ExerciseCategory category;
  final String skillCategoryId;
  final String branchId;
  final String name;
  final String description;
  final int difficulty; // 1–5
  final int treeOrder; // exercises with the same value appear on the same row
  final List<String> prerequisiteIds;
  final ExerciseProgramSection programSection;
  final String? imageUrl;

  const Exercise({
    required this.id,
    required this.category,
    this.skillCategoryId = '',
    this.branchId = 'main',
    required this.name,
    required this.description,
    required this.difficulty,
    required this.treeOrder,
    this.prerequisiteIds = const [],
    this.programSection = ExerciseProgramSection.mainExercises,
    this.imageUrl,
  });
}
