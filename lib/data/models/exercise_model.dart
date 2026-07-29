enum ExerciseCategory {
  verticalPull,
  verticalPush,
  horizontalPull,
  horizontalPush,
  squat,
  hinge,
  core,
  skill,

  /// Isolation, power and carry work from the general exercise library —
  /// real training, but not one of the patterns a tree is built on.
  other,
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
      case ExerciseCategory.other:
        return 'other';
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
      case ExerciseCategory.other:
        return 'Other';
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

/// Name fragments that mean "this is a hold" — the exercise is measured in
/// seconds rather than counted in reps.
const _holdWords = [
  'hang',
  'hold',
  'lean',
  'plank',
  'l-sit',
  'v-sit',
  'lever',
  'handstand',
  'headstand',
];

/// Name fragments that mean "this is counted", and so outrank [_holdWords]:
/// a front lever *row* is reps even though it is held throughout.
const _repWords = [
  'pull-up',
  'pull up',
  'pullup',
  'push-up',
  'push up',
  'pushup',
  'row',
  'dip',
  'raise',
  'curl',
  'squat',
  'deadlift',
  'crunch',
  'sit-up',
  'rollout',
  'extension',
  'press',
];

/// Name fragments that mark a unilateral bodyweight step, which is never one
/// of the open-ended loaded lifts.
const _singleSideWords = ['one-leg', 'one leg', 'single leg', 'single-leg'];

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

  /// True for a movement from the general exercise library rather than a step
  /// of a skill tree. It can be added to a day and logged like anything else,
  /// but it is in no progression: nothing unlocks it and it unlocks nothing.
  final bool isLibrary;

  /// Muscle groups this movement trains, for the picker's filters. Empty for
  /// tree steps, which report the muscles of their movement pattern instead.
  final List<String> muscles;

  /// True for isometric/hold exercises measured in seconds (L-sits, planks,
  /// hangs, planche leans); false for rep-based movements.
  ///
  /// Read from the name rather than stored: the exercise sheet the catalog is
  /// built from has no such column, and the name already says it. A name that
  /// carries a hold word is timed unless it also names a rep — "L-Sit" holds,
  /// "L-Sit Pull-Up" counts.
  bool get isTimed {
    final lower = name.toLowerCase();
    if (_repWords.any(lower.contains)) return false;
    return _holdWords.any(lower.contains);
  }

  /// True for exercises trained by adding weight rather than by climbing a
  /// progression (barbell squat, Romanian deadlift). They have no harder
  /// variation to unlock, so they are never mastered: the program suggests
  /// the next step — more reps, then more load — and the user approves it.
  ///
  /// Read from the name, like [isTimed]. The bodyweight ladders add weight in
  /// named steps ("1.5x Bodyweight") and stay progressions; only the barbell
  /// lifts are open-ended. Single-leg hinges are bodyweight steps of the
  /// squat tree, so they are excluded however they end up being named.
  ///
  /// Every library movement is loaded too, for the same reason the barbell
  /// lifts are: there is no harder variation waiting, so the only way it can
  /// go forward is to ask for more.
  bool get isLoaded {
    if (isLibrary) return true;
    final lower = name.toLowerCase();
    if (_singleSideWords.any(lower.contains)) return false;
    return lower.contains('barbell') || lower.contains('deadlift');
  }

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
    this.isLibrary = false,
    this.muscles = const [],
  });
}
