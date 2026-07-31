import 'package:flutter/material.dart';

import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';

/// Flat per-day exercise plan used by the Program Overview screen and the
/// per-day editor. Each item is either a skill-path progression (the shown
/// exercise advances automatically with the user's level) or a standalone
/// exercise that progresses by load / reps.

enum ProgramDayItemKind { progression, exercise }

const List<String> kProgramRepOptions = ['3–5', '5–8', '8–12'];
const int kProgramDefaultSets = 3;
const String kProgramDefaultReps = '5–8';

const List<String> kProgramMuscleGroups = [
  'Back',
  'Core',
  'Shoulders',
  'Chest',
  'Arms',
  'Legs / glutes',
];
const int kProgramSetsMin = 10;
const int kProgramSetsMax = 20;

class ProgramDayItem {
  final String id;
  final ProgramDayItemKind kind;
  final String name;
  final String? skillCategoryId;
  final String? branchId;
  final String? exerciseId;
  final int sets;
  final String reps;

  const ProgramDayItem({
    required this.id,
    required this.kind,
    required this.name,
    this.skillCategoryId,
    this.branchId,
    this.exerciseId,
    this.sets = kProgramDefaultSets,
    this.reps = kProgramDefaultReps,
  });

  ProgramDayItem copyWith({int? sets, String? reps}) {
    return ProgramDayItem(
      id: id,
      kind: kind,
      name: name,
      skillCategoryId: skillCategoryId,
      branchId: branchId,
      exerciseId: exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }

  /// Movement pattern this item trains, derived from its skill category (for
  /// progressions) or the catalog exercise (for standalone exercises).
  ExerciseCategory get category {
    if (kind == ProgramDayItemKind.progression && skillCategoryId != null) {
      final skillCategory = SkillCategoryCatalog.findById(skillCategoryId!);
      if (skillCategory != null) return skillCategory.track;
    }
    final exercise =
        exerciseId == null ? null : ExerciseCatalog.findById(exerciseId!);
    if (exercise != null) return exercise.category;
    for (final candidate in ExerciseCatalog.all()) {
      if (candidate.name == name) return candidate.category;
    }
    return ExerciseCategory.skill;
  }

  /// The muscle groups this item's work lands on, in the detailed terms the
  /// picker filters by.
  List<String> get muscles {
    final exercise =
        exerciseId == null ? null : ExerciseCatalog.findById(exerciseId!);
    if (exercise != null) return ProgramSessionPlan.musclesForExercise(exercise);
    return ProgramSessionPlan.musclesForCategory(category);
  }

  /// The same, folded to the six groups the weekly volume chart reads.
  List<String> get coarseMuscles =>
      ProgramSessionPlan.coarseMusclesFor(muscles);
}

/// Loads, serializes, and summarizes the per-day plans stored under the
/// `session_items_v1` key of the program's variation rules.
class ProgramSessionPlan {
  ProgramSessionPlan._();

  static const List<ExerciseCategory> coverageOrder = [
    ExerciseCategory.verticalPull,
    ExerciseCategory.horizontalPull,
    ExerciseCategory.verticalPush,
    ExerciseCategory.horizontalPush,
    ExerciseCategory.hinge,
    ExerciseCategory.squat,
    ExerciseCategory.core,
    ExerciseCategory.skill,
  ];

  static List<ProgramDayItem> loadDay({
    required TrainingProgramService service,
    required Map<String, dynamic> sessionItemsConfig,
    required TrainingProgramType programType,
    required TrainingSessionType sessionType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, ExerciseStatus> progressMap,
    List<SkillTrack> skillTracks = const [],
    int? weekday,
  }) {
    final sessionMap = programDayConfig(
      sessionItemsConfig,
      sessionType,
      weekday: weekday,
    );
    if (sessionMap != null) {
      final items = <ProgramDayItem>[];
      for (final component
          in const ['warmup', 'skill', 'strength', 'cooldown']) {
        final rawItems = sessionMap[component];
        if (rawItems is! List) continue;
        for (final rawItem in rawItems.whereType<Map>()) {
          items.add(
            _itemFromMap(Map<String, dynamic>.from(rawItem), progressMap),
          );
        }
      }
      return items;
    }

    // Skills-as-tracks: the default day is the included tracks scheduled for
    // this session type, each on its own branch — no lane juggling.
    if (skillTracks.any((track) => track.included)) {
      final recommendation = service.buildToday(
        progressMap: progressMap,
        programType: programType,
        sessionType: sessionType,
        skillTracks: skillTracks,
      );
      final branchByCategory = {
        for (final track in skillTracks)
          if (track.included) track.skillCategoryId: track.branchId,
      };

      return [
        for (final item in recommendation.items)
          ProgramDayItem(
            id: 'track-${item.sourceSkillCategoryId}-${item.exercise.id}',
            kind: ProgramDayItemKind.progression,
            name: item.exercise.name,
            skillCategoryId: item.sourceSkillCategoryId,
            branchId: branchByCategory[item.sourceSkillCategoryId] ??
                item.exercise.branchId,
            exerciseId: item.exercise.id,
          ),
      ];
    }

    return _defaultDay(
      service: service,
      programType: programType,
      sessionType: sessionType,
      branchSelections: branchSelections,
      progressMap: progressMap,
    );
  }

  static Map<String, dynamic> serializeDay(List<ProgramDayItem> items) {
    return {
      'warmup': const [],
      'skill': const [],
      'strength': [for (final item in items) _itemToMap(item)],
      'cooldown': const [],
    };
  }

  /// Exercises per movement pattern across every training day of the week.
  static Map<ExerciseCategory, List<ProgramDayItem>> weeklyCoverage({
    required TrainingProgramService service,
    required Map<String, dynamic> sessionItemsConfig,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, ExerciseStatus> progressMap,
    List<TrainingSessionType>? weekCycle,
  }) {
    final coverage = <ExerciseCategory, List<ProgramDayItem>>{
      for (final category in coverageOrder) category: <ProgramDayItem>[],
    };

    // With a week cycle, coverage is read off the days actually trained, so
    // days edited on their own count for what they really hold.
    final days = <({TrainingSessionType sessionType, int? weekday})>[
      if (weekCycle == null)
        for (final sessionType in service.trainingDaysForProgramType(
          programType,
        ))
          (sessionType: sessionType, weekday: null)
      else
        for (var i = 0; i < weekCycle.length; i++)
          if (weekCycle[i] != TrainingSessionType.rest)
            (sessionType: weekCycle[i], weekday: i),
    ];

    for (final day in days) {
      final items = loadDay(
        service: service,
        sessionItemsConfig: sessionItemsConfig,
        programType: programType,
        sessionType: day.sessionType,
        branchSelections: branchSelections,
        progressMap: progressMap,
        weekday: day.weekday,
      );
      for (final item in items) {
        // Accessory work has no pattern to cover, so it is simply not part
        // of the balance reading.
        coverage[item.category]?.add(item);
      }
    }

    return coverage;
  }

  /// Weekly training sets per muscle group, spread from each item's movement
  /// pattern across the muscles that pattern loads.
  static Map<String, int> weeklyMuscleSets({
    required TrainingProgramService service,
    required Map<String, dynamic> sessionItemsConfig,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final sets = <String, int>{
      for (final group in kProgramMuscleGroups) group: 0,
    };

    for (final sessionType in service.trainingDaysForProgramType(programType)) {
      final items = loadDay(
        service: service,
        sessionItemsConfig: sessionItemsConfig,
        programType: programType,
        sessionType: sessionType,
        branchSelections: branchSelections,
        progressMap: progressMap,
      );
      for (final item in items) {
        for (final group in item.coarseMuscles) {
          if (sets.containsKey(group)) sets[group] = sets[group]! + item.sets;
        }
      }
    }

    return sets;
  }

  /// Which muscle groups a movement pattern trains. Muscles are a property
  /// of the pattern, not of the individual exercise, so every step of a tree
  /// reports the same groups.
  static List<String> musclesForCategory(ExerciseCategory category) =>
      _musclesForCategory[category] ?? const [];

  /// The groups an exercise trains, in [kExerciseMuscleGroups] terms — what
  /// the picker filters on. Every exercise names its own; the pattern is only
  /// a fallback for one that somehow does not.
  static List<String> musclesForExercise(Exercise exercise) =>
      exercise.muscles.isNotEmpty
          ? exercise.muscles
          : musclesForCategory(exercise.category);

  /// What the exercise is chosen for, as a result row says it. A row has one
  /// line to spend, and the muscles a movement merely touches along the way
  /// are the ones worth losing.
  static List<String> primaryMusclesForExercise(Exercise exercise) =>
      exercise.primaryMuscles.isNotEmpty
          ? exercise.primaryMuscles
          : musclesForCategory(exercise.category);

  /// The same work read in the six groups the weekly volume chart is built
  /// on. Balancing a week is a coarser question than picking an exercise, so
  /// the detailed groups fold up rather than crowding that chart with
  /// seventeen bars. Cardio and Other fold to nothing: they are not volume
  /// for any muscle.
  static List<String> coarseMusclesFor(Iterable<String> detailed) {
    final coarse = <String>[];
    for (final group in detailed) {
      final folded = _coarseByDetailed[group];
      if (folded != null && !coarse.contains(folded)) coarse.add(folded);
    }
    return coarse;
  }

  static const Map<String, String> _coarseByDetailed = {
    'Chest': 'Chest',
    'upper chest': 'Chest',
    'Lats': 'Back',
    'Upper back': 'Back',
    'Middle Back': 'Back',
    'Lower back': 'Back',
    'Traps': 'Back',
    'Shoulders': 'Shoulders',
    'front deltoids': 'Shoulders',
    'rear deltoids': 'Shoulders',
    'rotator cuff': 'Shoulders',
    'Neck': 'Shoulders',
    'Biceps': 'Arms',
    'Triceps': 'Arms',
    'Forearms': 'Arms',
    'Abdominals': 'Core',
    'obliques': 'Core',
    'Hip flexors': 'Core',
    'Glutes': 'Legs / glutes',
    'Quadriceps': 'Legs / glutes',
    'Hamstrings': 'Legs / glutes',
    'Calves': 'Legs / glutes',
    'adductors': 'Legs / glutes',
    'Hip adductors': 'Legs / glutes',
    'Hip abductors': 'Legs / glutes',
    // 'Full body', 'Cardiovascular system' and 'Other' fold to nothing: they
    // are not volume for any one group.
  };

  static const Map<ExerciseCategory, List<String>> _musclesForCategory = {
    ExerciseCategory.verticalPull: ['Back', 'Arms'],
    ExerciseCategory.horizontalPull: ['Back', 'Arms'],
    ExerciseCategory.verticalPush: ['Shoulders', 'Arms'],
    ExerciseCategory.horizontalPush: ['Chest', 'Shoulders', 'Arms'],
    ExerciseCategory.hinge: ['Legs / glutes', 'Back'],
    ExerciseCategory.squat: ['Legs / glutes'],
    ExerciseCategory.core: ['Core'],
    ExerciseCategory.skill: ['Shoulders', 'Core'],
  };

  /// The exercise the user is currently on within a skill-path branch:
  /// the active one, else the first not yet mastered, else the last step.
  static Exercise? currentExerciseForPath({
    required String skillCategoryId,
    required String branchId,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final category = SkillCategoryCatalog.findById(skillCategoryId);
    final exerciseIds = category?.pathFor(branchId) ?? const <String>[];
    final exercises = exerciseIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();

    if (exercises.isEmpty) return null;

    for (final exercise in exercises) {
      if (progressMap[exercise.id] == ExerciseStatus.active) return exercise;
    }
    for (final exercise in exercises) {
      if (!(progressMap[exercise.id]?.isCleared ?? false)) return exercise;
    }
    return exercises.last;
  }

  static ProgramDayItem _itemFromMap(
    Map<String, dynamic> map,
    Map<String, ExerciseStatus> progressMap,
  ) {
    final kind =
        (map['kind'] as String?) == ProgramDayItemKind.progression.name
            ? ProgramDayItemKind.progression
            : ProgramDayItemKind.exercise;
    final rawSets = map['sets'];
    final rawReps = map['reps'];
    final sets = rawSets is int ? rawSets : kProgramDefaultSets;
    final reps = rawReps is String ? rawReps : kProgramDefaultReps;

    if (kind == ProgramDayItemKind.progression) {
      final skillCategoryId = map['skill_category_id'] as String? ?? '';
      final branchId = map['branch_id'] as String? ?? 'main';
      final current = currentExerciseForPath(
        skillCategoryId: skillCategoryId,
        branchId: branchId,
        progressMap: progressMap,
      );
      return ProgramDayItem(
        id: map['id'] as String? ?? newProgramItemId(),
        kind: ProgramDayItemKind.progression,
        name: current?.name ?? (map['name'] as String? ?? 'Exercise'),
        skillCategoryId: skillCategoryId,
        branchId: branchId,
        exerciseId: current?.id ?? map['exercise_id'] as String?,
        sets: sets,
        reps: reps,
      );
    }

    return ProgramDayItem(
      id: map['id'] as String? ?? newProgramItemId(),
      kind: ProgramDayItemKind.exercise,
      name: map['name'] as String? ??
          (map['exercise_id'] as String? ?? 'Exercise'),
      exerciseId: map['exercise_id'] as String?,
      sets: sets,
      reps: reps,
    );
  }

  static Map<String, dynamic> _itemToMap(ProgramDayItem item) {
    return {
      'id': item.id,
      'kind': item.kind.name,
      'name': item.name,
      if (item.skillCategoryId != null)
        'skill_category_id': item.skillCategoryId,
      if (item.branchId != null) 'branch_id': item.branchId,
      if (item.exerciseId != null) 'exercise_id': item.exerciseId,
      'sets': item.sets,
      if (item.kind == ProgramDayItemKind.exercise) 'reps': item.reps,
    };
  }

  static List<ProgramDayItem> _defaultDay({
    required TrainingProgramService service,
    required TrainingProgramType programType,
    required TrainingSessionType sessionType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final resolvedBranches = service.resolveSelectedBranches(branchSelections);
    final skillOption = resolvedBranches[TrainingTrack.skillWork]!;
    final skillExercise =
        service.currentExerciseForOption(skillOption, progressMap);

    final recommendation = service.buildToday(
      progressMap: progressMap,
      programType: programType,
      sessionType: sessionType,
      branchSelections: branchSelections,
    );

    final items = <ProgramDayItem>[
      ProgramDayItem(
        id: 'skill-${sessionType.dbValue}',
        kind: ProgramDayItemKind.progression,
        name: skillExercise?.name ?? skillOption.title,
        skillCategoryId: skillOption.sourceSkillCategoryId,
        branchId: skillOption.trainingPathId,
        exerciseId: skillExercise?.id,
      ),
    ];

    for (final item in recommendation.items) {
      if (item.track == TrainingTrack.skillWork) continue;

      final category = SkillCategoryCatalog.findById(item.sourceSkillCategoryId);
      final selectedOption = resolvedBranches[item.track];
      final selectedBranchId =
          selectedOption?.sourceSkillCategoryId == item.sourceSkillCategoryId
              ? selectedOption?.trainingPathId
              : null;

      if (category != null) {
        items.add(
          ProgramDayItem(
            id: 'strength-${item.track.dbValue}-${item.exercise.id}',
            kind: ProgramDayItemKind.progression,
            name: item.exercise.name,
            skillCategoryId: item.sourceSkillCategoryId,
            branchId: selectedBranchId ?? item.exercise.branchId,
            exerciseId: item.exercise.id,
          ),
        );
      } else {
        items.add(
          ProgramDayItem(
            id: 'strength-${item.track.dbValue}-${item.exercise.id}',
            kind: ProgramDayItemKind.exercise,
            name: item.exercise.name,
            exerciseId: item.exercise.id,
          ),
        );
      }
    }

    return items;
  }
}

String newProgramItemId() =>
    DateTime.now().microsecondsSinceEpoch.toString();

String programDayTitle(TrainingSessionType sessionType) {
  switch (sessionType) {
    case TrainingSessionType.fullBody:
      return 'Full Body';
    case TrainingSessionType.push:
      return 'Push';
    case TrainingSessionType.pull:
      return 'Pull';
    case TrainingSessionType.upper:
      return 'Upper';
    case TrainingSessionType.lower:
      return 'Lower';
    case TrainingSessionType.rest:
      return 'Rest';
  }
}

String programPatternLabel(ExerciseCategory category) {
  switch (category) {
    case ExerciseCategory.verticalPull:
      return 'Vertical pull';
    case ExerciseCategory.horizontalPull:
      return 'Horizontal pull';
    case ExerciseCategory.verticalPush:
      return 'Vertical push';
    case ExerciseCategory.horizontalPush:
      return 'Horizontal push';
    case ExerciseCategory.hinge:
      return 'Hinge';
    case ExerciseCategory.squat:
      return 'Squat';
    case ExerciseCategory.core:
      return 'Core';
    case ExerciseCategory.skill:
      return 'Skill';
    case ExerciseCategory.other:
      return 'Other';
  }
}

/// Lowercase and drop separators so "pullup" matches "Pull-Up" / "Pull Up".
String normalizeExerciseSearch(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Orders the exercise lists people search: browse, adding to a day, and
/// swapping a movement mid-workout.
///
/// Untouched — nothing typed, nothing filtered — the general library leads.
/// The skill trees already have a screen of their own that shows them in the
/// order they are meant to be climbed, so an alphabetical run of tree steps
/// is the least useful thing this list can open on; the library has nowhere
/// else to be seen. Type or filter and that stops: then the list is about
/// what was asked for, best match first.
void sortExerciseResults(
  List<Exercise> exercises, {
  required String query,
  required bool isFiltered,
}) {
  final queryNorm = normalizeExerciseSearch(query);
  final libraryFirst = queryNorm.isEmpty && !isFiltered;

  int rank(Exercise exercise) =>
      queryNorm.isNotEmpty &&
              normalizeExerciseSearch(exercise.name).startsWith(queryNorm)
          ? 0
          : 1;
  int origin(Exercise exercise) => exercise.isLibrary ? 0 : 1;

  exercises.sort((a, b) {
    if (libraryFirst) {
      final byOrigin = origin(a).compareTo(origin(b));
      if (byOrigin != 0) return byOrigin;
    }
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    return a.name.compareTo(b.name);
  });
}

IconData programPatternIcon(ExerciseCategory category) {
  switch (category) {
    case ExerciseCategory.verticalPull:
      return Icons.fitness_center;
    case ExerciseCategory.horizontalPull:
      return Icons.rowing;
    case ExerciseCategory.verticalPush:
      return Icons.upload_rounded;
    case ExerciseCategory.horizontalPush:
      return Icons.open_in_full_rounded;
    case ExerciseCategory.hinge:
      return Icons.swap_vert_rounded;
    case ExerciseCategory.squat:
      return Icons.south_rounded;
    case ExerciseCategory.core:
      return Icons.adjust_rounded;
    case ExerciseCategory.skill:
      return Icons.auto_awesome_rounded;
    case ExerciseCategory.other:
      return Icons.more_horiz_rounded;
  }
}

IconData programMuscleIcon(String group) {
  switch (group) {
    case 'Back':
      return Icons.rowing;
    case 'Core':
      return Icons.adjust_rounded;
    case 'Shoulders':
      return Icons.sports_gymnastics_rounded;
    case 'Chest':
      return Icons.open_in_full_rounded;
    case 'Arms':
      return Icons.fitness_center;
    default:
      return Icons.south_rounded;
  }
}

String programBranchLabel(SkillCategory category, SkillCategoryBranch branch) {
  switch (branch.id) {
    case 'main':
    case 'foundation':
      return 'Foundation';
    case 'one_arm':
      return 'One-arm';
    case 'rings':
      return 'Ring';
    case 'close_grip':
      if (category.id == SkillCategoryCatalog.pullupsId) {
        return 'High Pull';
      }
      return 'Close Grip';
    default:
      return branch.label;
  }
}
