import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../home/home_dashboard_metrics.dart';
import 'performance_overview.dart';
import 'skill_wheel_data.dart';
import 'widgets/skill_wheel.dart';

/// Everything a skill-wheel screen needs, fetched and derived in one place —
/// the Progress tab and the Program tab's wheel page share it, so the two
/// wheels can never drift apart on how statuses or journey numbers are read.
class SkillWheelBundle {
  final Map<String, ExerciseStatus> progressMap;
  final Map<String, ExerciseProgress> progressEntries;
  final List<SkillTrack> skillTracks;
  final TrainingProgramLogicSnapshot? logicSnapshot;
  final List<PastWorkout> pastWorkouts;
  final List<WheelFamily> families;
  final Map<String, JourneySkillProgressData> journeyByCategory;

  /// MY PERFORMANCE: every exercise in the program's workout lists,
  /// classified by how its best set moved. Null without a program.
  final PerformanceOverview? performance;

  const SkillWheelBundle({
    required this.progressMap,
    required this.progressEntries,
    required this.skillTracks,
    required this.logicSnapshot,
    required this.pastWorkouts,
    required this.families,
    required this.journeyByCategory,
    required this.performance,
  });

  bool get hasProgram => logicSnapshot != null;

  /// Categories with a progression running — the trees the wheel names in
  /// blue.
  Set<String> get activeCategoryIds => {
        for (final track in skillTracks)
          if (track.included) track.skillCategoryId,
      };

  /// Trees behind an unmet prerequisite, with what unlocks them.
  Map<String, WheelTreeLock> get treeLocks => computeTreeLocks(progressMap);
}

Future<SkillWheelBundle>? _warmBundle;

/// Started by main() during the splash animation, so the landing tab's data
/// is already in flight — usually finished — by the time the shell builds.
void warmSkillWheelBundle(String userId) {
  final future = loadSkillWheelBundle(userId);
  _warmBundle = future;
  // A failed warm-up quietly withdraws itself; the tab then runs its own
  // fresh load with its normal error handling.
  future.then<void>((_) {}, onError: (Object _) {
    if (identical(_warmBundle, future)) _warmBundle = null;
  });
}

/// Hands the warmed bundle to its one consumer — the Progress tab's first
/// load. Take-once, so a later refresh can never see startup-stale data.
Future<SkillWheelBundle>? takeWarmSkillWheelBundle() {
  final future = _warmBundle;
  _warmBundle = null;
  return future;
}

/// Fetches progress, program logic, workout history and skill tracks, then
/// derives the wheel families and per-tree journey numbers from them.
Future<SkillWheelBundle> loadSkillWheelBundle(String userId) async {
  final progressService = ProgressService();
  final trainingProgramService = TrainingProgramService();
  final trainingProgramStoreService = TrainingProgramStoreService();
  final exerciseLogService = ExerciseLogService();
  final devClockService = DevClockService();

  final results = await Future.wait([
    progressService.fetchAll(userId),
    trainingProgramStoreService.fetchProgramLogic(userId),
    exerciseLogService.fetchPastWorkouts(userId),
    // Best-effort: missing tracks shouldn't block the wheel — it simply
    // shows no tree as running.
    SkillTrackService()
        .fetchAll(userId)
        .catchError((Object _) => const <SkillTrack>[]),
    devClockService.loadOffset(),
  ]);
  final skillTracks = results[3] as List<SkillTrack>;

  final progress = results[0] as List<ExerciseProgress>;
  final progressEntries = {
    for (final item in progress) item.exerciseId: item,
  };
  final progressMap = {
    for (final item in progress) item.exerciseId: item.status,
  };
  final logicSnapshot = results[1] as TrainingProgramLogicSnapshot?;
  final pastWorkouts = results[2] as List<PastWorkout>;

  final families = buildWheelFamilies(
    progressMap: progressMap,
    skillTracks: skillTracks,
  );

  final derived = _buildDerived(
    logicSnapshot: logicSnapshot,
    progressMap: progressMap,
    progressEntries: progressEntries,
    pastWorkouts: pastWorkouts,
    skillTracks: skillTracks,
    trainingProgramService: trainingProgramService,
    devClockService: devClockService,
  );
  final metrics = derived?.metrics;

  return SkillWheelBundle(
    progressMap: progressMap,
    progressEntries: progressEntries,
    skillTracks: skillTracks,
    logicSnapshot: logicSnapshot,
    pastWorkouts: pastWorkouts,
    families: families,
    journeyByCategory: {
      if (metrics != null)
        for (final skill in metrics.journeySnapshot.closestSkills)
          skill.skillCategoryId: skill,
    },
    performance: derived?.performance,
  );
}

({HomeDashboardMetrics metrics, PerformanceOverview performance})?
    _buildDerived({
  required TrainingProgramLogicSnapshot? logicSnapshot,
  required Map<String, ExerciseStatus> progressMap,
  required Map<String, ExerciseProgress> progressEntries,
  required List<PastWorkout> pastWorkouts,
  required List<SkillTrack> skillTracks,
  required TrainingProgramService trainingProgramService,
  required DevClockService devClockService,
}) {
  final snapshot = logicSnapshot;
  if (snapshot == null) return null;

  final programType = snapshot.program.programType;
  final scheduleVariant = snapshot.program.scheduleVariant;
  final now = devClockService.now();
  final branchSelections = {
    ...trainingProgramService.defaultBranchSelections(),
    ...snapshot.branchSelections,
    ...trainingProgramService.laneSelectionsFromTracks(skillTracks),
  };
  final rawSessionItems = snapshot.program.variationRules['session_items_v1'];
  final sessionItemsConfig = rawSessionItems is Map
      ? Map<String, dynamic>.from(rawSessionItems)
      : const <String, dynamic>{};
  final dayMask =
      TrainingScheduleService.dayMaskFrom(snapshot.program.variationRules);
  final cycle = trainingProgramService.scheduleCycleFor(
    programType: programType,
    scheduleVariant: scheduleVariant,
    frequencyPerWeek: snapshot.program.frequencyPerWeek,
    dayMask: dayMask,
  );
  final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
    cycle: cycle,
    nextStepIndex: snapshot.state.nextStepIndex,
    nextSessionType: snapshot.state.nextSessionType,
    lastWorkoutAt: pastWorkouts.isEmpty ? null : pastWorkouts.first.loggedAt,
    now: now,
  );
  final hasGym = programUsesGym(snapshot.program.variationRules);
  final recommendation = trainingProgramService.buildToday(
    progressMap: progressMap,
    programType: programType,
    sessionType: schedule.effectiveSessionType,
    branchSelections: branchSelections,
    sessionItemsConfig: sessionItemsConfig,
    skillTracks: skillTracks,
    hasGym: hasGym,
  );

  // Every exercise across the program's workout lists — one build per
  // session type in the cycle, deduped. Removing or replacing an exercise
  // in the workout editor removes it here.
  final activeExercises = <ActivePerformanceExercise>[];
  final seenExerciseIds = <String>{};
  final sessionTypes = <TrainingSessionType>{
    for (final type in cycle)
      if (type != TrainingSessionType.rest) type,
  };
  for (final type in sessionTypes) {
    final session = type == schedule.effectiveSessionType
        ? recommendation
        : trainingProgramService.buildToday(
            progressMap: progressMap,
            programType: programType,
            sessionType: type,
            branchSelections: branchSelections,
            sessionItemsConfig: sessionItemsConfig,
            skillTracks: skillTracks,
            hasGym: hasGym,
          );
    for (final item in session.items) {
      if (seenExerciseIds.add(item.exercise.id)) {
        activeExercises.add(ActivePerformanceExercise(
          exerciseId: item.exercise.id,
          exerciseName: item.exercise.name,
          isTimed: item.exercise.isTimed,
        ));
      }
    }
  }

  final performance = buildPerformanceOverview(
    activeExercises: activeExercises,
    workouts: pastWorkouts,
    now: now,
  );

  final metrics = HomeDashboardMetricsCalculator.build(
    recommendation: recommendation,
    trainingProgramService: trainingProgramService,
    programType: programType,
    scheduleVariant: scheduleVariant,
    schedule: schedule,
    branchSelections: branchSelections,
    sessionItemsConfig: sessionItemsConfig,
    progressMap: progressMap,
    progressEntries: progressEntries,
    workouts: pastWorkouts,
    skillTracks: skillTracks,
    goalSkillIds: snapshot.program.goalSkillIds,
    frequencyPerWeek: snapshot.program.frequencyPerWeek,
    dayMask: dayMask,
    now: now,
  );

  return (metrics: metrics, performance: performance);
}
