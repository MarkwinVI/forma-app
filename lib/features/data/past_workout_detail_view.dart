import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/workout_history_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
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
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    // What deleting this session would do to progression: events of the
    // track's most recent session get rolled back; anything a later workout
    // depends on is preserved. Assessed BEFORE deleting — the session's
    // events cascade away with it.
    SessionRollbackAssessment assessment = const SessionRollbackAssessment(
      reversible: [],
      preserved: [],
    );
    try {
      assessment = await ExerciseProgressionService().assessSessionRollback(
        userId: userId,
        sessionId: workout.id,
        sessionFinishedAt: workout.loggedAt,
      );
    } catch (error, stackTrace) {
      // Best-effort: without the assessment the delete still works, the
      // sheet just shows the generic copy and nothing is rolled back.
      debugPrint('Failed to assess rollback: $error\n$stackTrace');
    }
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ConfirmDeleteSheet(
        message: _deleteMessageFor(assessment),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteWorkout(userId, assessment);
  }

  String _deleteMessageFor(SessionRollbackAssessment assessment) {
    if (assessment.reversible.isNotEmpty) {
      return 'It comes off your history and streak, and the level-ups and '
          'target increases it earned are rolled back. This can’t be undone.';
    }
    if (assessment.preserved.isNotEmpty) {
      return 'It comes off your workout history and statistics. Your current '
          'progression won’t change — you’ve completed later workouts in '
          'this progression.';
    }
    return 'This removes the session and every set you logged in it. '
        'Your stats and calendar will update. This can’t be undone.';
  }

  Future<void> _deleteWorkout(
    String userId,
    SessionRollbackAssessment assessment,
  ) async {
    setState(() => _deleting = true);
    try {
      // Deleting a session only reopens the slot it consumed when it happened
      // today. An older workout is history being corrected, not a plan
      // change — rewinding the pointer there would make every day since then
      // read as missed and drag the whole schedule backwards.
      final loggedOn = TrainingScheduleService.dateOnly(workout.loggedAt);
      final deletedToday = loggedOn.isAtSameMomentAs(
        TrainingScheduleService.dateOnly(DevClockService().now()),
      );

      // Only the day's last remaining session releases the slot; a second
      // workout logged the same day still holds it.
      var wasOnlySessionOfDay = false;
      if (deletedToday) {
        try {
          wasOnlySessionOfDay = await _exerciseLogService
                  .countSessionsOnLocalDate(userId, workout.loggedAt) ==
              1;
        } catch (_) {
          // Count is best-effort; worst case the pointer stays one step ahead
          // and self-heals on the next save.
        }
      }

      await _exerciseLogService.deleteWorkoutSession(userId, workout.id);

      if (wasOnlySessionOfDay) {
        try {
          await TrainingProgramStoreService()
              .syncProgramStateToLatestPlannedWorkout(userId);
        } catch (error, stackTrace) {
          // The workout itself is deleted — a failed sync only leaves the
          // schedule cursor stale and self-heals on the next planned save.
          debugPrint('Failed to sync program state: $error\n$stackTrace');
        }
      }

      if (assessment.reversible.isNotEmpty) {
        try {
          await ExerciseProgressionService().reverseSessionEvents(
            userId: userId,
            events: assessment.reversible,
          );
        } catch (error, stackTrace) {
          // The workout is gone either way; a failed reversal leaves the
          // earned progression in place, which the user can adjust manually.
          debugPrint('Failed to roll back progression: $error\n$stackTrace');
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
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 44),
                children: [
                  TypeTitle(
                    workout.title,
                    sub: '${_formatSessionDate(workout.loggedAt)} · '
                        '${_formatTime(workout.loggedAt)}',
                  ),
                  TypeStatBand(
                    stats: [
                      TypeStat(
                        value: formatWorkoutDuration(elapsed),
                        caption: 'duration',
                      ),
                      TypeStat(
                        value: '${workout.exercises.length}',
                        caption: 'exercises',
                      ),
                    ],
                  ),
                  const TypeSectionLabel('Exercises'),
                  for (var i = 0; i < workout.exercises.length; i++)
                    _ExerciseRow(
                      exercise: workout.exercises[i],
                      last: i == workout.exercises.length - 1,
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
      padding: const EdgeInsets.fromLTRB(19, 10, 22, 0),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          if (deleting)
            const SizedBox(
              width: 26,
              height: 26,
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
            Pressable(
              onTap: onMore,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One exercise as it was performed: the name it was logged under, then the
/// sets themselves as mono lines under it.
class _ExerciseRow extends StatelessWidget {
  final PastWorkoutExercise exercise;
  final bool last;

  const _ExerciseRow({
    required this.exercise,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseModel = ExerciseCatalog.findById(exercise.exerciseId);

    return Container(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: exerciseModel == null
                ? null
                : () => openExerciseDetailView<void>(
                      context,
                      exercise: exerciseModel,
                      initialTab: ExerciseDetailTab.trends,
                    ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.42,
                      height: 1.15,
                    ),
                  ),
                ),
                if (exerciseModel != null) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final set in exercise.sets)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.cardHighlight),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'SET ${set.number}',
                      style: monoStyle(size: 12.5, letterSpacing: 1.25),
                    ),
                  ),
                  Text(
                    _setValueLabel(set),
                    style: monoStyle(
                      size: 14,
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
  final String message;

  const _ConfirmDeleteSheet({required this.message});

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
              Text(
                message,
                style: const TextStyle(
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
