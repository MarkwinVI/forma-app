import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../home/home_dashboard_metrics.dart';
import '../home/live_workout_view.dart';
import '../home/session_overview_view.dart';
import '../skills/skill_tree_view.dart';
import 'widgets/skill_tree_progress_card.dart';
import 'widgets/today_workout_card.dart';

/// Progress tab — today's workout as a performance list (planned exercises
/// with last result and change vs the previous attempt), a coaching tip, then
/// every skill tree as a node map with the user's path highlighted.
class ProgressView extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onOpenSkillsTab;

  const ProgressView({
    super.key,
    this.isActive = false,
    this.onOpenSkillsTab,
  });

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final _progressService = ProgressService();
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  TrainingProgramLogicSnapshot? _logicSnapshot;

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
      final results = await Future.wait([
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
        _exerciseLogService.fetchPastWorkouts(userId),
      ]);

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
        _loading = false;
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

  _ProgressSnapshot? _buildSnapshot() {
    final snapshot = _logicSnapshot;
    if (snapshot == null) return null;

    final programType = snapshot.program.programType;
    final scheduleVariant = snapshot.program.scheduleVariant;
    final branchSelections = {
      ..._trainingProgramService.defaultBranchSelections(),
      ...snapshot.branchSelections,
    };
    final sessionItemsConfig = _sessionItemsConfigFor(snapshot.program);
    final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
      cycle: _trainingProgramService.scheduleCycleFor(
        programType: programType,
        scheduleVariant: scheduleVariant,
      ),
      nextStepIndex: snapshot.state.nextStepIndex,
      nextSessionType: snapshot.state.nextSessionType,
      lastWorkoutAt:
          _pastWorkouts.isEmpty ? null : _pastWorkouts.first.loggedAt,
    );
    final recommendation = _trainingProgramService.buildToday(
      progressMap: _progressMap,
      programType: programType,
      sessionType: schedule.effectiveSessionType,
      branchSelections: branchSelections,
      sessionItemsConfig: sessionItemsConfig,
    );

    return _ProgressSnapshot(
      recommendation: recommendation,
      metrics: HomeDashboardMetricsCalculator.build(
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
        goalSkillIds: snapshot.program.goalSkillIds,
        frequencyPerWeek: snapshot.program.frequencyPerWeek,
      ),
    );
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram program) {
    final raw = program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<void> _startWorkout(DailyTrainingRecommendation recommendation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => recommendation.isRestDay
            ? SessionOverviewView(recommendation: recommendation)
            : LiveWorkoutView(recommendation: recommendation),
      ),
    );
    // A finished workout changes today's card and the trees — re-fetch.
    await _loadData();
  }

  Future<void> _openSkillTree(String skillCategoryId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillTreeView(
          skillCategoryId: skillCategoryId,
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

  @override
  Widget build(BuildContext context) {
    final snapshot = _loading ? null : _buildSnapshot();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : RefreshIndicator(
                color: AppColors.accentPrimary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Text(
                          _headerDate(DateTime.now()).toUpperCase(),
                          style: GoogleFonts.robotoMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        child: !_hasProgram || snapshot == null
                            ? const _NoProgramCard()
                            : _buildSections(snapshot),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSections(_ProgressSnapshot snapshot) {
    final metrics = snapshot.metrics;
    final skills = metrics.journeySnapshot.closestSkills;
    final tip = _buildTip(metrics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        TodayWorkoutCard(
          summary: metrics.today,
          subtitle: _todaySubtitle(metrics),
          rows: _todayRows(metrics),
          onStart: () => _startWorkout(snapshot.recommendation),
        ),
        const SizedBox(height: 12),
        TipCard(highlight: tip.$1, body: tip.$2),
        const Padding(
          padding: EdgeInsets.only(top: 28, left: 2),
          child: Text(
            'Progress',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.96,
              height: 1.05,
            ),
          ),
        ),
        SectionHeader(
          title: 'Skill trees',
          sub: 'Every branch named — your path is highlighted',
          action: 'All trees',
          onAction: widget.onOpenSkillsTab,
        ),
        if (skills.isEmpty)
          const SurfaceCard(
            padding: EdgeInsets.all(18),
            child: Text(
              'Your program has no active skill progressions yet. '
              'Pick branches in your program settings to grow your trees.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          )
        else
          for (var index = 0; index < skills.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildTreeCard(skills[index], metrics),
          ],
      ],
    );
  }

  List<TodayWorkoutRow> _todayRows(HomeDashboardMetrics metrics) {
    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };
    final stalledNames = {
      for (final path in metrics.activeSkillPaths)
        if (path.momentum == HomeSkillMomentum.stalled)
          path.currentExerciseName,
    };

    return [
      for (final planned in metrics.today.plannedExercises)
        _rowFor(
          planned,
          perfByName[planned.name],
          stalledNames.contains(planned.name),
        ),
    ];
  }

  TodayWorkoutRow _rowFor(
    HomePlannedExerciseSummary planned,
    HomeExercisePerformance? perf,
    bool stalled,
  ) {
    final history = perf?.history ?? const <int>[];
    final unit = (perf?.isTimed ?? false) ? 's' : '';
    final delta = perf?.sessionDelta;

    return TodayWorkoutRow(
      name: planned.name,
      setsLabel: planned.targetLabel,
      stalled: stalled,
      lastLabel: history.isEmpty ? '—' : '${history.last}$unit',
      changeLabel: delta == null
          ? '—'
          : delta == 0
              ? '±0'
              : delta > 0
                  ? '+$delta$unit'
                  : '−${delta.abs()}$unit',
      changeDir: delta == null ? 0 : delta.sign,
    );
  }

  String _todaySubtitle(HomeDashboardMetrics metrics) {
    final summary = metrics.today;
    if (summary.isRestDay) {
      return 'Rest day — recovery keeps the split moving';
    }

    final count = '${summary.exerciseCount} exercise'
        '${summary.exerciseCount == 1 ? '' : 's'}';
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum == HomeSkillMomentum.stalled) {
        return '$count · targets your stalled ${path.skillTitle} node';
      }
    }
    return '$count · built from your current program';
  }

  /// (highlight, body) for the tip card, from the most pressing momentum
  /// signal across the active skill paths.
  (String, String) _buildTip(HomeDashboardMetrics metrics) {
    if (metrics.today.isRestDay) {
      return (
        'Rest is part of the program.',
        'Recovery today means better numbers in your next session.',
      );
    }

    final perfByName = {
      for (final perf in metrics.exercisePerformance) perf.exerciseName: perf,
    };
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum != HomeSkillMomentum.stalled) continue;
      final perf = perfByName[path.currentExerciseName];
      final at = perf != null && perf.history.isNotEmpty
          ? ' at ${perf.history.last}${perf.isTimed ? 's' : ' reps'}'
          : '';
      return (
        'Your ${path.currentExerciseName} has stalled$at.',
        "Focus on clean, full-range reps today — quality sets are what "
            'break the plateau.',
      );
    }
    for (final path in metrics.activeSkillPaths) {
      if (path.momentum != HomeSkillMomentum.improving) continue;
      return (
        'Your ${path.currentExerciseName} is trending up.',
        "Keep the momentum — hitting today's targets brings the next "
            'node closer.',
      );
    }
    return (
      'Consistency beats intensity.',
      "Show up for today's session and every tree on this page keeps "
          'growing.',
    );
  }

  Widget _buildTreeCard(
    JourneySkillProgressData skill,
    HomeDashboardMetrics metrics,
  ) {
    final category = SkillCategoryCatalog.findById(skill.skillCategoryId);
    if (category == null) return const SizedBox.shrink();

    var stalled = false;
    for (final path in metrics.activeSkillPaths) {
      if (path.skillCategoryId == skill.skillCategoryId &&
          path.branchId == skill.branchId) {
        stalled = path.momentum == HomeSkillMomentum.stalled;
        break;
      }
    }

    return SkillTreeProgressCard(
      skill: skill,
      category: category,
      progressMap: _progressMap,
      stalled: stalled,
      onTap: () => _openSkillTree(skill.skillCategoryId),
    );
  }
}

class _ProgressSnapshot {
  final DailyTrainingRecommendation recommendation;
  final HomeDashboardMetrics metrics;

  const _ProgressSnapshot({
    required this.recommendation,
    required this.metrics,
  });
}

class _NoProgramCard extends StatelessWidget {
  const _NoProgramCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: SurfaceCard(
        padding: EdgeInsets.all(18),
        child: Text(
          'Set up your training program on the Train tab to start '
          'tracking performance and growing your skill trees.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

String _headerDate(DateTime now) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}
