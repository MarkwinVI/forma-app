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

/// Where an exercise stands for a user.
///
/// [skipped] is a cleared-but-unproven step: program setup started the user
/// further up a tree, so the steps behind the starting node were never
/// trained here. They read as cleared everywhere a mastered step does — the
/// path is open past them — but they say "Skipped", and logging the mastery
/// target for one still masters it for real.
enum ExerciseStatus { inactive, active, mastered, skipped }

extension ExerciseStatusX on ExerciseStatus {
  /// Whether the step is behind the user: mastered outright, or skipped at
  /// setup. Everything that asks "is this step done" asks this.
  bool get isCleared =>
      this == ExerciseStatus.mastered || this == ExerciseStatus.skipped;
}

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

  /// True for isometric/hold exercises measured in seconds (L-sits, planks,
  /// hangs, planche leans); false for rep-based movements.
  final bool isTimed;

  /// True for exercises trained by adding weight rather than by climbing a
  /// progression (barbell squat, Romanian deadlift). They have no harder
  /// variation to unlock, so they are never mastered: the program suggests
  /// the next step — more reps, then more load — and the user approves it.
  final bool isLoaded;

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
    this.isTimed = false,
    this.isLoaded = false,
  });
}
