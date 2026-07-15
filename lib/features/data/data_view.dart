import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
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
import '../settings/settings_view.dart';
import '../skills/skill_tree_view.dart';
import 'calendar_view.dart';
import 'exercises_browse_view.dart';
import 'past_workout_detail_view.dart';
import 'workout_calendar_metrics.dart';

class DataView extends StatefulWidget {
  final bool isActive;

  const DataView({
    super.key,
    this.isActive = false,
  });

  @override
  State<DataView> createState() => _DataViewState();
}

class _DataViewState extends State<DataView> {
  final _exerciseLogService = ExerciseLogService();
  final _progressService = ProgressService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  String? _error;
  List<PastWorkout> _workouts = const [];
  Map<String, ExerciseStatus> _progressMap = {};
  Map<String, ExerciseProgress> _progressEntries = {};
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  Map<TrainingTrack, String> _branchSelections = {};
  Map<String, dynamic> _sessionItemsConfig = const {};
  List<ActiveSkillPathData> _activeSkillPaths = const [];
  int _weeklyGoal = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DataView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sign in to see workout history.';
        _workouts = const [];
        _activeSkillPaths = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _exerciseLogService.fetchPastWorkouts(userId),
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
      ]);
      final workouts = results[0] as List<PastWorkout>;
      final progress = results[1] as List<ExerciseProgress>;
      final logicSnapshot = results[2] as TrainingProgramLogicSnapshot?;
      final progressEntries = {
        for (final item in progress) item.exerciseId: item,
      };
      final progressMap = {
        for (final item in progress) item.exerciseId: item.status,
      };
      final branchSelections = {
        ..._trainingProgramService.defaultBranchSelections(),
        ...?logicSnapshot?.branchSelections,
      };
      final programType =
          logicSnapshot?.program.programType ?? TrainingProgramType.fullBody;
      final sessionItemsConfig = _sessionItemsConfigFor(logicSnapshot?.program);
      // No training program yet — show empty skill paths instead of
      // creating a default program behind the user's back.
      final activeSkillPaths = logicSnapshot == null
          ? const <ActiveSkillPathData>[]
          : HomeDashboardMetricsCalculator.buildActiveSkillPathData(
              trainingProgramService: _trainingProgramService,
              programType: programType,
              branchSelections: branchSelections,
              sessionItemsConfig: sessionItemsConfig,
              progressMap: progressMap,
              progressEntries: progressEntries,
              workouts: workouts,
            );

      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _progressMap = progressMap;
        _progressEntries = progressEntries;
        _selectedProgramType = programType;
        _branchSelections = branchSelections;
        _sessionItemsConfig = sessionItemsConfig;
        _activeSkillPaths = activeSkillPaths;
        _weeklyGoal = logicSnapshot?.program.frequencyPerWeek ?? 3;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load workouts.';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _sessionItemsConfigFor(UserTrainingProgram? program) {
    final raw = program?.variationRules['session_items_v1'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
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
              _activeSkillPaths =
                  HomeDashboardMetricsCalculator.buildActiveSkillPathData(
                trainingProgramService: _trainingProgramService,
                programType: _selectedProgramType,
                branchSelections: _branchSelections,
                sessionItemsConfig: _sessionItemsConfig,
                progressMap: _progressMap,
                progressEntries: _progressEntries,
                workouts: _workouts,
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _openWorkout(PastWorkout workout) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
    if (deleted == true) {
      await _loadData();
    }
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarView(
          workouts: _workouts,
          weeklyGoal: _weeklyGoal,
          onDataChanged: _loadData,
        ),
      ),
    );
  }

  void _openExercises() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisesBrowseView(workouts: _workouts),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  void _openAllSessions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AllSessionsView(
          workouts: _workouts,
          onDataChanged: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Profile',
                  actions: [
                    HeaderCircleButton(
                      icon: Icons.settings_outlined,
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DataStateMessage(
                    icon: Icons.error_outline_rounded,
                    title: _error!,
                    body: 'Pull down to try again.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList.list(
                    children: _buildHubContent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHubContent() {
    final metrics = WorkoutCalendarMetrics(
      workouts: _workouts,
      weeklyGoal: _weeklyGoal,
    );
    final recentWorkouts = _workouts.take(3).toList();

    return [
      _CalendarMiniCard(metrics: metrics, onTap: _openCalendar),
      _TrendCard(paths: _activeSkillPaths, onOpenPath: _openSkillPath),
      SectionHeader(
        title: 'Recent sessions',
        action: _workouts.length > 3 ? 'View all' : null,
        onAction: _workouts.length > 3 ? _openAllSessions : null,
      ),
      if (recentWorkouts.isEmpty)
        const SurfaceCard(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Text(
            'Saved workouts will appear here with every exercise and set.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        )
      else
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < recentWorkouts.length; i++)
                _SessionRow(
                  workout: recentWorkouts[i],
                  showDivider: i > 0,
                  onTap: () => _openWorkout(recentWorkouts[i]),
                ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      SurfaceCard(
        onTap: _openExercises,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            IconTile(
              icon: Icons.fitness_center_rounded,
              size: 36,
              tint: true,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Browse all exercises',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    ];
  }
}

// ── Calendar widget card ──────────────────────────────────────────────

class _CalendarMiniCard extends StatelessWidget {
  final WorkoutCalendarMetrics metrics;
  final VoidCallback onTap;

  const _CalendarMiniCard({
    required this.metrics,
    required this.onTap,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthName = _monthNames[month.month - 1];
    final streak = metrics.currentStreakWeeks;
    final sessionsThisMonth = metrics.sessionsInMonth(month);

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(9, 3.5, 5, 3.5),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak-week streak',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.accentPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniMonthGrid(metrics: metrics, month: month),
          const SizedBox(height: 11),
          Text.rich(
            TextSpan(
              text: sessionsThisMonth == 0
                  ? 'No sessions yet in $monthName'
                  : '$sessionsThisMonth '
                      '${sessionsThisMonth == 1 ? 'session' : 'sessions'} '
                      'in $monthName · ',
              children: [
                if (sessionsThisMonth > 0)
                  TextSpan(
                    text: '${metrics.sessionsThisWeek} of '
                        '${metrics.weeklyGoal} this week',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMonthGrid extends StatelessWidget {
  final WorkoutCalendarMetrics metrics;
  final DateTime month;

  const _MiniMonthGrid({
    required this.metrics,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final sessionDays = metrics.sessionDaysInMonth(month);
    final today = DateTime.now().day;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cells = <int?>[
      ...List<int?>.filled(leading, null),
      for (var day = 1; day <= daysInMonth; day++) day,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      children: [
        Row(
          children: [
            for (final letter in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < cells.length; i += 7)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                for (final day in cells.sublist(i, i + 7))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: Container(
                          decoration: BoxDecoration(
                            color: day == today
                                ? AppColors.accentPrimary
                                : day != null && sessionDays.contains(day)
                                    ? AppColors.accentSoft
                                    : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            day == null ? '' : '$day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: day == today
                                  ? Colors.white
                                  : day != null && sessionDays.contains(day)
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── My performance card ──────────────────────────────────────────────

enum _PerformanceVerdict { improving, declining, steady }

class _TrendCard extends StatefulWidget {
  final List<ActiveSkillPathData> paths;
  final ValueChanged<ActiveSkillPathData> onOpenPath;

  const _TrendCard({
    required this.paths,
    required this.onOpenPath,
  });

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'My performance'),
        if (widget.paths.isEmpty) _buildEmptyState() else _buildVerdict(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const SurfaceCard(
      padding: EdgeInsets.all(18),
      child: Row(
        children: [
          IconTile(icon: Icons.query_stats_rounded, size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No performance data yet',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Complete a few workouts and your key movements '
                  'will be tracked here.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdict() {
    final rising = widget.paths
        .where((path) => path.momentum == HomeSkillMomentum.improving)
        .toList();
    final attention = widget.paths
        .where((path) => path.momentum == HomeSkillMomentum.stalled)
        .toList();

    final verdict = rising.length > attention.length
        ? _PerformanceVerdict.improving
        : attention.length > rising.length
            ? _PerformanceVerdict.declining
            : _PerformanceVerdict.steady;
    final headline = switch (verdict) {
      _PerformanceVerdict.improving => 'You’re trending up',
      _PerformanceVerdict.declining => 'Trending down',
      _PerformanceVerdict.steady => 'Holding steady',
    };
    final subtitle = rising.isEmpty && attention.isEmpty
        ? 'No big moves · last 14 days'
        : '${rising.length} rising · ${attention.length} need '
            'attention · last 14 days';
    final tileColor = switch (verdict) {
      _PerformanceVerdict.improving => AppColors.greenSoft,
      _PerformanceVerdict.declining => AppColors.amberSoft,
      _PerformanceVerdict.steady => AppColors.surface2,
    };
    final iconColor = switch (verdict) {
      _PerformanceVerdict.improving => AppColors.green,
      _PerformanceVerdict.declining => AppColors.amber,
      _PerformanceVerdict.steady => AppColors.textSecondary,
    };
    final icon = switch (verdict) {
      _PerformanceVerdict.improving => Icons.trending_up_rounded,
      _PerformanceVerdict.declining => Icons.trending_down_rounded,
      _PerformanceVerdict.steady => Icons.trending_flat_rounded,
    };
    final hasRows = rising.isNotEmpty || attention.isNotEmpty;

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: hasRows ? () => setState(() => _open = !_open) : null,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasRows)
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (_open && hasRows) ...[
            if (rising.isNotEmpty) ...[
              const SizedBox(height: 15),
              const _TrendGroupLabel(label: 'ON THE RISE', up: true),
              for (final path in rising)
                _TrendRow(
                  path: path,
                  up: true,
                  onTap: () => widget.onOpenPath(path),
                ),
            ],
            if (attention.isNotEmpty) ...[
              const SizedBox(height: 15),
              const _TrendGroupLabel(label: 'NEEDS ATTENTION', up: false),
              for (final path in attention)
                _TrendRow(
                  path: path,
                  up: false,
                  onTap: () => widget.onOpenPath(path),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TrendGroupLabel extends StatelessWidget {
  final String label;
  final bool up;

  const _TrendGroupLabel({required this.label, required this.up});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: up ? AppColors.green : AppColors.amber,
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  final ActiveSkillPathData path;
  final bool up;
  final VoidCallback onTap;

  const _TrendRow({
    required this.path,
    required this.up,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.currentExerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    path.skillTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: up ? AppColors.greenSoft : AppColors.amberSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 11,
                    color: up ? AppColors.green : AppColors.amber,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    path.deltaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: up ? AppColors.green : AppColors.amber,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sessions ──────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final PastWorkout workout;
  final bool showDivider;
  final VoidCallback onTap;

  const _SessionRow({
    required this.workout,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = workout.loggedAt.difference(workout.startedAt);
    final summaryParts = <String>[
      '${workout.totalSets} sets',
      if (workout.totalReps > 0) '${workout.totalReps} reps',
      if (workout.totalTimedSeconds > 0)
        formatWorkoutSeconds(workout.totalTimedSeconds),
    ];

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            IconTile(
              icon: workoutIconForSessionType(workout.sessionType),
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _relativeSessionLabel(workout.loggedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatElapsedShort(elapsed),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  summaryParts.join(' · '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllSessionsView extends StatefulWidget {
  final List<PastWorkout> workouts;
  final VoidCallback onDataChanged;

  const _AllSessionsView({
    required this.workouts,
    required this.onDataChanged,
  });

  @override
  State<_AllSessionsView> createState() => _AllSessionsViewState();
}

class _AllSessionsViewState extends State<_AllSessionsView> {
  late final List<PastWorkout> _workouts = List.of(widget.workouts);

  Future<void> _openWorkout(PastWorkout workout) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
    if (deleted == true && mounted) {
      setState(() {
        _workouts.removeWhere((item) => item.id == workout.id);
      });
      widget.onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SubScreenHeader(
              title: 'All sessions',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 44),
                children: [
                  if (_workouts.isEmpty)
                    const SurfaceCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Text(
                        'No saved sessions.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (var i = 0; i < _workouts.length; i++)
                            _SessionRow(
                              workout: _workouts[i],
                              showDivider: i > 0,
                              onTap: () => _openWorkout(_workouts[i]),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _DataStateMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeSessionLabel(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final difference = today.difference(day).inDays;

  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

  final String dayLabel;
  if (difference == 0) {
    dayLabel = 'Today';
  } else if (difference == 1) {
    dayLabel = 'Yesterday';
  } else if (difference < 7 && difference > 0) {
    dayLabel = weekdays[dateTime.weekday - 1];
  } else {
    dayLabel = '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$dayLabel, $displayHour:$minute $suffix';
}

String _formatElapsedShort(Duration duration) {
  if (duration.isNegative) return '—';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
