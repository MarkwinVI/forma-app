import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/training_program_service.dart';

enum HomeSkillMomentum { stalled, steady, improving }

class HomeDashboardMetrics {
  final HomeTodaySummary today;
  final HomeWeekStripData weekStrip;
  final JourneySnapshotData journeySnapshot;
  final List<ActiveSkillPathData> activeSkillPaths;

  const HomeDashboardMetrics({
    required this.today,
    required this.weekStrip,
    required this.journeySnapshot,
    required this.activeSkillPaths,
  });
}

class HomeTodaySummary {
  final String sessionTitle;
  final String ctaLabel;
  final bool isRestDay;
  final int exerciseCount;
  final int estimatedDurationMinutes;
  final List<String> focusTags;
  final List<HomeTodayMixSegment> mixSegments;
  final String supportingText;

  const HomeTodaySummary({
    required this.sessionTitle,
    required this.ctaLabel,
    required this.isRestDay,
    required this.exerciseCount,
    required this.estimatedDurationMinutes,
    required this.focusTags,
    required this.mixSegments,
    required this.supportingText,
  });
}

class HomeTodayMixSegment {
  final String label;
  final int percentage;

  const HomeTodayMixSegment({
    required this.label,
    required this.percentage,
  });
}

class HomeWeekStripData {
  final List<HomeWeekStripDay> days;
  final int completedSessions;
  final int totalSessions;
  final String supportingText;

  const HomeWeekStripData({
    required this.days,
    required this.completedSessions,
    required this.totalSessions,
    required this.supportingText,
  });
}

class HomeWeekStripDay {
  final DateTime date;
  final TrainingSessionType sessionType;
  final bool isCurrent;
  final bool isCompleted;

  const HomeWeekStripDay({
    required this.date,
    required this.sessionType,
    required this.isCurrent,
    required this.isCompleted,
  });

  bool get isRestDay => sessionType == TrainingSessionType.rest;
}

class JourneySnapshotData {
  final int totalLevel;
  final int maxLevel;
  final double averageSkillLevel;
  final String tierLabel;
  final int unlockedSkillTrees;
  final int totalSkillTrees;

  const JourneySnapshotData({
    required this.totalLevel,
    required this.maxLevel,
    required this.averageSkillLevel,
    required this.tierLabel,
    required this.unlockedSkillTrees,
    required this.totalSkillTrees,
  });
}

class ActiveSkillPathData {
  final TrainingTrack track;
  final String skillCategoryId;
  final String branchId;
  final String trackLabel;
  final String skillTitle;
  final String currentExerciseName;
  final int level;
  final int progressPercent;
  final HomeSkillMomentum momentum;
  final String note;

  const ActiveSkillPathData({
    required this.track,
    required this.skillCategoryId,
    required this.branchId,
    required this.trackLabel,
    required this.skillTitle,
    required this.currentExerciseName,
    required this.level,
    required this.progressPercent,
    required this.momentum,
    required this.note,
  });
}

class HomeDashboardMetricsCalculator {
  static const double _activeStepCredit = 0.6;
  static const Duration _recentStatusPromotionWindow = Duration(days: 28);

  static HomeDashboardMetrics build({
    required DailyTrainingRecommendation recommendation,
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required String? scheduleVariant,
    required int nextStepIndex,
    required TrainingSessionType nextSessionType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, ExerciseStatus> progressMap,
    required Map<String, ExerciseProgress> progressEntries,
    required List<PastWorkout> workouts,
    DateTime? now,
  }) {
    final cycle = trainingProgramService.scheduleCycleFor(
      programType: programType,
      scheduleVariant: scheduleVariant,
    );

    return HomeDashboardMetrics(
      today: buildTodaySummary(recommendation),
      weekStrip: buildWeekStripData(
        cycle: cycle,
        nextStepIndex: nextStepIndex,
        nextSessionType: nextSessionType,
        now: now,
      ),
      journeySnapshot: buildJourneySnapshotData(progressMap),
      activeSkillPaths: buildActiveSkillPathData(
        trainingProgramService: trainingProgramService,
        programType: programType,
        branchSelections: branchSelections,
        sessionItemsConfig: sessionItemsConfig,
        progressMap: progressMap,
        progressEntries: progressEntries,
        workouts: workouts,
        now: now,
      ),
    );
  }

  static HomeTodaySummary buildTodaySummary(
    DailyTrainingRecommendation recommendation,
  ) {
    final sessionTitle = recommendation.isRestDay
        ? 'Recovery'
        : _homeSessionTitle(recommendation.sessionType);
    final tags = recommendation.items.map((item) => item.exercise.name).take(4);

    return HomeTodaySummary(
      sessionTitle: sessionTitle,
      ctaLabel: recommendation.isRestDay ? 'View plan' : 'Start $sessionTitle',
      isRestDay: recommendation.isRestDay,
      exerciseCount: recommendation.items.length,
      estimatedDurationMinutes: _estimateWorkoutMinutes(recommendation),
      focusTags: tags.toList(),
      mixSegments: _buildTodayMixSegments(recommendation),
      supportingText: recommendation.isRestDay
          ? 'Take the day to recover, then review the next session and keep the split moving.'
          : 'Built from your current program state and ready to start immediately.',
    );
  }

  static HomeWeekStripData buildWeekStripData({
    required List<TrainingSessionType> cycle,
    required int nextStepIndex,
    required TrainingSessionType nextSessionType,
    DateTime? now,
  }) {
    if (cycle.isEmpty) {
      return const HomeWeekStripData(
        days: [],
        completedSessions: 0,
        totalSessions: 0,
        supportingText: 'No schedule is available yet.',
      );
    }

    final currentIndex = _resolveCurrentIndex(
      cycle: cycle,
      nextStepIndex: nextStepIndex,
      nextSessionType: nextSessionType,
    );
    final today = _dateOnly(now ?? DateTime.now());
    final startDate = today.subtract(Duration(days: currentIndex));
    final totalSessions =
        cycle.where((session) => session != TrainingSessionType.rest).length;
    final completedSessions = cycle
        .take(currentIndex)
        .where((session) => session != TrainingSessionType.rest)
        .length;

    return HomeWeekStripData(
      days: List.generate(
        cycle.length,
        (index) => HomeWeekStripDay(
          date: startDate.add(Duration(days: index)),
          sessionType: cycle[index],
          isCurrent: index == currentIndex,
          isCompleted:
              index < currentIndex && cycle[index] != TrainingSessionType.rest,
        ),
      ),
      completedSessions: completedSessions,
      totalSessions: totalSessions,
      supportingText:
          '$completedSessions of $totalSessions sessions done. Sessions roll forward, so a missed day becomes your next training day.',
    );
  }

  static JourneySnapshotData buildJourneySnapshotData(
    Map<String, ExerciseStatus> progressMap,
  ) {
    final categories = SkillCategoryCatalog.browsable();
    final treeLevels = [
      for (final category in categories)
        treeLevelForCategory(category, progressMap),
    ];
    final total = treeLevels.fold<double>(0, (sum, level) => sum + level);
    final max = categories.length * 10;
    final average = categories.isEmpty ? 0.0 : total / categories.length;

    return JourneySnapshotData(
      totalLevel: total.round(),
      maxLevel: max,
      averageSkillLevel: double.parse(average.toStringAsFixed(1)),
      tierLabel: _tierForAverage(average),
      unlockedSkillTrees: treeLevels.where((level) => level > 0).length,
      totalSkillTrees: categories.length,
    );
  }

  static double treeLevelForCategory(
    SkillCategory category,
    Map<String, ExerciseStatus> progressMap,
  ) {
    final branchIds = category.trainingPaths.isEmpty
        ? const ['main']
        : category.trainingPaths.keys.toList();
    var bestLevel = 0.0;

    for (final branchId in branchIds) {
      final exerciseIds = category.trainingPaths.isEmpty
          ? ExerciseCatalog.forSkillCategory(category.id)
              .where((exercise) => exercise.branchId == 'main')
              .map((exercise) => exercise.id)
              .toList()
          : List<String>.from(
              category.trainingPaths[branchId] ?? const <String>[],
            );

      final branchLevel =
          branchScoreForExerciseIds(exerciseIds, progressMap) * 10;
      if (branchLevel > bestLevel) {
        bestLevel = branchLevel;
      }
    }

    return bestLevel;
  }

  static double branchScoreForExerciseIds(
    List<String> exerciseIds,
    Map<String, ExerciseStatus> progressMap,
  ) {
    if (exerciseIds.isEmpty) return 0;

    var earned = 0.0;
    var firstUnfinishedReached = false;

    for (final exerciseId in exerciseIds) {
      final status = progressMap[exerciseId] ?? ExerciseStatus.inactive;
      if (status == ExerciseStatus.mastered && !firstUnfinishedReached) {
        earned += 1.0;
        continue;
      }
      if (status == ExerciseStatus.active && !firstUnfinishedReached) {
        earned += _activeStepCredit;
      }
      firstUnfinishedReached = true;
    }

    return earned / exerciseIds.length;
  }

  static List<ActiveSkillPathData> buildActiveSkillPathData({
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, ExerciseStatus> progressMap,
    required Map<String, ExerciseProgress> progressEntries,
    required List<PastWorkout> workouts,
    DateTime? now,
  }) {
    final categoriesById = {
      for (final category in SkillCategoryCatalog.browsable())
        category.id: category,
    };
    final configuredOptions = _activePathOptionsFromSessionConfig(
      trainingProgramService: trainingProgramService,
      programType: programType,
      sessionItemsConfig: sessionItemsConfig,
      categoriesById: categoriesById,
    );
    final options = configuredOptions.isNotEmpty
        ? configuredOptions
        : trainingProgramService
            .resolveSelectedBranches(branchSelections)
            .values
            .toList();

    final rows = <ActiveSkillPathData>[];
    for (final option in options) {
      final category = categoriesById[option.sourceSkillCategoryId];
      if (category == null) continue;

      final currentExercise =
          trainingProgramService.currentExerciseForOption(option, progressMap);
      final progressScore =
          branchScoreForExerciseIds(option.exerciseIds, progressMap);
      final progressPercent = (progressScore * 100).round();
      final momentum = _momentumForExercise(
        exercise: currentExercise,
        workouts: workouts,
        currentStatus: progressMap[currentExercise?.id],
        progressEntry: currentExercise == null
            ? null
            : progressEntries[currentExercise.id],
        now: now,
      );

      rows.add(
        ActiveSkillPathData(
          track: option.track,
          skillCategoryId: category.id,
          branchId: option.trainingPathId,
          trackLabel: option.track.label,
          skillTitle: _skillTitleForOption(category, option.trainingPathId),
          currentExerciseName: currentExercise?.name ?? option.title,
          level: (progressScore * 10).round(),
          progressPercent: progressPercent,
          momentum: momentum,
          note: _momentumNote(
            momentum: momentum,
            exercise: currentExercise,
            workouts: workouts,
          ),
        ),
      );
    }

    rows.sort((a, b) {
      final severity =
          _momentumSeverity(a.momentum) - _momentumSeverity(b.momentum);
      if (severity != 0) return severity;
      return a.trackLabel.compareTo(b.trackLabel);
    });

    return rows;
  }

  static List<TrainingBranchOption> _activePathOptionsFromSessionConfig({
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, SkillCategory> categoriesById,
  }) {
    if (sessionItemsConfig.isEmpty) return const [];

    final optionsByKey = <String, TrainingBranchOption>{};
    for (final sessionType
        in trainingProgramService.trainingDaysForProgramType(programType)) {
      final rawSession = sessionItemsConfig[sessionType.dbValue];
      if (rawSession is! Map) continue;

      final sessionMap = Map<String, dynamic>.from(rawSession);
      for (final component in const ['skill', 'strength']) {
        final rawItems = sessionMap[component];
        if (rawItems is! List) continue;

        for (final rawItem in rawItems.whereType<Map>()) {
          final item = Map<String, dynamic>.from(rawItem);
          if (item['kind'] != 'progression') continue;

          final skillCategoryId = item['skill_category_id'] as String?;
          final branchId = item['branch_id'] as String? ?? 'main';
          if (skillCategoryId == null) continue;

          final category = categoriesById[skillCategoryId];
          if (category == null) continue;

          final exerciseIds = category.trainingPaths.isEmpty
              ? ExerciseCatalog.forSkillCategory(category.id)
                  .where((exercise) => exercise.branchId == branchId)
                  .map((exercise) => exercise.id)
                  .toList()
              : List<String>.from(
                  category.trainingPaths[branchId] ?? const <String>[],
                );
          if (exerciseIds.isEmpty) continue;

          final track = component == 'skill'
              ? TrainingTrack.skillWork
              : _trackForExerciseCategory(category.track);
          final option = TrainingBranchOption(
            id: '$skillCategoryId:$branchId',
            track: track,
            sourceCategory: category.track,
            sourceSkillCategoryId: category.id,
            trainingPathId: branchId,
            title: _skillTitleForOption(category, branchId),
            subtitle: category.title,
            rationale: '',
            exerciseIds: exerciseIds,
          );
          optionsByKey.putIfAbsent(
            '${track.dbValue}|${category.id}|$branchId',
            () => option,
          );
        }
      }
    }

    return optionsByKey.values.toList();
  }

  static TrainingTrack _trackForExerciseCategory(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.verticalPull:
        return TrainingTrack.verticalPull;
      case ExerciseCategory.verticalPush:
        return TrainingTrack.verticalPush;
      case ExerciseCategory.horizontalPull:
        return TrainingTrack.horizontalPull;
      case ExerciseCategory.horizontalPush:
        return TrainingTrack.horizontalPush;
      case ExerciseCategory.squat:
        return TrainingTrack.squat;
      case ExerciseCategory.hinge:
        return TrainingTrack.hinge;
      case ExerciseCategory.core:
        return TrainingTrack.core;
      case ExerciseCategory.skill:
        return TrainingTrack.skillWork;
    }
  }

  static int _estimateWorkoutMinutes(
      DailyTrainingRecommendation recommendation) {
    if (recommendation.isRestDay) return 0;

    var minutes = 0;
    for (final item in recommendation.items) {
      switch (item.exercise.programSection) {
        case ExerciseProgramSection.warmup:
          minutes += 3;
          break;
        case ExerciseProgramSection.skillWork:
          minutes += 6;
          break;
        case ExerciseProgramSection.mainExercises:
          minutes += 8;
          break;
        case ExerciseProgramSection.coolDown:
          minutes += 2;
          break;
      }
    }

    final rounded = ((minutes / 5).round()) * 5;
    return rounded < 20 ? 20 : rounded;
  }

  static List<HomeTodayMixSegment> _buildTodayMixSegments(
    DailyTrainingRecommendation recommendation,
  ) {
    if (recommendation.items.isEmpty) return const [];

    final counts = <String, int>{};
    for (final item in recommendation.items) {
      final label = _mixLabelForTrack(item.track);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final total = recommendation.items.length;
    return counts.entries
        .map(
          (entry) => HomeTodayMixSegment(
            label: entry.key,
            percentage: ((entry.value / total) * 100).round(),
          ),
        )
        .toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  static String _mixLabelForTrack(TrainingTrack track) {
    switch (track) {
      case TrainingTrack.verticalPull:
      case TrainingTrack.horizontalPull:
        return 'Pull';
      case TrainingTrack.verticalPush:
      case TrainingTrack.horizontalPush:
        return 'Push';
      case TrainingTrack.squat:
      case TrainingTrack.hinge:
        return 'Legs';
      case TrainingTrack.core:
        return 'Core';
      case TrainingTrack.skillWork:
        return 'Skill';
    }
  }

  static int _resolveCurrentIndex({
    required List<TrainingSessionType> cycle,
    required int nextStepIndex,
    required TrainingSessionType nextSessionType,
  }) {
    if (nextStepIndex >= 0 &&
        nextStepIndex < cycle.length &&
        cycle[nextStepIndex] == nextSessionType) {
      return nextStepIndex;
    }

    final matchedIndex = cycle.indexOf(nextSessionType);
    return matchedIndex >= 0 ? matchedIndex : 0;
  }

  static String _homeSessionTitle(TrainingSessionType sessionType) {
    switch (sessionType) {
      case TrainingSessionType.fullBody:
        return 'Full Body';
      case TrainingSessionType.push:
        return 'Push Day';
      case TrainingSessionType.pull:
        return 'Pull Day';
      case TrainingSessionType.upper:
        return 'Upper Day';
      case TrainingSessionType.lower:
        return 'Lower Day';
      case TrainingSessionType.rest:
        return 'Recovery';
    }
  }

  static String _tierForAverage(double average) {
    if (average < 3.5) return 'Beginner';
    if (average < 6.5) return 'Intermediate';
    if (average < 8.5) return 'Advanced';
    return 'Elite';
  }

  static String _skillTitleForOption(SkillCategory category, String branchId) {
    final branch =
        category.branches.where((item) => item.id == branchId).firstOrNull;
    if (branch == null || branch.label.toLowerCase() == 'main') {
      return category.title;
    }
    return '${branch.label} ${category.title}';
  }

  static HomeSkillMomentum _momentumForExercise({
    required Exercise? exercise,
    required List<PastWorkout> workouts,
    required ExerciseStatus? currentStatus,
    required ExerciseProgress? progressEntry,
    DateTime? now,
  }) {
    if (exercise == null) return HomeSkillMomentum.steady;

    final values = _performanceValuesForExercise(exercise.id, workouts);
    final recentPromotion = progressEntry != null &&
        currentStatus != ExerciseStatus.inactive &&
        (now ?? DateTime.now()).difference(progressEntry.updatedAt) <=
            _recentStatusPromotionWindow;

    if (values.isNotEmpty) {
      final latest = values.first;
      final previousBest = values.skip(1).fold<int>(
            0,
            (best, value) => value > best ? value : best,
          );

      if (latest > previousBest) {
        return HomeSkillMomentum.improving;
      }
    }

    if (recentPromotion) return HomeSkillMomentum.improving;

    if (values.length >= 4) {
      final latest = values.first;
      final previousBest = values.skip(1).fold<int>(
            0,
            (best, value) => value > best ? value : best,
          );
      if (latest <= previousBest) {
        return HomeSkillMomentum.stalled;
      }
    }

    return HomeSkillMomentum.steady;
  }

  static String _momentumNote({
    required HomeSkillMomentum momentum,
    required Exercise? exercise,
    required List<PastWorkout> workouts,
  }) {
    final name = exercise?.name ?? 'this path';
    final sessionCount = exercise == null
        ? 0
        : _performanceValuesForExercise(exercise.id, workouts).length;

    switch (momentum) {
      case HomeSkillMomentum.improving:
        return 'New momentum on $name';
      case HomeSkillMomentum.stalled:
        return 'No new best in the last $sessionCount sessions';
      case HomeSkillMomentum.steady:
        return sessionCount == 0
            ? 'No sessions logged yet'
            : 'Holding steady on $name';
    }
  }

  static int _momentumSeverity(HomeSkillMomentum momentum) {
    switch (momentum) {
      case HomeSkillMomentum.stalled:
        return 0;
      case HomeSkillMomentum.steady:
        return 1;
      case HomeSkillMomentum.improving:
        return 2;
    }
  }

  static List<int> _performanceValuesForExercise(
    String exerciseId,
    List<PastWorkout> workouts,
  ) {
    final values = <int>[];
    for (final workout in workouts) {
      final match = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (match == null) continue;
      if (match.sets.isEmpty) continue;

      values.add(
        match.sets.fold<int>(
          0,
          (best, set) => set.value > best ? set.value : best,
        ),
      );
      if (values.length == 4) break;
    }
    return values;
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
