import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/training_program_model.dart';
import 'home_dashboard_metrics.dart';

const _homeShell = Color(0xFF161618);
const _homeCard = Color(0xFF202023);
const _homeCardAlt = Color(0xFF2A2A2E);
const _homeBorder = Color(0xFF323237);
const _homeDivider = Color(0xFF2A2A2E);
const _homeText = Color(0xFFF5F5F7);
const _homeTextSecondary = Color(0xFF9C9CA3);
const _homeTextTertiary = Color(0xFF6C6C73);
const _homeOrange = Color(0xFFFC5200);
const _homeOrangeSoft = Color(0x26FC5200);
const _homeGreen = Color(0xFF4CC97E);
const _homeGold = Color(0xFFE0A526);

class HomeDashboardContent extends StatelessWidget {
  final HomeTodaySummary todaySummary;
  final HomeWeekStripData weekStrip;
  final JourneySnapshotData journeySnapshot;
  final List<ActiveSkillPathData> activeSkillPaths;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProgramSettings;
  final ValueChanged<JourneySkillProgressData> onOpenJourneySkill;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;

  const HomeDashboardContent({
    super.key,
    required this.todaySummary,
    required this.weekStrip,
    required this.journeySnapshot,
    required this.activeSkillPaths,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    required this.onOpenSettings,
    required this.onOpenProgramSettings,
    required this.onOpenJourneySkill,
    required this.onOpenSkillPath,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(onOpenSettings: onOpenSettings),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 26, 4, 12),
                  child: _SectionLabel(label: 'Program'),
                ),
                _TodayCard(
                  summary: todaySummary,
                  onPrimaryAction: onPrimaryAction,
                  onSecondaryAction: onSecondaryAction,
                ),
                const SizedBox(height: 12),
                _WeekStripCard(data: weekStrip),
                const SizedBox(height: 12),
                _ProgramSettingsCard(onTap: onOpenProgramSettings),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 26, 4, 12),
                  child: _SectionLabel(label: 'Closest to levelling up'),
                ),
                _JourneySnapshotCard(
                  data: journeySnapshot,
                  onOpenSkillPath: onOpenJourneySkill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

    return _ActiveSkillPathList(
      paths: paths,
      onOpenSkillPath: onOpenSkillPath,
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _TopBar({
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        color: _homeShell,
        border: Border(
          bottom: BorderSide(color: _homeBorder),
        ),
      ),
      child: Row(
        children: [
          Text(
            'FORMA',
            style: GoogleFonts.ibmPlexSansCondensed(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _homeOrange,
              letterSpacing: 0.35,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onOpenSettings,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _homeCardAlt,
                shape: BoxShape.circle,
                border: Border.all(color: _homeBorder),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.settings_outlined,
                color: _homeTextSecondary,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.ibmPlexSansCondensed(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _homeTextSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

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
    final badgeLabel = summary.isRestDay ? 'RECOVERY' : 'TODAY';
    final plannedExercises = summary.plannedExercises;
    final visibleExercises =
        _isExpanded ? plannedExercises : plannedExercises.take(4).toList();
    final canToggleExercises = plannedExercises.length > 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            badgeLabel,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _homeOrange,
              letterSpacing: 0.95,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary.sessionTitle,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _homeText,
              letterSpacing: -0.75,
              height: 1,
            ),
          ),
          if (visibleExercises.isNotEmpty) ...[
            const SizedBox(height: 14),
            Column(
              children: [
                for (var index = 0;
                    index < visibleExercises.length;
                    index++) ...[
                  _PlannedExerciseRow(
                    index: index + 1,
                    exercise: visibleExercises[index],
                    showDivider: index > 0,
                  ),
                ],
              ],
            ),
          ],
          if (canToggleExercises) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
                foregroundColor: _homeOrange,
                backgroundColor: Colors.transparent,
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Show all',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _homeOrange,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Transform.rotate(
                    angle: _isExpanded ? 3.141592653589793 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: _homeOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onPrimaryAction,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _homeOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    summary.ctaLabel,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!summary.isRestDay) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onSecondaryAction,
                style: TextButton.styleFrom(
                  foregroundColor: _homeText,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _homeBorder),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Train something else',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _homeText,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlannedExerciseRow extends StatelessWidget {
  final int index;
  final HomePlannedExerciseSummary exercise;
  final bool showDivider;

  const _PlannedExerciseRow({
    required this.index,
    required this.exercise,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          top: showDivider
              ? const BorderSide(color: _homeBorder)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$index',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _homeTextTertiary,
                letterSpacing: -0.05,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.name,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _homeText,
                letterSpacing: -0.12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            exercise.targetLabel,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _homeTextSecondary,
              letterSpacing: -0.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStripCard extends StatelessWidget {
  final HomeWeekStripData data;

  const _WeekStripCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final day in data.days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WeekStripDayCell(day: day),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStripDayCell extends StatelessWidget {
  final HomeWeekStripDay day;

  const _WeekStripDayCell({
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day.isCurrent;
    final isDone = day.isCompleted;
    final isRest = day.isRestDay;

    final background = isToday
        ? _homeOrange
        : isDone
            ? _homeOrangeSoft
            : isRest
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.06);
    final border = isToday
        ? Colors.transparent
        : isDone
            ? _homeOrange.withValues(alpha: 0.28)
            : Colors.transparent;
    final labelColor = isToday
        ? Colors.white
        : isRest
            ? _homeTextTertiary
            : _homeText;
    final tertiaryColor = isToday
        ? Colors.white.withValues(alpha: 0.82)
        : isRest
            ? _homeTextTertiary
            : _homeTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            _weekdayLetter(day.date),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tertiaryColor,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            day.date.day.toString(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRest
                ? 'REST'
                : isDone
                    ? '✓'
                    : _shortLabel(day.sessionType),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDone && !isToday ? _homeOrange : tertiaryColor,
              letterSpacing: 0.35,
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

  String _shortLabel(TrainingSessionType sessionType) {
    switch (sessionType) {
      case TrainingSessionType.fullBody:
        return 'FULL';
      case TrainingSessionType.push:
        return 'PUSH';
      case TrainingSessionType.pull:
        return 'PULL';
      case TrainingSessionType.upper:
        return 'UP';
      case TrainingSessionType.lower:
        return 'LOW';
      case TrainingSessionType.rest:
        return 'REST';
    }
  }
}

class _JourneySnapshotCard extends StatefulWidget {
  final JourneySnapshotData data;
  final ValueChanged<JourneySkillProgressData> onOpenSkillPath;

  const _JourneySnapshotCard({
    required this.data,
    required this.onOpenSkillPath,
  });

  @override
  State<_JourneySnapshotCard> createState() => _JourneySnapshotCardState();
}

class _JourneySnapshotCardState extends State<_JourneySnapshotCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final visibleSkills =
        _showAll ? data.closestSkills : data.closestSkills.take(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.closestSkills.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
              child: Text(
                'No active skill progress yet.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _homeTextSecondary,
                ),
              ),
            )
          else ...[
            for (var index = 0; index < visibleSkills.length; index++)
              _JourneySkillRow(
                data: visibleSkills.elementAt(index),
                showDivider: index > 0,
                onTap: () =>
                    widget.onOpenSkillPath(visibleSkills.elementAt(index)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: InkWell(
                onTap: () => setState(() => _showAll = !_showAll),
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _homeDivider),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAll
                            ? 'SHOW FEWER'
                            : 'SHOW ALL ${data.closestSkills.length} SKILLS',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _homeOrange,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.rotate(
                        angle: _showAll ? 3.141592653589793 : 0,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _homeOrange,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final deltaColor = switch (data.lastSessionTrend) {
      JourneySkillTrend.up => _homeGreen,
      JourneySkillTrend.down => _homeOrange,
      JourneySkillTrend.flat => _homeTextSecondary,
    };

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: showDivider
                ? const BorderSide(color: _homeDivider)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _homeCardAlt,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _trackIcon(data.track),
                    size: 21,
                    color: _homeText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.motionLabel.toUpperCase()} TREE',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _homeTextTertiary,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        data.skillTitle,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _homeText,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _homeCardAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.currentExerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _homeText,
                            letterSpacing: -0.08,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _homeOrange,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _homeOrangeSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.nextExerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _homeOrange,
                            letterSpacing: -0.08,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Last ',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12.5,
                                      color: _homeTextSecondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: data.lastLabel,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _homeText,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: switch (data.lastSessionTrend) {
                                JourneySkillTrend.up =>
                                  _homeGreen.withValues(alpha: 0.13),
                                JourneySkillTrend.down => _homeOrangeSoft,
                                JourneySkillTrend.flat => _homeCardAlt,
                              },
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data.lastSessionDeltaLabel,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: deltaColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Goal ',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              color: _homeTextSecondary,
                            ),
                          ),
                          TextSpan(
                            text: data.targetLabel,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _homeOrange,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: data.progressPercent.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: _homeCardAlt,
                    color: _homeOrange,
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

class _ActiveSkillPathList extends StatelessWidget {
  final List<ActiveSkillPathData> paths;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;

  const _ActiveSkillPathList({
    required this.paths,
    required this.onOpenSkillPath,
  });

  @override
  Widget build(BuildContext context) {
    final rising = paths
        .where((path) => path.momentum == HomeSkillMomentum.improving)
        .toList();
    final attention = paths
        .where((path) => path.momentum != HomeSkillMomentum.improving)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
            child: Text(
              'BEST-SET VOLUME · LAST 14 DAYS vs PREV. 14',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _homeTextTertiary,
                letterSpacing: 0.55,
              ),
            ),
          ),
          if (rising.isNotEmpty) ...[
            _SkillPathGroupHeader(
              color: _homeGreen,
              label: 'On the rise',
              count: rising.length,
            ),
            _SkillPathGroupRows(
              paths: rising,
              onOpenSkillPath: onOpenSkillPath,
            ),
          ],
          if (rising.isNotEmpty && attention.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Divider(height: 1, thickness: 1, color: _homeBorder),
            ),
          if (attention.isNotEmpty) ...[
            _SkillPathGroupHeader(
              color: _homeGold,
              label: 'Needs attention',
              count: attention.length,
            ),
            _SkillPathGroupRows(
              paths: attention,
              onOpenSkillPath: onOpenSkillPath,
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
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 9),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _homeTextTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPathGroupRows extends StatelessWidget {
  final List<ActiveSkillPathData> paths;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;

  const _SkillPathGroupRows({
    required this.paths,
    required this.onOpenSkillPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < paths.length; index++)
          _ActiveSkillPathRow(
            data: paths[index],
            first: index == 0,
            onTap: () => onOpenSkillPath(paths[index]),
          ),
      ],
    );
  }
}

class _ActiveSkillPathRow extends StatelessWidget {
  final ActiveSkillPathData data;
  final bool first;
  final VoidCallback onTap;

  const _ActiveSkillPathRow({
    required this.data,
    required this.first,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
          decoration: BoxDecoration(
            border: Border(
              top: first
                  ? BorderSide.none
                  : const BorderSide(color: _homeDivider),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _homeCardAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _trackIcon(data.track),
                  color: _homeText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.currentExerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _homeText,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.skillTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _homeTextSecondary,
                        letterSpacing: -0.05,
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
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _homeText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _SkillDeltaBadge(data: data),
                ],
              ),
            ],
          ),
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
    final color = _momentumColor(data.momentum);
    final background = switch (data.momentum) {
      HomeSkillMomentum.improving => _homeGreen.withValues(alpha: 0.13),
      HomeSkillMomentum.stalled => _homeGold.withValues(alpha: 0.13),
      HomeSkillMomentum.steady => _homeCardAlt,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _momentumIcon(data.momentum),
            size: 11,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            data.deltaLabel,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _momentumIcon(HomeSkillMomentum momentum) {
  switch (momentum) {
    case HomeSkillMomentum.improving:
      return Icons.arrow_drop_up_rounded;
    case HomeSkillMomentum.stalled:
      return Icons.arrow_drop_down_rounded;
    case HomeSkillMomentum.steady:
      return Icons.remove_rounded;
  }
}

Color _momentumColor(HomeSkillMomentum momentum) {
  switch (momentum) {
    case HomeSkillMomentum.stalled:
      return _homeGold;
    case HomeSkillMomentum.steady:
      return _homeTextSecondary;
    case HomeSkillMomentum.improving:
      return _homeGreen;
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

class _EmptySkillPathsCard extends StatelessWidget {
  const _EmptySkillPathsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Text(
        'No active skill paths are configured yet.',
        style: GoogleFonts.ibmPlexSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _homeTextSecondary,
        ),
      ),
    );
  }
}

class _ProgramSettingsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProgramSettingsCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _homeCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _homeBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: _homeText,
                  size: 22,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Program overview',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _homeText,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _homeTextTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
