import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/training_program_model.dart';
import 'getting_started_checklist.dart';
import 'home_dashboard_metrics.dart';

class HomeDashboardContent extends StatelessWidget {
  final HomeTodaySummary todaySummary;
  final HomeWeekStripData weekStrip;
  final JourneySnapshotData journeySnapshot;
  final List<ActiveSkillPathData> activeSkillPaths;
  final List<HomeExercisePerformance> exercisePerformance;
  final List<HomeGoalSkillData> goalSkills;
  final int nodesClearedAllTime;
  final bool showGettingStarted;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProgramSettings;
  final VoidCallback onEditGoals;
  final ValueChanged<JourneySkillProgressData> onOpenJourneySkill;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;
  final ValueChanged<HomeGoalSkillData> onOpenGoalSkill;

  const HomeDashboardContent({
    super.key,
    required this.todaySummary,
    required this.weekStrip,
    required this.journeySnapshot,
    required this.activeSkillPaths,
    required this.exercisePerformance,
    required this.goalSkills,
    required this.nodesClearedAllTime,
    this.showGettingStarted = false,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.onOpenSettings,
    required this.onOpenProgramSettings,
    required this.onEditGoals,
    required this.onOpenJourneySkill,
    required this.onOpenSkillPath,
    required this.onOpenGoalSkill,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Today',
            actions: [
              HeaderCircleButton(
                icon: Icons.settings_outlined,
                onTap: onOpenSettings,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _TodayCard(
                  summary: todaySummary,
                  onPrimaryAction: onPrimaryAction,
                  onSecondaryAction: onSecondaryAction,
                ),
                const SizedBox(height: 12),
                _WeekCalendarCard(data: weekStrip),
                const SizedBox(height: 12),
                _ProgramOverviewRow(onTap: onOpenProgramSettings),
                if (showGettingStarted) ...[
                  const SectionHeader(title: 'Getting started'),
                  GettingStartedChecklist(
                    programDone: true,
                    onStartWorkout: onPrimaryAction,
                  ),
                ],
                SectionHeader(
                  title: 'Your skill trees',
                  sub: '$nodesClearedAllTime node'
                      '${nodesClearedAllTime == 1 ? '' : 's'}'
                      ' cleared all-time',
                ),
                _ClosestSkillsCard(
                  data: journeySnapshot,
                  onOpenSkillPath: onOpenJourneySkill,
                ),
                const SectionHeader(
                  title: 'Exercise performance',
                  sub: 'Session totals vs your previous session',
                ),
                _ExercisePerformanceCard(rows: exercisePerformance),
                SectionHeader(
                  title: 'Long-term goals',
                  sub: goalSkills.isEmpty
                      ? null
                      : "The skills you're climbing toward",
                  action: goalSkills.isEmpty ? null : 'Edit',
                  onAction: goalSkills.isEmpty ? null : onEditGoals,
                ),
                if (goalSkills.isEmpty)
                  _GoalsEmptyCard(onAddGoals: onEditGoals)
                else
                  _GoalSkillsCard(
                    goals: goalSkills,
                    onOpenGoalSkill: onOpenGoalSkill,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero: today's workout ───────────────────────────────────

class _TodayCard extends StatefulWidget {
  final HomeTodaySummary summary;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const _TodayCard({
    required this.summary,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final completed = summary.completed;
    if (completed != null) {
      return _buildCompletedState(completed);
    }
    final plannedExercises = summary.plannedExercises;
    final visibleExercises =
        _isExpanded ? plannedExercises : plannedExercises.take(4).toList();
    final canToggleExercises = plannedExercises.length > 4;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.sessionTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.48,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            summary.isRestDay
                ? summary.supportingText
                : '${summary.estimatedDurationMinutes} min · ${summary.exerciseCount} exercises',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (visibleExercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < visibleExercises.length; index++)
              _PlannedExerciseRow(
                exercise: visibleExercises[index],
                showDivider: index > 0,
              ),
          ],
          if (canToggleExercises)
            Pressable(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? 'Show fewer'
                          : 'Show all ${plannedExercises.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          PillButton(
            label: summary.ctaLabel,
            icon: Icons.play_arrow_rounded,
            color: summary.isRestDay ? null : AppColors.startOrange,
            onTap: widget.onPrimaryAction,
          ),
          if (!summary.isRestDay) ...[
            const SizedBox(height: 10),
            PillButton(
              label: 'Train something else',
              tonal: true,
              onTap: widget.onSecondaryAction,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedState(HomeCompletedWorkoutSummary completed) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout complete',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.48,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${completed.title} · ${completed.durationMinutes} min'
                      ' · ${completed.setCount}'
                      ' set${completed.setCount == 1 ? '' : 's'} logged',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'That’s today done — next up: ${completed.nextSessionLabel} '
            'tomorrow.',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'Train something else',
            tonal: true,
            onTap: widget.onSecondaryAction,
          ),
        ],
      ),
    );
  }
}

class _PlannedExerciseRow extends StatelessWidget {
  final HomePlannedExerciseSummary exercise;
  final bool showDivider;

  const _PlannedExerciseRow({
    required this.exercise,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final hasPath = exercise.nodeStates.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.5),
      decoration: BoxDecoration(
        border: Border(
          top: showDivider
              ? const BorderSide(color: AppColors.divider)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                exercise.targetLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (hasPath) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                _PathDots(nodeStates: exercise.nodeStates),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    exercise.treeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact node-progress dots: green mastered, blue working, muted upcoming.
class _PathDots extends StatelessWidget {
  final List<PathNodeState> nodeStates;

  const _PathDots({required this.nodeStates});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < nodeStates.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          _dot(nodeStates[index]),
        ],
      ],
    );
  }

  Widget _dot(PathNodeState state) {
    switch (state) {
      case PathNodeState.mastered:
        return Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.greenSoft, spreadRadius: 3),
            ],
          ),
        );
      case PathNodeState.working:
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.accentPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.accentSoft, spreadRadius: 5),
            ],
          ),
        );
      case PathNodeState.upcoming:
        return Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.surface3,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

// ── Week calendar — boxed day cells ─────────────────────────

class _WeekCalendarCard extends StatelessWidget {
  final HomeWeekStripData data;

  const _WeekCalendarCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (var index = 0; index < data.days.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index > 0 ? 6 : 0),
                child: _WeekDayCell(day: data.days[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  final HomeWeekStripDay day;

  const _WeekDayCell({
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day.isCurrent;
    final isDone = day.isCompleted;
    final isRest = day.isRestDay;

    final background = isToday
        ? AppColors.accentPrimary
        : isDone
            ? AppColors.accentSoft
            : isRest
                ? Colors.white.withValues(alpha: 0.03)
                : AppColors.surface2;
    final dayColor =
        isToday ? Colors.white.withValues(alpha: 0.75) : AppColors.textMuted;
    final labelColor = isToday
        ? Colors.white
        : isRest
            ? AppColors.textMuted
            : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 9, 0, 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _weekdayLetter(day.date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: dayColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _sessionLabel(day),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: -0.12,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 13,
            child: Center(
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      size: 12,
                      color:
                          isToday ? Colors.white : AppColors.accentPrimary,
                    )
                  : isToday
                      ? Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLetter(DateTime date) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  String _sessionLabel(HomeWeekStripDay day) {
    switch (day.sessionType) {
      case TrainingSessionType.fullBody:
        return 'Full';
      case TrainingSessionType.push:
        return 'Push';
      case TrainingSessionType.pull:
        return 'Pull';
      case TrainingSessionType.upper:
        return 'Upper';
      case TrainingSessionType.lower:
        return 'Lower';
      case TrainingSessionType.rest:
        return 'Rest';
    }
  }
}

// ── Program overview row (kept under the calendar) ──────────

class _ProgramOverviewRow extends StatelessWidget {
  final VoidCallback onTap;

  const _ProgramOverviewRow({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: const Row(
        children: [
          IconTile(icon: Icons.tune_rounded),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Program overview',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Closest to levelling up ─────────────────────────────────

class _ClosestSkillsCard extends StatefulWidget {
  final JourneySnapshotData data;
  final ValueChanged<JourneySkillProgressData> onOpenSkillPath;

  const _ClosestSkillsCard({
    required this.data,
    required this.onOpenSkillPath,
  });

  @override
  State<_ClosestSkillsCard> createState() => _ClosestSkillsCardState();
}

class _ClosestSkillsCardState extends State<_ClosestSkillsCard> {
  static const _collapsedCount = 3;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final skills = widget.data.closestSkills;
    final visibleSkills =
        _showAll ? skills : skills.take(_collapsedCount).toList();
    final canToggle = skills.length > _collapsedCount;

    if (skills.isEmpty) {
      return const SurfaceCard(
        padding: EdgeInsets.all(18),
        child: Text(
          'No active skill progress yet.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SurfaceCard(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < visibleSkills.length; index++)
            _JourneySkillRow(
              data: visibleSkills.elementAt(index),
              showDivider: index > 0,
              onTap: () =>
                  widget.onOpenSkillPath(visibleSkills.elementAt(index)),
            ),
          if (canToggle)
            Pressable(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(0, 13, 0, 15),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAll
                          ? 'Show fewer'
                          : 'Show all ${skills.length} skills',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedRotation(
                      turns: _showAll ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JourneySkillRow extends StatelessWidget {
  final JourneySkillProgressData data;
  final bool showDivider;
  final VoidCallback onTap;

  const _JourneySkillRow({
    required this.data,
    required this.showDivider,
    required this.onTap,
  });

  String get _remainingLabel {
    final remaining = data.targetVolume - data.lastSessionVolume;
    if (remaining <= 0) return 'Ready to attempt';
    if (data.isTimed) return '${remaining}s longer hold to reach';
    return remaining == 1
        ? '1 more clean rep to reach'
        : '$remaining more clean reps to reach';
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        (data.progressPercent.clamp(0.0, 1.0) * 100).round().clamp(1, 100);
    final slipping = data.lastSessionTrend == JourneySkillTrend.down;
    final tone = slipping ? AppColors.amber : AppColors.green;
    final cleared = data.stages
        .where((stage) => stage.status == JourneySkillStageStatus.cleared)
        .length;
    final total = data.stages.length;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        decoration: BoxDecoration(
          border: Border(
            top: showDivider
                ? const BorderSide(color: AppColors.divider)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon: _trackIcon(data.track), size: 34, warn: slipping),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.skillTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: cleared.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(
                        text: '/${total.toString().padLeft(2, '0')} nodes',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.stages.isNotEmpty) ...[
              const SizedBox(height: 13),
              _StageSpine(stages: data.stages),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Working: ',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: data.currentExerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' — ${data.lastLabel} / ${data.targetLabel}',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: slipping ? AppColors.amberSoft : AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: tone,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: data.progressPercent.clamp(0.02, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.surface2,
                color: tone,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '$_remainingLabel ',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: data.nextExerciseName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal spine of a tree: cleared (green) → working (blue) → locked.
class _StageSpine extends StatelessWidget {
  final List<JourneySkillStageData> stages;

  const _StageSpine({required this.stages});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var index = 0; index < stages.length; index++) {
      if (index > 0) {
        final connected =
            stages[index - 1].status == JourneySkillStageStatus.cleared;
        children.add(
          Expanded(
            child: Container(
              height: 1.5,
              color: connected
                  ? AppColors.green.withValues(alpha: 0.45)
                  : AppColors.surface3,
            ),
          ),
        );
      }
      children.add(_StageDot(status: stages[index].status));
    }

    return Row(children: children);
  }
}

class _StageDot extends StatelessWidget {
  final JourneySkillStageStatus status;

  const _StageDot({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case JourneySkillStageStatus.cleared:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.greenSoft, spreadRadius: 2.5),
            ],
          ),
        );
      case JourneySkillStageStatus.inProgress:
        return Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.accentPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.accentSoft, spreadRadius: 3),
            ],
          ),
        );
      case JourneySkillStageStatus.locked:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.surface3,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

// ── Exercise performance — session totals vs previous session ──

class _ExercisePerformanceCard extends StatelessWidget {
  final List<HomeExercisePerformance> rows;

  const _ExercisePerformanceCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final hasAnyData = rows.any((row) => row.history.isNotEmpty);

    if (rows.isEmpty || !hasAnyData) {
      return const SurfaceCard(
        padding: EdgeInsets.all(18),
        child: Text(
          'Finish your first workout to start tracking whether each '
          'exercise beats your previous session.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      );
    }

    return SurfaceCard(
      clip: true,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            _ExercisePerformanceRow(
              perf: rows[index],
              showDivider: index > 0,
            ),
        ],
      ),
    );
  }
}

class _ExercisePerformanceRow extends StatelessWidget {
  final HomeExercisePerformance perf;
  final bool showDivider;

  const _ExercisePerformanceRow({
    required this.perf,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final delta = perf.sessionDelta;
    final tone = delta == null
        ? AppColors.textMuted
        : delta > 0
            ? AppColors.green
            : delta < 0
                ? AppColors.amber
                : AppColors.textSecondary;
    final label = delta == null
        ? 'No trend yet'
        : delta > 0
            ? 'Improving'
            : delta < 0
                ? 'Slipping'
                : 'Steady';
    final unit = perf.isTimed ? 's' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: showDivider
              ? const BorderSide(color: AppColors.divider)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perf.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tone,
                    ),
                    children: [
                      if (perf.history.isNotEmpty)
                        TextSpan(
                          text: ' · last ${perf.history.last}'
                              '${perf.isTimed ? 's' : ' reps'}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
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
          if (perf.history.length >= 2) ...[
            const SizedBox(width: 12),
            CustomPaint(
              size: const Size(72, 24),
              painter: _SparklinePainter(
                values: perf.history,
                color: tone,
              ),
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: delta == null || delta == 0
                      ? AppColors.divider
                      : delta > 0
                          ? AppColors.greenSoft
                          : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta == null
                      ? '—'
                      : delta > 0
                          ? '+$delta$unit'
                          : '$delta$unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tone,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = (max - min) == 0 ? 1.0 : (max - min).toDouble();

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = 3 + (index / (values.length - 1)) * (size.width - 6);
      final y =
          size.height - 4 - ((values[index] - min) / span) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(Path()..addPolygon(points, false), line);
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ── Long-term goals — the goal skills set in the program ───────

class _GoalSkillsCard extends StatelessWidget {
  final List<HomeGoalSkillData> goals;
  final ValueChanged<HomeGoalSkillData> onOpenGoalSkill;

  const _GoalSkillsCard({
    required this.goals,
    required this.onOpenGoalSkill,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      clip: true,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          for (var index = 0; index < goals.length; index++)
            _GoalSkillRow(
              goal: goals[index],
              showDivider: index > 0,
              onTap: () => onOpenGoalSkill(goals[index]),
            ),
        ],
      ),
    );
  }
}

class _GoalSkillRow extends StatelessWidget {
  final HomeGoalSkillData goal;
  final bool showDivider;
  final VoidCallback onTap;

  const _GoalSkillRow({
    required this.goal,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          border: Border(
            top: showDivider
                ? const BorderSide(color: AppColors.divider)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconTile(icon: Icons.flag_rounded, size: 36, tint: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${goal.categoryTitle} · ${goal.masteredSteps} of '
                        '${goal.totalSteps} steps mastered',
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
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: goal.progress.clamp(0.02, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.surface2,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsEmptyCard extends StatelessWidget {
  final VoidCallback onAddGoals;

  const _GoalsEmptyCard({required this.onAddGoals});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flag_outlined,
              size: 24,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No goals yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: 260,
            child: Text(
              'Pick the skills you want your training to build toward '
              'and track your climb here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Add goals',
            onTap: onAddGoals,
          ),
        ],
      ),
    );
  }
}

// ── Skill paths (rendered in the Data tab) ──────────────────

class HomeSkillPathsSection extends StatelessWidget {
  final List<ActiveSkillPathData> paths;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;

  const HomeSkillPathsSection({
    super.key,
    required this.paths,
    required this.onOpenSkillPath,
  });

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return const _EmptySkillPathsCard();
    }

    final rising = paths
        .where((path) => path.momentum == HomeSkillMomentum.improving)
        .toList();
    final attention = paths
        .where((path) => path.momentum != HomeSkillMomentum.improving)
        .toList();

    return SurfaceCard(
      clip: true,
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rising.isNotEmpty) ...[
            _SkillPathGroupHeader(
              color: AppColors.green,
              label: 'On the rise',
              count: rising.length,
            ),
            for (var index = 0; index < rising.length; index++)
              _ActiveSkillPathRow(
                data: rising[index],
                last: index == rising.length - 1,
                onTap: () => onOpenSkillPath(rising[index]),
              ),
          ],
          if (rising.isNotEmpty && attention.isNotEmpty)
            Container(
              height: 1,
              margin: const EdgeInsets.only(top: 4),
              color: AppColors.divider,
            ),
          if (attention.isNotEmpty) ...[
            _SkillPathGroupHeader(
              color: AppColors.amber,
              label: 'Needs attention',
              count: attention.length,
            ),
            for (var index = 0; index < attention.length; index++)
              _ActiveSkillPathRow(
                data: attention[index],
                last: index == attention.length - 1,
                onTap: () => onOpenSkillPath(attention[index]),
              ),
          ],
        ],
      ),
    );
  }
}

class _SkillPathGroupHeader extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _SkillPathGroupHeader({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$count',
            style: const TextStyle(
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

class _ActiveSkillPathRow extends StatelessWidget {
  final ActiveSkillPathData data;
  final bool last;
  final VoidCallback onTap;

  const _ActiveSkillPathRow({
    required this.data,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: last
                ? BorderSide.none
                : const BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            IconTile(icon: _trackIcon(data.track)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.currentExerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.skillTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.personalBestLabel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                _SkillDeltaBadge(data: data),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillDeltaBadge extends StatelessWidget {
  final ActiveSkillPathData data;

  const _SkillDeltaBadge({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (data.momentum) {
      HomeSkillMomentum.improving => AppColors.green,
      HomeSkillMomentum.stalled => AppColors.amber,
      HomeSkillMomentum.steady => AppColors.textSecondary,
    };
    final background = switch (data.momentum) {
      HomeSkillMomentum.improving => AppColors.greenSoft,
      HomeSkillMomentum.stalled => AppColors.amberSoft,
      HomeSkillMomentum.steady => AppColors.divider,
    };
    final icon = switch (data.momentum) {
      HomeSkillMomentum.improving => Icons.arrow_drop_up_rounded,
      HomeSkillMomentum.stalled => Icons.arrow_drop_down_rounded,
      HomeSkillMomentum.steady => Icons.remove_rounded,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3.5, 8, 3.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
          Text(
            data.deltaLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySkillPathsCard extends StatelessWidget {
  const _EmptySkillPathsCard();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      padding: EdgeInsets.all(18),
      child: Text(
        'No active skill paths are configured yet.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
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
