import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import 'session_overview_view.dart';
import 'training_program_settings_view.dart';
import 'workout_prescription.dart';

const _cardHighlight = Color(0x0BFFFFFF);
const _cardShadow = Color(0x38000000);
const _minutesPerSet = 3;

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
  Map<String, _LastResult> _lastResults = {};
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  TrainingSessionType _nextSessionType = TrainingSessionType.fullBody;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    final userId = AuthService().currentUser?.id;
    final progressMap = <String, ExerciseStatus>{};
    final lastResults = <String, _LastResult>{};
    UserTrainingProgramSnapshot? programSnapshot;

    if (userId != null) {
      try {
        final progress = await _progressService.fetchAll(userId);
        for (final item in progress) {
          progressMap[item.exerciseId] = item.status;
        }

        programSnapshot =
            await _trainingProgramStoreService.getOrCreateActiveProgram(
          userId,
        );

        final pastWorkouts =
            await _exerciseLogService.fetchPastWorkouts(userId);
        for (final workout in pastWorkouts) {
          for (final exercise in workout.exercises) {
            if (lastResults.containsKey(exercise.exerciseId)) continue;
            if (exercise.sets.isEmpty) continue;

            var best = 0;
            var isTimed = false;
            for (final set in exercise.sets) {
              if (set.value > best) {
                best = set.value;
                isTimed = set.isTimed;
              }
            }
            if (best > 0) {
              lastResults[exercise.exerciseId] =
                  _LastResult(value: best, isTimed: isTimed);
            }
          }
        }
      } catch (_) {
        // Keep the widget usable with default local fallback state.
      }
    }

    if (!mounted) return;

    setState(() {
      _progressMap = progressMap;
      _lastResults = lastResults;
      _selectedProgramType =
          programSnapshot?.program.programType ?? TrainingProgramType.fullBody;
      _nextSessionType = programSnapshot?.state.nextSessionType ??
          TrainingSessionType.fullBody;
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
    await _loadRecommendation();
  }

  List<_PathSnapshot> _pathSnapshots() {
    final recommendation = _recommendation;
    if (recommendation == null) return const [];

    return recommendation.items
        .map((item) => _PathSnapshot.build(item, _progressMap))
        .whereType<_PathSnapshot>()
        .toList();
  }

  List<_InReachEntry> _inReachEntries(List<_PathSnapshot> paths) {
    final entries = <_InReachEntry>[];

    for (final path in paths) {
      final next = path.nextExercise;
      final lastResult = _lastResults[path.workingExercise.id];
      if (next == null || lastResult == null) continue;

      entries.add(
        _InReachEntry(
          path: path,
          nextExercise: next,
          lastResult: lastResult,
          target: defaultTargetForExercise(next),
        ),
      );
    }

    entries.sort((a, b) => b.progress.compareTo(a.progress));
    return entries.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final paths = _pathSnapshots();
    final inReach = _inReachEntries(paths);
    final goals = paths.where((path) => path.exercises.length >= 2).toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: _loading
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _HomeHeader(),
                    ),
                    const SizedBox(height: 18),
                    if (recommendation != null)
                      _TodayWorkoutCard(
                        recommendation: recommendation,
                        paths: paths,
                        onEditProgram: _openProgramSettings,
                        onStartWorkout: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionOverviewView(
                                recommendation: recommendation,
                              ),
                            ),
                          );
                        },
                      ),
                    if (inReach.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionHeader(
                        title: 'In reach',
                        subtitle: "Last result vs the next node's target",
                      ),
                      const SizedBox(height: 14),
                      _InReachCard(entries: inReach),
                    ],
                    if (goals.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionHeader(
                        title: 'Your goals',
                        subtitle:
                            'The goals you picked — swipe through your paths',
                      ),
                      const SizedBox(height: 14),
                      _GoalsPager(paths: goals),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// A recommendation item resolved against its full training path.
class _PathSnapshot {
  final TrainingRecommendationItem item;
  final List<Exercise> exercises;
  final List<_NodeState> nodeStates;
  final int workingIndex;

  const _PathSnapshot({
    required this.item,
    required this.exercises,
    required this.nodeStates,
    required this.workingIndex,
  });

  static _PathSnapshot? build(
    TrainingRecommendationItem item,
    Map<String, ExerciseStatus> progressMap,
  ) {
    final exercises = item.pathExerciseIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();
    if (exercises.isEmpty) return null;

    var workingIndex = exercises.indexWhere(
      (exercise) => exercise.id == item.exercise.id,
    );
    if (workingIndex < 0) workingIndex = 0;

    final nodeStates = <_NodeState>[];
    for (var index = 0; index < exercises.length; index++) {
      if (index == workingIndex) {
        nodeStates.add(_NodeState.working);
      } else if (progressMap[exercises[index].id] == ExerciseStatus.mastered) {
        nodeStates.add(_NodeState.mastered);
      } else {
        nodeStates.add(_NodeState.upcoming);
      }
    }

    return _PathSnapshot(
      item: item,
      exercises: exercises,
      nodeStates: nodeStates,
      workingIndex: workingIndex,
    );
  }

  Exercise get workingExercise => item.exercise;

  Exercise? get nextExercise => workingIndex + 1 < exercises.length
      ? exercises[workingIndex + 1]
      : null;

  Exercise get goalExercise => exercises.last;

  SkillCategory? get category =>
      SkillCategoryCatalog.findById(item.sourceSkillCategoryId);

  String get treeTitle => category?.title ?? item.sourceCategory.label;

  /// Prefer the branch label when the program follows a non-default path
  /// (e.g. the core tree's "L-Sit / V-Sit" path).
  String get pathTitle {
    final skillCategory = category;
    if (skillCategory != null &&
        item.trainingPathId.isNotEmpty &&
        item.trainingPathId != skillCategory.defaultTrainingPathId) {
      for (final branch in skillCategory.branches) {
        if (branch.id == item.trainingPathId) return branch.label;
      }
    }
    return treeTitle;
  }

  IconData get icon {
    switch (item.sourceSkillCategoryId) {
      case SkillCategoryCatalog.handstandPushupsId:
        return Icons.sports_gymnastics;
      case SkillCategoryCatalog.coreId:
        return Icons.self_improvement;
      case SkillCategoryCatalog.rowsId:
        return Icons.rowing;
      case SkillCategoryCatalog.squatId:
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}

enum _NodeState { mastered, working, upcoming }

class _LastResult {
  final int value;
  final bool isTimed;

  const _LastResult({required this.value, required this.isTimed});
}

class _InReachEntry {
  final _PathSnapshot path;
  final Exercise nextExercise;
  final _LastResult lastResult;
  final int target;

  const _InReachEntry({
    required this.path,
    required this.nextExercise,
    required this.lastResult,
    required this.target,
  });

  double get progress =>
      target <= 0 ? 0 : (lastResult.value / target).clamp(0.0, 1.0);

  int get percent => (progress * 100).round().clamp(1, 100);

  String get remainingLabel {
    final remaining = target - lastResult.value;
    if (remaining <= 0) return 'Ready to attempt';
    if (isTimedExercise(nextExercise)) {
      return '${remaining}s longer hold to reach';
    }
    return remaining == 1
        ? '1 more clean rep to reach'
        : '$remaining more clean reps to reach';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Today',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
            letterSpacing: -0.96,
          ),
        ),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(0, 1)),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 19,
            color: AppColors.textStrong,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surfaceCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _cardHighlight),
    boxShadow: const [
      BoxShadow(
        color: _cardShadow,
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
  );
}

class _TodayWorkoutCard extends StatelessWidget {
  final DailyTrainingRecommendation recommendation;
  final List<_PathSnapshot> paths;
  final VoidCallback onEditProgram;
  final VoidCallback onStartWorkout;

  const _TodayWorkoutCard({
    required this.recommendation,
    required this.paths,
    required this.onEditProgram,
    required this.onStartWorkout,
  });

  int get _estimatedMinutes {
    final totalSets = recommendation.items.fold(
      0,
      (sum, item) => sum + defaultSetCount(item),
    );
    return totalSets * _minutesPerSet;
  }

  _PathSnapshot? _pathFor(TrainingRecommendationItem item) {
    for (final path in paths) {
      if (identical(path.item, item)) return path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = recommendation.items;
    final isEmpty = recommendation.isRestDay || items.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  recommendation.sessionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                    letterSpacing: -0.48,
                  ),
                ),
              ),
              _TrainingProgramMenuButton(onEditProgram: onEditProgram),
            ],
          ),
          const SizedBox(height: 2),
          if (isEmpty)
            Text(
              'Recover today and come back ready for your next session.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid,
                height: 1.5,
              ),
            )
          else ...[
            Text(
              '$_estimatedMinutes min · ${items.length} exercises',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid,
              ),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(height: 16),
              _TodayExerciseRow(
                item: items[index],
                path: _pathFor(items[index]),
              ),
            ],
            const SizedBox(height: 18),
            _StartWorkoutButton(onPressed: onStartWorkout),
          ],
        ],
      ),
    );
  }
}

class _TodayExerciseRow extends StatelessWidget {
  final TrainingRecommendationItem item;
  final _PathSnapshot? path;

  const _TodayExerciseRow({
    required this.item,
    required this.path,
  });

  String get _setsLabel {
    final sets = defaultSetCount(item);
    final target = defaultTarget(item);
    final suffix = isTimedExercise(item.exercise) ? 's' : '';
    return '$sets × $target$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _setsLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid,
              ),
            ),
          ],
        ),
        if (snapshot != null) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              _PathDots(nodeStates: snapshot.nodeStates),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${snapshot.treeTitle} tree',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PathDots extends StatelessWidget {
  final List<_NodeState> nodeStates;

  const _PathDots({required this.nodeStates});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < nodeStates.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          _dot(nodeStates[index]),
        ],
      ],
    );
  }

  Widget _dot(_NodeState state) {
    switch (state) {
      case _NodeState.mastered:
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.signalGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.signalGreen.withValues(alpha: 0.13),
                spreadRadius: 3,
              ),
            ],
          ),
        );
      case _NodeState.working:
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.signalBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.signalBlue.withValues(alpha: 0.1),
                spreadRadius: 5,
              ),
            ],
          ),
        );
      case _NodeState.upcoming:
        return Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.surfaceTrack,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

class _StartWorkoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartWorkoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.startOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Start workout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InReachCard extends StatelessWidget {
  final List<_InReachEntry> entries;

  const _InReachCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0x08FFFFFF),
              ),
            _InReachRow(entry: entries[index]),
          ],
        ],
      ),
    );
  }
}

class _InReachRow extends StatelessWidget {
  final _InReachEntry entry;

  const _InReachRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final path = entry.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceChip,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                path.icon,
                size: 21,
                color: AppColors.textMid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.pathTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Working: ${path.workingExercise.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.percent}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.signalGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProgressBar(progress: entry.progress, height: 7),
        const SizedBox(height: 9),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.textFaint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${entry.remainingLabel} ',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMid,
                  ),
                  children: [
                    TextSpan(
                      text: entry.nextExercise.name,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.signalBlue,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const _ProgressBar({
    required this.progress,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Container(color: AppColors.surfaceChip),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.02, 1.0),
              child: Container(color: AppColors.signalGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsPager extends StatefulWidget {
  final List<_PathSnapshot> paths;

  const _GoalsPager({required this.paths});

  @override
  State<_GoalsPager> createState() => _GoalsPagerState();
}

class _GoalsPagerState extends State<_GoalsPager> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            onPageChanged: (page) => setState(() => _page = page),
            itemCount: widget.paths.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _GoalCard(path: widget.paths[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < widget.paths.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: index == _page ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _page
                      ? AppColors.textMid
                      : AppColors.surfaceChip,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _PathSnapshot path;

  const _GoalCard({required this.path});

  @override
  Widget build(BuildContext context) {
    final total = path.exercises.length;
    final position = path.workingIndex + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${path.treeTitle} tree'.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFaint,
                    letterSpacing: 0.69,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  path.goalExercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                    letterSpacing: -0.36,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Working: ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMid,
                    ),
                    children: [
                      TextSpan(
                        text: path.workingExercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.signalBlue,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(
                        progress: total <= 0 ? 0 : position / total,
                        height: 6,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${position.toString().padLeft(2, '0')}'
                      '/${total.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: CustomPaint(
              painter: _MiniConstellationPainter(
                nodeStates: path.nodeStates,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small constellation-style preview of a training path: mastered nodes in
/// green, the working node in blue, upcoming nodes muted.
class _MiniConstellationPainter extends CustomPainter {
  final List<_NodeState> nodeStates;

  const _MiniConstellationPainter({required this.nodeStates});

  @override
  void paint(Canvas canvas, Size size) {
    final count = nodeStates.length;
    if (count == 0) return;

    final positions = <Offset>[];
    for (var index = 0; index < count; index++) {
      final t = count == 1 ? 0.5 : index / (count - 1);
      final y = size.height - 10 - t * (size.height - 20);
      final x = size.width / 2 + math.sin(index * 2.1) * size.width * 0.28;
      positions.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < count - 1; index++) {
      final a = nodeStates[index];
      final b = nodeStates[index + 1];
      if (a == _NodeState.mastered &&
          (b == _NodeState.mastered || b == _NodeState.working)) {
        linePaint.color = AppColors.signalGreen.withValues(alpha: 0.45);
      } else {
        linePaint.color = Colors.white.withValues(alpha: 0.09);
      }
      canvas.drawLine(positions[index], positions[index + 1], linePaint);
    }

    final nodePaint = Paint();
    for (var index = 0; index < count; index++) {
      final position = positions[index];
      switch (nodeStates[index]) {
        case _NodeState.mastered:
          nodePaint.color = AppColors.signalGreen.withValues(alpha: 0.16);
          canvas.drawCircle(position, 6.5, nodePaint);
          nodePaint.color = AppColors.signalGreen;
          canvas.drawCircle(position, 3, nodePaint);
        case _NodeState.working:
          nodePaint.color = AppColors.signalBlue.withValues(alpha: 0.18);
          canvas.drawCircle(position, 8, nodePaint);
          nodePaint.color = AppColors.signalBlue;
          canvas.drawCircle(position, 4, nodePaint);
        case _NodeState.upcoming:
          nodePaint.color = AppColors.surfaceTrack;
          canvas.drawCircle(position, 2.75, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniConstellationPainter oldDelegate) =>
      oldDelegate.nodeStates != nodeStates;
}

class _TrainingProgramMenuButton extends StatefulWidget {
  final VoidCallback onEditProgram;

  const _TrainingProgramMenuButton({
    required this.onEditProgram,
  });

  @override
  State<_TrainingProgramMenuButton> createState() =>
      _TrainingProgramMenuButtonState();
}

class _TrainingProgramMenuButtonState
    extends State<_TrainingProgramMenuButton> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(-132, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceChip),
        surfaceTintColor: WidgetStateProperty.all(AppColors.surfaceChip),
        side: WidgetStateProperty.all(
          const BorderSide(color: _cardHighlight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onEditProgram();
          },
          child: Text(
            'Edit program',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
            setState(() {});
          },
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.more_horiz,
              size: 22,
              color: AppColors.textMid,
            ),
          ),
        );
      },
    );
  }
}
