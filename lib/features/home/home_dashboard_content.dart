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
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProgramSettings;
  final ValueChanged<ActiveSkillPathData> onOpenSkillPath;

  const HomeDashboardContent({
    super.key,
    required this.todaySummary,
    required this.weekStrip,
    required this.journeySnapshot,
    required this.activeSkillPaths,
    required this.onPrimaryAction,
    required this.onOpenSettings,
    required this.onOpenProgramSettings,
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
                ),
                const SizedBox(height: 12),
                _WeekStripCard(data: weekStrip),
                const SizedBox(height: 12),
                _ProgramSettingsCard(onTap: onOpenProgramSettings),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 26, 4, 12),
                  child: _SectionLabel(label: 'Your progress'),
                ),
                _JourneySnapshotCard(data: journeySnapshot),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
                  child: _SectionHeader(
                    title: '${activeSkillPaths.length} active skill paths',
                  ),
                ),
                if (activeSkillPaths.isEmpty)
                  const _EmptySkillPathsCard()
                else
                  _ActiveSkillPathList(
                    paths: activeSkillPaths,
                    onOpenSkillPath: onOpenSkillPath,
                  ),
              ],
            ),
          ),
        ],
      ),
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
            style: GoogleFonts.inter(
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
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _homeTextSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _homeTextSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final HomeTodaySummary summary;
  final VoidCallback onPrimaryAction;

  const _TodayCard({
    required this.summary,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final badgeLabel = summary.isRestDay ? 'RECOVERY' : 'TODAY';
    final visibleTags = summary.focusTags.take(5).toList();

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
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _homeOrange,
              letterSpacing: 0.95,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary.sessionTitle,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _homeText,
              letterSpacing: -0.75,
              height: 1,
            ),
          ),
          if (visibleTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tag in visibleTags) _TagChip(label: tag),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
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
                    style: GoogleFonts.inter(
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
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _homeCardAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: _homeText,
          letterSpacing: -0.15,
        ),
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
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tertiaryColor,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            day.date.day.toString(),
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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

class _JourneySnapshotCard extends StatelessWidget {
  final JourneySnapshotData data;

  const _JourneySnapshotCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final percent = data.maxLevel == 0 ? 0.0 : data.totalLevel / data.maxLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FITNESS LEVEL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _homeTextSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.totalLevel.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: _homeText,
                        letterSpacing: -1.4,
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.tierLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _homeOrange,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${data.maxLevel} max',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _homeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _homeCardAlt,
              color: _homeOrange,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 15),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _homeBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DenseStat(
                    value: '${data.totalLevel}',
                    label: 'TOTAL LEVEL',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _DenseStat(
                    value: '${data.unlockedSkillTrees}/${data.totalSkillTrees}',
                    label: 'SKILLS',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _DenseStat(
                    value: data.averageSkillLevel.toStringAsFixed(1),
                    label: 'AVG / SKILL',
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

class _DenseStat extends StatelessWidget {
  final String value;
  final String label;

  const _DenseStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _homeText,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _homeTextSecondary,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: _homeBorder,
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
    return Container(
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _homeBorder),
      ),
      child: Column(
        children: [
          for (var index = 0; index < paths.length; index++) ...[
            _ActiveSkillPathRow(
              data: paths[index],
              isFirst: index == 0,
              isLast: index == paths.length - 1,
              onTap: () => onOpenSkillPath(paths[index]),
            ),
            if (index != paths.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: _homeDivider,
                indent: 66,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActiveSkillPathRow extends StatelessWidget {
  final ActiveSkillPathData data;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ActiveSkillPathRow({
    required this.data,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = _momentumColor(data.momentum);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(14) : Radius.zero,
          bottom: isLast ? const Radius.circular(14) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                      data.trackLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _homeTextTertiary,
                        letterSpacing: 0.65,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      data.skillTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _homeText,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _momentumLabel(data.momentum),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: trendColor,
                            letterSpacing: 0.45,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ' · ${data.note}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _homeTextSecondary,
                              letterSpacing: -0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(),
                      children: [
                        TextSpan(
                          text: '${data.level}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _homeText,
                            letterSpacing: -0.3,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '/10',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _homeTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 52,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (data.progressPercent / 100).clamp(0.0, 1.0),
                        backgroundColor: _homeCardAlt,
                        color: _homeOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _momentumLabel(HomeSkillMomentum momentum) {
    switch (momentum) {
      case HomeSkillMomentum.stalled:
        return 'STALLED';
      case HomeSkillMomentum.steady:
        return 'STEADY';
      case HomeSkillMomentum.improving:
        return 'IMPROVING';
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
        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
