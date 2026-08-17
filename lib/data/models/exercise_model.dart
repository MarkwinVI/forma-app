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
/// There is no "skipped" state: placement (setup answers, or tapping where
/// you are on a path) marks the steps behind the start mastered outright,
/// and a manual jump to a later step leaves the steps in between inactive
/// until the jumped-to exercise is mastered — which then masters them too.
enum ExerciseStatus { inactive, active, mastered }

extension ExerciseStatusX on ExerciseStatus {
  /// Whether the step is behind the user. Everything that asks "is this step
  /// done" asks this.
  bool get isCleared => this == ExerciseStatus.mastered;
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

/// The muscle groups an exercise can name, exactly as the exercise sheet
/// spells them. The app does not rename or merge them: what the sheet says is
/// what the filter offers, so a term that reads wrong is fixed in the sheet
/// rather than translated somewhere you cannot see.
///
/// The one liberty taken is case: the same muscle spelled twice would be two
/// filters, so the sheet's spelling is matched case-insensitively.
///
/// Flat, in the order the filter shows them: [kExerciseMuscleGroupSections]
/// is the same list cut into the sections the filter sheet is laid out in.
final List<String> kExerciseMuscleGroups = List.unmodifiable([
  for (final section in kExerciseMuscleGroupSections) ...section.groups,
]);

/// One section of the muscle-group filter — a heading and the groups under
/// it, in display order.
class ExerciseMuscleGroupSection {
  final String title;
  final List<String> groups;

  const ExerciseMuscleGroupSection(this.title, this.groups);
}

/// The muscle groups as the filter lays them out: upper body, lower body,
/// then the catch-alls that are not a muscle at all.
const List<ExerciseMuscleGroupSection> kExerciseMuscleGroupSections = [
  ExerciseMuscleGroupSection('Upper Body', [
    'Abdominals',
    'Biceps',
    'Chest',
    'Forearms',
    'Lats',
    'Lower Back',
    'Neck',
    'Shoulders',
    'Traps',
    'Triceps',
    'Upper Back',
  ]),
  ExerciseMuscleGroupSection('Lower Body', [
    'Abductors',
    'Adductors',
    'Calves',
    'Glutes',
    'Hamstrings',
    'Quadriceps',
  ]),
  ExerciseMuscleGroupSection('Other', [
    'Cardio',
    'Full Body',
    'Other',
  ]),
];

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

  /// Muscle groups this movement is for, in the sheet's own words — what it
  /// is chosen to train.
  final List<String> primaryMuscles;

  /// Muscle groups it also works along the way. Never repeats a primary one:
  /// a muscle named in both columns of the sheet is a primary muscle.
  final List<String> secondaryMuscles;

  /// Everything the movement touches, primary first. What a filter matches on
  /// and what balance advice is weighed against — both want the whole picture,
  /// where a list row wants only [primaryMuscles].
  List<String> get muscles => [...primaryMuscles, ...secondaryMuscles];

  /// True for a hold, measured in seconds rather than counted in reps. Read
  /// from the sheet's exercise-type column, not guessed from the name.
  final bool isTimed;

  /// True for a movement carrying external load: the workout row takes a kg
  /// field of its own and its history reads "60kg x 8". Read from the same
  /// exercise-type column as [isTimed] — the sheet's four types are reps,
  /// reps x weight, timed and timed x weight, so the two flags are
  /// independent and a loaded hold sets both.
  final bool isWeighted;

  /// True for a movement whose way forward is more load rather than a harder
  /// variation: the legacy one-lift barbell tree, and every library movement,
  /// since the library is outside the progressions. Progression itself treats
  /// these like any other step — this flag only describes the movement.
  final bool isLoaded;

  /// The library movement this step is performed with. Several steps share
  /// one: the seven weighted pull-up rungs are all a weighted pull-up, and
  /// they read their how-to, form checks and demo from it.
  final String libraryId;

  /// How much to load the bar for this step, where the step is a rung of a
  /// weighted ladder. Written as the sheet writes it, in terms of
  /// `user_bodyweight`.
  final String? weightFormula;

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
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.isTimed = false,
    this.isWeighted = false,
    this.isLoaded = false,
    this.libraryId = '',
    this.weightFormula,
  });
}
