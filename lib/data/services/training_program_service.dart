import '../catalog/exercise_catalog.dart';
import '../models/exercise_model.dart';
import '../models/training_program_model.dart';

class TrainingProgramService {
  DailyTrainingRecommendation buildToday({
    required Map<String, ExerciseStatus> progressMap,
    TrainingProgramType programType = TrainingProgramType.fullBody,
    TrainingSessionType? sessionType,
  }) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        final currentSessionType = sessionType ?? TrainingSessionType.fullBody;
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: currentSessionType == TrainingSessionType.rest
              ? const []
              : _buildItems(_fullBodyBranches, progressMap),
        );
      case TrainingProgramType.pushPull:
        final currentSessionType = sessionType ?? TrainingSessionType.push;
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: _buildPushPullItems(currentSessionType, progressMap),
        );
      case TrainingProgramType.upperLower:
        final currentSessionType = sessionType ?? TrainingSessionType.upper;
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: _buildUpperLowerItems(currentSessionType, progressMap),
        );
    }
  }

  List<TrainingRecommendationItem> _buildPushPullItems(
    TrainingSessionType sessionType,
    Map<String, ExerciseStatus> progressMap,
  ) {
    switch (sessionType) {
      case TrainingSessionType.pull:
        return _buildItems(_pullDayBranches, progressMap);
      case TrainingSessionType.rest:
        return const [];
      case TrainingSessionType.push:
      default:
        return _buildItems(_pushDayBranches, progressMap);
    }
  }

  List<TrainingRecommendationItem> _buildUpperLowerItems(
    TrainingSessionType sessionType,
    Map<String, ExerciseStatus> progressMap,
  ) {
    switch (sessionType) {
      case TrainingSessionType.lower:
        return _buildItems(_lowerDayBranches, progressMap);
      case TrainingSessionType.rest:
        return const [];
      case TrainingSessionType.upper:
      default:
        return _buildItems(_upperDayBranches(progressMap), progressMap);
    }
  }

  List<TrainingRecommendationItem> _buildItems(
    List<_TrainingBranch> branches,
    Map<String, ExerciseStatus> progressMap,
  ) {
    final items = <TrainingRecommendationItem>[];

    for (final branch in branches) {
      final exercise = _pickCurrentExercise(branch, progressMap);
      if (exercise == null) continue;

      items.add(
        TrainingRecommendationItem(
          track: branch.track,
          exercise: exercise,
          status: progressMap[exercise.id] ?? ExerciseStatus.inactive,
          sourceCategory: branch.sourceCategory,
        ),
      );
    }

    return items;
  }

  Exercise? _pickCurrentExercise(
    _TrainingBranch branch,
    Map<String, ExerciseStatus> progressMap,
  ) {
    final exercises = branch.exerciseIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();

    if (exercises.isEmpty) return null;

    for (final exercise in exercises) {
      if (progressMap[exercise.id] == ExerciseStatus.active) {
        return exercise;
      }
    }

    for (final exercise in exercises) {
      if (progressMap[exercise.id] != ExerciseStatus.mastered) {
        return exercise;
      }
    }

    return exercises.last;
  }

  List<_TrainingBranch> _upperDayBranches(
    Map<String, ExerciseStatus> progressMap,
  ) {
    final primaryPush = _preferCategory(
      primary: ExerciseCategory.verticalPush,
      secondary: ExerciseCategory.horizontalPush,
      progressMap: progressMap,
    );
    final primaryPull = _preferCategory(
      primary: ExerciseCategory.verticalPull,
      secondary: ExerciseCategory.horizontalPull,
      progressMap: progressMap,
    );

    final primaryPushBranch = primaryPush == ExerciseCategory.verticalPush
        ? _verticalPushBranch
        : _horizontalPushBranch;
    final secondaryPushBranch = primaryPush == ExerciseCategory.verticalPush
        ? _horizontalPushBranch
        : _verticalPushBranch;
    final primaryPullBranch = primaryPull == ExerciseCategory.verticalPull
        ? _verticalPullBranch
        : _horizontalPullBranch;
    final secondaryPullBranch = primaryPull == ExerciseCategory.verticalPull
        ? _horizontalPullBranch
        : _verticalPullBranch;

    return [
      _skillWorkBranch,
      primaryPushBranch,
      primaryPullBranch,
      secondaryPushBranch,
      secondaryPullBranch,
    ];
  }

  ExerciseCategory _preferCategory({
    required ExerciseCategory primary,
    required ExerciseCategory secondary,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final primaryScore = _categoryScore(primary, progressMap);
    final secondaryScore = _categoryScore(secondary, progressMap);

    if (secondaryScore > primaryScore) {
      return secondary;
    }

    return primary;
  }

  int _categoryScore(
    ExerciseCategory category,
    Map<String, ExerciseStatus> progressMap,
  ) {
    var score = 0;

    for (final exercise in ExerciseCatalog.forCategory(category)) {
      final status = progressMap[exercise.id];
      switch (status) {
        case ExerciseStatus.mastered:
          score += 2;
        case ExerciseStatus.active:
          score += 1;
        case ExerciseStatus.inactive:
        case null:
          break;
      }
    }

    return score;
  }

  static const _skillWorkBranch = _TrainingBranch(
    track: TrainingTrack.skillWork,
    sourceCategory: ExerciseCategory.core,
    exerciseIds: ['hollow_body', 'l_sit_tuck', 'l_sit', 'v_sit'],
  );

  static const _verticalPushBranch = _TrainingBranch(
    track: TrainingTrack.verticalPush,
    sourceCategory: ExerciseCategory.verticalPush,
    exerciseIds: [
      'wall_plank',
      'pike_push_up',
      'elevated_pike_push_up',
      'wall_handstand',
      'freestanding_handstand',
      'wall_hspu',
      'freestanding_hspu',
    ],
  );

  static const _horizontalPushBranch = _TrainingBranch(
    track: TrainingTrack.horizontalPush,
    sourceCategory: ExerciseCategory.horizontalPush,
    exerciseIds: [
      'wall_push_up',
      'incline_push_up',
      'push_up',
      'diamond_push_up',
      'archer_push_up',
      'one_arm_push_up',
    ],
  );

  static const _verticalPullBranch = _TrainingBranch(
    track: TrainingTrack.verticalPull,
    sourceCategory: ExerciseCategory.verticalPull,
    exerciseIds: [
      'dead_hang',
      'scapular_pull',
      'negative_pull_up',
      'pull_up',
      'weighted_pull_up',
      'one_arm_negative',
      'one_arm_pull_up',
    ],
  );

  static const _horizontalPullBranch = _TrainingBranch(
    track: TrainingTrack.horizontalPull,
    sourceCategory: ExerciseCategory.horizontalPull,
    exerciseIds: [
      'table_row',
      'incline_row',
      'australian_pull_up',
      'tuck_front_lever',
      'adv_tuck_front_lever',
      'straddle_front_lever',
      'front_lever',
    ],
  );

  static const _coreBranch = _TrainingBranch(
    track: TrainingTrack.core,
    sourceCategory: ExerciseCategory.core,
    exerciseIds: [
      'plank',
      'ab_wheel_kneeling',
      'dragon_flag_neg',
      'dragon_flag',
      'ab_wheel_standing',
    ],
  );

  static const _squatBranch = _TrainingBranch(
    track: TrainingTrack.squat,
    sourceCategory: ExerciseCategory.squat,
    exerciseIds: [
      'squat',
      'lunge',
      'bulgarian_split_squat',
      'pistol_squat_neg',
      'pistol_squat',
      'dragon_squat',
    ],
  );

  static const _hingeBranch = _TrainingBranch(
    track: TrainingTrack.hinge,
    sourceCategory: ExerciseCategory.hinge,
    exerciseIds: ['single_leg_rdl', 'nordic_curl'],
  );

  static const _calvesBranch = _TrainingBranch(
    track: TrainingTrack.calves,
    sourceCategory: ExerciseCategory.calves,
    exerciseIds: ['calf_raise', 'single_leg_calf_raise'],
  );

  static const List<_TrainingBranch> _fullBodyBranches = [
    _skillWorkBranch,
    _verticalPushBranch,
    _horizontalPushBranch,
    _verticalPullBranch,
    _horizontalPullBranch,
    _coreBranch,
    _squatBranch,
    _hingeBranch,
  ];

  static const List<_TrainingBranch> _pushDayBranches = [
    _skillWorkBranch,
    _horizontalPushBranch,
    _verticalPushBranch,
    _squatBranch,
    _coreBranch,
  ];

  static const List<_TrainingBranch> _pullDayBranches = [
    _skillWorkBranch,
    _horizontalPullBranch,
    _verticalPullBranch,
    _hingeBranch,
    _coreBranch,
  ];

  static const List<_TrainingBranch> _lowerDayBranches = [
    _squatBranch,
    _hingeBranch,
    _coreBranch,
    _calvesBranch,
  ];
}

class _TrainingBranch {
  final TrainingTrack track;
  final ExerciseCategory sourceCategory;
  final List<String> exerciseIds;

  const _TrainingBranch({
    required this.track,
    required this.sourceCategory,
    required this.exerciseIds,
  });
}
