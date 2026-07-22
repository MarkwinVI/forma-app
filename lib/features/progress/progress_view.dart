import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/progression_event_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/progression_event_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../home/home_dashboard_metrics.dart';
import '../skills/skill_tree_view.dart';
import '../skills/skills_view.dart';
import 'widgets/achievements_card.dart';
import 'widgets/biggest_gain_card.dart';
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
  final _exerciseLogService = ExerciseLogService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();
  final _progressionEventService = ProgressionEventService();

  static const _maxAchievements = 6;

  bool _loading = true;
  bool _hasProgram = true;
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  List<PastWorkout> _pastWorkouts = const [];
  List<ProgressionEvent> _personalBests = const [];
  List<SkillTrack> _skillTracks = const [];
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
      // Best-effort: missing achievements shouldn't block the tab.
      var personalBests = const <ProgressionEvent>[];
      try {
        personalBests = (await _progressionEventService.fetchRecent(userId))
            .where(
              (event) => event.kind == ProgressionEventKind.personalBest,
            )
            .take(_maxAchievements)
            .toList();
      } catch (error, stackTrace) {
        debugPrint('Failed to load achievements: $error\n$stackTrace');
      }
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
        _personalBests = personalBests;
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
                      ScreenHeader(
                        title: 'Progress',
                        eyebrow: formatHeaderDate(DateTime.now()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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
    final skills = metrics.journeySnapshot.closestSkills;
    final biggestGain = BiggestGainData.compute(_pastWorkouts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (biggestGain != null) ...[
          const SizedBox(height: 16),
          BiggestGainCard(data: biggestGain, skills: skills),
        ],
        if (_personalBests.isNotEmpty) ...[
          const SectionHeader(
            title: 'Achievements',
            sub: 'Your latest personal bests',
          ),
          AchievementsCard(personalBests: _personalBests),
        ],
        SectionHeader(
          title: 'Skill trees',
          sub: 'Every branch named — your path is highlighted',
          action: 'All trees',
          onAction: _openAllTrees,
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
