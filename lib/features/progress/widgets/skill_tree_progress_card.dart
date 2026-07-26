import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';
import '../../../data/models/training_program_model.dart';
import '../../home/home_dashboard_metrics.dart';

/// One skill tree on the Progress tab. Expanded it shows the header, a
/// NOW → NEXT rail that fills with session volume, and the node map of the
/// whole tree (spine → hub → named branches, the user's path highlighted);
/// collapsed it folds down to a single row. Tapping the header toggles
/// between the two — only the map opens the full tree view.
class SkillTreeProgressCard extends StatelessWidget {
  final JourneySkillProgressData skill;
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final bool stalled;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenTree;

  const SkillTreeProgressCard({
    super.key,
    required this.skill,
    required this.category,
    required this.progressMap,
    required this.stalled,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpenTree,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: expanded ? _buildExpanded() : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    final toGo = _toGoLabel(skill);

    return SurfaceCard(
      onTap: onToggleExpanded,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconTile(icon: trackIcon(skill.track), size: 42, warn: stalled),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // The unlock label keeps its natural width, but never
                        // more than most of the row — the tree name gives way
                        // first, then this ellipsizes.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.6,
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: toGo,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                              children: const [
                                TextSpan(
                                  text: ' to unlock',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 3.5),
                Text.rich(
                  TextSpan(
                    text: skill.currentExerciseName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(
                        text: '  →  ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      TextSpan(text: _nextLabel(skill)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    final viz = TreeVizModel.fromCategory(
      category: category,
      progressMap: progressMap,
      activeBranchId: skill.branchId,
    );

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: onToggleExpanded,
            child: Row(
              children: [
                IconTile(
                  icon: trackIcon(skill.track),
                  size: 40,
                  warn: stalled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.17,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      _UnlockLine(skill: skill, fontSize: 13),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _NowNextRail(skill: skill),
          const SizedBox(height: 10),
          Pressable(
            onTap: onOpenTree,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _TreeLayout(
                    viz: viz,
                    width: constraints.maxWidth,
                  );
                  return SizedBox(
                    width: double.infinity,
                    height: layout.height,
                    child: CustomPaint(
                      painter: _TreeMapPainter(
                        layout: layout,
                        fillPct: skill.progressPercent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 reps to unlock Incline Pushups" — the volume left is the only number
/// on the line, so it carries the accent.
class _UnlockLine extends StatelessWidget {
  final JourneySkillProgressData skill;
  final double fontSize;

  const _UnlockLine({required this.skill, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final atEnd = skill.nextExerciseName == skill.currentExerciseName;

    return Text.rich(
      TextSpan(
        text: _toGoLabel(skill),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
        children: [
          TextSpan(
            text: atEnd
                ? ' to finish the tree'
                : ' to unlock ${skill.nextExerciseName}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// NOW → NEXT: the working exercise and its last set on the left, the unlock
/// and its target on the right, joined by a rail that fills with progress.
class _NowNextRail extends StatelessWidget {
  final JourneySkillProgressData skill;

  const _NowNextRail({required this.skill});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The rail keeps a minimum length; the two label columns split what is
        // left so a long exercise name can't squeeze it away.
        const railMin = 56.0;
        const gap = 8.0;
        final columnMax =
            math.max(64.0, (constraints.maxWidth - railMin - gap * 2) / 2);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: columnMax),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NOW',
                    style: GoogleFonts.robotoMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    skill.currentExerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      text: 'Last set ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: skill.lastLabel,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
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
            const SizedBox(width: gap),
            Expanded(
              child: SizedBox(
                height: 14,
                child: CustomPaint(
                  painter: _RailPainter(fillPct: skill.progressPercent),
                ),
              ),
            ),
            const SizedBox(width: gap),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: columnMax),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEXT',
                    style: GoogleFonts.robotoMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _nextLabel(skill),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      text: 'Unlocks at ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: skill.targetLabel,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
          ],
        );
      },
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

IconData trackIcon(TrainingTrack track) {
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

/// Node states for the map. Same color language as the Skills tab:
/// green = cleared, blue = working, blue ring = next unlock, gray = locked.
enum TreeNodeState { done, cur, goal, locked }

class TreeVizBranch {
  final String label;
  final List<TreeNodeState> states;
  final bool isActive;

  const TreeVizBranch({
    required this.label,
    required this.states,
    required this.isActive,
  });
}

/// The whole tree flattened for the horizontal map: a shared spine
/// (foundation steps every branch passes through) fanning into named
/// branches at a hub.
class TreeVizModel {
  final List<TreeNodeState> spine;
  final List<TreeVizBranch> branches;

  const TreeVizModel({required this.spine, required this.branches});

  int get totalNodes =>
      spine.length +
      branches.fold<int>(0, (sum, branch) => sum + branch.states.length);

  /// 1-based position of the working node along the user's path.
  int get position {
    var done = spine.where((state) => state == TreeNodeState.done).length;
    final active = branches.where((branch) => branch.isActive).firstOrNull;
    if (active != null) {
      done += active.states.where((state) => state == TreeNodeState.done).length;
    }
    return math.min(done + 1, math.max(totalNodes, 1));
  }

  static TreeVizModel fromCategory({
    required SkillCategory category,
    required Map<String, ExerciseStatus> progressMap,
    required String activeBranchId,
  }) {
    // Foundation = the opening steps shared by every branch path (same
    // longest-common-prefix rule the Skills tab uses).
    final allPaths = category.trainingPaths.values.toList();
    final foundation = <String>[];
    if (allPaths.length >= 2) {
      for (var index = 0;; index++) {
        if (allPaths.any((path) => path.length <= index)) break;
        final exerciseId = allPaths.first[index];
        if (allPaths.any((path) => path[index] != exerciseId)) break;
        foundation.add(exerciseId);
      }
    }

    final branchIds = <String>[];
    final branchLabels = <String, String>{};
    final branchPaths = <String, List<String>>{};
    for (final branch in category.branches) {
      final ids = category.pathFor(branch.id);
      if (ids.isEmpty) continue;
      final visible =
          ids.length > foundation.length ? ids.sublist(foundation.length) : const <String>[];
      if (visible.isEmpty) continue;
      branchIds.add(branch.id);
      branchLabels[branch.id] = branch.label;
      branchPaths[branch.id] = visible;
    }

    TreeNodeState stateFor(String exerciseId) {
      switch (progressMap[exerciseId] ?? ExerciseStatus.inactive) {
        case ExerciseStatus.mastered:
          return TreeNodeState.done;
        case ExerciseStatus.active:
          return TreeNodeState.cur;
        case ExerciseStatus.inactive:
          return TreeNodeState.locked;
      }
    }

    // A tree with one linear path renders as a plain spine, no hub.
    List<String> spineIds;
    if (branchIds.length <= 1 && foundation.isEmpty) {
      spineIds = branchIds.isEmpty
          ? category.pathFor(category.defaultTrainingPathId)
          : branchPaths[branchIds.first]!;
      branchIds.clear();
    } else {
      spineIds = foundation;
    }

    final spineStates = spineIds.map(stateFor).toList();
    final branchStates = {
      for (final id in branchIds) id: branchPaths[id]!.map(stateFor).toList(),
    };

    final activeId = branchIds.contains(activeBranchId)
        ? activeBranchId
        : branchIds
            .where((id) => branchStates[id]!.contains(TreeNodeState.cur))
            .firstOrNull;

    // Mark the next unlock (goal ring) along the user's path: the first
    // locked node after the working node.
    final pathStates = <TreeNodeState>[
      ...spineStates,
      if (activeId != null) ...branchStates[activeId]!,
    ];
    final curIndex = pathStates.lastIndexOf(TreeNodeState.cur);
    var goalIndex = -1;
    for (var index = math.max(curIndex, 0); index < pathStates.length; index++) {
      if (pathStates[index] == TreeNodeState.locked) {
        goalIndex = index;
        break;
      }
    }
    if (goalIndex >= 0) {
      if (goalIndex < spineStates.length) {
        spineStates[goalIndex] = TreeNodeState.goal;
      } else if (activeId != null) {
        branchStates[activeId]![goalIndex - spineStates.length] =
            TreeNodeState.goal;
      }
    }

    return TreeVizModel(
      spine: spineStates,
      branches: [
        for (final id in branchIds)
          TreeVizBranch(
            label: branchLabels[id]!,
            states: branchStates[id]!,
            isActive: id == activeId,
          ),
      ],
    );
  }
}

/// Geometry for the node map, resolved against the width it has to fill.
///
/// Two rules shape it: every tree fills the same width (spacing stretches or
/// squashes so the widest element lands on the right edge), and every branch
/// runs the same distance from the hub (a short branch spreads its nodes
/// further apart rather than stopping early).
class _TreeLayout {
  static const double dot = 4;
  static const double pad = 10;
  static const double hubR = 6;
  static const double _maxAngleDeg = 24;
  static const double _maxHeight = 164;
  static const double _plainHeight = 62;
  static const double _spineRef = 22; // reference spine spacing
  static const double _branchRef = 17; // reference branch spacing

  final TreeVizModel viz;
  final double width;

  late final double height;
  late final List<_Segment> segments;
  late final List<_Dot> dots;
  late final List<_Label> labels;
  late final Offset? hub;
  late final _Segment? fillSegment;

  _TreeLayout({required this.viz, required this.width}) {
    _build();
  }

  /// The design fans three branches within ±24°; wider trees open up so their
  /// tip labels stay legible instead of stacking on top of each other.
  static double _baseAngle(int branchCount) =>
      (_maxAngleDeg + 3.5 * (branchCount - 3)).clamp(_maxAngleDeg, 34.0) *
      math.pi /
      180;

  /// Radial room every branch gets at scale 1 — set by the longest branch, so
  /// shorter ones simply space their nodes out over the same distance.
  double get _referenceSpan {
    if (viz.branches.isEmpty) return 0;
    final maxN =
        viz.branches.map((branch) => branch.states.length).reduce(math.max);
    return (maxN + 0.6) * _branchRef;
  }

  /// Fan angle at a given scale: flattened only when the branches would
  /// otherwise grow taller than the card allows.
  double _angleFor(double scale) {
    if (viz.branches.isEmpty) return 0;
    final base = _baseAngle(viz.branches.length);
    final radial = hubR + _referenceSpan * scale;
    final fitRatio = ((_maxHeight / 2 - 13) / radial).clamp(0.18, 1.0);
    return math.min(base, math.asin(fitRatio));
  }

  double _hubXFor(double scale) =>
      pad + viz.spine.length * _spineRef * scale + hubR - 4;

  /// A tree whose branches fork straight from the start (Core) has no shared
  /// step to mark, so it gets no hub node — the branches just diverge from a
  /// bare point.
  bool get _hasHub => viz.branches.isNotEmpty && viz.spine.isNotEmpty;

  /// Where a branch's first segment leaves the fork: off the hub ring when
  /// there is one, straight from the fork point when there isn't.
  double get _stemRadius => _hasHub ? hubR : 0;

  /// Radial distance of branch [j]'s node [k] — the +0.6 slot past the last
  /// node is where the branch label sits.
  double _radialFor(double scale, int nodeCount, int k) =>
      hubR + _referenceSpan * scale * (k + 1) / (nodeCount + 0.6);

  /// Rightmost painted edge at a given scale, labels and dot radii included.
  double _rightEdgeFor(double scale, List<_Label> labelPainters) {
    var right = pad + dot + 4;
    for (var index = 0; index < viz.spine.length; index++) {
      right = math.max(right, pad + index * _spineRef * scale + dot + 4);
    }
    if (viz.branches.isEmpty) return right;

    final hubX = _hubXFor(scale);
    if (_hasHub) right = math.max(right, hubX + hubR);
    final angle = _angleFor(scale);
    final angles = _anglesFor(angle);
    for (var j = 0; j < viz.branches.length; j++) {
      final nodeCount = viz.branches[j].states.length;
      final cos = math.cos(angles[j]);
      for (var k = 0; k < nodeCount; k++) {
        right = math.max(
          right,
          hubX + cos * _radialFor(scale, nodeCount, k) + dot + 4,
        );
      }
      final tipX = hubX + cos * (hubR + _referenceSpan * scale);
      right = math.max(right, tipX + 2 + labelPainters[j].painter.width);
    }
    return right;
  }

  List<double> _anglesFor(double maxAngle) {
    final count = viz.branches.length;
    if (count == 1) return const [0.0];
    return [
      for (var index = 0; index < count; index++)
        -maxAngle + (2 * maxAngle * index) / (count - 1),
    ];
  }

  void _build() {
    final spine = viz.spine;
    final branches = viz.branches;
    final activeIndex = branches.indexWhere((branch) => branch.isActive);

    final labelPainters = [
      for (var j = 0; j < branches.length; j++)
        _Label(
          anchor: Offset.zero,
          painter: TextPainter(
            text: TextSpan(
              text: branches[j].label,
              style: GoogleFonts.robotoMono(
                fontSize: 9.5,
                fontWeight:
                    j == activeIndex ? FontWeight.w700 : FontWeight.w600,
                color: j == activeIndex
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        ),
    ];

    // Largest scale whose rightmost edge still fits — the map ends flush with
    // the card no matter how many nodes the tree has.
    final limit = width - 2;
    var low = 0.25;
    var high = 3.0;
    if (_rightEdgeFor(low, labelPainters) > limit) {
      high = low;
    } else if (_rightEdgeFor(high, labelPainters) <= limit) {
      low = high;
    } else {
      for (var step = 0; step < 24; step++) {
        final mid = (low + high) / 2;
        if (_rightEdgeFor(mid, labelPainters) <= limit) {
          low = mid;
        } else {
          high = mid;
        }
      }
    }
    final scale = low;
    final angle = _angleFor(scale);
    final angles = _anglesFor(angle);

    height = branches.isEmpty
        ? _plainHeight
        : math.min(
            2 * (math.sin(angle) * (hubR + _referenceSpan * scale) + 13),
            _maxHeight,
          );
    final midY = height / 2;
    Offset point(double x, double dy) => Offset(x, midY + dy);

    final builtSegments = <_Segment>[];
    final builtDots = <_Dot>[];
    final builtLabels = <_Label>[];
    _Segment? fill;

    final spineSpacing = _spineRef * scale;
    final spinePoints = [
      for (var index = 0; index < spine.length; index++)
        point(pad + index * spineSpacing, 0),
    ];
    for (var index = 1; index < spine.length; index++) {
      builtSegments.add(_Segment(
        a: spinePoints[index - 1],
        b: spinePoints[index],
        on: spine[index - 1] == TreeNodeState.done,
      ));
    }

    final hubX = _hubXFor(scale);
    hub = _hasHub ? point(hubX, 0) : null;
    if (spine.isNotEmpty && branches.isNotEmpty) {
      builtSegments.add(_Segment(
        a: spinePoints.last,
        b: point(hubX - hubR, 0),
        on: spine.last == TreeNodeState.done,
      ));
    }

    // The volume fill runs along the segment from the working node to the next
    // unlock — only meaningful while the two sit next to each other.
    final curS = spine.indexOf(TreeNodeState.cur);
    final goalS = spine.indexOf(TreeNodeState.goal);
    if (curS >= 0 && goalS == curS + 1) {
      final from = spinePoints[curS];
      final to = spinePoints[goalS];
      if ((to.dx - from.dx) > 18) {
        fill = _Segment(
          a: Offset(from.dx + 11, from.dy),
          b: Offset(to.dx - 7, to.dy),
          on: true,
        );
      }
    }

    for (var j = 0; j < branches.length; j++) {
      final branch = branches[j];
      final states = branch.states;
      final branchAngle = angles[j];
      final cos = math.cos(branchAngle);
      final sin = math.sin(branchAngle);

      Offset nodeAt(int k) {
        final radial = _radialFor(scale, states.length, k);
        return point(hubX + cos * radial, sin * radial);
      }

      builtSegments.add(_Segment(
        a: point(hubX + cos * _stemRadius, sin * _stemRadius),
        b: nodeAt(0),
        on: j == activeIndex &&
            spine.isNotEmpty &&
            spine.last == TreeNodeState.done,
        faint: j != activeIndex,
      ));
      for (var k = 1; k < states.length; k++) {
        builtSegments.add(_Segment(
          a: nodeAt(k - 1),
          b: nodeAt(k),
          on: j == activeIndex && states[k - 1] == TreeNodeState.done,
          faint: j != activeIndex,
        ));
      }
      for (var k = 0; k < states.length; k++) {
        builtDots.add(_Dot(
          center: nodeAt(k),
          state: states[k],
          faint: j != activeIndex,
        ));
      }

      if (j == activeIndex) {
        final curB = states.indexOf(TreeNodeState.cur);
        final goalB = states.indexOf(TreeNodeState.goal);
        if (curB >= 0 && goalB == curB + 1) {
          final from = nodeAt(curB);
          final to = nodeAt(goalB);
          final delta = to - from;
          final length = delta.distance;
          if (length > 18) {
            final unit = delta / length;
            fill = _Segment(a: from + unit * 11, b: to - unit * 7, on: true);
          }
        }
      }

      builtLabels.add(_Label(
        anchor: point(
          hubX + cos * (hubR + _referenceSpan * scale),
          sin * (hubR + _referenceSpan * scale),
        ),
        painter: labelPainters[j].painter,
      ));
    }

    for (var index = 0; index < spine.length; index++) {
      builtDots.add(_Dot(center: spinePoints[index], state: spine[index]));
    }

    segments = builtSegments;
    dots = builtDots;
    labels = builtLabels;
    fillSegment = fill;
  }
}

/// Paints the node map from a resolved [_TreeLayout]. Progress lives on the
/// map itself — the working node wears a rep ring and the segment toward the
/// next unlock fills as volume lands.
class _TreeMapPainter extends CustomPainter {
  final _TreeLayout layout;
  final double fillPct;

  const _TreeMapPainter({required this.layout, required this.fillPct});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = Colors.white.withValues(alpha: 0.10);
    final branchLineColor = Colors.white.withValues(alpha: 0.08);
    final pathColor = AppColors.green.withValues(alpha: 0.45);
    const doneColor = AppColors.green;
    const curColor = AppColors.accentBright;
    final curSoft = AppColors.accentBright.withValues(alpha: 0.2);
    const lockedColor = AppColors.surface3;
    const dot = _TreeLayout.dot;

    for (final segment in layout.segments) {
      canvas.drawLine(
        segment.a,
        segment.b,
        Paint()
          ..color = segment.on
              ? pathColor
              : segment.faint
                  ? branchLineColor
                  : lineColor
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }

    final fill = layout.fillSegment;
    if (fill != null) {
      canvas.drawLine(
        fill.a,
        fill.a + (fill.b - fill.a) * fillPct.clamp(0.0, 1.0),
        Paint()
          ..color = curColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final hub = layout.hub;
    if (hub != null) {
      canvas.drawCircle(
        hub,
        _TreeLayout.hubR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = lineColor,
      );
      canvas.drawCircle(hub, 1.9, Paint()..color = lockedColor);
    }

    for (final node in layout.dots) {
      final center = node.center;
      switch (node.state) {
        case TreeNodeState.done:
          canvas.drawCircle(center, dot, Paint()..color = doneColor);
        case TreeNodeState.cur:
          // Rep ring: how much of the target this session's volume covers.
          canvas.drawCircle(
            center,
            8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = curSoft,
          );
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: 8),
            -math.pi / 2,
            2 * math.pi * fillPct.clamp(0.0, 1.0),
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round
              ..color = curColor,
          );
          canvas.drawCircle(center, dot, Paint()..color = curColor);
        case TreeNodeState.goal:
          canvas.drawCircle(
            center,
            dot + 0.6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.7
              ..color = curColor,
          );
        case TreeNodeState.locked:
          canvas.drawCircle(
            center,
            node.faint ? dot - 1.3 : dot - 0.8,
            Paint()
              ..color = node.faint
                  ? lockedColor.withValues(alpha: 0.75)
                  : lockedColor,
          );
      }
    }

    for (final label in layout.labels) {
      label.painter.paint(
        canvas,
        Offset(
          label.anchor.dx + 2,
          label.anchor.dy - label.painter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreeMapPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.fillPct != fillPct;
}

/// The NOW → NEXT rail: filled cap, progress bar, dotted remainder, and a
/// hollow cap for the node still to unlock.
class _RailPainter extends CustomPainter {
  final double fillPct;

  const _RailPainter({required this.fillPct});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const startR = 6.5;
    const endR = 5.0;
    final start = Offset(startR, y);
    final end = Offset(size.width - endR, y);
    final trackStart = start.dx + startR + 2;
    final trackEnd = end.dx - endR - 2;
    final fillX =
        trackStart + (trackEnd - trackStart) * fillPct.clamp(0.0, 1.0);

    if (fillX > trackStart) {
      canvas.drawLine(
        Offset(trackStart, y),
        Offset(fillX, y),
        Paint()
          ..color = AppColors.green
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dotted remainder — what is still to be earned.
    final dottedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (var x = fillX + 4; x < trackEnd; x += 5) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 1, trackEnd), y),
          dottedPaint);
    }

    canvas.drawCircle(
      start,
      startR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.green,
    );
    canvas.drawCircle(start, 3, Paint()..color = AppColors.green);
    canvas.drawCircle(end, endR, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      end,
      endR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.fillPct != fillPct;
}

class _Segment {
  final Offset a;
  final Offset b;
  final bool on;
  final bool faint;

  const _Segment({
    required this.a,
    required this.b,
    required this.on,
    this.faint = false,
  });
}

class _Dot {
  final Offset center;
  final TreeNodeState state;
  final bool faint;

  const _Dot({
    required this.center,
    required this.state,
    this.faint = false,
  });
}

class _Label {
  final Offset anchor;
  final TextPainter painter;

  const _Label({required this.anchor, required this.painter});
}
