import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/user_profile_service.dart';
import '../settings/settings_view.dart';
import '../exercises/exercise_picker_view.dart';
import 'bodyweight_row.dart';
import 'calendar_view.dart';
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
  final _profileService = UserProfileService();

  bool _loading = true;
  String? _error;
  List<PastWorkout> _workouts = const [];
  double? _bodyweightKg;
  bool _bodyweightJustSaved = false;

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
      final workouts = await _exerciseLogService.fetchPastWorkouts(userId);

      // Best-effort: the tab still works without a bodyweight to show.
      double? bodyweightKg;
      try {
        bodyweightKg = await _profileService.fetchBodyweightKg(userId);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _bodyweightKg = bodyweightKg;
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

  /// The same catalogue people meet when adding an exercise to a day, in
  /// browse mode — one search, one set of filters, learned once.
  void _openExercises() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExercisePickerView.browse(),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
    await _loadData();
  }

  Future<void> _openBodyweightSheet() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    final savedKg = await showBodyweightSheet(
      context,
      kg: _bodyweightKg,
      now: _devClockService.now(),
    );
    if (savedKg == null || !mounted) return;

    final previous = _bodyweightKg;
    setState(() {
      _bodyweightKg = savedKg;
      _bodyweightJustSaved = true;
    });
    try {
      await _profileService.updateBodyweightKg(userId, savedKg);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bodyweightKg = previous;
        _bodyweightJustSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update bodyweight.")),
      );
    }
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
            // Attached to the shell's per-tab controller, so re-tapping the
            // tab scrolls back to the top.
            primary: true,
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
        now: now,
        onDataChanged: _loadData,
        showActivityHeatmap: false,
      ),
      BodyweightRow(
        kg: _bodyweightKg,
        savedNow: _bodyweightJustSaved,
        onOpen: _openBodyweightSheet,
      ),
      const TypeSectionLabel('Recent sessions'),
      if (recentWorkouts.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Saved workouts will appear here.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        )
      else
        for (var i = 0; i < recentWorkouts.length; i++)
          TypeContentRow(
            name: recentWorkouts[i].title,
            sub: _relativeSessionLabel(recentWorkouts[i].loggedAt, now: now),
            right: _formatElapsedShort(
              recentWorkouts[i].loggedAt.difference(
                    recentWorkouts[i].startedAt,
                  ),
            ),
            rightSub: _sessionCountLabel(recentWorkouts[i]),
            last: i == recentWorkouts.length - 1,
            onTap: () => _openWorkout(recentWorkouts[i]),
          ),
      // More of the same list is a written action, not another row that looks
      // like a session.
      if (_workouts.length > recentWorkouts.length)
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
              onTap: _openAllSessions,
              child: const Text(
                'View all sessions  →',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      const TypeSectionLabel('Library'),
      TypeContentRow(
        name: 'All exercises',
        sub: 'Browse by movement pattern',
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
