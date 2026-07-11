import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../skills/skill_tree_view.dart';
import 'goal_skills_view.dart';
import 'session_overview_view.dart';
import 'training_program_settings_view.dart';

// Node color language mirrors the Skills tab: green = mastered,
// orange = working, gray = locked.
const _nodeDone = Color(0xFF00FF8C);
const _nodeDoneSoft = Color(0x2400FF8C);
const _nodeLocked = Color(0xFF3F3F46);
const _amber = Color(0xFFE9B43D);
const _amberSoft = Color(0x22E9B43D);
const _greenSoft = Color(0x2200FF8C);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _exerciseLogService = ExerciseLogService();
  final _progressService = ProgressService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  Map<String, ExerciseStatus> _progressMap = {};
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  TrainingSessionType _nextSessionType = TrainingSessionType.fullBody;
  List<String> _goalSkillIds = const [];
  List<PastWorkout> _pastWorkouts = const [];
  int _plannedPerWeek = 3;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final userId = AuthService().currentUser?.id;
    final progressMap = <String, ExerciseStatus>{};
    UserTrainingProgramSnapshot? programSnapshot;
    var pastWorkouts = const <PastWorkout>[];

    if (userId != null) {
      try {
        final results = await Future.wait<Object>([
          _progressService.fetchAll(userId),
          _trainingProgramStoreService.getOrCreateActiveProgram(userId),
          _exerciseLogService.fetchPastWorkouts(userId),
        ]);

        final progress = results[0] as List<ExerciseProgress>;
        for (final item in progress) {
          progressMap[item.exerciseId] = item.status;
        }
        programSnapshot = results[1] as UserTrainingProgramSnapshot;
        pastWorkouts = results[2] as List<PastWorkout>;
      } catch (_) {
        // Keep the widget usable with default local fallback state.
      }
    }

    if (!mounted) return;

    setState(() {
      _progressMap = progressMap;
      _pastWorkouts = pastWorkouts;
      _selectedProgramType =
          programSnapshot?.program.programType ?? TrainingProgramType.fullBody;
      _nextSessionType = programSnapshot?.state.nextSessionType ??
          TrainingSessionType.fullBody;
      _goalSkillIds = programSnapshot?.program.goalSkillIds ?? const [];
      _plannedPerWeek = programSnapshot?.program.frequencyPerWeek ?? 3;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
      );
      _loading = false;
    });
  }

  Future<void> _saveProgramType(TrainingProgramType type) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || type == _selectedProgramType) return;

    final snapshot = await _trainingProgramStoreService.updateProgramType(
      userId: userId,
      programType: type,
    );

    if (!mounted) return;

    setState(() {
      _selectedProgramType = snapshot.program.programType;
      _nextSessionType = snapshot.state.nextSessionType;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
      );
    });
  }

  Future<void> _openProgramSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingProgramSettingsView(
          initialProgramType: _selectedProgramType,
          onSave: _saveProgramType,
        ),
      ),
    );

    if (!mounted) return;
    await _loadDashboard();
  }

  Future<void> _openGoalPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalSkillsView(
          initialGoalIds: _goalSkillIds,
          onSave: (goalIds) async {
            final userId = AuthService().currentUser?.id;
            if (userId == null) return;
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

  void _openSessionOverview() {
    final recommendation = _recommendation;
    if (recommendation == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SessionOverviewView(
              recommendation: recommendation,
            ),
          ),
        )
        .then((_) => _loadDashboard());
  }

  void _openSkillTree(String skillCategoryId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SkillTreeView(
              skillCategoryId: skillCategoryId,
              progressMap: _progressMap,
              onProgressChanged: (id, status) {
                setState(() => _progressMap[id] = status);
              },
            ),
          ),
        )
        .then((_) => _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final treeRows = recommendation == null
        ? const <_TreeRowData>[]
        : _buildTreeRows(recommendation, _progressMap);
    final perfRows = recommendation == null
        ? const <_ExercisePerf>[]
        : _buildPerfRows(recommendation, _pastWorkouts);
    final goals = _buildGoals(_goalSkillIds, _progressMap);
    final weekStats = _WeekStats.fromWorkouts(_pastWorkouts, _plannedPerWeek);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: _loading
            ? const Center(child: LoadingIndicator())
            : RefreshIndicator(
                color: AppColors.accentPrimary,
                backgroundColor: AppColors.bgTertiary,
                onRefresh: _loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 18),
                      _StreakCard(stats: weekStats),
                      const SizedBox(height: 20),
                      if (recommendation != null)
                        _UpNextCard(
                          recommendation: recommendation,
                          onStart: _openSessionOverview,
                        ),
                      const SizedBox(height: 10),
                      _ProgramRow(
                        programType: _selectedProgramType,
                        onTap: _openProgramSettings,
                      ),
                      if (treeRows.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Your skill trees',
                          sub: _treesSubtitle(_progressMap),
                        ),
                        _HomeCard(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Column(
                            children: [
                              for (var i = 0; i < treeRows.length; i++)
                                _TreeRow(
                                  data: treeRows[i],
                                  first: i == 0,
                                  onTap: () => _openSkillTree(
                                    treeRows[i].category.id,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const _SectionHeader(
                        title: 'Exercise performance',
                        sub: 'Session totals vs your previous session',
                      ),
                      _PerformanceCard(rows: perfRows),
                      _SectionHeader(
                        title: 'Long-term goals',
                        sub: goals.isEmpty
                            ? null
                            : 'The skills you\'re climbing toward',
                        action: goals.isEmpty ? null : 'Edit',
                        onAction: goals.isEmpty ? null : _openGoalPicker,
                      ),
                      if (goals.isEmpty)
                        _GoalsEmptyState(onAddGoals: _openGoalPicker)
                      else
                        _HomeCard(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Column(
                            children: [
                              for (var i = 0; i < goals.length; i++)
                                _GoalRow(goal: goals[i], first: i == 0),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Derived data ────────────────────────────────────────────────────────────

class _WeekStats {
  final int streakWeeks;
  final int doneThisWeek;
  final int planned;
  final bool hasWorkouts;

  const _WeekStats({
    required this.streakWeeks,
    required this.doneThisWeek,
    required this.planned,
    required this.hasWorkouts,
  });

  factory _WeekStats.fromWorkouts(List<PastWorkout> workouts, int planned) {
    final now = DateTime.now();
    final thisWeek = _startOfWeek(now);
    final weeks = <DateTime>{
      for (final workout in workouts) _startOfWeek(workout.loggedAt),
    };

    var cursor = thisWeek;
    // The current week can't break the streak until it's over.
    if (!weeks.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 7));
    }

    var streak = 0;
    while (weeks.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }

    final doneThisWeek = workouts
        .where((workout) => !_startOfWeek(workout.loggedAt).isBefore(thisWeek))
        .length;

    return _WeekStats(
      streakWeeks: streak,
      doneThisWeek: doneThisWeek,
      planned: planned,
      hasWorkouts: workouts.isNotEmpty,
    );
  }

  static DateTime _startOfWeek(DateTime dateTime) {
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }
}

class _TreeRowData {
  final TrainingRecommendationItem item;
  final SkillCategory category;
  final String title;
  final List<ExerciseStatus> nodeStatuses;
  final int masteredCount;
  final String? nextExerciseName;

  const _TreeRowData({
    required this.item,
    required this.category,
    required this.title,
    required this.nodeStatuses,
    required this.masteredCount,
    required this.nextExerciseName,
  });
}

List<_TreeRowData> _buildTreeRows(
  DailyTrainingRecommendation recommendation,
  Map<String, ExerciseStatus> progressMap,
) {
  final rows = <_TreeRowData>[];

  for (final item in recommendation.items) {
    final path = item.progressionExerciseIds;
    if (path.isEmpty) continue;
    if (!SkillCategoryCatalog.isBrowsableId(item.sourceSkillCategoryId)) {
      continue;
    }

    final category = SkillCategoryCatalog.findById(item.sourceSkillCategoryId);
    if (category == null) continue;

    final statuses = <ExerciseStatus>[];
    var mastered = 0;
    String? nextName;
    final currentIndex = path.indexOf(item.exercise.id);

    for (var i = 0; i < path.length; i++) {
      final status = path[i] == item.exercise.id
          ? ExerciseStatus.active
          : (progressMap[path[i]] == ExerciseStatus.mastered
              ? ExerciseStatus.mastered
              : ExerciseStatus.inactive);
      statuses.add(status);
      if (status == ExerciseStatus.mastered) mastered++;
    }

    if (currentIndex >= 0 && currentIndex + 1 < path.length) {
      nextName = ExerciseCatalog.findById(path[currentIndex + 1])?.name;
    }

    final branches = category.branches
        .where((branch) => branch.id == item.exercise.branchId)
        .toList();
    final title = branches.isEmpty || branches.first.id == 'main'
        ? category.title
        : '${category.title} · ${branches.first.label}';

    rows.add(
      _TreeRowData(
        item: item,
        category: category,
        title: title,
        nodeStatuses: statuses,
        masteredCount: mastered,
        nextExerciseName: nextName,
      ),
    );
  }

  return rows;
}

String _treesSubtitle(Map<String, ExerciseStatus> progressMap) {
  final mastered = progressMap.values
      .where((status) => status == ExerciseStatus.mastered)
      .length;
  return '$mastered nodes cleared all-time';
}

class _ExercisePerf {
  final Exercise exercise;
  final List<int> history; // chronological session totals
  final bool isTimed;

  const _ExercisePerf({
    required this.exercise,
    required this.history,
    required this.isTimed,
  });

  int? get delta =>
      history.length >= 2 ? history.last - history[history.length - 2] : null;

  String get unit => isTimed ? 's' : '';

  String get lastLabel =>
      history.isEmpty ? '—' : '${history.last}${isTimed ? 's' : ' reps'}';
}

List<_ExercisePerf> _buildPerfRows(
  DailyTrainingRecommendation recommendation,
  List<PastWorkout> workouts,
) {
  final rows = <_ExercisePerf>[];

  for (final item in recommendation.items) {
    // Newest first, capped at the last 4 logged sessions.
    final values = <int>[];
    var isTimed = false;

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId != item.exercise.id) continue;
        final timed = exercise.isTimed;
        values.add(timed ? exercise.totalTimedSeconds : exercise.totalReps);
        if (values.length == 1) isTimed = timed;
        break;
      }
      if (values.length >= 4) break;
    }

    rows.add(
      _ExercisePerf(
        exercise: item.exercise,
        history: values.reversed.toList(),
        isTimed: isTimed,
      ),
    );
  }

  return rows;
}

class _GoalData {
  final Exercise exercise;
  final String categoryTitle;
  final int masteredSteps;
  final int totalSteps;

  const _GoalData({
    required this.exercise,
    required this.categoryTitle,
    required this.masteredSteps,
    required this.totalSteps,
  });

  double get progress => totalSteps == 0 ? 0 : masteredSteps / totalSteps;
}

List<_GoalData> _buildGoals(
  List<String> goalSkillIds,
  Map<String, ExerciseStatus> progressMap,
) {
  final goals = <_GoalData>[];

  for (final goalId in goalSkillIds) {
    final exercise = ExerciseCatalog.findById(goalId);
    if (exercise == null) continue;

    final category = SkillCategoryCatalog.findById(
      ExerciseCatalog.skillCategoryIdForExercise(exercise),
    );

    List<String>? path;
    for (final candidate in (category?.trainingPaths ?? const {}).values) {
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
      _GoalData(
        exercise: exercise,
        categoryTitle: category?.title ?? exercise.category.label,
        masteredSteps: mastered,
        totalSteps: steps.length,
      ),
    );
  }

  return goals;
}

// ── Shared building blocks ──────────────────────────────────────────────────

class _HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _HomeCard({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSecondary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.sub,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 28, 2, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    action!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
            Text(
              sub!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExerciseCategory category;
  final double size;
  final bool tint;

  const _CategoryTile({
    required this.category,
    this.size = 36,
    this.tint = false,
  });

  IconData get _icon {
    switch (category) {
      case ExerciseCategory.verticalPull:
        return Icons.sports_gymnastics_rounded;
      case ExerciseCategory.verticalPush:
        return Icons.front_hand_outlined;
      case ExerciseCategory.horizontalPull:
        return Icons.swap_horiz_rounded;
      case ExerciseCategory.horizontalPush:
        return Icons.push_pin_outlined;
      case ExerciseCategory.squat:
        return Icons.accessibility_new_rounded;
      case ExerciseCategory.hinge:
        return Icons.keyboard_double_arrow_down_rounded;
      case ExerciseCategory.core:
        return Icons.crop_free_rounded;
      case ExerciseCategory.skill:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = tint
        ? AppColors.accentPrimary.withValues(alpha: 0.13)
        : const Color(0xFF232329);
    final color = tint ? AppColors.accentPrimary : AppColors.textSecondary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(_icon, size: size * 0.54, color: color),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Today',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak ──────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final _WeekStats stats;

  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final onTrack = stats.doneThisWeek >= stats.planned;
    final title = stats.streakWeeks > 0
        ? '${stats.streakWeeks}-week streak'
        : 'Start your streak';
    final subtitle = stats.hasWorkouts
        ? '${stats.doneThisWeek} of ${stats.planned} sessions this week'
        : 'Finish your first workout to begin week one';

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 26,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.17,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (stats.hasWorkouts) ...[
            const SizedBox(width: 8),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: onTrack ? _nodeDone : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  onTrack
                      ? 'On track'
                      : '${stats.doneThisWeek}/${stats.planned}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: onTrack ? _nodeDone : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Up next ─────────────────────────────────────────────────────────────────

class _UpNextCard extends StatelessWidget {
  final DailyTrainingRecommendation recommendation;
  final VoidCallback onStart;

  const _UpNextCard({
    required this.recommendation,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final items = recommendation.items;

    return _HomeCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UP NEXT · TODAY',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accentPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.sessionLabel,
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.42,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items.isEmpty
                          ? 'Recover today and come back ready.'
                          : '${items.length} exercises · picks up your working nodes',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onStart,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Start',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items.take(3)) ...[
                    _ExerciseChip(label: item.exercise.name),
                    const SizedBox(width: 6),
                  ],
                  if (items.length > 3)
                    _ExerciseChip(
                      label: '+${items.length - 3} more',
                      muted: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  final bool muted;

  const _ExerciseChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF232329),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textMuted : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Program row ─────────────────────────────────────────────────────────────

class _ProgramRow extends StatelessWidget {
  final TrainingProgramType programType;
  final VoidCallback onTap;

  const _ProgramRow({
    required this.programType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _HomeCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              'Your program',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${programType.label} split',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skill trees ─────────────────────────────────────────────────────────────

class _TreeRow extends StatelessWidget {
  final _TreeRowData data;
  final bool first;
  final VoidCallback onTap;

  const _TreeRow({
    required this.data,
    required this.first,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.nodeStatuses.length;
    final countText = data.masteredCount.toString().padLeft(2, '0');
    final totalText = total.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(
                  top: BorderSide(color: AppColors.borderSecondary),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryTile(category: data.item.exercise.category, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: countText),
                      TextSpan(
                        text: '/$totalText nodes',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            _NodeSpine(statuses: data.nodeStatuses),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Working: '),
                        TextSpan(
                          text: data.item.exercise.name,
                          style: const TextStyle(
                            color: AppColors.accentBright,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (data.nextExerciseName != null) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          const TextSpan(text: 'Clear it to unlock '),
                          TextSpan(
                            text: data.nextExerciseName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NodeSpine extends StatelessWidget {
  final List<ExerciseStatus> statuses;

  const _NodeSpine({required this.statuses});

  Color _dotColor(ExerciseStatus status) {
    switch (status) {
      case ExerciseStatus.mastered:
        return _nodeDone;
      case ExerciseStatus.active:
        return AppColors.accentBright;
      case ExerciseStatus.inactive:
        return _nodeLocked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < statuses.length; i++) {
      if (i > 0) {
        final connected = statuses[i - 1] == ExerciseStatus.mastered;
        children.add(
          Expanded(
            child: Container(
              height: 1.5,
              color: connected ? _nodeDoneSoft : _nodeLocked,
            ),
          ),
        );
      }

      final status = statuses[i];
      final size = status == ExerciseStatus.active ? 10.0 : 8.0;
      children.add(
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _dotColor(status),
            shape: BoxShape.circle,
            boxShadow: status == ExerciseStatus.mastered
                ? const [
                    BoxShadow(color: _nodeDoneSoft, spreadRadius: 2.5),
                  ]
                : status == ExerciseStatus.active
                    ? [
                        BoxShadow(
                          color:
                              AppColors.accentBright.withValues(alpha: 0.25),
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
          ),
        ),
      );
    }

    return Row(children: children);
  }
}

// ── Exercise performance ────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  final List<_ExercisePerf> rows;

  const _PerformanceCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final hasAnyData = rows.any((row) => row.history.isNotEmpty);

    if (rows.isEmpty || !hasAnyData) {
      return _HomeCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF232329),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.query_stats,
                size: 24,
                color: Color(0xFF52525C),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No performance data yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(
                'Finish your first workout to start tracking whether each exercise is improving session to session.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _HomeCard(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _PerformanceRow(perf: rows[i], first: i == 0),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final _ExercisePerf perf;
  final bool first;

  const _PerformanceRow({required this.perf, required this.first});

  @override
  Widget build(BuildContext context) {
    final delta = perf.delta;
    final tone = delta == null
        ? AppColors.textMuted
        : delta > 0
            ? _nodeDone
            : delta < 0
                ? _amber
                : AppColors.textSecondary;
    final label = delta == null
        ? 'No trend yet'
        : delta > 0
            ? 'Improving'
            : delta < 0
                ? 'Slipping'
                : 'Steady';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(
                top: BorderSide(color: AppColors.borderSecondary),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perf.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tone,
                    ),
                    children: [
                      TextSpan(text: label),
                      if (perf.history.isNotEmpty)
                        TextSpan(
                          text: ' · last ${perf.lastLabel}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (perf.history.length >= 2) ...[
            const SizedBox(width: 12),
            CustomPaint(
              size: const Size(72, 24),
              painter: _SparklinePainter(
                values: perf.history,
                color: tone,
              ),
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Align(
              alignment: Alignment.centerRight,
              child: _DeltaPill(delta: delta, unit: perf.unit),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final int? delta;
  final String unit;

  const _DeltaPill({required this.delta, required this.unit});

  @override
  Widget build(BuildContext context) {
    final value = delta;
    final color = value == null
        ? AppColors.textMuted
        : value > 0
            ? _nodeDone
            : value < 0
                ? _amber
                : AppColors.textSecondary;
    final background = value == null || value == 0
        ? const Color(0x10FFFFFF)
        : value > 0
            ? _greenSoft
            : _amberSoft;
    final text = value == null
        ? '—'
        : value > 0
            ? '+$value$unit'
            : '$value$unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : (max - min).toDouble();

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = 3 + (i / (values.length - 1)) * (size.width - 6);
      final y =
          size.height - 4 - ((values[i] - min) / span) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()..addPolygon(points, false),
      line,
    );
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ── Long-term goals ─────────────────────────────────────────────────────────

class _GoalRow extends StatelessWidget {
  final _GoalData goal;
  final bool first;

  const _GoalRow({required this.goal, required this.first});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(
                top: BorderSide(color: AppColors.borderSecondary),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryTile(
                category: goal.exercise.category,
                size: 36,
                tint: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goal.categoryTitle} · ${goal.masteredSteps} of ${goal.totalSteps} steps mastered',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '$percent'),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: goal.progress.clamp(0.02, 1.0),
                backgroundColor: const Color(0xFF232329),
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.accentPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsEmptyState extends StatelessWidget {
  final VoidCallback onAddGoals;

  const _GoalsEmptyState({required this.onAddGoals});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF232329),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 24,
              color: Color(0xFF52525C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              'Pick the skills you want your training to build toward and track your climb here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAddGoals,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Add goals',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
