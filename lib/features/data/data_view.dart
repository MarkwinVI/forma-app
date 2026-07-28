import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/training_program_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../settings/settings_view.dart';
import 'calendar_view.dart';
import 'exercises_browse_view.dart';
import 'past_workout_detail_view.dart';

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
  final _devClockService = DevClockService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  String? _error;
  List<PastWorkout> _workouts = const [];
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
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _devClockService.loadOffset();
      final results = await Future.wait([
        _exerciseLogService.fetchPastWorkouts(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
      ]);
      final workouts = results[0] as List<PastWorkout>;
      final logicSnapshot = results[1] as TrainingProgramLogicSnapshot?;

      if (!mounted) return;
      setState(() {
        _workouts = workouts;
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

  void _openExercises() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisesBrowseView(workouts: _workouts),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
    await _loadData();
  }

  void _openAllSessions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AllSessionsView(
          workouts: _workouts,
          now: _devClockService.now(),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: TypeTitle('Profile')),
                      Pressable(
                        onTap: _openSettings,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 6, left: 12),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
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
    final recentWorkouts = _workouts.take(3).toList();
    final now = _devClockService.now();

    return [
      CalendarPanel(
        workouts: _workouts,
        weeklyGoal: _weeklyGoal,
        now: now,
        onDataChanged: _loadData,
        showActivityHeatmap: false,
      ),
      const TypeSectionLabel('Recent sessions'),
      if (recentWorkouts.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Saved workouts will appear here with every exercise and set.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        )
      else
        for (final workout in recentWorkouts)
          TypeContentRow(
            name: workout.title,
            sub: _relativeSessionLabel(workout.loggedAt, now: now),
            right: _formatElapsedShort(
              workout.loggedAt.difference(workout.startedAt),
            ),
            rightSub: _sessionCountLabel(workout),
            onTap: () => _openWorkout(workout),
          ),
      if (_workouts.length > 3)
        TypeContentRow(
          name: 'All sessions',
          nameSize: 18.5,
          onTap: _openAllSessions,
        ),
      TypeContentRow(
        name: 'Browse all exercises',
        nameSize: 18.5,
        last: true,
        onTap: _openExercises,
      ),
    ];
  }
}

/// The mono caption under a session's duration — what it was made of.
String _sessionCountLabel(PastWorkout workout) {
  return [
    '${workout.totalSets} sets',
    if (workout.totalReps > 0) '${workout.totalReps} reps',
    if (workout.totalTimedSeconds > 0)
      formatWorkoutSeconds(workout.totalTimedSeconds),
  ].join(' · ');
}

// ── Sessions ──────────────────────────────────────────────────────────

class _AllSessionsView extends StatefulWidget {
  final List<PastWorkout> workouts;
  final DateTime now;
  final VoidCallback onDataChanged;

  const _AllSessionsView({
    required this.workouts,
    required this.now,
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
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 44),
                children: [
                  if (_workouts.isEmpty)
                    const Text(
                      'No saved sessions.',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < _workouts.length; i++)
                      TypeContentRow(
                        name: _workouts[i].title,
                        sub: _relativeSessionLabel(
                          _workouts[i].loggedAt,
                          now: widget.now,
                        ),
                        right: _formatElapsedShort(
                          _workouts[i]
                              .loggedAt
                              .difference(_workouts[i].startedAt),
                        ),
                        rightSub: _sessionCountLabel(_workouts[i]),
                        last: i == _workouts.length - 1,
                        onTap: () => _openWorkout(_workouts[i]),
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

String _relativeSessionLabel(DateTime dateTime, {required DateTime now}) {
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
