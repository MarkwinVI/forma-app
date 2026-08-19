import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/skill_tree_map.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';
import '../../home/home_dashboard_metrics.dart';

/// One skill tree in the Progress list — no card, no tile: a big name and a
/// single calm line, with a rule under it.
///
/// Collapsed, a tree being trained says how far its next step is; one that
/// hasn't been started says what it builds. Expanded, it adds the NOW → NEXT
/// pair, the progress bar, and the node map. Tapping the row toggles the two;
/// only the map opens the full tree.
class SkillTreeRow extends StatelessWidget {
  final JourneySkillProgressData? skill;
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final bool expanded;

  /// The last row in a group carries no rule.
  final bool last;

  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenTree;

  const SkillTreeRow({
    super.key,
    required this.skill,
    required this.category,
    required this.progressMap,
    required this.expanded,
    required this.last,
    required this.onToggleExpanded,
    required this.onOpenTree,
  });

  /// The branch the map highlights: the one being trained, or the tree's
  /// default when it isn't in the program.
  String get _branchId => skill?.branchId ?? category.defaultTrainingPathId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: expanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    final active = skill;

    return Pressable(
      onTap: onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.42,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (active == null)
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        text: _toGoLabel(active),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                        children: const [
                          TextSpan(
                            text: ' to level up',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    final active = skill;
    final viz = TreeVizModel.fromCategory(
      category: category,
      progressMap: progressMap,
      activeBranchId: _branchId,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: onToggleExpanded,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          if (active != null) ...[
            const SizedBox(height: 18),
            // The NOW → NEXT block belongs to the header, not the map: it
            // folds the row back up rather than navigating.
            Pressable(
              onTap: onToggleExpanded,
              child: _NowNext(skill: active),
            ),
          ] else ...[
            // An untrained tree has no session to report, so the line that
            // says what it builds stays put when the row opens.
            const SizedBox(height: 7),
            Text(
              category.description,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Pressable(
              onTap: onOpenTree,
              child: Container(
                padding: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SkillTreeMap(
                  viz: viz,
                  fillPct: active?.progressPercent,
                  // Branch names read at the same size as in the tree's own
                  // screen, so the two maps look like one thing.
                  labelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.14,
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

/// NOW → NEXT: the working exercise and the one it opens, the bar between
/// them, and the volume that closes the gap.
class _NowNext extends StatelessWidget {
  final JourneySkillProgressData skill;

  const _NowNext({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    'NOW',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.accentBright,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skill.currentExerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'NEXT',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _nextLabel(skill),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        // Full-width bar: its length reads as progress on its own, so a long
        // exercise name can never shrink it.
        _ProgressBar(value: skill.progressPercent),
        const SizedBox(height: 9),
        _VolumeCaption(skill: skill),
      ],
    );
  }
}

/// The session volume landed against the unlock target.
class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.07),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accentBright.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Last 21 of 24 reps (total)" — what the last session landed against what
/// the next level asks for, counted across the whole session rather than a
/// single set.
class _VolumeCaption extends StatelessWidget {
  final JourneySkillProgressData skill;

  const _VolumeCaption({required this.skill});

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final figure = GoogleFonts.robotoMono(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    // Timed work reads "45s"; reps keep a word space before the unit.
    final unit = skill.isTimed ? 's' : ' reps';

    return Text.rich(
      TextSpan(
        text: 'Last ',
        style: body,
        children: [
          TextSpan(text: '${skill.lastSessionVolume}', style: figure),
          const TextSpan(text: ' of '),
          TextSpan(text: '${skill.targetVolume}', style: figure),
          TextSpan(
            text: unit,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const TextSpan(
            text: ' (total)',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Volume still owed before the next node unlocks — "3 reps", "8s", or
/// "Ready" once the target has been hit.
String _toGoLabel(JourneySkillProgressData skill) {
  final remaining = skill.targetVolume - skill.lastSessionVolume;
  if (remaining <= 0) return 'Ready';
  if (skill.isTimed) return '${remaining}s';
  return '$remaining ${remaining == 1 ? 'rep' : 'reps'}';
}

/// The next node's name, or a plain marker when the path has no node left.
String _nextLabel(JourneySkillProgressData skill) =>
    skill.nextExerciseName == skill.currentExerciseName
        ? 'Final step'
        : skill.nextExerciseName;
