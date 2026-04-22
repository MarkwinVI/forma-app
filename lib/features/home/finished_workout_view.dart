import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import 'completed_workout_model.dart';

class FinishedWorkoutView extends StatefulWidget {
  final CompletedWorkout workout;

  const FinishedWorkoutView({
    super.key,
    required this.workout,
  });

  @override
  State<FinishedWorkoutView> createState() => _FinishedWorkoutViewState();
}

class _FinishedWorkoutViewState extends State<FinishedWorkoutView>
    with SingleTickerProviderStateMixin {
  final _exerciseLogService = ExerciseLogService();
  late final AnimationController _confettiController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (_saving) return;

    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to save this workout.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _exerciseLogService.saveWorkoutSession(
        userId: userId,
        title: widget.workout.historyTitle,
        sessionType: widget.workout.sessionType.dbValue,
        startedAt: widget.workout.startedAt,
        finishedAt: widget.workout.finishedAt,
        exercises: widget.workout.exercises.map((exerciseEntry) {
          final sets = exerciseEntry.sets
              .map(
                (set) => ExerciseSet(
                  reps: set.isTimed ? 0 : set.value,
                  durationSeconds: set.isTimed ? set.value : 0,
                ),
              )
              .toList();

          return WorkoutExerciseLogInput(
            exerciseId: exerciseEntry.exercise.id,
            sets: sets,
          );
        }).toList(),
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save workout: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter:
                      _ConfettiPainter(progress: _confettiController.value),
                  size: Size.infinite,
                );
              },
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _CelebrationHeader(workout: workout),
                const SizedBox(height: 18),
                _MetricGrid(workout: workout),
                const SizedBox(height: 22),
                _ExerciseOverviewList(workout: workout),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppColors.bgSecondary,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.35),
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: LoadingIndicator(),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 20),
              label: Text(
                _saving ? 'Saving' : 'Save workout',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationHeader extends StatelessWidget {
  final CompletedWorkout workout;

  const _CelebrationHeader({
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.18),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.accentPrimary,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            workout.historyTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF25272B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatFinishedAt(workout.finishedAt),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A9CA1),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: _formatDuration(workout.totalDuration),
                  label: 'Total duration',
                ),
              ),
              Container(
                width: 1,
                height: 54,
                color: const Color(0xFFE9EAEC),
              ),
              Expanded(
                child: _HeroStat(
                  value: workout.totalSets.toString(),
                  label: 'Sets logged',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF25272B),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9A9CA1),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final CompletedWorkout workout;

  const _MetricGrid({
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    final timedSeconds = workout.totalTimedSeconds;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.95,
      children: [
        _MetricTile(
          icon: Icons.fitness_center_rounded,
          value: workout.exercises.length.toString(),
          label: 'Exercises',
        ),
        _MetricTile(
          icon: Icons.repeat_rounded,
          value: workout.totalReps.toString(),
          label: 'Total reps',
        ),
        _MetricTile(
          icon: Icons.timer_outlined,
          value: timedSeconds > 0 ? _formatShortDuration(timedSeconds) : '0s',
          label: 'Hold time',
        ),
        _MetricTile(
          icon: Icons.layers_rounded,
          value: workout.totalSets.toString(),
          label: 'Total sets',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
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

class _ExerciseOverviewList extends StatelessWidget {
  final CompletedWorkout workout;

  const _ExerciseOverviewList({
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'WORKOUT OVERVIEW',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...workout.exercises.map(
          (exercise) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExerciseSummaryCard(exercise: exercise),
          ),
        ),
      ],
    );
  }
}

class _ExerciseSummaryCard extends StatelessWidget {
  final CompletedWorkoutExercise exercise;

  const _ExerciseSummaryCard({
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        exercise.isTimed ? const Color(0xFFA78BFA) : AppColors.accentPrimary;
    final totalLabel = exercise.isTimed
        ? _formatShortDuration(exercise.totalTimedSeconds)
        : '${exercise.totalReps} reps';

    return Container(
      padding: const EdgeInsets.all(16),
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
                  exercise.exercise.name,
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
                '${exercise.sets.length} sets',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${exercise.track.label} · $totalLabel',
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
                  (set) => _SetSummaryChip(
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

class _SetSummaryChip extends StatelessWidget {
  final CompletedWorkoutSet set;
  final Color color;

  const _SetSummaryChip({
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

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(18);
    const colors = [
      Color(0xFFFF6900),
      Color(0xFFA78BFA),
      Color(0xFF4ECDC4),
      Color(0xFF34D399),
      Color(0xFFFFD166),
      Color(0xFFFF6B9A),
    ];

    for (var i = 0; i < 72; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.55 + random.nextDouble() * 0.9;
      final sway = math.sin((progress * math.pi * 2) + i) * 16;
      final x = baseX + sway;
      final y =
          ((baseY + progress * size.height * speed) % (size.height + 70)) - 35;
      final width = 4 + random.nextDouble() * 5;
      final height = 9 + random.nextDouble() * 12;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.52);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + random.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

String _formatFinishedAt(DateTime dateTime) {
  final now = DateTime.now();
  final sameDay = now.year == dateTime.year &&
      now.month == dateTime.month &&
      now.day == dateTime.day;
  final datePrefix =
      sameDay ? 'Today' : '${dateTime.month}/${dateTime.day}/${dateTime.year}';

  return '$datePrefix at ${_formatTime(dateTime)}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$displayHour:$minute $suffix';
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

String _formatShortDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes == 0) return '${remainingSeconds}s';
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}
