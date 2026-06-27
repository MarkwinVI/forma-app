import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/training_program_model.dart';
import 'home_dashboard_metrics.dart';

const _progressShell = Color(0xFF161618);
const _progressCard = Color(0xFF202023);
const _progressCardAlt = Color(0xFF2A2A2E);
const _progressBorder = Color(0xFF323237);
const _progressDivider = Color(0xFF2A2A2E);
const _progressText = Color(0xFFF5F5F7);
const _progressTextSecondary = Color(0xFF9C9CA3);
const _progressTextTertiary = Color(0xFF6C6C73);
const _progressOrange = Color(0xFFFC5200);

class JourneyProgressView extends StatelessWidget {
  final JourneySnapshotData snapshot;
  final ValueChanged<JourneySkillProgressData> onOpenSkillPath;

  const JourneyProgressView({
    super.key,
    required this.snapshot,
    required this.onOpenSkillPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _progressShell,
      appBar: AppBar(
        backgroundColor: _progressShell,
        elevation: 0,
        title: Text(
          'Your Progress',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _progressText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _progressCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _progressBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CLOSEST TO LEVELLING UP',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _progressTextTertiary,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Text(
                        '${snapshot.levelsToNextTier} TO ${snapshot.nextTierLabel.toUpperCase()}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _progressTextTertiary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var index = 0;
                    index < snapshot.closestSkills.length;
                    index++)
                  _JourneyProgressRow(
                    data: snapshot.closestSkills[index],
                    showDivider: index > 0,
                    onTap: () => onOpenSkillPath(snapshot.closestSkills[index]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyProgressRow extends StatelessWidget {
  final JourneySkillProgressData data;
  final bool showDivider;
  final VoidCallback onTap;

  const _JourneyProgressRow({
    required this.data,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            top: showDivider
                ? const BorderSide(color: _progressDivider)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _progressCardAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                _trackIcon(data.track),
                size: 19,
                color: _progressText,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.skillTitle,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _progressText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.currentExerciseName,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _progressTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: data.progressPercent.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: _progressCardAlt,
                      color: _progressOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'To level up ',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            color: _progressTextSecondary,
                          ),
                        ),
                        TextSpan(
                          text: data.targetLabel,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _progressText,
                          ),
                        ),
                        TextSpan(
                          text: ' · ',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            color: _progressTextTertiary,
                          ),
                        ),
                        TextSpan(
                          text: 'Last ',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            color: _progressTextSecondary,
                          ),
                        ),
                        TextSpan(
                          text: data.lastLabel,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _progressText,
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
      ),
    );
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
