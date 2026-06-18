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
import 'home_dashboard_content.dart';
import 'home_dashboard_metrics.dart';
import 'live_workout_view.dart';
import 'program_overview_view.dart';
import 'session_overview_view.dart';

const _homeBg = Color(0xFF161618);

class HomeView extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const HomeView({
    super.key,
    this.onOpenSettings,
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
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  String? _scheduleVariant;
  Map<TrainingTrack, String> _branchSelections = {};
  RepGoalProfile _repGoalProfile = RepGoalProfile.balanced;
  Map<String, dynamic> _sessionItemsConfig = const {};
  int _nextStepIndex = 0;
  TrainingSessionType _nextSessionType = TrainingSessionType.fullBody;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final userId = AuthService().currentUser?.id;
    var progressMap = <String, ExerciseStatus>{};
    var progressEntries = <String, ExerciseProgress>{};
    var workouts = const <PastWorkout>[];
    TrainingProgramLogicSnapshot? logicSnapshot;

    if (userId != null) {
      try {
        final results = await Future.wait([
          _progressService.fetchAll(userId),
          _trainingProgramStoreService.getOrCreateProgramLogic(userId),
          _exerciseLogService.fetchPastWorkouts(userId),
        ]);

        final progress = results[0] as List<ExerciseProgress>;
        logicSnapshot = results[1] as TrainingProgramLogicSnapshot;
        workouts = results[2] as List<PastWorkout>;

        progressEntries = {
          for (final item in progress) item.exerciseId: item,
        };
        progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
      } catch (_) {
        // Keep the widget usable with default local fallback state.
      }
    }

    if (!mounted) return;

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
    final nextStepIndex = logicSnapshot?.state.nextStepIndex ?? 0;
    final nextSessionType =
        logicSnapshot?.state.nextSessionType ?? TrainingSessionType.fullBody;
    final recommendation = _trainingProgramService.buildToday(
      progressMap: progressMap,
      programType: selectedProgramType,
      sessionType: nextSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
    );

    setState(() {
      _progressMap = progressMap;
      _progressEntries = progressEntries;
      _pastWorkouts = workouts;
      _selectedProgramType = selectedProgramType;
      _scheduleVariant = scheduleVariant;
      _branchSelections = branchSelections;
      _repGoalProfile = repGoalProfile;
      _sessionItemsConfig = sessionItemsConfig;
      _nextStepIndex = nextStepIndex;
      _nextSessionType = nextSessionType;
      _recommendation = recommendation;
      _loading = false;
    });
  }

  Future<TrainingProgramLogicSnapshot> _updateProgramLogic({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      final snapshot = TrainingProgramLogicSnapshot(
        program: UserTrainingProgram(
          id: 'local',
          userId: '',
          programType: programType,
          scheduleVariant: _scheduleVariant,
          frequencyPerWeek: 3,
          variationRules: {
            'rep_goal_profile': repGoalProfile.dbValue,
            'session_items_v1': sessionItemsConfig,
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
          _recommendation = _trainingProgramService.buildToday(
            progressMap: _progressMap,
            programType: _selectedProgramType,
            sessionType: _nextSessionType,
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
    );

    if (!mounted) return snapshot;

    setState(() {
      _selectedProgramType = snapshot.program.programType;
      _scheduleVariant = snapshot.program.scheduleVariant;
      _branchSelections = {
        ..._trainingProgramService.defaultBranchSelections(),
        ...snapshot.branchSelections,
      };
      _repGoalProfile = snapshot.repGoalProfile;
      _sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
      _nextStepIndex = snapshot.state.nextStepIndex;
      _nextSessionType = snapshot.state.nextSessionType;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
        branchSelections: _branchSelections,
        sessionItemsConfig: _sessionItemsConfig,
      );
    });

    return snapshot;
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
          }) {
            return _updateProgramLogic(
              programType: programType,
              branchSelections: branchSelections,
              repGoalProfile: repGoalProfile,
              sessionItemsConfig: sessionItemsConfig,
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

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final metrics = recommendation == null
        ? null
        : HomeDashboardMetricsCalculator.build(
            recommendation: recommendation,
            trainingProgramService: _trainingProgramService,
            programType: _selectedProgramType,
            scheduleVariant: _scheduleVariant,
            nextStepIndex: _nextStepIndex,
            nextSessionType: _nextSessionType,
            branchSelections: _branchSelections,
            sessionItemsConfig: _sessionItemsConfig,
            progressMap: _progressMap,
            progressEntries: _progressEntries,
            workouts: _pastWorkouts,
          );

    return Scaffold(
      backgroundColor: _homeBg,
      body: SafeArea(
        child: _loading || recommendation == null || metrics == null
            ? const Center(child: LoadingIndicator())
            : RefreshIndicator(
                color: AppColors.accentPrimary,
                backgroundColor: AppColors.bgTertiary,
                onRefresh: _loadHomeData,
                child: HomeDashboardContent(
                  todaySummary: metrics.today,
                  weekStrip: metrics.weekStrip,
                  journeySnapshot: metrics.journeySnapshot,
                  activeSkillPaths: metrics.activeSkillPaths,
                  onPrimaryAction: () => _openPrimaryAction(recommendation),
                  onOpenSettings: widget.onOpenSettings ?? () {},
                  onOpenProgramSettings: _openProgramOverview,
                  onOpenSkillPath: _openSkillPath,
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
        frequencyPerWeek: 3,
        variationRules: {
          'rep_goal_profile': _repGoalProfile.dbValue,
          'session_items_v1': _sessionItemsConfig,
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
