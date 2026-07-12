import '../catalog/exercise_catalog.dart';
import '../catalog/skill_category_catalog.dart';
import '../models/exercise_model.dart';
import '../models/skill_category_model.dart';
import '../models/training_program_model.dart';

class TrainingBranchOption {
  final String id;
  final TrainingTrack track;
  final ExerciseCategory sourceCategory;
  final String sourceSkillCategoryId;
  final String trainingPathId;
  final String title;
  final String subtitle;
  final String rationale;
  final List<String> exerciseIds;

  const TrainingBranchOption({
    required this.id,
    required this.track,
    required this.sourceCategory,
    required this.sourceSkillCategoryId,
    required this.trainingPathId,
    required this.title,
    required this.subtitle,
    required this.rationale,
    required this.exerciseIds,
  });
}

class TrainingProgramService {
  static final Map<TrainingTrack, String> _defaultBranchIds = {
    TrainingTrack.skillWork: '${SkillCategoryCatalog.coreId}:l_sit',
    TrainingTrack.verticalPush:
        '${SkillCategoryCatalog.handstandPushupsId}:main',
    TrainingTrack.horizontalPush: '${SkillCategoryCatalog.pushupsId}:one_arm',
    TrainingTrack.verticalPull: '${SkillCategoryCatalog.pullupsId}:weighted',
    TrainingTrack.horizontalPull: '${SkillCategoryCatalog.rowsId}:front_lever',
    TrainingTrack.core: '${SkillCategoryCatalog.coreId}:ab_wheel',
    TrainingTrack.squat: '${SkillCategoryCatalog.squatId}:pistol',
    TrainingTrack.hinge: 'hinge:posterior_chain',
  };

  DailyTrainingRecommendation buildToday({
    required Map<String, ExerciseStatus> progressMap,
    TrainingProgramType programType = TrainingProgramType.fullBody,
    TrainingSessionType? sessionType,
    Map<TrainingTrack, String> branchSelections = const {},
    Map<String, dynamic> sessionItemsConfig = const {},
  }) {
    final selectedBranches = resolveSelectedBranches(branchSelections);

    switch (programType) {
      case TrainingProgramType.fullBody:
        final currentSessionType = sessionType ?? TrainingSessionType.fullBody;
        final configuredItems = currentSessionType == TrainingSessionType.rest
            ? const <TrainingRecommendationItem>[]
            : _buildConfiguredItems(
                sessionType: currentSessionType,
                progressMap: progressMap,
                sessionItemsConfig: sessionItemsConfig,
              );
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: configuredItems ??
              (currentSessionType == TrainingSessionType.rest
                  ? const []
                  : _buildItems(
                      _fullBodyBranches(selectedBranches),
                      progressMap,
                    )),
        );
      case TrainingProgramType.pushPull:
        final currentSessionType = sessionType ?? TrainingSessionType.push;
        final configuredItems = currentSessionType == TrainingSessionType.rest
            ? const <TrainingRecommendationItem>[]
            : _buildConfiguredItems(
                sessionType: currentSessionType,
                progressMap: progressMap,
                sessionItemsConfig: sessionItemsConfig,
              );
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: configuredItems ??
              _buildPushPullItems(
                currentSessionType,
                progressMap,
                selectedBranches,
              ),
        );
      case TrainingProgramType.upperLower:
        final currentSessionType = sessionType ?? TrainingSessionType.upper;
        final configuredItems = currentSessionType == TrainingSessionType.rest
            ? const <TrainingRecommendationItem>[]
            : _buildConfiguredItems(
                sessionType: currentSessionType,
                progressMap: progressMap,
                sessionItemsConfig: sessionItemsConfig,
              );
        return DailyTrainingRecommendation(
          programType: programType,
          sessionType: currentSessionType,
          sessionLabel: currentSessionType.label,
          isRestDay: currentSessionType == TrainingSessionType.rest,
          items: configuredItems ??
              _buildUpperLowerItems(
                currentSessionType,
                progressMap,
                selectedBranches,
              ),
        );
    }
  }

  List<TrainingRecommendationItem>? _buildConfiguredItems({
    required TrainingSessionType sessionType,
    required Map<String, ExerciseStatus> progressMap,
    required Map<String, dynamic> sessionItemsConfig,
  }) {
    final rawSession = sessionItemsConfig[sessionType.dbValue];
    if (rawSession is! Map) return null;

    final sessionMap = Map<String, dynamic>.from(rawSession);
    final items = <TrainingRecommendationItem>[];

    for (final component in const ['warmup', 'skill', 'strength', 'cooldown']) {
      final rawItems = sessionMap[component];
      if (rawItems is! List) continue;

      for (final rawItem in rawItems.whereType<Map>()) {
        final configuredItem = _configuredRecommendationItem(
          component: component,
          rawItem: Map<String, dynamic>.from(rawItem),
          progressMap: progressMap,
        );
        if (configuredItem != null) {
          items.add(configuredItem);
        }
      }
    }

    return items;
  }

  TrainingRecommendationItem? _configuredRecommendationItem({
    required String component,
    required Map<String, dynamic> rawItem,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final kind = rawItem['kind'] as String? ?? 'exercise';
    final exercise = kind == 'progression'
        ? _exerciseForConfiguredProgression(rawItem, progressMap, component)
        : _exerciseForConfiguredSingle(rawItem, component);
    if (exercise == null) return null;

    final sourceCategory = _sourceCategoryForConfiguredItem(
      component: component,
      rawItem: rawItem,
      exercise: exercise,
    );

    return TrainingRecommendationItem(
      track: _trackForConfiguredItem(
        component: component,
        sourceCategory: sourceCategory,
      ),
      exercise: exercise,
      status: progressMap[exercise.id] ?? ExerciseStatus.inactive,
      sourceCategory: sourceCategory,
      sourceSkillCategoryId: (rawItem['skill_category_id'] as String?) ??
          ExerciseCatalog.skillCategoryIdForExercise(exercise),
    );
  }

  Exercise? _exerciseForConfiguredProgression(
    Map<String, dynamic> rawItem,
    Map<String, ExerciseStatus> progressMap,
    String component,
  ) {
    final skillCategoryId = rawItem['skill_category_id'] as String?;
    final branchId = rawItem['branch_id'] as String?;
    if (skillCategoryId == null || branchId == null) return null;

    final category = SkillCategoryCatalog.findById(skillCategoryId);
    final path = category?.pathFor(branchId) ?? const <String>[];
    final current = _pickCurrentExercise(
      _TrainingBranch(
        track: _trackForConfiguredItem(
          component: component,
          sourceCategory: category?.track ?? ExerciseCategory.skill,
        ),
        sourceCategory: category?.track ?? ExerciseCategory.skill,
        sourceSkillCategoryId: skillCategoryId,
        exerciseIds: path,
      ),
      progressMap,
    );
    if (current == null) return null;

    return _copyExercise(
      current,
      programSection: _programSectionForComponent(component),
    );
  }

  Exercise? _exerciseForConfiguredSingle(
    Map<String, dynamic> rawItem,
    String component,
  ) {
    final exerciseId = rawItem['exercise_id'] as String?;
    final name = rawItem['name'] as String? ?? 'Exercise';
    final existing =
        exerciseId == null ? null : ExerciseCatalog.findById(exerciseId);

    if (existing != null) {
      return _copyExercise(
        existing,
        programSection: _programSectionForComponent(component),
      );
    }

    return Exercise(
      id: exerciseId ??
          "custom_${component}_${name.toLowerCase().replaceAll(' ', '_')}",
      category: ExerciseCategory.skill,
      skillCategoryId: '',
      branchId: 'main',
      name: name,
      description:
          'Custom ${component.replaceAll('cooldown', 'cool-down')} item.',
      difficulty: 1,
      treeOrder: 0,
      programSection: _programSectionForComponent(component),
    );
  }

  ExerciseCategory _sourceCategoryForConfiguredItem({
    required String component,
    required Map<String, dynamic> rawItem,
    required Exercise exercise,
  }) {
    final skillCategoryId = rawItem['skill_category_id'] as String?;
    final category = skillCategoryId == null
        ? null
        : SkillCategoryCatalog.findById(skillCategoryId);
    if (category != null) {
      return category.track;
    }
    if (component == 'warmup' || component == 'cooldown') {
      return ExerciseCategory.skill;
    }
    return exercise.category;
  }

  TrainingTrack _trackForConfiguredItem({
    required String component,
    required ExerciseCategory sourceCategory,
  }) {
    if (component == 'skill' ||
        component == 'warmup' ||
        component == 'cooldown') {
      return TrainingTrack.skillWork;
    }

    switch (sourceCategory) {
      case ExerciseCategory.verticalPush:
        return TrainingTrack.verticalPush;
      case ExerciseCategory.horizontalPush:
        return TrainingTrack.horizontalPush;
      case ExerciseCategory.verticalPull:
        return TrainingTrack.verticalPull;
      case ExerciseCategory.horizontalPull:
        return TrainingTrack.horizontalPull;
      case ExerciseCategory.core:
        return TrainingTrack.core;
      case ExerciseCategory.squat:
        return TrainingTrack.squat;
      case ExerciseCategory.hinge:
        return TrainingTrack.hinge;
      case ExerciseCategory.skill:
        return TrainingTrack.skillWork;
    }
  }

  ExerciseProgramSection _programSectionForComponent(String component) {
    switch (component) {
      case 'warmup':
        return ExerciseProgramSection.warmup;
      case 'skill':
        return ExerciseProgramSection.skillWork;
      case 'cooldown':
        return ExerciseProgramSection.coolDown;
      case 'strength':
      default:
        return ExerciseProgramSection.mainExercises;
    }
  }

  Exercise _copyExercise(
    Exercise exercise, {
    required ExerciseProgramSection programSection,
  }) {
    return Exercise(
      id: exercise.id,
      category: exercise.category,
      skillCategoryId: exercise.skillCategoryId,
      branchId: exercise.branchId,
      name: exercise.name,
      description: exercise.description,
      difficulty: exercise.difficulty,
      treeOrder: exercise.treeOrder,
      prerequisiteIds: exercise.prerequisiteIds,
      programSection: programSection,
      imageUrl: exercise.imageUrl,
    );
  }

  List<TrainingSessionType> scheduleCycleFor({
    required TrainingProgramType programType,
    String? scheduleVariant,
  }) {
    switch (scheduleVariant) {
      case 'push_rest_pull_rest_push_pull_rest':
        return const [
          TrainingSessionType.push,
          TrainingSessionType.rest,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
        ];
      case 'upper_rest_lower_rest_upper_lower_rest':
        return const [
          TrainingSessionType.upper,
          TrainingSessionType.rest,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
          TrainingSessionType.upper,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
        ];
      case 'full_body_3x':
        return const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ];
    }

    switch (programType) {
      case TrainingProgramType.pushPull:
        return const [
          TrainingSessionType.push,
          TrainingSessionType.rest,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.upperLower:
        return const [
          TrainingSessionType.upper,
          TrainingSessionType.rest,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
          TrainingSessionType.upper,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.fullBody:
        return const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ];
    }
  }

  List<TrainingSessionType> trainingDaysForProgramType(
    TrainingProgramType programType,
  ) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return const [TrainingSessionType.fullBody];
      case TrainingProgramType.pushPull:
        return const [TrainingSessionType.push, TrainingSessionType.pull];
      case TrainingProgramType.upperLower:
        return const [TrainingSessionType.upper, TrainingSessionType.lower];
    }
  }

  List<TrainingTrack> editableTracksForProgramType(
    TrainingProgramType programType,
  ) {
    switch (programType) {
      case TrainingProgramType.fullBody:
        return const [
          TrainingTrack.skillWork,
          TrainingTrack.verticalPush,
          TrainingTrack.horizontalPush,
          TrainingTrack.verticalPull,
          TrainingTrack.horizontalPull,
          TrainingTrack.core,
          TrainingTrack.squat,
          TrainingTrack.hinge,
        ];
      case TrainingProgramType.pushPull:
        return const [
          TrainingTrack.skillWork,
          TrainingTrack.horizontalPush,
          TrainingTrack.verticalPush,
          TrainingTrack.squat,
          TrainingTrack.core,
          TrainingTrack.horizontalPull,
          TrainingTrack.verticalPull,
          TrainingTrack.hinge,
        ];
      case TrainingProgramType.upperLower:
        return const [
          TrainingTrack.skillWork,
          TrainingTrack.verticalPush,
          TrainingTrack.horizontalPush,
          TrainingTrack.verticalPull,
          TrainingTrack.horizontalPull,
          TrainingTrack.squat,
          TrainingTrack.hinge,
          TrainingTrack.core,
        ];
    }
  }

  Map<TrainingTrack, String> defaultBranchSelections() =>
      Map<TrainingTrack, String>.from(_defaultBranchIds);

  List<TrainingBranchOption> branchOptionsForTrack(TrainingTrack track) {
    switch (track) {
      case TrainingTrack.skillWork:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'l_sit',
            rationale:
                'Use your opening slot to build compression and straight-arm control before heavier work.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'leg_raises',
            rationale:
                'Bias hanging control and trunk stiffness if you want a more dynamic skill opener.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'ab_wheel',
            rationale:
                'Turn the opener into a tension-focused skill slot when rollout strength is the main limiter.',
          ),
        ];
      case TrainingTrack.verticalPush:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.handstandPushups,
            pathId: 'main',
            rationale:
                'Best when your main goal is overhead pressing strength and handstand-specific control.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.dips,
            pathId: 'weighted',
            rationale:
                'Best when you want a loadable vertical press that can chase heavier strength milestones.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.dips,
            pathId: 'rings',
            rationale:
                'Best when shoulder stability and ring support strength matter more than absolute load.',
          ),
        ];
      case TrainingTrack.horizontalPush:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pushups,
            pathId: 'one_arm',
            rationale:
                'Keep the horizontal press lane on unilateral strength and body-tension progressions.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pushups,
            pathId: 'rings',
            rationale:
                'Use this when instability and deeper pressing range are more useful than pure leverage difficulty.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pushups,
            pathId: 'planche',
            rationale:
                'Best when you want your push volume to feed directly into planche-style lean and protraction strength.',
          ),
        ];
      case TrainingTrack.verticalPull:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pullups,
            pathId: 'weighted',
            rationale:
                'Use the vertical pull slot for pure strength when added load is the clearest next milestone.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pullups,
            pathId: 'close_grip',
            rationale:
                'Choose this when top-end range, sternum height, and stronger scapular depression are the priority.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pullups,
            pathId: 'one_arm',
            rationale:
                'Choose this when unilateral pulling strength is the long-term goal driving the whole branch.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.pullups,
            pathId: 'l_sit',
            rationale:
                'Blend pull strength with compression if you want your vertical pull lane to stay skill-heavy.',
          ),
        ];
      case TrainingTrack.horizontalPull:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.rows,
            pathId: 'front_lever',
            rationale:
                'Best when row work should feed front lever body-line strength and harder torso angles.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.rows,
            pathId: 'weighted',
            rationale:
                'Best when you want a clean, loadable horizontal pull progression with obvious strength checkpoints.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.rows,
            pathId: 'one_arm',
            rationale:
                'Use this when unilateral back strength and anti-rotation control are the real target.',
          ),
        ];
      case TrainingTrack.core:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'ab_wheel',
            rationale:
                'Default core lane for trunk strength that supports almost every other movement pattern.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'leg_raises',
            rationale:
                'Best when you want your core work to bias hanging control and lower-ab compression.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.core,
            pathId: 'l_sit',
            rationale:
                'Best when you want the core lane to double as a visible skill goal instead of pure accessory work.',
          ),
        ];
      case TrainingTrack.squat:
        return [
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.squat,
            pathId: 'pistol',
            rationale:
                'Use the squat lane for deep single-leg strength and balance that carries well to full-body sessions.',
          ),
          _branchOptionFromCategory(
            track: track,
            category: SkillCategoryCatalog.squat,
            pathId: 'shrimp',
            rationale:
                'Best when you want knee-flexion strength and a more closed-chain single-leg pattern.',
          ),
        ];
      case TrainingTrack.hinge:
        return const [
          TrainingBranchOption(
            id: 'hinge:posterior_chain',
            track: TrainingTrack.hinge,
            sourceCategory: ExerciseCategory.hinge,
            sourceSkillCategoryId: 'hinge',
            trainingPathId: 'posterior_chain',
            title: 'Posterior Chain',
            subtitle: 'Hinge',
            rationale:
                'This slot stays fixed for now so the program always keeps a simple hamstring and hinge balance.',
            exerciseIds: ['single_leg_rdl', 'nordic_curl'],
          ),
        ];
    }
  }

  Map<TrainingTrack, TrainingBranchOption> resolveSelectedBranches(
    Map<TrainingTrack, String> branchSelections,
  ) {
    final resolved = <TrainingTrack, TrainingBranchOption>{};

    for (final track in TrainingTrack.values) {
      final options = branchOptionsForTrack(track);
      final savedId = branchSelections[track];
      final defaultId = _defaultBranchIds[track];

      resolved[track] = options.firstWhere(
        (option) => option.id == savedId,
        orElse: () => options.firstWhere(
          (option) => option.id == defaultId,
          orElse: () => options.first,
        ),
      );
    }

    return resolved;
  }

  Exercise? currentExerciseForOption(
    TrainingBranchOption option,
    Map<String, ExerciseStatus> progressMap,
  ) {
    return _pickCurrentExercise(
      _TrainingBranch(
        track: option.track,
        sourceCategory: option.sourceCategory,
        sourceSkillCategoryId: option.sourceSkillCategoryId,
        exerciseIds: option.exerciseIds,
      ),
      progressMap,
    );
  }

  List<TrainingRecommendationItem> _buildPushPullItems(
    TrainingSessionType sessionType,
    Map<String, ExerciseStatus> progressMap,
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    switch (sessionType) {
      case TrainingSessionType.pull:
        return _buildItems(_pullDayBranches(selectedBranches), progressMap);
      case TrainingSessionType.rest:
        return const [];
      case TrainingSessionType.push:
      default:
        return _buildItems(_pushDayBranches(selectedBranches), progressMap);
    }
  }

  List<TrainingRecommendationItem> _buildUpperLowerItems(
    TrainingSessionType sessionType,
    Map<String, ExerciseStatus> progressMap,
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    switch (sessionType) {
      case TrainingSessionType.lower:
        return _buildItems(_lowerDayBranches(selectedBranches), progressMap);
      case TrainingSessionType.rest:
        return const [];
      case TrainingSessionType.upper:
      default:
        return _buildItems(
          _upperDayBranches(progressMap, selectedBranches),
          progressMap,
        );
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
          sourceSkillCategoryId: branch.sourceSkillCategoryId.isEmpty
              ? branch.sourceCategory.id
              : branch.sourceSkillCategoryId,
          progressionExerciseIds: branch.exerciseIds,
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
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
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

    final verticalPushBranch =
        _branchFromOption(selectedBranches[TrainingTrack.verticalPush]!);
    final horizontalPushBranch =
        _branchFromOption(selectedBranches[TrainingTrack.horizontalPush]!);
    final verticalPullBranch =
        _branchFromOption(selectedBranches[TrainingTrack.verticalPull]!);
    final horizontalPullBranch =
        _branchFromOption(selectedBranches[TrainingTrack.horizontalPull]!);

    final primaryPushBranch = primaryPush == ExerciseCategory.verticalPush
        ? verticalPushBranch
        : horizontalPushBranch;
    final secondaryPushBranch = primaryPush == ExerciseCategory.verticalPush
        ? horizontalPushBranch
        : verticalPushBranch;
    final primaryPullBranch = primaryPull == ExerciseCategory.verticalPull
        ? verticalPullBranch
        : horizontalPullBranch;
    final secondaryPullBranch = primaryPull == ExerciseCategory.verticalPull
        ? horizontalPullBranch
        : verticalPullBranch;

    return [
      _branchFromOption(selectedBranches[TrainingTrack.skillWork]!),
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

  List<_TrainingBranch> _fullBodyBranches(
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    return [
      _branchFromOption(selectedBranches[TrainingTrack.skillWork]!),
      _branchFromOption(selectedBranches[TrainingTrack.verticalPush]!),
      _branchFromOption(selectedBranches[TrainingTrack.horizontalPush]!),
      _branchFromOption(selectedBranches[TrainingTrack.verticalPull]!),
      _branchFromOption(selectedBranches[TrainingTrack.horizontalPull]!),
      _branchFromOption(selectedBranches[TrainingTrack.core]!),
      _branchFromOption(selectedBranches[TrainingTrack.squat]!),
      _branchFromOption(selectedBranches[TrainingTrack.hinge]!),
    ];
  }

  List<_TrainingBranch> _pushDayBranches(
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    return [
      _branchFromOption(selectedBranches[TrainingTrack.skillWork]!),
      _branchFromOption(selectedBranches[TrainingTrack.horizontalPush]!),
      _branchFromOption(selectedBranches[TrainingTrack.verticalPush]!),
      _branchFromOption(selectedBranches[TrainingTrack.squat]!),
      _branchFromOption(selectedBranches[TrainingTrack.core]!),
    ];
  }

  List<_TrainingBranch> _pullDayBranches(
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    return [
      _branchFromOption(selectedBranches[TrainingTrack.skillWork]!),
      _branchFromOption(selectedBranches[TrainingTrack.horizontalPull]!),
      _branchFromOption(selectedBranches[TrainingTrack.verticalPull]!),
      _branchFromOption(selectedBranches[TrainingTrack.hinge]!),
      _branchFromOption(selectedBranches[TrainingTrack.core]!),
    ];
  }

  List<_TrainingBranch> _lowerDayBranches(
    Map<TrainingTrack, TrainingBranchOption> selectedBranches,
  ) {
    return [
      _branchFromOption(selectedBranches[TrainingTrack.squat]!),
      _branchFromOption(selectedBranches[TrainingTrack.hinge]!),
      _branchFromOption(selectedBranches[TrainingTrack.core]!),
    ];
  }

  _TrainingBranch _branchFromOption(TrainingBranchOption option) {
    return _TrainingBranch(
      track: option.track,
      sourceCategory: option.sourceCategory,
      sourceSkillCategoryId: option.sourceSkillCategoryId,
      exerciseIds: option.exerciseIds,
    );
  }

  TrainingBranchOption _branchOptionFromCategory({
    required TrainingTrack track,
    required SkillCategory category,
    required String pathId,
    required String rationale,
  }) {
    final exercises = category.trainingPaths[pathId] ?? const <String>[];

    return TrainingBranchOption(
      id: '${category.id}:$pathId',
      track: track,
      sourceCategory: category.track,
      sourceSkillCategoryId: category.id,
      trainingPathId: pathId,
      title: _branchTitle(category, pathId),
      subtitle: category.subtitle,
      rationale: rationale,
      exerciseIds: exercises,
    );
  }

  String _branchTitle(SkillCategory category, String pathId) {
    final label = _pathLabel(category, pathId);
    if (label.toLowerCase() == 'main') {
      return category.title;
    }
    return '$label ${category.title}';
  }

  String _pathLabel(SkillCategory category, String pathId) {
    for (final branch in category.branches) {
      if (branch.id == pathId) return branch.label;
    }

    return pathId
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _TrainingBranch {
  final TrainingTrack track;
  final ExerciseCategory sourceCategory;
  final String sourceSkillCategoryId;
  final List<String> exerciseIds;

  const _TrainingBranch({
    required this.track,
    required this.sourceCategory,
    this.sourceSkillCategoryId = '',
    required this.exerciseIds,
  });
}
