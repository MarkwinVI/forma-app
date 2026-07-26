import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
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
import '../home/home_dashboard_metrics.dart';
import '../skills/skill_tree_view.dart';
import '../skills/skills_view.dart';
import 'widgets/skill_tree_progress_card.dart';

/// Progress tab — every skill tree as a node map with the user's path
/// highlighted and a node-anchored rail toward the next unlock.
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

  /// Null until the user touches a card — the closest tree is expanded by
  /// default, everything else folded.
  Set<String>? _expandedTrees;
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
    final schedule = HomeDashboardMetricsCalculator.resolveSchedule(
      cycle: _trainingProgramService.scheduleCycleFor(
        programType: programType,
        scheduleVariant: scheduleVariant,
        frequencyPerWeek: snapshot.program.frequencyPerWeek,
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
      goalSkillIds: snapshot.program.goalSkillIds,
      frequencyPerWeek: snapshot.program.frequencyPerWeek,
      now: now,
    );
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram program) {
    final raw = program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<void> _openAllTrees() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SkillsView()),
    );
    // Statuses may have changed while browsing the trees.
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
    final metrics = _loading ? null : _buildMetrics();

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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        child: !_hasProgram || metrics == null
                            ? const _NoProgramCard()
                            : _buildSections(metrics),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSections(HomeDashboardMetrics metrics) {
    // closestSkills is ordered by how close each tree is to its next unlock,
    // so the first one is the tree that starts out expanded.
    final trees = <({JourneySkillProgressData skill, SkillCategory category})>[
      for (final skill in metrics.journeySnapshot.closestSkills)
        if (SkillCategoryCatalog.findById(skill.skillCategoryId)
            case final category?)
          (skill: skill, category: category),
    ];
    final expandedKeys = _expandedTrees ??
        {if (trees.isNotEmpty) _treeKey(trees.first.skill)};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Skill roadmap',
          action: 'View all',
          onAction: _openAllTrees,
        ),
        if (trees.isEmpty)
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
          for (final tree in trees) ...[
            if (tree != trees.first) const SizedBox(height: 12),
            SkillTreeProgressCard(
              key: ValueKey(_treeKey(tree.skill)),
              skill: tree.skill,
              category: tree.category,
              progressMap: _progressMap,
              stalled: _isStalled(tree.skill, metrics),
              expanded: expandedKeys.contains(_treeKey(tree.skill)),
              onToggleExpanded: () => _toggleTree(tree.skill, expandedKeys),
              onOpenTree: () => _openSkillTree(tree.skill.skillCategoryId),
            ),
          ],
      ],
    );
  }

  /// Cards are identified by category + branch: the same tree can appear on
  /// two branches, and each keeps its own expanded state.
  String _treeKey(JourneySkillProgressData skill) =>
      '${skill.skillCategoryId}:${skill.branchId}';

  void _toggleTree(JourneySkillProgressData skill, Set<String> current) {
    final key = _treeKey(skill);
    setState(() {
      _expandedTrees = {...current};
      if (!_expandedTrees!.remove(key)) _expandedTrees!.add(key);
    });
  }

  bool _isStalled(
    JourneySkillProgressData skill,
    HomeDashboardMetrics metrics,
  ) {
    for (final path in metrics.activeSkillPaths) {
      if (path.skillCategoryId == skill.skillCategoryId &&
          path.branchId == skill.branchId) {
        return path.momentum == HomeSkillMomentum.stalled;
      }
    }
    return false;
  }
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
