import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';

Future<T?> openExerciseDetailView<T>(
  BuildContext context, {
  required Exercise exercise,
  Color accentColor = AppColors.accentPrimary,
  String? skillCategoryId,
  List<String>? focusChips,
  bool autoScrollToProgress = false,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ExerciseDetailView(
        exercise: exercise,
        accentColor: accentColor,
        skillCategoryId: skillCategoryId,
        focusChips: focusChips,
        autoScrollToProgress: autoScrollToProgress,
      ),
    ),
  );
}

/// Exercise detail page in the polished design language: demo media,
/// target/level/rest stats, how-to steps, form checks, and session history.
class ExerciseDetailView extends StatefulWidget {
  final Exercise exercise;
  final Color accentColor;
  final String? skillCategoryId;
  final List<String>? focusChips;
  final bool autoScrollToProgress;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
    this.accentColor = AppColors.accentPrimary,
    this.skillCategoryId,
    this.focusChips,
    this.autoScrollToProgress = false,
  });

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  final _exerciseLogService = ExerciseLogService();
  final _restPreferencesService = WorkoutRestPreferencesService();
  final _scrollController = ScrollController();
  final _historyKey = GlobalKey();

  late Future<List<ExerciseLog>> _logsFuture;
  int _restSeconds = 0;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
    _loadRestPreference();
    if (widget.autoScrollToProgress) {
      _logsFuture.whenComplete(() {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToHistory();
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<ExerciseLog>> _loadLogs() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return const [];
    return _exerciseLogService.fetchForExercise(userId, widget.exercise.id);
  }

  Future<void> _loadRestPreference() async {
    final stored = await _restPreferencesService.loadRestIntervals();
    if (!mounted) return;
    setState(() => _restSeconds = stored[widget.exercise.id] ?? 0);
  }

  String get _resolvedSkillCategoryId {
    final requestedId = widget.skillCategoryId;
    if (requestedId != null && requestedId.isNotEmpty) {
      return requestedId;
    }
    return ExerciseCatalog.skillCategoryIdForExercise(widget.exercise);
  }

  Future<void> _scrollToHistory() async {
    final context = _historyKey.currentContext;
    if (context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject == null) return;
    await _scrollController.position.ensureVisible(
      renderObject,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final skillCategory =
        SkillCategoryCatalog.findById(_resolvedSkillCategoryId);
    final coachData = _coachDataFor(exercise);
    final targetPlan = _targetPlanFor(exercise);
    final isTimed = _isTimedExercise(exercise);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailNavBar(
              title: exercise.name,
              subtitle:
                  '${skillCategory?.title ?? exercise.category.label} · '
                  '${_branchLabel(exercise.branchId)}',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 44),
                children: [
                  _DemoMedia(exercise: exercise),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(
                      'Demo · ${exercise.name} shown at working tempo',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatBlock(
                            label: 'TARGET',
                            value: targetPlan.targetLabel,
                          ),
                        ),
                        Expanded(
                          child: _StatBlock(
                            label: 'LEVEL',
                            value: _levelLabel(exercise.difficulty),
                          ),
                        ),
                        Expanded(
                          child: _StatBlock(
                            label: 'REST',
                            value: _formatRestLabel(_restSeconds),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'How to'),
                  SurfaceCard(
                    clip: true,
                    child: Column(
                      children: [
                        for (var i = 0; i < coachData.steps.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i > 0
                                  ? const Border(
                                      top: BorderSide(
                                        color: AppColors.divider,
                                      ),
                                    )
                                  : null,
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(18, 13, 16, 13),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 18,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accentPrimary,
                                      height: 1.45,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    coachData.steps[i],
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SectionHeader(
                    title: 'Form check',
                    sub: 'Every rep should pass these',
                  ),
                  SurfaceCard(
                    clip: true,
                    child: Column(
                      children: [
                        for (var i = 0; i < coachData.formChecks.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i > 0
                                  ? const Border(
                                      top: BorderSide(
                                        color: AppColors.divider,
                                      ),
                                    )
                                  : null,
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(18, 12, 16, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 21,
                                  height: 21,
                                  margin: const EdgeInsets.only(top: 0.5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.greenSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    coachData.formChecks[i],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  KeyedSubtree(
                    key: _historyKey,
                    child: const SectionHeader(title: 'History'),
                  ),
                  FutureBuilder<List<ExerciseLog>>(
                    future: _logsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SurfaceCard(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: LoadingIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const _MessageCard(
                          message:
                              'Couldn’t load your history. Pull back and try '
                              'again in a moment.',
                        );
                      }
                      final logs = snapshot.data ?? const <ExerciseLog>[];
                      if (logs.isEmpty) {
                        return const _MessageCard(
                          message:
                              'Log this exercise in a finished workout and '
                              'your sessions will show up here.',
                        );
                      }
                      return _HistoryCard(logs: logs, isTimed: isTimed);
                    },
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

class _DetailNavBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _DetailNavBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoMedia extends StatelessWidget {
  final Exercise exercise;

  const _DemoMedia({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(kCardRadius),
      child: SizedBox(
        height: 208,
        width: double.infinity,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DemoPlaceholder(),
              )
            : const _DemoPlaceholder(),
      ),
    );
  }
}

class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo coming soon',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.17,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<ExerciseLog> logs;
  final bool isTimed;

  const _HistoryCard({required this.logs, required this.isTimed});

  String _setsLabel(ExerciseLog log) {
    final values = log.sets
        .map(
          (set) => isTimed ? '${set.durationSeconds}s' : '${set.reps}',
        )
        .join(' · ');
    return isTimed ? values : '$values reps';
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < logs.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(top: BorderSide(color: AppColors.divider))
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatShortDate(logs[i].loggedAt),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _setsLabel(logs[i]),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
            child: Text(
              isTimed
                  ? 'Hold per set · most recent first'
                  : 'Reps per set · most recent first',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coach content & helpers ───────────────────────────────────────────

class _ExerciseTargetPlan {
  final int sets;
  final int primaryTarget;
  final bool isTimed;

  const _ExerciseTargetPlan({
    required this.sets,
    required this.primaryTarget,
    required this.isTimed,
  });

  String get targetLabel =>
      isTimed ? '$sets × ${primaryTarget}s' : '$sets × $primaryTarget';
}

class _ExerciseCoachData {
  final List<String> steps;
  final List<String> formChecks;

  const _ExerciseCoachData({
    required this.steps,
    required this.formChecks,
  });
}

_ExerciseTargetPlan _targetPlanFor(Exercise exercise) {
  final isTimed = _isTimedExercise(exercise);
  final sets = switch (exercise.programSection) {
    ExerciseProgramSection.warmup => 2,
    ExerciseProgramSection.skillWork => 3,
    ExerciseProgramSection.mainExercises => exercise.difficulty >= 4 ? 4 : 3,
    ExerciseProgramSection.coolDown => 2,
  };

  final target = isTimed
      ? (exercise.difficulty <= 1
          ? 30
          : exercise.difficulty <= 3
              ? 20
              : 12)
      : (exercise.difficulty <= 1
          ? 12
          : exercise.difficulty <= 3
              ? 8
              : 5);

  return _ExerciseTargetPlan(
    sets: sets,
    primaryTarget: target,
    isTimed: isTimed,
  );
}

_ExerciseCoachData _coachDataFor(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.verticalPull:
      return const _ExerciseCoachData(
        steps: [
          'Take your grip, create tension first, and pack the shoulder before the pull starts.',
          'Pull by driving the elbows down toward your ribs instead of reaching the chin forward.',
          'Keep ribs tucked and legs quiet so the rep stays clean without swing.',
          'Pause the top briefly, then lower under control for a full eccentric.',
        ],
        formChecks: [
          'Bottom position stays active instead of hanging passively.',
          'Neck stays neutral and the ribs do not flare mid-rep.',
          'Every descent is controlled instead of dropping out of the bar.',
        ],
      );
    case ExerciseCategory.verticalPush:
      return const _ExerciseCoachData(
        steps: [
          'Set the hands, brace the trunk, and build a straight line before pressing.',
          'Keep wrists, elbows, and shoulders stacked as you move upward.',
          'Move slowly enough that you can control the bottom and the lockout.',
          'Finish tall with active shoulders instead of arching to find range.',
        ],
        formChecks: [
          'Ribs stay down while the shoulders keep reaching.',
          'The line stays clean instead of bending through the lower back.',
          'You can pause the hardest position without collapsing.',
        ],
      );
    case ExerciseCategory.horizontalPull:
      return const _ExerciseCoachData(
        steps: [
          'Set your torso angle and keep the chest open before the first rep.',
          'Start the pull with the upper back, then bring the elbows toward the body.',
          'Pause the squeezed position instead of bouncing through it.',
          'Return with control and keep the same body angle from rep to rep.',
        ],
        formChecks: [
          'Shoulders stay away from the ears at the finish.',
          'Torso angle stays steady with no jerking or twisting.',
          'Each rep finishes with the back doing the work, not just the hands moving.',
        ],
      );
    case ExerciseCategory.horizontalPush:
      return const _ExerciseCoachData(
        steps: [
          'Set a clean plank before bending the elbows.',
          'Lower under control so the chest, shoulders, and triceps stay loaded.',
          'Press the floor away evenly with both hands on the way up.',
          'Finish each rep without losing the rib-to-hip connection.',
        ],
        formChecks: [
          'Head, ribs, hips, and heels stay in one line.',
          'Elbows track consistently instead of flaring wider every rep.',
          'The bottom position is controlled instead of bounced.',
        ],
      );
    case ExerciseCategory.squat:
      return const _ExerciseCoachData(
        steps: [
          'Build pressure through the whole foot before you descend.',
          'Let knees and hips bend together so you stay centered.',
          'Reach depth with control instead of dropping into the bottom.',
          'Stand by driving through the full foot and finishing tall.',
        ],
        formChecks: [
          'Heels stay planted through the whole rep.',
          'Knees track with the toes instead of collapsing inward.',
          'The torso stays organized instead of folding suddenly at the bottom.',
        ],
      );
    case ExerciseCategory.hinge:
      return const _ExerciseCoachData(
        steps: [
          'Push the hips back first and keep the spine long as you hinge.',
          'Feel the hamstrings load before changing direction.',
          'Drive the floor away and extend the hips to stand up.',
          'Finish tall without leaning back at lockout.',
        ],
        formChecks: [
          'Back position stays steady throughout the full rep.',
          'The movement comes from the hips, not just the knees moving.',
          'You can feel tension in the posterior chain before standing up.',
        ],
      );
    case ExerciseCategory.core:
      return const _ExerciseCoachData(
        steps: [
          'Exhale just enough to lock the ribs down before the set starts.',
          'Keep the trunk rigid while breathing quietly into the brace.',
          'Stay organized through the shoulders and hips instead of sagging.',
          'Stop the set when position changes, not only when the timer ends.',
        ],
        formChecks: [
          'Lower back position stays consistent throughout the set.',
          'Shoulders and hips stay level instead of rotating.',
          'Breathing happens without losing trunk tension.',
        ],
      );
    case ExerciseCategory.skill:
      return const _ExerciseCoachData(
        steps: [
          'Treat the first rep like practice and build the same setup every time.',
          'Move deliberately enough that you can feel the balance and line.',
          'Pause key positions so you actually own them instead of passing through them.',
          'End the set while the movement still looks sharp.',
        ],
        formChecks: [
          'Your start position is repeatable from set to set.',
          'Line, rhythm, and balance stay predictable through the rep.',
          'You can pause important positions without losing control.',
        ],
      );
  }
}

bool _isTimedExercise(Exercise exercise) {
  final name = exercise.name.toLowerCase();
  final description = exercise.description.toLowerCase();
  return name.contains('hold') ||
      name.contains('hang') ||
      name.contains('plank') ||
      name.contains('lever') ||
      name.contains('handstand') ||
      description.contains('for time');
}

String _branchLabel(String branchId) {
  if (branchId.isEmpty || branchId == 'main') return 'Main line';
  return branchId
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _levelLabel(int difficulty) {
  if (difficulty <= 2) return 'Beginner';
  if (difficulty <= 5) return 'Intermediate';
  if (difficulty <= 7) return 'Advanced';
  return 'Expert';
}

String _formatRestLabel(int seconds) {
  if (seconds <= 0) return 'Off';
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (remainder == 0) return '$minutes min';
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _formatShortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}
