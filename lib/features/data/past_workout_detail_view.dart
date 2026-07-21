import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../exercises/exercise_detail_view.dart';

const Color _deleteRed = Color(0xFFF2564A);

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

  Future<void> _openActionsSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ActionsSheet(workout: workout),
    );
    if (action == 'delete' && mounted) {
      await _confirmDelete();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _ConfirmDeleteSheet(),
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
    final elapsed = workout.loggedAt.difference(workout.startedAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBar(
              deleting: _deleting,
              onBack: () => Navigator.of(context).maybePop(),
              onMore: _openActionsSheet,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_formatSessionDate(workout.loggedAt)} · '
                          '${_formatTime(workout.loggedAt)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SessionStat(
                            label: 'DURATION',
                            value: formatWorkoutDuration(elapsed),
                          ),
                        ),
                        Expanded(
                          child: _SessionStat(
                            label: 'EXERCISES',
                            value: '${workout.exercises.length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(
                    title: 'Exercises',
                  ),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        for (var i = 0; i < workout.exercises.length; i++)
                          _ExerciseRow(
                            exercise: workout.exercises[i],
                            showDivider: i > 0,
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

class _HeaderBar extends StatelessWidget {
  final bool deleting;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _HeaderBar({
    required this.deleting,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _CircleButton(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (deleting)
            const SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            _CircleButton(
              onTap: onMore,
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CircleButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final String label;
  final String value;

  const _SessionStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final PastWorkoutExercise exercise;
  final bool showDivider;

  const _ExerciseRow({
    required this.exercise,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseModel = ExerciseCatalog.findById(exercise.exerciseId);
    final subtitle = exerciseModel?.category.label ?? 'Exercise';

    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: exerciseModel == null
                ? null
                : () => openExerciseDetailView<void>(
                      context,
                      exercise: exerciseModel,
                      initialTab: ExerciseDetailTab.summary,
                    ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 3),
              child: Row(
                children: [
                  IconTile(
                    icon: _categoryGlyph(exerciseModel?.category),
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
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
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 3, 4, 13),
            child: Column(
              children: [
                for (var i = 0; i < exercise.sets.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set ${exercise.sets[i].number}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _setValueLabel(exercise.sets[i]),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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

// ── Bottom sheets ───────────────────────────────────────────────────────

class _ActionsSheet extends StatelessWidget {
  final PastWorkout workout;

  const _ActionsSheet({required this.workout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(kCardRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_formatSessionDate(workout.loggedAt)} · '
                          '${_formatTime(workout.loggedAt)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  Pressable(
                    onTap: () => Navigator.of(context).pop('delete'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: _deleteRed,
                          ),
                          SizedBox(width: 13),
                          Text(
                            'Delete session',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: _deleteRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Pressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDeleteSheet extends StatelessWidget {
  const _ConfirmDeleteSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete this session?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'It comes off your history and streak, and any level-ups it '
                'earned are rolled back. This can’t be undone.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Pressable(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _deleteRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Delete session',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Pressable(
                onTap: () => Navigator.of(context).pop(false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text(
                    'Keep it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Formatting helpers ──────────────────────────────────────────────────

IconData _categoryGlyph(ExerciseCategory? category) {
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
    case null:
      return Icons.fitness_center_rounded;
  }
}

String _setValueLabel(PastWorkoutSet set) {
  return set.isTimed ? '${set.value}s hold' : '${set.value} reps';
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

String _formatSessionDate(DateTime dateTime) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
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
  final weekday = weekdays[dateTime.weekday - 1];
  final month = months[dateTime.month - 1];

  return '$weekday, $month ${dateTime.day}';
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
    return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '$minutes:${twoDigits(seconds)}';
}
