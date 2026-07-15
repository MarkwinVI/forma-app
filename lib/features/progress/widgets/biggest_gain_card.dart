import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/workout_history_model.dart';
import '../../home/home_dashboard_metrics.dart';

/// One exercise's gain across its last few logged sessions.
class BiggestGainEntry {
  final String exerciseId;
  final String name;
  final bool isTimed;
  final int first;
  final int last;
  final int sessionCount;
  final bool isPersonalBest;

  const BiggestGainEntry({
    required this.exerciseId,
    required this.name,
    required this.isTimed,
    required this.first,
    required this.last,
    required this.sessionCount,
    required this.isPersonalBest,
  });

  int get delta => last - first;
  String get unit => isTimed ? 's' : '';
  String get deltaLabel => '+$delta$unit';
}

/// The exercises that improved the most over their last 4 logged sessions,
/// ranked by relative gain so holds, reps, and loads compare fairly.
class BiggestGainData {
  final BiggestGainEntry top;
  final BiggestGainEntry? runnerUp;

  const BiggestGainData({required this.top, this.runnerUp});

  static BiggestGainData? compute(List<PastWorkout> workouts) {
    final sorted = [...workouts]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    // Most-recent-first session totals per exercise, capped at 4, plus the
    // all-time best total for the personal-best chip.
    final windows = <String, List<int>>{};
    final allTimeBest = <String, int>{};
    final names = <String, String>{};
    final timed = <String, bool>{};

    for (final workout in sorted) {
      for (final exercise in workout.exercises) {
        if (exercise.sets.isEmpty) continue;
        final total =
            exercise.sets.fold<int>(0, (sum, set) => sum + set.value);
        final window = windows.putIfAbsent(exercise.exerciseId, () => []);
        if (window.length < 4) window.add(total);
        allTimeBest[exercise.exerciseId] =
            math.max(allTimeBest[exercise.exerciseId] ?? 0, total);
        names.putIfAbsent(exercise.exerciseId, () => exercise.exerciseName);
        timed.putIfAbsent(
          exercise.exerciseId,
          () => exercise.sets.any((set) => set.isTimed),
        );
      }
    }

    final entries = <(double, BiggestGainEntry)>[];
    windows.forEach((exerciseId, window) {
      if (window.length < 2) return;
      final last = window.first;
      final first = window.last;
      final delta = last - first;
      if (delta <= 0 || first <= 0) return;
      entries.add((
        delta / first,
        BiggestGainEntry(
          exerciseId: exerciseId,
          name: names[exerciseId]!,
          isTimed: timed[exerciseId]!,
          first: first,
          last: last,
          sessionCount: window.length,
          isPersonalBest: last >= allTimeBest[exerciseId]!,
        ),
      ));
    });
    if (entries.isEmpty) return null;

    entries.sort((a, b) => b.$1.compareTo(a.$1));
    return BiggestGainData(
      top: entries.first.$2,
      runnerUp: entries.length > 1 ? entries[1].$2 : null,
    );
  }
}

/// "Biggest gain" celebration card at the top of the Progress tab: the
/// exercise that improved the most over its last sessions, with a
/// personal-best chip, the unlock it moves toward, and the runner-up.
class BiggestGainCard extends StatelessWidget {
  final BiggestGainData data;

  /// Active skill paths, used to name the unlock a gain is moving toward.
  final List<JourneySkillProgressData> skills;

  const BiggestGainCard({
    super.key,
    required this.data,
    required this.skills,
  });

  JourneySkillProgressData? _skillFor(BiggestGainEntry entry) {
    for (final skill in skills) {
      if (skill.currentExerciseName == entry.name) return skill;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final top = data.top;
    final runnerUp = data.runnerUp;
    final topSkill = _skillFor(top);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            offset: Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kCardRadius),
          gradient: RadialGradient(
            center: const Alignment(0.9, -1.0),
            radius: 1.35,
            colors: [
              AppColors.green.withValues(alpha: 0.17),
              Colors.transparent,
            ],
            stops: const [0, 0.62],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BIGGEST GAIN · LAST ${top.sessionCount} SESSIONS',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconTile(icon: _exerciseIcon(top.exerciseId), size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          text: '${top.first}${top.unit} → '
                              '${top.last}${top.unit}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: top.isTimed ? ' hold' : ' reps',
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  top.deltaLabel,
                  style: GoogleFonts.robotoMono(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            if (top.isPersonalBest || topSkill != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (top.isPersonalBest)
                    const _Chip(
                      label: 'Personal best',
                      color: AppColors.green,
                      background: AppColors.greenSoft,
                    ),
                  if (topSkill != null)
                    _Chip(
                      label: '≈${topSkill.targetLabel} → '
                          '${topSkill.nextExerciseName} unlock',
                      color: AppColors.textSecondary,
                      background: AppColors.surface2,
                    ),
                ],
              ),
            ],
            if (runnerUp != null) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    IconTile(
                      icon: _exerciseIcon(runnerUp.exerciseId),
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            runnerUp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _runnerUpNote(runnerUp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      runnerUp.deltaLabel,
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _runnerUpNote(BiggestGainEntry entry) {
    final skill = _skillFor(entry);
    if (skill != null && skill.targetVolume > 0) {
      final remaining = skill.targetVolume - skill.lastSessionVolume;
      if (remaining <= 0) return 'ready to unlock ${skill.nextExerciseName}';
      final perSession = entry.delta / (entry.sessionCount - 1);
      if (perSession > 0) {
        final sessions = (remaining / perSession).ceil().clamp(1, 9);
        return 'next unlock ≈$sessions session${sessions == 1 ? '' : 's'} away';
      }
    }
    return 'up ${entry.deltaLabel} over ${entry.sessionCount} sessions';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

IconData _exerciseIcon(String exerciseId) {
  final category = ExerciseCatalog.findById(exerciseId)?.category;
  switch (category) {
    case ExerciseCategory.skill:
      return Icons.self_improvement_rounded;
    case ExerciseCategory.verticalPush:
      return Icons.north_rounded;
    case ExerciseCategory.horizontalPush:
      return Icons.trending_flat_rounded;
    case ExerciseCategory.verticalPull:
      return Icons.arrow_upward_rounded;
    case ExerciseCategory.horizontalPull:
      return Icons.sync_alt_rounded;
    case ExerciseCategory.core:
      return Icons.radio_button_checked_rounded;
    case ExerciseCategory.squat:
      return Icons.accessibility_new_rounded;
    case ExerciseCategory.hinge:
      return Icons.fit_screen_rounded;
    case null:
      return Icons.fitness_center_rounded;
  }
}
