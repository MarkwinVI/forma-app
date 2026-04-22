import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';

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

  bool _loading = true;
  String? _error;
  List<PastWorkout> _workouts = const [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void didUpdateWidget(covariant DataView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isActive && widget.isActive) {
      _loadWorkouts();
    }
  }

  Future<void> _loadWorkouts() async {
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
      final workouts = await _exerciseLogService.fetchPastWorkouts(userId);
      if (!mounted) return;
      setState(() {
        _workouts = workouts;
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

  void _openWorkout(PastWorkout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PastWorkoutDetailView(workout: workout),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.bgTertiary,
          onRefresh: _loadWorkouts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'Data',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Text(
                    'Past workouts',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
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
              else if (_workouts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DataStateMessage(
                    icon: Icons.query_stats_rounded,
                    title: 'No workouts yet',
                    body:
                        'Saved workouts will appear here with every exercise and set.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return _PastWorkoutCard(
                        workout: workout,
                        onTap: () => _openWorkout(workout),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _workouts.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastWorkoutCard extends StatelessWidget {
  final PastWorkout workout;
  final VoidCallback onTap;

  const _PastWorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _WorkoutIcon(sessionType: workout.sessionType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatWorkoutDate(workout.loggedAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.fitness_center_rounded,
                  label: '${workout.exercises.length} exercises',
                ),
                _SummaryChip(
                  icon: Icons.layers_rounded,
                  label: '${workout.totalSets} sets',
                ),
                if (workout.totalReps > 0)
                  _SummaryChip(
                    icon: Icons.repeat_rounded,
                    label: '${workout.totalReps} reps',
                  ),
                if (workout.totalTimedSeconds > 0)
                  _SummaryChip(
                    icon: Icons.timer_outlined,
                    label: _formatSeconds(workout.totalTimedSeconds),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PastWorkoutDetailView extends StatelessWidget {
  final PastWorkout workout;

  const PastWorkoutDetailView({
    super.key,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.bgSecondary,
        elevation: 0,
        title: Text(
          workout.title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _WorkoutDetailHeader(workout: workout),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'EXERCISES',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...workout.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WorkoutExerciseCard(exercise: exercise),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutDetailHeader extends StatelessWidget {
  final PastWorkout workout;

  const _WorkoutDetailHeader({
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _WorkoutIcon(sessionType: workout.sessionType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatWorkoutDate(workout.loggedAt),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDuration(
                          workout.loggedAt.difference(workout.startedAt)),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.fitness_center_rounded,
                label: '${workout.exercises.length} exercises',
              ),
              _SummaryChip(
                icon: Icons.layers_rounded,
                label: '${workout.totalSets} sets',
              ),
              if (workout.totalReps > 0)
                _SummaryChip(
                  icon: Icons.repeat_rounded,
                  label: '${workout.totalReps} reps',
                ),
              if (workout.totalTimedSeconds > 0)
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  label: _formatSeconds(workout.totalTimedSeconds),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutExerciseCard extends StatelessWidget {
  final PastWorkoutExercise exercise;

  const _WorkoutExerciseCard({
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        exercise.isTimed ? const Color(0xFFA78BFA) : AppColors.accentPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${exercise.setCount} sets',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _exerciseTotalLabel(exercise),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise.sets
                .map(
                  (set) => _SetChip(
                    set: set,
                    color: accentColor,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkoutIcon extends StatelessWidget {
  final String sessionType;

  const _WorkoutIcon({
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        _iconForSessionType(sessionType),
        color: AppColors.accentPrimary,
        size: 22,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  final PastWorkoutSet set;
  final Color color;

  const _SetChip({
    required this.set,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = set.isTimed ? '${set.value}s' : '${set.value} reps';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        'Set ${set.number}: $value',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
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
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
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

IconData _iconForSessionType(String sessionType) {
  switch (sessionType) {
    case 'push':
      return Icons.arrow_upward_rounded;
    case 'pull':
      return Icons.arrow_downward_rounded;
    case 'upper':
      return Icons.accessibility_new_rounded;
    case 'lower':
      return Icons.directions_run_rounded;
    case 'full_body':
    default:
      return Icons.sports_gymnastics_rounded;
  }
}

String _exerciseTotalLabel(PastWorkoutExercise exercise) {
  final parts = <String>[];
  if (exercise.totalReps > 0) parts.add('${exercise.totalReps} reps');
  if (exercise.totalTimedSeconds > 0) {
    parts.add(_formatSeconds(exercise.totalTimedSeconds));
  }

  return parts.isEmpty ? 'No completed sets' : parts.join(' · ');
}

String _formatWorkoutDate(DateTime dateTime) {
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
  final month = months[dateTime.month - 1];

  return '$month ${dateTime.day}, ${dateTime.year} at ${_formatTime(dateTime)}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$displayHour:$minute $suffix';
}

String _formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes == 0) return '${remainingSeconds}s';
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  if (hours > 0) {
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}
