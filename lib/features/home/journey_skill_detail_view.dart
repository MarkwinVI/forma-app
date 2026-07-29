import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../exercises/exercise_detail_view.dart';
import '../skills/widgets/exercise_preview_sheet.dart';
import 'home_dashboard_metrics.dart';

const _detailShell = Color(0xFF111114);
const _detailCard = Color(0xFF1C1C20);
const _detailCardAlt = Color(0xFF2A2A2E);
const _detailBorder = Color(0xFF323237);
const _detailText = Color(0xFFF5F5F7);
const _detailTextSecondary = Color(0xFF9C9CA3);
const _detailTextTertiary = Color(0xFF6C6C73);
const _detailAccent = AppColors.accentPrimary;
const _detailAccentSoft = AppColors.accentSoft;
const _detailGreen = Color(0xFF4CC97E);

class JourneySkillDetailView extends StatelessWidget {
  final JourneySkillProgressData skill;

  const JourneySkillDetailView({
    super.key,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    final orderedStages = skill.stages;
    final clearedCount = skill.stages
        .where((stage) => stage.status == JourneySkillStageStatus.cleared)
        .length;
    final inProgressCount = skill.stages
        .where((stage) => stage.status == JourneySkillStageStatus.inProgress)
        .length;
    final lockedCount = skill.stages
        .where((stage) => stage.status == JourneySkillStageStatus.locked)
        .length;

    return Scaffold(
      backgroundColor: _detailShell,
      appBar: AppBar(
        backgroundColor: _detailShell,
        elevation: 0,
        foregroundColor: _detailText,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _detailCardAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(
                _trackIcon(skill.track),
                size: 20,
                color: _detailText,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${skill.motionLabel.toUpperCase()} TREE',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _detailTextTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    skill.skillTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _detailText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const Text(
            'PROGRESSION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _detailTextSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$clearedCount cleared',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _detailGreen,
                  ),
                ),
                const TextSpan(
                  text: ' · ',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _detailTextSecondary,
                  ),
                ),
                TextSpan(
                  text: '$inProgressCount in progress',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _detailAccent,
                  ),
                ),
                const TextSpan(
                  text: ' · ',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _detailTextSecondary,
                  ),
                ),
                TextSpan(
                  text: '$lockedCount locked',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _detailTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < orderedStages.length; index++)
            _JourneyStageRow(
              stage: orderedStages[index],
              skillCategoryId: skill.skillCategoryId,
              isLast: index == orderedStages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _JourneyStageRow extends StatelessWidget {
  final JourneySkillStageData stage;
  final String skillCategoryId;
  final bool isLast;

  const _JourneyStageRow({
    required this.stage,
    required this.skillCategoryId,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _metaForStage(stage.status);
    final exercise = ExerciseCatalog.findById(stage.exerciseId);
    final difficultyLabel = exercise == null
        ? 'Goal ${stage.targetLabel}'
        : 'Difficulty ${exercise.difficulty}/5 · Goal ${stage.targetLabel}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 17),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stage.status == JourneySkillStageStatus.locked
                      ? _detailShell
                      : meta.color,
                  border: Border.all(color: meta.color, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 178,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: _detailBorder,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
            decoration: BoxDecoration(
              color: _detailCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stage.status == JourneySkillStageStatus.inProgress
                    ? _detailAccent
                    : _detailBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.exerciseName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _detailText,
                              letterSpacing: -0.1,
                            ),
                          )._tap(
                            exercise == null
                                ? null
                                : () => _showExerciseSheet(
                                      context,
                                      exercise,
                                    ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            difficultyLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _detailTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: meta.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meta.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: meta.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (stage.status == JourneySkillStageStatus.locked &&
                    stage.history.isEmpty)
                  _LockedStageNotice(stage: stage)
                else if (stage.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No session history yet.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _detailTextSecondary,
                      ),
                    ),
                  )
                else
                  _JourneyStageChart(
                    stage: stage,
                    barColor: meta.color,
                    dimBarColor: meta.dimBarColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExerciseSheet(
    BuildContext context,
    Exercise exercise,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => ExercisePreviewSheet(
        exercise: exercise,
        skillCategoryId: skillCategoryId,
        onLearnMore: () {
          Navigator.of(sheetContext).pop();
          openExerciseDetailView<void>(
            context,
            exercise: exercise,
            accentColor: _accentForExerciseCategory(exercise.category),
            skillCategoryId: skillCategoryId,
          );
        },
      ),
    );
  }
}

extension on Widget {
  Widget _tap(VoidCallback? onTap) {
    if (onTap == null) return this;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: this,
    );
  }
}

class _LockedStageNotice extends StatelessWidget {
  final JourneySkillStageData stage;

  const _LockedStageNotice({
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _detailShell,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: _detailTextTertiary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Unlocks once you clear '),
                  TextSpan(
                    text: stage.unlockRequirementName ?? 'the previous step',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _detailText,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: const TextStyle(
                fontSize: 12.5,
                color: _detailTextSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStageChart extends StatelessWidget {
  final JourneySkillStageData stage;
  final Color barColor;
  final Color dimBarColor;

  const _JourneyStageChart({
    required this.stage,
    required this.barColor,
    required this.dimBarColor,
  });

  @override
  Widget build(BuildContext context) {
    final targetValue = stage.targetVolume > 0
        ? stage.targetVolume
        : stage.history
            .map((point) => point.value)
            .fold<int>(0, (best, value) => value > best ? value : best);
    final historyMax = stage.history
        .map((point) => point.value)
        .fold<int>(0, (best, value) => value > best ? value : best);
    final scaleMax =
        ((targetValue > historyMax ? targetValue : historyMax) * 1.12)
            .clamp(1, 100000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 112,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Bars scale against the height minus the value label that sits
              // on top of each bar, so a 100%-of-goal bar still fits.
              const labelSpace = 20.0;
              final barSpace = constraints.maxHeight - labelSpace;
              final goalBottom = barSpace * (targetValue / scaleMax);
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: goalBottom.clamp(0, barSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'GOAL ${stage.targetLabel}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _detailAccent,
                            letterSpacing: 0.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 1.5,
                          color: _detailAccent.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < stage.history.length; index++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == stage.history.length - 1 ? 0 : 10,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _volumeLabel(stage.history[index].value),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: index == stage.history.length - 1
                                        ? _detailText
                                        : _detailTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(maxWidth: 38),
                                  height: barSpace *
                                      (stage.history[index].value / scaleMax),
                                  decoration: BoxDecoration(
                                    color: index == stage.history.length - 1
                                        ? barColor
                                        : dimBarColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var index = 0; index < stage.history.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stage.history.length - 1 ? 0 : 10,
                  ),
                  child: Text(
                    _dateLabel(stage.history[index].loggedAt),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _detailTextTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _volumeLabel(int value) {
    final suffix = stage.targetLabel.endsWith('s') ? 's' : ' reps';
    return '$value$suffix';
  }

  String _dateLabel(DateTime date) {
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
}

class _StageMeta {
  final String label;
  final Color color;
  final Color background;
  final Color dimBarColor;

  const _StageMeta({
    required this.label,
    required this.color,
    required this.background,
    required this.dimBarColor,
  });
}

_StageMeta _metaForStage(JourneySkillStageStatus status) {
  switch (status) {
    case JourneySkillStageStatus.cleared:
      return const _StageMeta(
        label: 'CLEARED',
        color: _detailGreen,
        background: Color(0x214CC97E),
        dimBarColor: Color(0x474CC97E),
      );
    case JourneySkillStageStatus.inProgress:
      return const _StageMeta(
        label: 'IN PROGRESS',
        color: _detailAccent,
        background: _detailAccentSoft,
        dimBarColor: Color(0x523D7BFF),
      );
    case JourneySkillStageStatus.locked:
      return const _StageMeta(
        label: 'LOCKED',
        color: _detailTextTertiary,
        background: _detailCardAlt,
        dimBarColor: _detailCardAlt,
      );
  }
}

IconData _trackIcon(TrainingTrack track) {
  switch (track) {
    case TrainingTrack.skillWork:
      return Icons.self_improvement_rounded;
    case TrainingTrack.verticalPush:
      return Icons.north_rounded;
    case TrainingTrack.horizontalPush:
      return Icons.trending_flat_rounded;
    case TrainingTrack.verticalPull:
      return Icons.arrow_upward_rounded;
    case TrainingTrack.horizontalPull:
      return Icons.sync_alt_rounded;
    case TrainingTrack.core:
      return Icons.radio_button_checked_rounded;
    case TrainingTrack.squat:
      return Icons.accessibility_new_rounded;
    case TrainingTrack.hinge:
      return Icons.fit_screen_rounded;
  }
}

Color _accentForExerciseCategory(ExerciseCategory category) {
  switch (category) {
    case ExerciseCategory.verticalPull:
      return const Color(0xFF4CC9F0);
    case ExerciseCategory.verticalPush:
      return const Color(0xFFFF9F43);
    case ExerciseCategory.horizontalPull:
      return const Color(0xFF6EC1E4);
    case ExerciseCategory.horizontalPush:
      return const Color(0xFFFC5200);
    case ExerciseCategory.squat:
      return const Color(0xFF7ED957);
    case ExerciseCategory.hinge:
      return const Color(0xFFC9A227);
    case ExerciseCategory.core:
      return const Color(0xFF4CC9F0);
    case ExerciseCategory.skill:
      return const Color(0xFFA66CFF);
    case ExerciseCategory.other:
      return const Color(0xFF9AA0AA);
  }
}
