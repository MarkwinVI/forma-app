import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../skills/skill_tree_view.dart';
import 'alternate_workout_options_view.dart';
import 'goal_skills_view.dart';
import 'home_dashboard_content.dart';
import 'home_dashboard_metrics.dart';
import 'home_empty_state.dart';
import 'program_setup_view.dart';
import 'journey_skill_detail_view.dart';
import 'live_workout_view.dart';
import 'program_overview_view.dart';
import 'session_overview_view.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  final bool isActive;

  const HomeView({
    super.key,
    this.onOpenSettings,
    this.isActive = false,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _progressService = ProgressService();
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  String? _scheduleVariant;
  Map<TrainingTrack, String> _branchSelections = {};
  RepGoalProfile _repGoalProfile = RepGoalProfile.balanced;
  Map<String, dynamic> _sessionItemsConfig = const {};
  int _frequencyPerWeek = 3;
  Map<String, dynamic>? _setupAnswers;
  int _nextStepIndex = 0;
  TrainingSessionType _nextSessionType = TrainingSessionType.fullBody;
  HomeScheduleResolution? _schedule;
  List<String> _goalSkillIds = const [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — e.g. after a dev reset from Settings the
    // dashboard would otherwise keep showing the deleted program.
    if (!oldWidget.isActive && widget.isActive) {
      _loadHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    final userId = AuthService().currentUser?.id;
    var progressMap = <String, ExerciseStatus>{};
    var progressEntries = <String, ExerciseProgress>{};
    var workouts = const <PastWorkout>[];
    TrainingProgramLogicSnapshot? logicSnapshot;
    var loadFailed = false;
    var hasProgram = true;

    if (userId != null) {
      try {
        final results = await Future.wait([
          _progressService.fetchAll(userId),
          _trainingProgramStoreService.fetchProgramLogic(userId),
          _exerciseLogService.fetchPastWorkouts(userId),
        ]);

        final progress = results[0] as List<ExerciseProgress>;
        logicSnapshot = results[1] as TrainingProgramLogicSnapshot?;
        workouts = results[2] as List<PastWorkout>;
        hasProgram = logicSnapshot != null;

        progressEntries = {
          for (final item in progress) item.exerciseId: item,
        };
        progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
      } catch (error, stackTrace) {
        // Fall back to default local state so the screen stays usable.
        debugPrint('Failed to load home data: $error\n$stackTrace');
        loadFailed = true;
      }
    }

    if (!mounted) return;

    if (loadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't load your training data. Pull down to retry.",
          ),
        ),
      );
    }

    final selectedProgramType =
        logicSnapshot?.program.programType ?? TrainingProgramType.fullBody;
    final scheduleVariant = logicSnapshot?.program.scheduleVariant;
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...?logicSnapshot?.branchSelections,
    };
    final repGoalProfile =
        logicSnapshot?.repGoalProfile ?? RepGoalProfile.balanced;
    final sessionItemsConfig = _sessionItemsConfigFor(logicSnapshot?.program);
    final frequencyPerWeek = logicSnapshot?.program.frequencyPerWeek ?? 3;
    final setupAnswers = _setupAnswersFor(logicSnapshot?.program);
    final nextStepIndex = logicSnapshot?.state.nextStepIndex ?? 0;
    final nextSessionType =
        logicSnapshot?.state.nextSessionType ?? TrainingSessionType.fullBody;
    final schedule = _resolveSchedule(
      programType: selectedProgramType,
      scheduleVariant: scheduleVariant,
      nextStepIndex: nextStepIndex,
      nextSessionType: nextSessionType,
      workouts: workouts,
    );
    final recommendation = _trainingProgramService.buildToday(
      progressMap: progressMap,
      programType: selectedProgramType,
      sessionType: schedule.effectiveSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
    );

    setState(() {
      _hasProgram = hasProgram;
      _progressMap = progressMap;
      _progressEntries = progressEntries;
      _pastWorkouts = workouts;
      _selectedProgramType = selectedProgramType;
      _scheduleVariant = scheduleVariant;
      _branchSelections = branchSelections;
      _repGoalProfile = repGoalProfile;
      _sessionItemsConfig = sessionItemsConfig;
      _frequencyPerWeek = frequencyPerWeek;
      _setupAnswers = setupAnswers;
      _nextStepIndex = nextStepIndex;
      _nextSessionType = nextSessionType;
      _schedule = schedule;
      _recommendation = recommendation;
      _goalSkillIds = logicSnapshot?.program.goalSkillIds ?? const [];
      _loading = false;
    });
  }

  /// Where the rolling split stands today (local time): whether today's
  /// session is already done and which step the dashboard should show, with
  /// past rest days rolled forward.
  HomeScheduleResolution _resolveSchedule({
    required TrainingProgramType programType,
    required String? scheduleVariant,
    required int nextStepIndex,
    required TrainingSessionType nextSessionType,
    required List<PastWorkout> workouts,
  }) {
    return HomeDashboardMetricsCalculator.resolveSchedule(
      cycle: _trainingProgramService.scheduleCycleFor(
        programType: programType,
        scheduleVariant: scheduleVariant,
      ),
      nextStepIndex: nextStepIndex,
      nextSessionType: nextSessionType,
      lastWorkoutAt: workouts.isEmpty ? null : workouts.first.loggedAt,
    );
  }

  Map<String, dynamic>? _setupAnswersFor(UserTrainingProgram? program) {
    final raw = program?.variationRules['program_setup_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<TrainingProgramLogicSnapshot> _updateProgramLogic({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
  }) async {
    final userId = AuthService().currentUser?.id;
    final effectiveSetupAnswers = setupAnswers ?? _setupAnswers;
    if (userId == null) {
      final snapshot = TrainingProgramLogicSnapshot(
        program: UserTrainingProgram(
          id: 'local',
          userId: '',
          programType: programType,
          scheduleVariant: _scheduleVariant,
          frequencyPerWeek: frequencyPerWeek ?? _frequencyPerWeek,
          variationRules: {
            'rep_goal_profile': repGoalProfile.dbValue,
            'session_items_v1': sessionItemsConfig,
            if (effectiveSetupAnswers != null)
              'program_setup_v1': effectiveSetupAnswers,
          },
          isActive: true,
        ),
        state: UserTrainingProgramState(
          id: 'local',
          programId: 'local',
          userId: '',
          nextStepIndex: _nextStepIndex,
          nextSessionType: _nextSessionType,
        ),
        branchSelections: branchSelections,
        repGoalProfile: repGoalProfile,
      );

      if (mounted) {
        setState(() {
          _selectedProgramType = programType;
          _branchSelections = branchSelections;
          _repGoalProfile = repGoalProfile;
          _sessionItemsConfig = sessionItemsConfig;
          _frequencyPerWeek = frequencyPerWeek ?? _frequencyPerWeek;
          _setupAnswers = effectiveSetupAnswers;
          _schedule = _resolveSchedule(
            programType: _selectedProgramType,
            scheduleVariant: _scheduleVariant,
            nextStepIndex: _nextStepIndex,
            nextSessionType: _nextSessionType,
            workouts: _pastWorkouts,
          );
          _recommendation = _trainingProgramService.buildToday(
            progressMap: _progressMap,
            programType: _selectedProgramType,
            sessionType: _schedule!.effectiveSessionType,
            branchSelections: _branchSelections,
            sessionItemsConfig: _sessionItemsConfig,
          );
        });
      }

      return snapshot;
    }

    final snapshot = await _trainingProgramStoreService.updateProgramLogic(
      userId: userId,
      programType: programType,
      branchSelections: branchSelections,
      repGoalProfile: repGoalProfile,
      sessionItemsConfig: sessionItemsConfig,
      frequencyPerWeek: frequencyPerWeek,
      setupAnswers: setupAnswers,
    );

    if (!mounted) return snapshot;

    setState(() {
      _hasProgram = true;
      _selectedProgramType = snapshot.program.programType;
      _scheduleVariant = snapshot.program.scheduleVariant;
      _branchSelections = {
        ..._trainingProgramService.defaultBranchSelections(),
        ...snapshot.branchSelections,
      };
      _repGoalProfile = snapshot.repGoalProfile;
      _sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
      _frequencyPerWeek = snapshot.program.frequencyPerWeek;
      _setupAnswers = _setupAnswersFor(snapshot.program);
      _nextStepIndex = snapshot.state.nextStepIndex;
      _nextSessionType = snapshot.state.nextSessionType;
      _schedule = _resolveSchedule(
        programType: _selectedProgramType,
        scheduleVariant: _scheduleVariant,
        nextStepIndex: _nextStepIndex,
        nextSessionType: _nextSessionType,
        workouts: _pastWorkouts,
      );
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _schedule!.effectiveSessionType,
        branchSelections: _branchSelections,
        sessionItemsConfig: _sessionItemsConfig,
      );
    });

    return snapshot;
  }

  Future<void> _openProgramSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          onComplete: _completeProgramSetup,
        ),
      ),
    );
    // Re-fetch so the dashboard reflects the freshly created program even if
    // the user abandoned the wizard midway on a stale state.
    await _loadHomeData();
  }

  Future<void> _completeProgramSetup(ProgramSetupResult result) async {
    await _updateProgramLogic(
      programType: result.split,
      branchSelections: _branchSelections.isEmpty
          ? _trainingProgramService.defaultBranchSelections()
          : _branchSelections,
      repGoalProfile: _repGoalProfile,
      sessionItemsConfig: _sessionItemsConfig,
      frequencyPerWeek: result.daysPerWeek,
      setupAnswers: result.toMap(),
    );
  }

  Future<void> _openProgramOverview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramOverviewView(
          initialLogic: _buildCurrentLogicSnapshot(),
          progressMap: _progressMap,
          onSave: ({
            required programType,
            required branchSelections,
            required repGoalProfile,
            required sessionItemsConfig,
            frequencyPerWeek,
            setupAnswers,
          }) {
            return _updateProgramLogic(
              programType: programType,
              branchSelections: branchSelections,
              repGoalProfile: repGoalProfile,
              sessionItemsConfig: sessionItemsConfig,
              frequencyPerWeek: frequencyPerWeek,
              setupAnswers: setupAnswers,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAlternateWorkoutOptions() async {
    final effectiveSessionType =
        _schedule?.effectiveSessionType ?? _nextSessionType;
    final sessionType = effectiveSessionType == TrainingSessionType.rest
        ? TrainingSessionType.fullBody
        : effectiveSessionType;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlternateWorkoutOptionsView(
          onOpenBlankWorkout: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveWorkoutView(
                  recommendation: DailyTrainingRecommendation(
                    programType: _selectedProgramType,
                    sessionType: sessionType,
                    sessionLabel: 'Blank Workout',
                    isRestDay: false,
                    items: const [],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPrimaryAction(DailyTrainingRecommendation recommendation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => recommendation.isRestDay
            ? SessionOverviewView(recommendation: recommendation)
            : LiveWorkoutView(recommendation: recommendation),
      ),
    );
  }

  void _openSessionOverview(DailyTrainingRecommendation recommendation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionOverviewView(recommendation: recommendation),
      ),
    );
  }

  Future<void> _openSkillPath(ActiveSkillPathData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillTreeView(
          skillCategoryId: data.skillCategoryId,
          progressMap: _progressMap,
          onProgressChanged: (exerciseId, status) {
            setState(() {
              final updated = ExerciseProgress(
                exerciseId: exerciseId,
                status: status,
                updatedAt: DateTime.now(),
              );
              _progressMap[exerciseId] = status;
              _progressEntries[exerciseId] = updated;
            });
          },
        ),
      ),
    );
  }

  Future<void> _openGoalPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalSkillsView(
          initialGoalIds: _goalSkillIds,
          onSave: (goalIds) async {
            final userId = AuthService().currentUser?.id;
            if (userId == null) {
              if (mounted) setState(() => _goalSkillIds = goalIds);
              return;
            }
            final program = await _trainingProgramStoreService.updateGoalSkills(
              userId: userId,
              goalSkillIds: goalIds,
            );
            if (!mounted) return;
            setState(() => _goalSkillIds = program.goalSkillIds);
          },
        ),
      ),
    );
  }

  Future<void> _openGoalSkillTree(HomeGoalSkillData goal) async {
    if (goal.skillCategoryId.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillTreeView(
          skillCategoryId: goal.skillCategoryId,
          progressMap: _progressMap,
          onProgressChanged: (exerciseId, status) {
            setState(() {
              _progressMap[exerciseId] = status;
              _progressEntries[exerciseId] = ExerciseProgress(
                exerciseId: exerciseId,
                status: status,
                updatedAt: DateTime.now(),
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _openJourneySkill(JourneySkillProgressData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JourneySkillDetailView(
          skill: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final schedule = _schedule;
    final metrics = recommendation == null || schedule == null
        ? null
        : HomeDashboardMetricsCalculator.build(
            recommendation: recommendation,
            trainingProgramService: _trainingProgramService,
            programType: _selectedProgramType,
            scheduleVariant: _scheduleVariant,
            schedule: schedule,
            branchSelections: _branchSelections,
            sessionItemsConfig: _sessionItemsConfig,
            progressMap: _progressMap,
            progressEntries: _progressEntries,
            workouts: _pastWorkouts,
            goalSkillIds: _goalSkillIds,
            frequencyPerWeek: _frequencyPerWeek,
          );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading || recommendation == null || metrics == null
            ? const Center(child: LoadingIndicator())
            : !_hasProgram
                ? RefreshIndicator(
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.surface,
                    onRefresh: _loadHomeData,
                    child: HomeEmptyState(
                      onBuildProgram: _openProgramSetup,
                      onOpenSettings: widget.onOpenSettings ?? () {},
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.bgTertiary,
                    onRefresh: _loadHomeData,
                    child: HomeDashboardContent(
                      todaySummary: metrics.today,
                      streak: metrics.streak,
                      programLabel: '${_selectedProgramType.label}'
                          ' · $_frequencyPerWeek-day split',
                      journeySnapshot: metrics.journeySnapshot,
                      activeSkillPaths: metrics.activeSkillPaths,
                      exercisePerformance: metrics.exercisePerformance,
                      goalSkills: metrics.goalSkills,
                      nodesClearedThisMonth: metrics.nodesClearedThisMonth,
                      showGettingStarted: _pastWorkouts.isEmpty,
                      onPrimaryAction: () => _openPrimaryAction(recommendation),
                      onSecondaryAction: _openAlternateWorkoutOptions,
                      onViewExercises: () =>
                          _openSessionOverview(recommendation),
                      onOpenSettings: widget.onOpenSettings ?? () {},
                      onOpenProgramSettings: _openProgramOverview,
                      onEditGoals: _openGoalPicker,
                      onOpenJourneySkill: _openJourneySkill,
                      onOpenSkillPath: _openSkillPath,
                      onOpenGoalSkill: _openGoalSkillTree,
                    ),
                  ),
      ),
    );
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram? program) {
    final raw = program?.variationRules['session_items_v1'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  TrainingProgramLogicSnapshot _buildCurrentLogicSnapshot() {
    return TrainingProgramLogicSnapshot(
      program: UserTrainingProgram(
        id: 'local',
        userId: '',
        programType: _selectedProgramType,
        scheduleVariant: _scheduleVariant,
        frequencyPerWeek: _frequencyPerWeek,
        variationRules: {
          'rep_goal_profile': _repGoalProfile.dbValue,
          'session_items_v1': _sessionItemsConfig,
          if (_setupAnswers != null) 'program_setup_v1': _setupAnswers,
        },
        isActive: true,
      ),
      state: UserTrainingProgramState(
        id: 'local',
        programId: 'local',
        userId: '',
        nextStepIndex: _nextStepIndex,
        nextSessionType: _nextSessionType,
      ),
      branchSelections: _branchSelections,
      repGoalProfile: _repGoalProfile,
    );
  }
}
