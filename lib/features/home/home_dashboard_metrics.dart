import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_schedule_service.dart';

enum HomeSkillMomentum { stalled, steady, improving }

/// State of a single node inside a training path, for the small dot/
/// constellation previews on the home dashboard.
enum PathNodeState { mastered, working, upcoming }

class HomeDashboardMetrics {
  final HomeTodaySummary today;
  final HomeWeekStripData weekStrip;
  final HomeStreakData streak;
  final JourneySnapshotData journeySnapshot;
  final List<ActiveSkillPathData> activeSkillPaths;
  final List<HomeExercisePerformance> exercisePerformance;
  final List<HomeGoalSkillData> goalSkills;
  final int nodesClearedThisMonth;

  const HomeDashboardMetrics({
    required this.today,
    required this.weekStrip,
    required this.streak,
    required this.journeySnapshot,
    required this.activeSkillPaths,
    required this.exercisePerformance,
    required this.goalSkills,
    required this.nodesClearedThisMonth,
  });
}

/// Weekly training streak for the strip at the top of the dashboard:
/// consecutive calendar weeks (Monday-based) with at least one saved workout.
/// The running week can't break the streak until it is over.
class HomeStreakData {
  final int streakWeeks;
  final int completedThisWeek;
  final int plannedPerWeek;
  final bool hasWorkouts;

  const HomeStreakData({
    required this.streakWeeks,
    required this.completedThisWeek,
    required this.plannedPerWeek,
    required this.hasWorkouts,
  });

  bool get onTrack => plannedPerWeek > 0 && completedThisWeek >= plannedPerWeek;
}

/// Session-over-session totals for one exercise in the current program:
/// has the user beaten their previous session's total reps (or hold time)?
class HomeExercisePerformance {
  final String exerciseId;
  final String exerciseName;

  /// Chronological session totals, capped at the last 4 logged sessions.
  final List<int> history;
  final bool isTimed;

  const HomeExercisePerformance({
    required this.exerciseId,
    required this.exerciseName,
    required this.history,
    required this.isTimed,
  });

  /// Latest session total minus the previous one; null with fewer than two
  /// logged sessions.
  int? get sessionDelta =>
      history.length >= 2 ? history.last - history[history.length - 2] : null;
}

/// One long-term goal skill picked in the training program, with progress
/// along the progression path that leads to it.
class HomeGoalSkillData {
  final String exerciseId;
  final String exerciseName;
  final String skillCategoryId;
  final String categoryTitle;
  final int masteredSteps;
  final int totalSteps;

  const HomeGoalSkillData({
    required this.exerciseId,
    required this.exerciseName,
    required this.skillCategoryId,
    required this.categoryTitle,
    required this.masteredSteps,
    required this.totalSteps,
  });

  double get progress => totalSteps == 0 ? 0 : masteredSteps / totalSteps;
}

class HomeTodaySummary {
  final String sessionTitle;
  final String ctaLabel;
  final bool isRestDay;
  final int exerciseCount;
  final int estimatedDurationMinutes;
  final List<String> focusTags;
  final List<HomePlannedExerciseSummary> plannedExercises;
  final List<HomeTodayMixSegment> mixSegments;
  final String supportingText;

  /// Set when a workout was already finished today — the hero card renders a
  /// "Workout complete" state instead of the start CTA.
  final HomeCompletedWorkoutSummary? completed;

  const HomeTodaySummary({
    required this.sessionTitle,
    required this.ctaLabel,
    required this.isRestDay,
    required this.exerciseCount,
    required this.estimatedDurationMinutes,
    required this.focusTags,
    required this.plannedExercises,
    required this.mixSegments,
    required this.supportingText,
    this.completed,
  });
}

class HomeCompletedWorkoutSummary {
  final String title;
  final int durationMinutes;
  final int setCount;
  final int exerciseCount;
  final String nextSessionLabel;

  const HomeCompletedWorkoutSummary({
    required this.title,
    required this.durationMinutes,
    required this.setCount,
    required this.exerciseCount,
    required this.nextSessionLabel,
  });
}

/// Where the rolling schedule stands on a given (local) day, derived from the
/// stored program pointer and the date of the last saved workout.
///
/// The stored state always points at the session AFTER the last completed
/// workout (advanced at save time). That step is due the day after that
/// workout; rest steps whose day has already passed roll forward here, while
/// training steps wait indefinitely ("a missed day becomes your next
/// training day").
class HomeScheduleResolution {
  /// Cycle index whose session the dashboard should recommend.
  final int effectiveStepIndex;
  final TrainingSessionType effectiveSessionType;

  /// Cycle index that represents *today* in the week calendar. Equal to
  /// [effectiveStepIndex] unless today's workout is already done — then it is
  /// the step just completed.
  final int todayPosition;
  final bool completedToday;

  const HomeScheduleResolution({
    required this.effectiveStepIndex,
    required this.effectiveSessionType,
    required this.todayPosition,
    required this.completedToday,
  });
}

class HomePlannedExerciseSummary {
  final String name;
  final String targetLabel;

  /// e.g. 'Handstand tree' — empty when the exercise has no known path.
  final String treeLabel;
  final List<PathNodeState> nodeStates;

  const HomePlannedExerciseSummary({
    required this.name,
    required this.targetLabel,
    this.treeLabel = '',
    this.nodeStates = const [],
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
  final bool isSelected;
  final bool isCompleted;
  final bool isMissed;
  final int stepIndex;

  const HomeWeekStripDay({
    required this.date,
    required this.sessionType,
    required this.isCurrent,
    this.isSelected = false,
    required this.isCompleted,
    this.isMissed = false,
    this.stepIndex = 0,
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
  final String nextTierLabel;
  final int levelsToNextTier;
  final List<JourneySkillProgressData> closestSkills;

  const JourneySnapshotData({
    required this.totalLevel,
    required this.maxLevel,
    required this.averageSkillLevel,
    required this.tierLabel,
    required this.unlockedSkillTrees,
    required this.totalSkillTrees,
    required this.nextTierLabel,
    required this.levelsToNextTier,
    required this.closestSkills,
  });
}

enum JourneySkillTrend { up, down, flat }

enum JourneySkillStageStatus { cleared, inProgress, locked }

class JourneySkillStageHistoryPoint {
  final int value;
  final DateTime loggedAt;

  const JourneySkillStageHistoryPoint({
    required this.value,
    required this.loggedAt,
  });
}

class JourneySkillStageData {
  final String exerciseId;
  final String exerciseName;
  final JourneySkillStageStatus status;
  final int targetVolume;
  final String targetLabel;
  final List<JourneySkillStageHistoryPoint> history;
  final String? unlockRequirementName;

  const JourneySkillStageData({
    required this.exerciseId,
    required this.exerciseName,
    required this.status,
    required this.targetVolume,
    required this.targetLabel,
    required this.history,
    required this.unlockRequirementName,
  });
}

class JourneySkillProgressData {
  final TrainingTrack track;
  final String skillCategoryId;
  final String branchId;
  final String motionLabel;
  final String skillTitle;
  final String currentExerciseName;
  final String nextExerciseName;
  final int targetVolume;
  final int lastSessionVolume;
  final String targetLabel;
  final String lastLabel;
  final String lastSessionDeltaLabel;
  final JourneySkillTrend lastSessionTrend;
  final double progressPercent;
  final bool isTimed;
  final List<JourneySkillStageData> stages;

  const JourneySkillProgressData({
    required this.track,
    required this.skillCategoryId,
    required this.branchId,
    required this.motionLabel,
    required this.skillTitle,
    required this.currentExerciseName,
    required this.nextExerciseName,
    required this.targetVolume,
    required this.lastSessionVolume,
    required this.targetLabel,
    required this.lastLabel,
    required this.lastSessionDeltaLabel,
    required this.lastSessionTrend,
    required this.progressPercent,
    this.isTimed = false,
    required this.stages,
  });
}

class ActiveSkillPathData {
  final TrainingTrack track;
  final String skillCategoryId;
  final String branchId;
  final String trackLabel;
  final String skillTitle;
  final String currentExerciseName;

  /// Name of the final exercise of the path — the goal the user picked.
  final String goalExerciseName;
  final List<PathNodeState> nodeStates;

  /// 1-based index of the working node within the path.
  final int workingPosition;
  final int totalNodes;
  final int level;
  final int progressPercent;
  final HomeSkillMomentum momentum;
  final String note;
  final String personalBestLabel;
  final String deltaLabel;
  final bool isTimed;

  const ActiveSkillPathData({
    required this.track,
    required this.skillCategoryId,
    required this.branchId,
    required this.trackLabel,
    required this.skillTitle,
    required this.currentExerciseName,
    this.goalExerciseName = '',
    this.nodeStates = const [],
    this.workingPosition = 0,
    this.totalNodes = 0,
    required this.level,
    required this.progressPercent,
    required this.momentum,
    required this.note,
    required this.personalBestLabel,
    required this.deltaLabel,
    required this.isTimed,
  });
}

class HomeDashboardMetricsCalculator {
  static const double _activeStepCredit = 0.6;
  static const Duration _recentStatusPromotionWindow = Duration(days: 28);
  static final DateTime _dummyComparisonNow = DateTime(2026, 6, 19);

  static HomeDashboardMetrics build({
    required DailyTrainingRecommendation recommendation,
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required String? scheduleVariant,
    required HomeScheduleResolution schedule,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, ExerciseStatus> progressMap,
    required Map<String, ExerciseProgress> progressEntries,
    required List<PastWorkout> workouts,
    List<String> goalSkillIds = const [],
    int frequencyPerWeek = 3,
    PastWorkout? completedWorkout,
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    TrainingScheduleWindow? scheduleWindow,
    DateTime? now,
  }) {
    final cycle = trainingProgramService.scheduleCycleFor(
      programType: programType,
      scheduleVariant: scheduleVariant,
      frequencyPerWeek: frequencyPerWeek,
    );
    final resolvedCompletedWorkout = completedWorkout ??
        (schedule.completedToday && workouts.isNotEmpty
            ? workouts.first
            : null);

    final categoriesById = {
      for (final category in SkillCategoryCatalog.browsable())
        category.id: category,
    };

    return HomeDashboardMetrics(
      today: buildTodaySummary(
        recommendation,
        completedWorkout: resolvedCompletedWorkout,
        pathOptions: resolveActivePathOptions(
          trainingProgramService: trainingProgramService,
          programType: programType,
          sessionItemsConfig: sessionItemsConfig,
          branchSelections: branchSelections,
          categoriesById: categoriesById,
        ),
        progressMap: progressMap,
        progressEntries: progressEntries,
        masterySettings: masterySettings,
      ),
      weekStrip: buildWeekStripData(
        cycle: cycle,
        todayPosition: schedule.todayPosition,
        completedToday: schedule.completedToday,
        scheduleWindow: scheduleWindow,
        now: now,
      ),
      streak: buildStreakData(
        workouts: workouts,
        plannedPerWeek: frequencyPerWeek,
        now: now,
      ),
      journeySnapshot: buildJourneySnapshotData(
        trainingProgramService: trainingProgramService,
        programType: programType,
        branchSelections: branchSelections,
        sessionItemsConfig: sessionItemsConfig,
        progressMap: progressMap,
        progressEntries: progressEntries,
        masterySettings: masterySettings,
        workouts: workouts,
        now: now,
      ),
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
      exercisePerformance: buildExercisePerformance(
        recommendation: recommendation,
        workouts: workouts,
      ),
      goalSkills: buildGoalSkillData(
        goalSkillIds: goalSkillIds,
        progressMap: progressMap,
      ),
      nodesClearedThisMonth: nodesClearedThisMonth(
        progressEntries: progressEntries,
        now: now,
      ),
    );
  }

  /// Exercises marked mastered during the current calendar month. Uses the
  /// progress row's updated_at, so re-toggling an old node counts again.
  static int nodesClearedThisMonth({
    required Map<String, ExerciseProgress> progressEntries,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toLocal();
    return progressEntries.values.where((entry) {
      final updatedAt = entry.updatedAt.toLocal();
      return entry.status == ExerciseStatus.mastered &&
          updatedAt.year == reference.year &&
          updatedAt.month == reference.month;
    }).length;
  }

  /// Weekly streak: consecutive completed Monday-based weeks that met the
  /// user's planned weekly sessions. The running week can extend the streak
  /// once it reaches the goal, but cannot break it before Sunday is over.
  static HomeStreakData buildStreakData({
    required List<PastWorkout> workouts,
    required int plannedPerWeek,
    DateTime? now,
  }) {
    final today = _dateOnly((now ?? DateTime.now()).toLocal());
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));

    final sessionsPerWeek = <DateTime, int>{};
    var completedThisWeek = 0;
    for (final workout in workouts) {
      final day = _dateOnly(workout.loggedAt.toLocal());
      final week = day.subtract(Duration(days: day.weekday - 1));
      sessionsPerWeek[week] = (sessionsPerWeek[week] ?? 0) + 1;
      if (!day.isBefore(thisWeek) && !day.isAfter(today)) {
        completedThisWeek++;
      }
    }

    var cursor = thisWeek;
    if ((sessionsPerWeek[cursor] ?? 0) < plannedPerWeek) {
      cursor = cursor.subtract(const Duration(days: 7));
    }
    var streakWeeks = 0;
    while ((sessionsPerWeek[cursor] ?? 0) >= plannedPerWeek) {
      streakWeeks++;
      cursor = cursor.subtract(const Duration(days: 7));
    }

    return HomeStreakData(
      streakWeeks: streakWeeks,
      completedThisWeek: completedThisWeek,
      plannedPerWeek: plannedPerWeek,
      hasWorkouts: workouts.isNotEmpty,
    );
  }

  /// Session totals per exercise in today's program — one row per planned
  /// exercise, with up to the last 4 logged sessions.
  static List<HomeExercisePerformance> buildExercisePerformance({
    required DailyTrainingRecommendation recommendation,
    required List<PastWorkout> workouts,
  }) {
    final sorted = [...workouts]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final rows = <HomeExercisePerformance>[];
    final seen = <String>{};

    for (final item in recommendation.items) {
      if (!seen.add(item.exercise.id)) continue;

      final values = <int>[];
      var isTimed = false;
      for (final workout in sorted) {
        final match = workout.exercises
            .where((exercise) => exercise.exerciseId == item.exercise.id)
            .firstOrNull;
        if (match == null || match.sets.isEmpty) continue;
        if (values.isEmpty) {
          isTimed = match.isTimed || match.sets.any((set) => set.isTimed);
        }
        values.add(match.sets.fold<int>(0, (sum, set) => sum + set.value));
        if (values.length >= 4) break;
      }

      rows.add(
        HomeExercisePerformance(
          exerciseId: item.exercise.id,
          exerciseName: item.exercise.name,
          history: values.reversed.toList(),
          isTimed: isTimed,
        ),
      );
    }

    return rows;
  }

  /// Progress toward each goal skill set in the training program. Progress is
  /// mastered steps along the progression path that ends at the goal.
  static List<HomeGoalSkillData> buildGoalSkillData({
    required List<String> goalSkillIds,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    final goals = <HomeGoalSkillData>[];

    for (final goalId in goalSkillIds) {
      final exercise = ExerciseCatalog.findById(goalId);
      if (exercise == null) continue;

      final category = SkillCategoryCatalog.findById(
        ExerciseCatalog.skillCategoryIdForExercise(exercise),
      );

      List<String>? path;
      for (final candidate
          in (category?.trainingPaths ?? const <String, List<String>>{})
              .values) {
        if (candidate.contains(goalId)) {
          path = candidate;
          break;
        }
      }

      final steps = path == null
          ? <String>[goalId]
          : path.sublist(0, path.indexOf(goalId) + 1);
      final mastered = steps
          .where((id) => progressMap[id] == ExerciseStatus.mastered)
          .length;

      goals.add(
        HomeGoalSkillData(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          skillCategoryId: category?.id ?? '',
          categoryTitle: category?.title ?? exercise.category.label,
          masteredSteps: mastered,
          totalSteps: steps.length,
        ),
      );
    }

    return goals;
  }

  /// Resolves what the dashboard should show for [now]'s local date. See
  /// [HomeScheduleResolution] for the schedule semantics.
  static HomeScheduleResolution resolveSchedule({
    required List<TrainingSessionType> cycle,
    required int nextStepIndex,
    required TrainingSessionType nextSessionType,
    DateTime? lastWorkoutAt,
    DateTime? now,
  }) {
    if (cycle.isEmpty) {
      return HomeScheduleResolution(
        effectiveStepIndex: 0,
        effectiveSessionType: nextSessionType,
        todayPosition: 0,
        completedToday: false,
      );
    }

    var index = _resolveCurrentIndex(
      cycle: cycle,
      nextStepIndex: nextStepIndex,
      nextSessionType: nextSessionType,
    );
    final today = _dateOnly(now ?? DateTime.now());
    var completedToday = false;

    if (lastWorkoutAt != null) {
      final lastWorkoutDate = _dateOnly(lastWorkoutAt.toLocal());
      completedToday = lastWorkoutDate.isAtSameMomentAs(today);

      if (!completedToday) {
        index = (index + 1) % cycle.length;
      }

      // The next step is due the day after the last workout. Rest steps whose
      // day has passed roll forward; training steps wait to be done.
      var due =
          completedToday ? today : lastWorkoutDate.add(const Duration(days: 1));
      while (cycle[index] == TrainingSessionType.rest && due.isBefore(today)) {
        index = (index + 1) % cycle.length;
        due = due.add(const Duration(days: 1));
      }
    }

    return HomeScheduleResolution(
      effectiveStepIndex: index,
      effectiveSessionType: cycle[index],
      todayPosition: index,
      completedToday: completedToday,
    );
  }

  static HomeTodaySummary buildTodaySummary(
    DailyTrainingRecommendation recommendation, {
    PastWorkout? completedWorkout,
    List<TrainingBranchOption> pathOptions = const [],
    Map<String, ExerciseStatus> progressMap = const {},
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final sessionTitle = recommendation.isRestDay
        ? 'Recovery'
        : _homeSessionTitle(recommendation.sessionType);
    final plannedExercises = recommendation.items
        .map(
          (item) => _buildPlannedExerciseSummary(
            item,
            pathOptions: pathOptions,
            progressMap: progressMap,
            progressEntries: progressEntries,
            masterySettings: masterySettings,
          ),
        )
        .toList();
    final tags = plannedExercises.map((exercise) => exercise.name);
    final nextSessionLabel = recommendation.isRestDay
        ? 'Rest day'
        : _homeSessionTitle(recommendation.sessionType);

    return HomeTodaySummary(
      sessionTitle: sessionTitle,
      ctaLabel: recommendation.isRestDay ? 'View plan' : 'Start $sessionTitle',
      isRestDay: recommendation.isRestDay,
      exerciseCount: recommendation.items.length,
      estimatedDurationMinutes: _estimateWorkoutMinutes(recommendation),
      focusTags: tags.toList(),
      plannedExercises: plannedExercises,
      mixSegments: _buildTodayMixSegments(recommendation),
      supportingText: recommendation.isRestDay
          ? 'Take the day to recover, then review the next session and keep the split moving.'
          : 'Built from your current program state and ready to start immediately.',
      completed: completedWorkout == null
          ? null
          : _buildCompletedSummary(completedWorkout, nextSessionLabel),
    );
  }

  static HomeCompletedWorkoutSummary _buildCompletedSummary(
    PastWorkout workout,
    String nextSessionLabel,
  ) {
    final minutes = workout.loggedAt.difference(workout.startedAt).inMinutes;
    final setCount = workout.exercises
        .fold<int>(0, (sum, exercise) => sum + exercise.setCount);

    return HomeCompletedWorkoutSummary(
      title: workout.title,
      durationMinutes: minutes < 1 ? 1 : minutes,
      setCount: setCount,
      exerciseCount: workout.exercises.length,
      nextSessionLabel: nextSessionLabel,
    );
  }

  static HomeWeekStripData buildWeekStripData({
    required List<TrainingSessionType> cycle,
    required int todayPosition,
    required bool completedToday,
    TrainingScheduleWindow? scheduleWindow,
    DateTime? now,
  }) {
    if (scheduleWindow != null) {
      return HomeWeekStripData(
        days: [
          for (final day in scheduleWindow.days)
            HomeWeekStripDay(
              date: day.date,
              sessionType: day.sessionType,
              isCurrent: day.isToday,
              isSelected: day.isSelected,
              isCompleted: day.isCompleted,
              isMissed: day.isMissed,
              stepIndex: day.stepIndex,
            ),
        ],
        completedSessions: scheduleWindow.completedSessions,
        totalSessions: scheduleWindow.totalSessions,
        supportingText:
            '${scheduleWindow.completedSessions} of ${scheduleWindow.totalSessions} sessions done. Sessions roll forward, so a missed day becomes your next training day.',
      );
    }

    if (cycle.isEmpty) {
      return const HomeWeekStripData(
        days: [],
        completedSessions: 0,
        totalSessions: 0,
        supportingText: 'No schedule is available yet.',
      );
    }

    final currentIndex = todayPosition.clamp(0, cycle.length - 1);
    final today = _dateOnly(now ?? DateTime.now());
    final startDate = today.subtract(Duration(days: currentIndex));
    final totalSessions =
        cycle.where((session) => session != TrainingSessionType.rest).length;
    final completedSessions = cycle
            .take(currentIndex)
            .where((session) => session != TrainingSessionType.rest)
            .length +
        (completedToday && cycle[currentIndex] != TrainingSessionType.rest
            ? 1
            : 0);

    return HomeWeekStripData(
      days: List.generate(
        cycle.length,
        (index) => HomeWeekStripDay(
          date: startDate.add(Duration(days: index)),
          sessionType: cycle[index],
          isCurrent: index == currentIndex,
          isCompleted: cycle[index] != TrainingSessionType.rest &&
              (index < currentIndex ||
                  (index == currentIndex && completedToday)),
        ),
      ),
      completedSessions: completedSessions,
      totalSessions: totalSessions,
      supportingText:
          '$completedSessions of $totalSessions sessions done. Sessions roll forward, so a missed day becomes your next training day.',
    );
  }

  static JourneySnapshotData buildJourneySnapshotData({
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, ExerciseStatus> progressMap,
    required List<PastWorkout> workouts,
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    DateTime? now,
  }) {
    final categories = SkillCategoryCatalog.browsable();
    final treeLevels = [
      for (final category in categories)
        treeLevelForCategory(category, progressMap),
    ];
    final total = treeLevels.fold<double>(0, (sum, level) => sum + level);
    final max = categories.length * 10;
    final average = categories.isEmpty ? 0.0 : total / categories.length;
    final totalLevel = total.round();
    final tier = _tierForAverage(average);
    final nextTier = _nextTierForAverage(average);
    final nextTierAt = _nextTierThresholdTotal(
      average: average,
      treeCount: categories.length,
      maxLevel: max,
    );
    final closestSkills = buildJourneySkillProgressData(
      trainingProgramService: trainingProgramService,
      programType: programType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      progressMap: progressMap,
      progressEntries: progressEntries,
      masterySettings: masterySettings,
      workouts: workouts,
      now: now,
    );

    return JourneySnapshotData(
      totalLevel: totalLevel,
      maxLevel: max,
      averageSkillLevel: double.parse(average.toStringAsFixed(1)),
      tierLabel: tier,
      unlockedSkillTrees: treeLevels.where((level) => level > 0).length,
      totalSkillTrees: categories.length,
      nextTierLabel: nextTier,
      levelsToNextTier: nextTierAt > totalLevel ? nextTierAt - totalLevel : 0,
      closestSkills: closestSkills,
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
    final options = resolveActivePathOptions(
      trainingProgramService: trainingProgramService,
      programType: programType,
      sessionItemsConfig: sessionItemsConfig,
      branchSelections: branchSelections,
      categoriesById: categoriesById,
    );

    final rows = <ActiveSkillPathData>[];
    final comparisonNow = now ?? _dummyComparisonNow;
    for (final option in options) {
      final category = categoriesById[option.sourceSkillCategoryId];
      if (category == null) continue;

      final currentExercise =
          trainingProgramService.currentExerciseForOption(option, progressMap);
      final progressScore =
          branchScoreForExerciseIds(option.exerciseIds, progressMap);
      final progressPercent = (progressScore * 100).round();
      final performance = currentExercise == null
          ? const _ExercisePerformanceSnapshot.empty()
          : _performanceSnapshotForExercise(
              exerciseId: currentExercise.id,
              workouts: workouts,
              now: comparisonNow,
            );
      final momentum = _momentumForExercise(
        performance: performance,
        currentStatus: progressMap[currentExercise?.id],
        progressEntry: currentExercise == null
            ? null
            : progressEntries[currentExercise.id],
        now: comparisonNow,
      );

      final workingIndex = currentExercise == null
          ? -1
          : option.exerciseIds.indexOf(currentExercise.id);
      final goalExercise = option.exerciseIds.isEmpty
          ? null
          : ExerciseCatalog.findById(option.exerciseIds.last);

      rows.add(
        ActiveSkillPathData(
          track: option.track,
          skillCategoryId: category.id,
          branchId: option.trainingPathId,
          trackLabel: option.track.label,
          skillTitle: _skillTitleForOption(category, option.trainingPathId),
          currentExerciseName: currentExercise?.name ?? option.title,
          goalExerciseName: goalExercise?.name ?? option.title,
          nodeStates: pathNodeStates(
            exerciseIds: option.exerciseIds,
            workingExerciseId: currentExercise?.id,
            progressMap: progressMap,
          ),
          workingPosition:
              workingIndex >= 0 ? workingIndex + 1 : option.exerciseIds.length,
          totalNodes: option.exerciseIds.length,
          level: (progressScore * 10).round(),
          progressPercent: progressPercent,
          momentum: momentum,
          note: _momentumNote(
            momentum: momentum,
            performance: performance,
          ),
          personalBestLabel: _personalBestLabel(performance),
          deltaLabel: _deltaLabel(performance),
          isTimed: performance.isTimed,
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

  static List<JourneySkillProgressData> buildJourneySkillProgressData({
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<String, ExerciseStatus> progressMap,
    required List<PastWorkout> workouts,
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
    DateTime? now,
  }) {
    final categoriesById = {
      for (final category in SkillCategoryCatalog.browsable())
        category.id: category,
    };
    // A freshly set-up program has an empty session-items config until the
    // user customises a day, so resolveActivePathOptions falls back to the
    // selected branches instead of leaving the card empty.
    final options = resolveActivePathOptions(
      trainingProgramService: trainingProgramService,
      programType: programType,
      sessionItemsConfig: sessionItemsConfig,
      branchSelections: branchSelections,
      categoriesById: categoriesById,
    );
    final comparisonNow = now ?? _dummyComparisonNow;
    final rows = <JourneySkillProgressData>[];

    for (final option in options) {
      final category = categoriesById[option.sourceSkillCategoryId];
      if (category == null) continue;

      final currentExercise =
          trainingProgramService.currentExerciseForOption(option, progressMap);
      if (currentExercise == null) continue;

      final performance = _performanceSnapshotForExercise(
        exerciseId: currentExercise.id,
        workouts: workouts,
        now: comparisonNow,
      );
      final latestVolumes = _latestSessionVolumesForExercise(
        currentExercise.id,
        workouts,
        limit: 2,
      );
      final targetVolume = _masteryVolumeFor(
        currentExercise,
        progressEntries: progressEntries,
        masterySettings: masterySettings,
      );
      final lastSessionVolume =
          _latestSessionVolumeForExercise(currentExercise.id, workouts);
      final previousSessionVolume =
          latestVolumes.length > 1 ? latestVolumes[1] : lastSessionVolume;
      final progressPercent = targetVolume <= 0
          ? 0.0
          : (lastSessionVolume / targetVolume).clamp(0.0, 1.0);
      final nextExercise = _nextExerciseInPath(
        option.exerciseIds,
        currentExercise.id,
      );

      rows.add(
        JourneySkillProgressData(
          track: option.track,
          skillCategoryId: category.id,
          branchId: option.trainingPathId,
          motionLabel: category.title,
          skillTitle: _skillTitleForOption(category, option.trainingPathId),
          currentExerciseName: currentExercise.name,
          nextExerciseName: nextExercise?.name ?? currentExercise.name,
          targetVolume: targetVolume,
          lastSessionVolume: lastSessionVolume,
          targetLabel: _volumeLabel(
            value: targetVolume,
            isTimed: performance.isTimed,
          ),
          lastLabel: _volumeLabel(
            value: lastSessionVolume,
            isTimed: performance.isTimed,
          ),
          lastSessionDeltaLabel: _sessionDeltaLabel(
            current: lastSessionVolume,
            previous: previousSessionVolume,
            isTimed: performance.isTimed,
          ),
          lastSessionTrend: _sessionTrend(
            current: lastSessionVolume,
            previous: previousSessionVolume,
          ),
          progressPercent: progressPercent,
          isTimed: performance.isTimed,
          stages: _buildJourneySkillStages(
            exerciseIds: option.exerciseIds,
            progressMap: progressMap,
            progressEntries: progressEntries,
            masterySettings: masterySettings,
            workouts: workouts,
          ),
        ),
      );
    }

    rows.sort((a, b) {
      final progressCompare = b.progressPercent.compareTo(a.progressPercent);
      if (progressCompare != 0) return progressCompare;
      return a.skillTitle.compareTo(b.skillTitle);
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

  static HomePlannedExerciseSummary _buildPlannedExerciseSummary(
    TrainingRecommendationItem item, {
    List<TrainingBranchOption> pathOptions = const [],
    Map<String, ExerciseStatus> progressMap = const {},
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final prescribed = _prescribedTargetFor(
      item,
      progressEntries: progressEntries,
      masterySettings: masterySettings,
    );
    final targetLabel = _isTimedExercise(item.exercise)
        ? '${prescribed.sets} × ${prescribed.value}s'
        : '${prescribed.sets} × ${prescribed.value}';

    TrainingBranchOption? option;
    for (final candidate in pathOptions) {
      if (candidate.sourceSkillCategoryId == item.sourceSkillCategoryId &&
          candidate.exerciseIds.contains(item.exercise.id)) {
        option = candidate;
        break;
      }
    }

    return HomePlannedExerciseSummary(
      name: item.exercise.name,
      targetLabel: targetLabel,
      treeLabel: option == null ? '' : '${option.subtitle} tree',
      nodeStates: option == null
          ? const []
          : pathNodeStates(
              exerciseIds: option.exerciseIds,
              workingExerciseId: item.exercise.id,
              progressMap: progressMap,
            ),
    );
  }

  /// The active training-path options for the current program — the
  /// customised session config when present, otherwise the selected branches.
  static List<TrainingBranchOption> resolveActivePathOptions({
    required TrainingProgramService trainingProgramService,
    required TrainingProgramType programType,
    required Map<String, dynamic> sessionItemsConfig,
    required Map<TrainingTrack, String> branchSelections,
    required Map<String, SkillCategory> categoriesById,
  }) {
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

    // A skill tree is a category — the skill-work and core lanes can both
    // resolve to a core-category branch (l-sit vs ab-wheel), which would
    // otherwise show "Core" twice. Keep one option per category.
    final seenCategories = <String>{};
    return [
      for (final option in options)
        if (seenCategories.add(option.sourceSkillCategoryId)) option,
    ];
  }

  static List<PathNodeState> pathNodeStates({
    required List<String> exerciseIds,
    required String? workingExerciseId,
    required Map<String, ExerciseStatus> progressMap,
  }) {
    return [
      for (final exerciseId in exerciseIds)
        if (exerciseId == workingExerciseId)
          PathNodeState.working
        else if (progressMap[exerciseId] == ExerciseStatus.mastered)
          PathNodeState.mastered
        else
          PathNodeState.upcoming,
    ];
  }

  // Timed detection and target math live in ExerciseProgressionService so
  // the goal shown here is exactly the goal that advances the progression.
  static bool _isTimedExercise(Exercise exercise) =>
      ExerciseProgressionService.isTimedExercise(exercise);

  /// Prescribed target for a planned item: the progression ladder target for
  /// progression items, the catalog formula for standalone exercises.
  static ExerciseTarget _prescribedTargetFor(
    TrainingRecommendationItem item, {
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    if (item.isProgression) {
      return ExerciseProgressionService.currentTargetForExercise(
        item.exercise,
        progress: progressEntries[item.exercise.id],
        masterySettings: masterySettings,
      );
    }
    return ExerciseTarget(
      sets: ExerciseProgressionService.setCountForExercise(item.exercise),
      value: ExerciseProgressionService.targetValueForExercise(item.exercise),
    );
  }

  /// Volume that masters (levels up) a progression exercise.
  static int _masteryVolumeFor(
    Exercise exercise, {
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    return ExerciseProgressionService.masteryTargetForExercise(
      exercise,
      progress: progressEntries[exercise.id],
      masterySettings: masterySettings,
    ).volume;
  }

  static int _latestSessionVolumeForExercise(
    String exerciseId,
    List<PastWorkout> workouts,
  ) {
    final sorted = [...workouts]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    for (final workout in sorted) {
      final match = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (match == null || match.sets.isEmpty) continue;
      return match.sets.fold<int>(0, (sum, set) => sum + set.value);
    }
    return 0;
  }

  static List<int> _latestSessionVolumesForExercise(
    String exerciseId,
    List<PastWorkout> workouts, {
    required int limit,
  }) {
    final sorted = [...workouts]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final values = <int>[];
    for (final workout in sorted) {
      final match = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (match == null || match.sets.isEmpty) continue;
      values.add(match.sets.fold<int>(0, (sum, set) => sum + set.value));
      if (values.length >= limit) break;
    }
    return values;
  }

  static JourneySkillTrend _sessionTrend({
    required int current,
    required int previous,
  }) {
    if (current > previous) return JourneySkillTrend.up;
    if (current < previous) return JourneySkillTrend.down;
    return JourneySkillTrend.flat;
  }

  static String _sessionDeltaLabel({
    required int current,
    required int previous,
    required bool isTimed,
  }) {
    final delta = current - previous;
    if (delta == 0) return 'no change';
    final absDelta = delta.abs();
    final suffix = isTimed ? 's' : ' reps';
    final sign = delta > 0 ? '+' : '-';
    return '$sign$absDelta$suffix';
  }

  static Exercise? _nextExerciseInPath(
    List<String> exerciseIds,
    String currentExerciseId,
  ) {
    final currentIndex = exerciseIds.indexOf(currentExerciseId);
    if (currentIndex < 0 || currentIndex + 1 >= exerciseIds.length) {
      return null;
    }
    return ExerciseCatalog.findById(exerciseIds[currentIndex + 1]);
  }

  static List<JourneySkillStageData> _buildJourneySkillStages({
    required List<String> exerciseIds,
    required Map<String, ExerciseStatus> progressMap,
    required List<PastWorkout> workouts,
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    if (exerciseIds.isEmpty) return const [];

    final explicitCurrentIndex = exerciseIds.indexWhere(
      (id) => progressMap[id] == ExerciseStatus.active,
    );
    final firstPendingIndex = exerciseIds.indexWhere(
      (id) => progressMap[id] != ExerciseStatus.mastered,
    );
    final currentIndex = explicitCurrentIndex >= 0
        ? explicitCurrentIndex
        : firstPendingIndex >= 0
            ? firstPendingIndex
            : exerciseIds.length - 1;

    return [
      for (var index = 0; index < exerciseIds.length; index++)
        _buildJourneySkillStage(
          stageIndex: index,
          exerciseId: exerciseIds[index],
          previousExerciseId: index > 0 ? exerciseIds[index - 1] : null,
          currentIndex: currentIndex,
          progressMap: progressMap,
          progressEntries: progressEntries,
          masterySettings: masterySettings,
          workouts: workouts,
        ),
    ];
  }

  static JourneySkillStageData _buildJourneySkillStage({
    required int stageIndex,
    required String exerciseId,
    required String? previousExerciseId,
    required int currentIndex,
    required Map<String, ExerciseStatus> progressMap,
    required List<PastWorkout> workouts,
    Map<String, ExerciseProgress> progressEntries = const {},
    MasteryTargetSettings masterySettings = MasteryTargetSettings.defaults,
  }) {
    final exercise = ExerciseCatalog.findById(exerciseId);
    if (exercise == null) {
      return const JourneySkillStageData(
        exerciseId: '',
        exerciseName: 'Unknown exercise',
        status: JourneySkillStageStatus.locked,
        targetVolume: 0,
        targetLabel: '--',
        history: [],
        unlockRequirementName: null,
      );
    }

    final targetVolume = _masteryVolumeFor(
      exercise,
      progressEntries: progressEntries,
      masterySettings: masterySettings,
    );
    final orderedHistory = _historyForExercise(
      exerciseId: exerciseId,
      workouts: workouts,
    );
    final status = switch (progressMap[exerciseId] ?? ExerciseStatus.inactive) {
      ExerciseStatus.mastered => JourneySkillStageStatus.cleared,
      ExerciseStatus.active => JourneySkillStageStatus.inProgress,
      ExerciseStatus.inactive => stageIndex == currentIndex
          ? JourneySkillStageStatus.inProgress
          : JourneySkillStageStatus.locked,
    };

    return JourneySkillStageData(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      status: status,
      targetVolume: targetVolume,
      targetLabel: _volumeLabel(
        value: targetVolume,
        isTimed: _isTimedExercise(exercise),
      ),
      history: orderedHistory,
      unlockRequirementName: previousExerciseId == null
          ? null
          : ExerciseCatalog.findById(previousExerciseId)?.name,
    );
  }

  static List<JourneySkillStageHistoryPoint> _historyForExercise({
    required String exerciseId,
    required List<PastWorkout> workouts,
    int limit = 4,
  }) {
    final matches = <JourneySkillStageHistoryPoint>[];
    final sorted = [...workouts]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    for (final workout in sorted) {
      final match = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (match == null || match.sets.isEmpty) continue;
      matches.add(
        JourneySkillStageHistoryPoint(
          value: match.sets.fold<int>(0, (sum, set) => sum + set.value),
          loggedAt: workout.loggedAt,
        ),
      );
    }

    if (matches.length <= limit) return matches;
    return matches.sublist(matches.length - limit);
  }

  static String _volumeLabel({
    required int value,
    required bool isTimed,
  }) {
    final suffix = isTimed ? 's' : ' reps';
    return '$value$suffix';
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

  static String _nextTierForAverage(double average) {
    if (average < 3.5) return 'Intermediate';
    if (average < 6.5) return 'Advanced';
    if (average < 8.5) return 'Elite';
    return 'Elite';
  }

  static int _nextTierThresholdTotal({
    required double average,
    required int treeCount,
    required int maxLevel,
  }) {
    if (treeCount == 0) return 0;
    if (average < 3.5) return (3.5 * treeCount).ceil();
    if (average < 6.5) return (6.5 * treeCount).ceil();
    if (average < 8.5) return (8.5 * treeCount).ceil();
    return maxLevel;
  }

  static String _skillTitleForOption(SkillCategory category, String branchId) {
    final branch =
        category.branches.where((item) => item.id == branchId).firstOrNull;
    if (branch == null || branch.label.toLowerCase() == 'main') {
      return category.title;
    }
    if (category.id == SkillCategoryCatalog.coreId) {
      return branch.label;
    }
    return '${branch.label} ${category.title}';
  }

  static HomeSkillMomentum _momentumForExercise({
    required _ExercisePerformanceSnapshot performance,
    required ExerciseStatus? currentStatus,
    required ExerciseProgress? progressEntry,
    DateTime? now,
  }) {
    final recentPromotion = progressEntry != null &&
        currentStatus != ExerciseStatus.inactive &&
        (now ?? _dummyComparisonNow).difference(progressEntry.updatedAt) <=
            _recentStatusPromotionWindow;
    final delta =
        performance.currentWindowBest - performance.previousWindowBest;

    if (delta > 0) return HomeSkillMomentum.improving;

    if (recentPromotion) return HomeSkillMomentum.improving;

    if (delta < 0) return HomeSkillMomentum.stalled;

    return HomeSkillMomentum.steady;
  }

  static String _momentumNote({
    required HomeSkillMomentum momentum,
    required _ExercisePerformanceSnapshot performance,
  }) {
    switch (momentum) {
      case HomeSkillMomentum.improving:
        return 'Best set is up from the previous 14 days';
      case HomeSkillMomentum.stalled:
        return 'Best set is down from the previous 14 days';
      case HomeSkillMomentum.steady:
        return performance.personalBest == 0
            ? 'No sessions logged yet'
            : 'Best set is flat across both 14-day windows';
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

  static _ExercisePerformanceSnapshot _performanceSnapshotForExercise({
    required String exerciseId,
    required List<PastWorkout> workouts,
    required DateTime now,
  }) {
    final currentWindowStart =
        _dateOnly(now).subtract(const Duration(days: 13));
    final previousWindowEnd =
        currentWindowStart.subtract(const Duration(days: 1));
    final previousWindowStart =
        previousWindowEnd.subtract(const Duration(days: 13));
    var personalBest = 0;
    var currentWindowBest = 0;
    var previousWindowBest = 0;
    var isTimed = false;

    for (final workout in workouts) {
      final match = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (match == null || match.sets.isEmpty) continue;

      isTimed =
          isTimed || match.isTimed || match.sets.any((set) => set.isTimed);
      final bestSet = match.sets.fold<int>(
        0,
        (best, set) => set.value > best ? set.value : best,
      );
      if (bestSet > personalBest) {
        personalBest = bestSet;
      }

      final loggedAt = _dateOnly(workout.loggedAt);
      if (!_isOnOrAfter(loggedAt, previousWindowStart) ||
          !_isOnOrBefore(loggedAt, _dateOnly(now))) {
        continue;
      }

      if (_isOnOrAfter(loggedAt, currentWindowStart)) {
        if (bestSet > currentWindowBest) {
          currentWindowBest = bestSet;
        }
      } else if (_isOnOrBefore(loggedAt, previousWindowEnd)) {
        if (bestSet > previousWindowBest) {
          previousWindowBest = bestSet;
        }
      }
    }

    return _ExercisePerformanceSnapshot(
      personalBest: personalBest,
      currentWindowBest: currentWindowBest,
      previousWindowBest: previousWindowBest,
      isTimed: isTimed,
    );
  }

  static String _personalBestLabel(_ExercisePerformanceSnapshot performance) {
    if (performance.personalBest <= 0) return 'Best --';
    final suffix = performance.isTimed ? 's' : ' reps';
    return 'Best ${performance.personalBest}$suffix';
  }

  static String _deltaLabel(_ExercisePerformanceSnapshot performance) {
    final delta =
        performance.currentWindowBest - performance.previousWindowBest;
    if (delta == 0) return '0';
    final sign = delta > 0 ? '+' : '';
    final suffix = performance.isTimed ? 's' : '';
    return '$sign$delta$suffix';
  }

  static bool _isOnOrAfter(DateTime value, DateTime threshold) =>
      !value.isBefore(threshold);

  static bool _isOnOrBefore(DateTime value, DateTime threshold) =>
      !value.isAfter(threshold);

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class _ExercisePerformanceSnapshot {
  final int personalBest;
  final int currentWindowBest;
  final int previousWindowBest;
  final bool isTimed;

  const _ExercisePerformanceSnapshot({
    required this.personalBest,
    required this.currentWindowBest,
    required this.previousWindowBest,
    required this.isTimed,
  });

  const _ExercisePerformanceSnapshot.empty()
      : personalBest = 0,
        currentWindowBest = 0,
        previousWindowBest = 0,
        isTimed = false;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
