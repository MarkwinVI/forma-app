import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';
import '../../../data/models/training_program_model.dart';
import '../../home/home_dashboard_metrics.dart';

/// One skill tree on the Progress tab: header row, a horizontal node map of
/// the whole tree (spine → hub → named branches, the user's path highlighted),
/// and a "node rail" anchored to the map — its left cap is the active node,
/// its right cap the next unlock; when the rail fills, the ring activates.
class SkillTreeProgressCard extends StatelessWidget {
  final JourneySkillProgressData skill;
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final bool stalled;
  final VoidCallback onTap;

  const SkillTreeProgressCard({
    super.key,
    required this.skill,
    required this.category,
    required this.progressMap,
    required this.stalled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final viz = TreeVizModel.fromCategory(
      category: category,
      progressMap: progressMap,
      activeBranchId: skill.branchId,
    );

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: _trackIcon(skill.track),
                size: 34,
                warn: stalled,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'node ${viz.position} of ${viz.totalNodes}',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: _TreeRailPainter.treeHeight + _TreeRailPainter.railZone,
            child: CustomPaint(
              painter: _TreeRailPainter(
                viz: viz,
                fillPct: skill.progressPercent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.accentBright,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skill.currentExerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: 'last ${skill.lastLabel}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          if (stalled)
                            TextSpan(
                              text: ' · stalled',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GOAL',
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    skill.targetLabel,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

/// Paints the node map plus the node-anchored progress rail underneath.
/// Geometry ported from the v10 design: spine dots spaced [_sp] apart, a hub
/// ring, branches fanned within ±[_maxAngleDeg]°, monospace branch labels at
/// the tips. If the natural layout is wider than the canvas it is squashed
/// horizontally so nothing clips.
class _TreeRailPainter extends CustomPainter {
  static const double treeHeight = 126;
  static const double railZone = 46;

  static const double _sp = 20; // spine node spacing
  static const double _bsp = 24; // branch node spacing
  static const double _dot = 4;
  static const double _pad = 12;
  static const double _hubR = 7;
  static const double _maxAngleDeg = 32;

  final TreeVizModel viz;
  final double fillPct;

  const _TreeRailPainter({required this.viz, required this.fillPct});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = Colors.white.withValues(alpha: 0.10);
    final pathColor = AppColors.accentBright.withValues(alpha: 0.5);
    const doneColor = AppColors.green;
    const curColor = AppColors.accentBright;
    final curSoft = AppColors.accentBright.withValues(alpha: 0.15);
    const lockedColor = AppColors.surface3;

    const midY = treeHeight / 2;
    final spine = viz.spine;
    final branches = viz.branches;

    final curS = spine.indexOf(TreeNodeState.cur);
    final goalS = spine.indexOf(TreeNodeState.goal);
    final actB = branches.indexWhere((branch) => branch.isActive);

    final hubU = _pad + spine.length * _sp + _hubR - 2;

    // Fan angle: the design's ±32°, tightened when a branch is long enough
    // that its tip would leave the canvas vertically.
    var maxAngle = _maxAngleDeg * math.pi / 180;
    final maxN = branches.isEmpty
        ? 0
        : branches.map((branch) => branch.states.length).reduce(math.max);
    if (maxN > 0) {
      final maxRadial = _hubR + (maxN + 0.55) * _bsp;
      final fitRatio = ((midY - 10) / maxRadial).clamp(0.18, 1.0);
      maxAngle = math.min(maxAngle, math.asin(fitRatio));
    }
    final angles = branches.length == 1
        ? [0.0]
        : [
            for (var index = 0; index < branches.length; index++)
              -maxAngle + (2 * maxAngle * index) / (branches.length - 1),
          ];

    final segments = <_Segment>[];
    final dots = <_Dot>[];
    final labels = <_Label>[];

    Offset point(double u, double v) => Offset(u, midY + v);

    final spinePoints = [
      for (var index = 0; index < spine.length; index++)
        point(_pad + index * _sp, 0),
    ];
    for (var index = 1; index < spine.length; index++) {
      segments.add(_Segment(
        a: spinePoints[index - 1],
        b: spinePoints[index],
        on: curS >= 0 &&
            index > curS &&
            (goalS >= 0 ? index <= goalS : actB >= 0),
      ));
    }
    if (spine.isNotEmpty && branches.isNotEmpty) {
      segments.add(_Segment(
        a: spinePoints.last,
        b: point(hubU - _hubR, 0),
        on: curS >= 0 && actB >= 0 && goalS < 0,
      ));
    }

    for (var j = 0; j < branches.length; j++) {
      final branch = branches[j];
      final angle = angles[j];
      final states = branch.states;
      final curB = states.indexOf(TreeNodeState.cur);
      final goalB = states.indexOf(TreeNodeState.goal);

      Offset nodeAt(int k) => point(
            hubU + math.cos(angle) * (_hubR + (k + 1) * _bsp),
            math.sin(angle) * (_hubR + (k + 1) * _bsp),
          );

      segments.add(_Segment(
        a: point(
          hubU + math.cos(angle) * _hubR,
          math.sin(angle) * _hubR,
        ),
        b: nodeAt(0),
        on: j == actB && curB < 0 && curS >= 0 && goalB >= 0,
      ));
      for (var k = 1; k < states.length; k++) {
        segments.add(_Segment(
          a: nodeAt(k - 1),
          b: nodeAt(k),
          on: j == actB &&
              ((curB >= 0 && k > curB && (goalB < 0 || k <= goalB)) ||
                  (curB < 0 && curS >= 0 && goalB >= 0 && k <= goalB)),
        ));
      }
      for (var k = 0; k < states.length; k++) {
        dots.add(_Dot(center: nodeAt(k), state: states[k]));
      }

      final tipRadial = _hubR + (states.length + 0.55) * _bsp;
      final tip = point(
        hubU + math.cos(angle) * tipRadial,
        math.sin(angle) * tipRadial,
      );
      labels.add(_Label(
        anchor: tip,
        painter: TextPainter(
          text: TextSpan(
            text: branch.label,
            style: GoogleFonts.robotoMono(
              fontSize: 9.5,
              fontWeight: j == actB ? FontWeight.w700 : FontWeight.w600,
              color: j == actB ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      ));
    }

    for (var index = 0; index < spine.length; index++) {
      dots.add(_Dot(center: spinePoints[index], state: spine[index]));
    }

    // Squash node positions horizontally if the natural layout overflows the
    // card. Dot radii and label text keep their size, so each element's
    // untransformed overhang is subtracted from the room its anchor may use.
    var scaleX = 1.0;
    void constrain(double anchorX, double overhang) {
      final reach = anchorX - _pad;
      if (reach <= 0) return;
      scaleX =
          math.min(scaleX, (size.width - 2 - overhang - _pad) / reach);
    }

    for (final dot in dots) {
      constrain(dot.center.dx, _dot + 3.2);
    }
    for (final label in labels) {
      constrain(label.anchor.dx, 2 + label.painter.width);
    }
    if (branches.isNotEmpty) {
      constrain(hubU, _hubR);
    }
    scaleX = scaleX.clamp(0.3, 1.0);
    double sx(double x) => _pad + (x - _pad) * scaleX;

    // ── Segments, hub, dots, labels ──
    for (final segment in segments) {
      canvas.drawLine(
        Offset(sx(segment.a.dx), segment.a.dy),
        Offset(sx(segment.b.dx), segment.b.dy),
        Paint()
          ..color = segment.on ? pathColor : lineColor
          ..strokeWidth = segment.on ? 1.6 : 1.2,
      );
    }

    if (branches.isNotEmpty) {
      final hub = Offset(sx(hubU), midY);
      final hubOn = curS >= 0 && actB >= 0 && goalS < 0;
      canvas.drawCircle(
        hub,
        _hubR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = hubOn ? pathColor : lineColor,
      );
      canvas.drawCircle(hub, 2.1, Paint()..color = lockedColor);
    }

    for (final dot in dots) {
      final center = Offset(sx(dot.center.dx), dot.center.dy);
      switch (dot.state) {
        case TreeNodeState.done:
          canvas.drawCircle(center, _dot, Paint()..color = doneColor);
        case TreeNodeState.cur:
          canvas.drawCircle(center, _dot + 3.2, Paint()..color = curSoft);
          canvas.drawCircle(center, _dot, Paint()..color = curColor);
        case TreeNodeState.goal:
          canvas.drawCircle(
            center,
            _dot + 0.8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.7
              ..color = curColor,
          );
        case TreeNodeState.locked:
          canvas.drawCircle(center, _dot - 0.6, Paint()..color = lockedColor);
      }
    }

    for (final label in labels) {
      label.painter.paint(
        canvas,
        Offset(
          sx(label.anchor.dx) + 2,
          label.anchor.dy - label.painter.height / 2,
        ),
      );
    }

    // ── Node rail: active node → next unlock, fill = progress ──
    const railY = treeHeight + 32;
    const railL = _pad;
    final railR = size.width - 14;
    const ringR = _dot + 0.8;
    const t0 = railL + _dot + 7;
    final t1 = railR - ringR - 7;
    final fillX = t0 + (t1 - t0) * fillPct.clamp(0.0, 1.0);

    canvas.drawLine(
      const Offset(t0, railY),
      Offset(t1, railY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.09)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    if (fillX > t0) {
      canvas.drawLine(
        const Offset(t0, railY),
        Offset(fillX, railY),
        Paint()
          ..color = curColor
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      const Offset(railL, railY),
      _dot + 3.2,
      Paint()..color = curSoft,
    );
    canvas.drawCircle(
      const Offset(railL, railY),
      _dot,
      Paint()..color = curColor,
    );
    canvas.drawCircle(
      Offset(railR, railY),
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..color = curColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TreeRailPainter oldDelegate) =>
      oldDelegate.viz != viz || oldDelegate.fillPct != fillPct;
}

class _Segment {
  final Offset a;
  final Offset b;
  final bool on;

  const _Segment({required this.a, required this.b, required this.on});
}

class _Dot {
  final Offset center;
  final TreeNodeState state;

  const _Dot({required this.center, required this.state});
}

class _Label {
  final Offset anchor;
  final TextPainter painter;

  const _Label({required this.anchor, required this.painter});
}
