import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../exercises/exercise_detail_view.dart';

/// Detail page for one saved workout. Pops with `true` when the session
/// was deleted so callers can refresh their data.
class PastWorkoutDetailView extends StatefulWidget {
  final PastWorkout workout;

  const PastWorkoutDetailView({
    super.key,
    required this.workout,
  });

  @override
  State<PastWorkoutDetailView> createState() => _PastWorkoutDetailViewState();
}

class _PastWorkoutDetailViewState extends State<PastWorkoutDetailView> {
  final _exerciseLogService = ExerciseLogService();
  bool _deleting = false;

  PastWorkout get workout => widget.workout;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete workout?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This removes the session and every set you logged in it. '
          'Your stats and calendar will update. This can’t be undone.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF5C5C),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteWorkout();
  }

  Future<void> _deleteWorkout() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    setState(() => _deleting = true);
    try {
      // Saving the first workout of a local day advances the program
      // pointer, so deleting the only workout of that day rewinds it —
      // the session becomes due again on the Home dashboard.
      var wasOnlySessionOfDay = false;
      try {
        wasOnlySessionOfDay = await _exerciseLogService
                .countSessionsOnLocalDate(userId, workout.loggedAt) ==
            1;
      } catch (_) {
        // Count is best-effort; worst case the pointer stays one step ahead
        // and self-heals on the next save.
      }

      await _exerciseLogService.deleteWorkoutSession(userId, workout.id);

      if (wasOnlySessionOfDay) {
        try {
          await TrainingProgramStoreService()
              .rewindProgramStateAfterWorkoutDeletion(userId);
        } catch (error, stackTrace) {
          // The workout itself is deleted — a failed rewind only leaves the
          // schedule one session ahead and self-heals on the next save.
          debugPrint('Failed to rewind program state: $error\n$stackTrace');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface2,
          content: Text(
            'Couldn’t delete the workout. Try again.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_deleting)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _confirmDelete,
              tooltip: 'Delete workout',
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _WorkoutDetailHeader(workout: workout),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'EXERCISES',
                style: TextStyle(
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
              WorkoutTypeIcon(sessionType: workout.sessionType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatWorkoutDate(workout.loggedAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatWorkoutDuration(
                          workout.loggedAt.difference(workout.startedAt)),
                      style: const TextStyle(
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
              WorkoutSummaryChip(
                icon: Icons.fitness_center_rounded,
                label: '${workout.exercises.length} exercises',
              ),
              WorkoutSummaryChip(
                icon: Icons.layers_rounded,
                label: '${workout.totalSets} sets',
              ),
              if (workout.totalReps > 0)
                WorkoutSummaryChip(
                  icon: Icons.repeat_rounded,
                  label: '${workout.totalReps} reps',
                ),
              if (workout.totalTimedSeconds > 0)
                WorkoutSummaryChip(
                  icon: Icons.timer_outlined,
                  label: formatWorkoutSeconds(workout.totalTimedSeconds),
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
    final exerciseModel = ExerciseCatalog.findById(exercise.exerciseId);

    return GestureDetector(
      onTap: exerciseModel == null
          ? null
          : () => openExerciseDetailView<void>(
                context,
                exercise: exerciseModel,
                accentColor: accentColor,
                initialTab: ExerciseDetailTab.summary,
              ),
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${exercise.setCount} sets',
                  style: const TextStyle(
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
              style: const TextStyle(
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
      ),
    );
  }
}

class WorkoutTypeIcon extends StatelessWidget {
  final String sessionType;

  const WorkoutTypeIcon({
    super.key,
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
        workoutIconForSessionType(sessionType),
        color: AppColors.accentPrimary,
        size: 22,
      ),
    );
  }
}

class WorkoutSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const WorkoutSummaryChip({
    super.key,
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
            style: const TextStyle(
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

IconData workoutIconForSessionType(String sessionType) {
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
    parts.add(formatWorkoutSeconds(exercise.totalTimedSeconds));
  }

  return parts.isEmpty ? 'No completed sets' : parts.join(' · ');
}

String formatWorkoutDate(DateTime dateTime) {
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

String formatWorkoutSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes == 0) return '${remainingSeconds}s';
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

String formatWorkoutDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  if (hours > 0) {
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}
