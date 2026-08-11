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

  const SkillWheelBundle({
    required this.progressMap,
    required this.progressEntries,
    required this.skillTracks,
    required this.logicSnapshot,
    required this.pastWorkouts,
    required this.families,
    required this.journeyByCategory,
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

/// Fetches progress, program logic, workout history and skill tracks, then
/// derives the wheel families and per-tree journey numbers from them.
Future<SkillWheelBundle> loadSkillWheelBundle(String userId) async {
  final progressService = ProgressService();
  final trainingProgramService = TrainingProgramService();
  final trainingProgramStoreService = TrainingProgramStoreService();
  final exerciseLogService = ExerciseLogService();
  final devClockService = DevClockService();

  await devClockService.loadOffset();
  final results = await Future.wait([
    progressService.fetchAll(userId),
    trainingProgramStoreService.fetchProgramLogic(userId),
    exerciseLogService.fetchPastWorkouts(userId),
  ]);
  // Best-effort: missing tracks shouldn't block the wheel.
  var skillTracks = const <SkillTrack>[];
  try {
    skillTracks = await SkillTrackService().fetchAll(userId);
  } catch (_) {
    // The wheel simply shows no tree as running.
  }

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

  final metrics = _buildMetrics(
    logicSnapshot: logicSnapshot,
    progressMap: progressMap,
    progressEntries: progressEntries,
    pastWorkouts: pastWorkouts,
    skillTracks: skillTracks,
    trainingProgramService: trainingProgramService,
    devClockService: devClockService,
  );

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
  );
}

HomeDashboardMetrics? _buildMetrics({
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
  final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
    cycle: trainingProgramService.scheduleCycleFor(
      programType: programType,
      scheduleVariant: scheduleVariant,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      dayMask: dayMask,
    ),
    nextStepIndex: snapshot.state.nextStepIndex,
    nextSessionType: snapshot.state.nextSessionType,
    lastWorkoutAt: pastWorkouts.isEmpty ? null : pastWorkouts.first.loggedAt,
    now: now,
  );
  final recommendation = trainingProgramService.buildToday(
    progressMap: progressMap,
    programType: programType,
    sessionType: schedule.effectiveSessionType,
    branchSelections: branchSelections,
    sessionItemsConfig: sessionItemsConfig,
    skillTracks: skillTracks,
    hasGym: programUsesGym(snapshot.program.variationRules),
  );

  return HomeDashboardMetricsCalculator.build(
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
}
