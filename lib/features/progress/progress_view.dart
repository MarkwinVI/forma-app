import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/no_program_state.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../home/home_dashboard_metrics.dart';
import '../home/program_day_items.dart';
import '../home/program_setup_completion.dart';
import '../home/program_setup_view.dart';
import 'skill_wheel_data.dart';
import 'widgets/skill_wheel.dart';
import 'widgets/skill_wheel_screen.dart';

/// Progress tab — every skill tree on one radial wheel. Tap a family to fly
/// in, swipe up/down to spin between families, swipe left/right to walk the
/// steps, tap the background to pull back out.
class ProgressView extends StatefulWidget {
  final bool isActive;

  const ProgressView({
    super.key,
    this.isActive = false,
  });

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final _progressService = ProgressService();
  final _devClockService = DevClockService();
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  List<SkillTrack> _skillTracks = const [];
  TrainingProgramLogicSnapshot? _logicSnapshot;

  List<WheelFamily> _families = const [];
  Map<String, JourneySkillProgressData> _journeyByCategory = const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — workouts logged or nodes cleared elsewhere
    // would otherwise leave the trees showing stale statuses.
    if (!oldWidget.isActive && widget.isActive) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      await _devClockService.loadOffset();
      final results = await Future.wait([
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
        _exerciseLogService.fetchPastWorkouts(userId),
      ]);
      // Best-effort: missing tracks shouldn't block the tab.
      var skillTracks = const <SkillTrack>[];
      try {
        skillTracks = await SkillTrackService().fetchAll(userId);
      } catch (error, stackTrace) {
        debugPrint('Failed to load skill tracks: $error\n$stackTrace');
      }

      if (!mounted) return;
      final progress = results[0] as List<ExerciseProgress>;
      setState(() {
        _progressEntries = {
          for (final item in progress) item.exerciseId: item,
        };
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
        _logicSnapshot = results[1] as TrainingProgramLogicSnapshot?;
        _hasProgram = _logicSnapshot != null;
        _pastWorkouts = results[2] as List<PastWorkout>;
        _skillTracks = skillTracks;
        _loading = false;
        _rebuildDerived();
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load progress data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your progress. Pull down to retry."),
        ),
      );
    }
  }

  /// Families for the wheel plus the per-tree journey numbers, rebuilt
  /// whenever the underlying data changes.
  void _rebuildDerived() {
    _families = buildWheelFamilies(
      progressMap: _progressMap,
      skillTracks: _skillTracks,
    );
    final metrics = _buildMetrics();
    _journeyByCategory = {
      if (metrics != null)
        for (final skill in metrics.journeySnapshot.closestSkills)
          skill.skillCategoryId: skill,
    };
  }

  HomeDashboardMetrics? _buildMetrics() {
    final snapshot = _logicSnapshot;
    if (snapshot == null) return null;

    final programType = snapshot.program.programType;
    final scheduleVariant = snapshot.program.scheduleVariant;
    final now = _devClockService.now();
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...snapshot.branchSelections,
      ..._trainingProgramService.laneSelectionsFromTracks(_skillTracks),
    };
    final sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
    final dayMask =
        TrainingScheduleService.dayMaskFrom(snapshot.program.variationRules);
    final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
      cycle: _trainingProgramService.scheduleCycleFor(
        programType: programType,
        scheduleVariant: scheduleVariant,
        frequencyPerWeek: snapshot.program.frequencyPerWeek,
        dayMask: dayMask,
      ),
      nextStepIndex: snapshot.state.nextStepIndex,
      nextSessionType: snapshot.state.nextSessionType,
      lastWorkoutAt:
          _pastWorkouts.isEmpty ? null : _pastWorkouts.first.loggedAt,
      now: now,
    );
    final recommendation = _trainingProgramService.buildToday(
      progressMap: _progressMap,
      programType: programType,
      sessionType: schedule.effectiveSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      skillTracks: _skillTracks,
      hasGym: programUsesGym(snapshot.program.variationRules),
    );

    return HomeDashboardMetricsCalculator.build(
      recommendation: recommendation,
      trainingProgramService: _trainingProgramService,
      programType: programType,
      scheduleVariant: scheduleVariant,
      schedule: schedule,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
      progressMap: _progressMap,
      progressEntries: _progressEntries,
      workouts: _pastWorkouts,
      skillTracks: _skillTracks,
      goalSkillIds: snapshot.program.goalSkillIds,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      dayMask: dayMask,
      now: now,
    );
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram program) {
    final raw = program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<void> _openProgramSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          progressMap: _progressMap,
          onComplete: _completeProgramSetup,
        ),
      ),
    );
    await _loadData();
  }

  Future<void> _completeProgramSetup(ProgramSetupResult result) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    await completeProgramSetup(
      userId: userId,
      result: result,
      trainingProgramService: _trainingProgramService,
      storeService: _trainingProgramStoreService,
    );
    await _loadData();
  }

  void _openExercise(WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailView(
          exercise: exercise,
          skillCategoryId: exercise.skillCategoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empty = !_loading && (!_hasProgram || _families.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : empty
                ? _ProgressEmptyState(onCreateProgram: _openProgramSetup)
                : SkillWheelScreen(
                    families: _families,
                    journeyByCategory: _journeyByCategory,
                    onOpenExercise: _openExercise,
                  ),
      ),
    );
  }
}

/// Progress before any training: the six movement paths named, none of them
/// started, framed as what the tab will show rather than what it lacks.
class _ProgressEmptyState extends StatelessWidget {
  final VoidCallback onCreateProgram;

  const _ProgressEmptyState({required this.onCreateProgram});

  static const _paths = [
    ExerciseCategory.horizontalPush,
    ExerciseCategory.verticalPush,
    ExerciseCategory.horizontalPull,
    ExerciseCategory.verticalPull,
    ExerciseCategory.squat,
    ExerciseCategory.core,
  ];

  @override
  Widget build(BuildContext context) {
    return NoProgramState(
      title: 'See how your strength develops',
      sub: 'As you train and hit your rep targets, you’ll move along each '
          'movement path and unlock harder exercises.',
      onCreateProgram: onCreateProgram,
      children: [
        const TypeSectionLabel('Movement paths'),
        for (var i = 0; i < _paths.length; i++)
          GhostRow(
            name: programPatternLabel(_paths[i]),
            note: 'NOT STARTED',
            nameSize: 19,
            last: i == _paths.length - 1,
          ),
      ],
    );
  }
}
