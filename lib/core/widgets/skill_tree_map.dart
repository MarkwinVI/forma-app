import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';

/// Horizontal node map of a whole skill tree: a shared spine fanning at a hub
/// into named branches, the user's path highlighted.
///
/// Two rules keep every tree comparable: the map always fills the width it is
/// given (sparse trees space their nodes further apart rather than stopping
/// short), and every branch runs the same distance from the fork (a short
/// branch spreads its nodes out instead of ending early).
class SkillTreeMap extends StatelessWidget {
  /// Route id standing for the shared spine every branch grows out of.
  static const String foundationRouteId = '__foundation__';

  final TreeVizModel viz;

  /// Volume landed on the working node, 0–1: fills its rep ring and the
  /// segment toward the next unlock. Null leaves both off.
  final double? fillPct;

  /// Tallest the fan may grow before it flattens instead.
  final double maxHeight;

  /// Route the map should read as selected — [foundationRouteId] or a branch
  /// id. It gets a soft track behind it and full brightness while the rest
  /// dims. Null treats every route alike.
  final String? selectedRouteId;

  /// Style for the branch tip labels; only the color is overridden, to mark
  /// the selected route.
  final TextStyle? labelStyle;

  /// Called with the branch whose tip label was tapped. Labels are only
  /// tappable when this is set.
  final void Function(TreeVizBranch branch)? onBranchTap;

  /// Called when the spine — the shared foundation — is tapped.
  final VoidCallback? onFoundationTap;

  const SkillTreeMap({
    super.key,
    required this.viz,
    this.fillPct,
    this.maxHeight = 164,
    this.selectedRouteId,
    this.labelStyle,
    this.onBranchTap,
    this.onFoundationTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _TreeLayout(
          viz: viz,
          width: constraints.maxWidth,
          maxHeight: maxHeight,
          selectedRouteId: selectedRouteId,
          labelStyle: labelStyle,
        );
        final map = SizedBox(
          width: double.infinity,
          height: layout.height,
          child: CustomPaint(
            painter: _TreeMapPainter(
              layout: layout,
              fillPct: fillPct,
              selectedRouteId: selectedRouteId,
            ),
          ),
        );
        if (onBranchTap == null && onFoundationTap == null) return map;

        // Hit targets sit on the painted tip labels, which are the handles for
        // picking a branch; the spine's target covers everything left of the
        // fork.
        return SizedBox(
          width: double.infinity,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (onFoundationTap != null && viz.spine.isNotEmpty)
                Positioned(
                  left: 0,
                  top: 0,
                  width: layout.forkX,
                  height: layout.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFoundationTap,
                  ),
                ),
              map,
              if (onBranchTap != null)
                for (var index = 0; index < layout.labels.length; index++)
                  Positioned(
                    left: layout.labels[index].anchor.dx,
                    top: layout.labels[index].anchor.dy -
                        layout.labels[index].painter.height / 2 -
                        8,
                    width: layout.labels[index].painter.width + 16,
                    height: layout.labels[index].painter.height + 16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onBranchTap!(viz.branches[index]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Node states for the map. Same color language as the Skills tab:
/// green = cleared, blue = working, gray = everything still shut.
enum TreeNodeState { done, cur, locked }

class TreeVizBranch {
  final String id;
  final String label;
  final List<TreeNodeState> states;
  final bool isActive;

  const TreeVizBranch({
    required this.id,
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

    return TreeVizModel(
      spine: spineStates,
      branches: [
        for (final id in branchIds)
          TreeVizBranch(
            id: id,
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
  static const double _plainHeight = 62;
  static const double _spineRef = 22; // reference spine spacing
  static const double _branchRef = 17; // reference branch spacing

  final TreeVizModel viz;
  final double width;
  final double maxHeight;
  final String? selectedRouteId;
  final TextStyle? labelStyle;

  late final double height;
  late final List<_Segment> segments;
  late final List<_Dot> dots;
  late final List<_Label> labels;
  late final Offset? hub;
  late final _Segment? fillSegment;

  /// Where the spine ends and the branches fan out — the split between the
  /// foundation's tap target and the branches'.
  late final double forkX;

  /// Points to trace for the selected route's soft track, keyed by route id.
  late final Map<String, List<Offset>> routeTracks;

  _TreeLayout({
    required this.viz,
    required this.width,
    required this.maxHeight,
    this.selectedRouteId,
    this.labelStyle,
  }) {
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
    final fitRatio = ((maxHeight / 2 - 13) / radial).clamp(0.18, 1.0);
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

  /// Selected route reads brightest; with a selection in play the others step
  /// back, and with none the active branch keeps the old emphasis.
  TextStyle _labelStyleFor(TreeVizBranch branch, bool isActiveBranch) {
    final base = labelStyle ??
        GoogleFonts.robotoMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        );
    if (selectedRouteId != null) {
      return base.copyWith(
        fontWeight:
            branch.id == selectedRouteId ? FontWeight.w700 : base.fontWeight,
        color: branch.id == selectedRouteId
            ? AppColors.textPrimary
            : AppColors.textMuted,
      );
    }
    return base.copyWith(
      fontWeight: isActiveBranch ? FontWeight.w700 : base.fontWeight,
      color:
          isActiveBranch ? AppColors.textSecondary : AppColors.textMuted,
    );
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
          routeId: branches[j].id,
          painter: TextPainter(
            text: TextSpan(
              text: branches[j].label,
              style: _labelStyleFor(branches[j], j == activeIndex),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
        ),
    ];

    // Largest scale whose rightmost edge still fits — the map ends flush with
    // the card no matter how many nodes the tree has. The ceiling is high
    // enough that a sparse tree (Muscle-up: four nodes, no branches) still
    // stretches the whole way rather than stopping short.
    final limit = width - 2;
    var low = 0.25;
    var high = 20.0;
    if (_rightEdgeFor(low, labelPainters) > limit) {
      high = low;
    } else if (_rightEdgeFor(high, labelPainters) <= limit) {
      low = high;
    } else {
      for (var step = 0; step < 30; step++) {
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
            maxHeight,
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
        routeId: SkillTreeMap.foundationRouteId,
      ));
    }

    final hubX = _hubXFor(scale);
    hub = _hasHub ? point(hubX, 0) : null;
    forkX = hubX - hubR;
    if (spine.isNotEmpty && branches.isNotEmpty) {
      builtSegments.add(_Segment(
        a: spinePoints.last,
        b: point(hubX - hubR, 0),
        on: spine.last == TreeNodeState.done,
        routeId: SkillTreeMap.foundationRouteId,
      ));
    }
    final tracks = <String, List<Offset>>{
      if (spinePoints.isNotEmpty)
        SkillTreeMap.foundationRouteId: [
          spinePoints.first,
          branches.isEmpty ? spinePoints.last : point(hubX, 0),
        ],
    };

    // The volume fill runs along the segment from the working node to the one
    // it opens.
    final curS = spine.indexOf(TreeNodeState.cur);
    if (curS >= 0 && curS + 1 < spinePoints.length) {
      final from = spinePoints[curS];
      final to = spinePoints[curS + 1];
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
        routeId: branch.id,
      ));
      for (var k = 1; k < states.length; k++) {
        builtSegments.add(_Segment(
          a: nodeAt(k - 1),
          b: nodeAt(k),
          on: j == activeIndex && states[k - 1] == TreeNodeState.done,
          faint: j != activeIndex,
          routeId: branch.id,
        ));
      }
      for (var k = 0; k < states.length; k++) {
        builtDots.add(_Dot(
          center: nodeAt(k),
          state: states[k],
          faint: j != activeIndex,
          routeId: branch.id,
        ));
      }
      tracks[branch.id] = [
        point(hubX + cos * _stemRadius, sin * _stemRadius),
        nodeAt(states.length - 1),
      ];

      if (j == activeIndex) {
        final curB = states.indexOf(TreeNodeState.cur);
        if (curB >= 0 && curB + 1 < states.length) {
          final from = nodeAt(curB);
          final to = nodeAt(curB + 1);
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
        routeId: branch.id,
      ));
    }

    for (var index = 0; index < spine.length; index++) {
      builtDots.add(_Dot(
        center: spinePoints[index],
        state: spine[index],
        routeId: SkillTreeMap.foundationRouteId,
      ));
    }

    segments = builtSegments;
    dots = builtDots;
    labels = builtLabels;
    fillSegment = fill;
    routeTracks = tracks;
  }
}

/// Paints the node map from a resolved [_TreeLayout]. Progress lives on the
/// map itself — the working node wears a rep ring and the segment toward the
/// next unlock fills as volume lands.
class _TreeMapPainter extends CustomPainter {
  final _TreeLayout layout;
  final double? fillPct;
  final String? selectedRouteId;

  const _TreeMapPainter({
    required this.layout,
    required this.fillPct,
    this.selectedRouteId,
  });

  /// Routes other than the selected one step back rather than disappear.
  double _opacityFor(String? routeId) {
    if (selectedRouteId == null || routeId == null) return 1;
    return routeId == selectedRouteId ? 1 : 0.38;
  }

  Color _dim(Color color, String? routeId) {
    final opacity = _opacityFor(routeId);
    return opacity == 1 ? color : color.withValues(alpha: color.a * opacity);
  }

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

    final track = selectedRouteId == null
        ? null
        : layout.routeTracks[selectedRouteId];
    if (track != null && track.length > 1) {
      final path = Path()..moveTo(track.first.dx, track.first.dy);
      for (final point in track.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.105)
          ..strokeWidth = 19
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final segment in layout.segments) {
      canvas.drawLine(
        segment.a,
        segment.b,
        Paint()
          ..color = _dim(
            segment.on
                ? pathColor
                : segment.faint
                    ? branchLineColor
                    : lineColor,
            segment.routeId,
          )
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }

    final progress = fillPct;
    final fill = layout.fillSegment;
    if (fill != null && progress != null) {
      canvas.drawLine(
        fill.a,
        fill.a + (fill.b - fill.a) * progress.clamp(0.0, 1.0),
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
      final route = node.routeId;
      switch (node.state) {
        case TreeNodeState.done:
          canvas.drawCircle(center, dot, Paint()..color = _dim(doneColor, route));
        case TreeNodeState.cur:
          // Rep ring: how much of the target this session's volume covers.
          if (progress != null) {
            canvas.drawCircle(
              center,
              8,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = _dim(curSoft, route),
            );
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: 8),
              -math.pi / 2,
              2 * math.pi * progress.clamp(0.0, 1.0),
              false,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round
                ..color = _dim(curColor, route),
            );
          } else {
            canvas.drawCircle(
              center,
              dot + 3.2,
              Paint()..color = _dim(curSoft, route),
            );
          }
          canvas.drawCircle(center, dot, Paint()..color = _dim(curColor, route));
        case TreeNodeState.locked:
          canvas.drawCircle(
            center,
            node.faint ? dot - 1.3 : dot - 0.8,
            Paint()
              ..color = _dim(
                node.faint
                    ? lockedColor.withValues(alpha: 0.75)
                    : lockedColor,
                route,
              ),
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
      oldDelegate.layout != layout ||
      oldDelegate.fillPct != fillPct ||
      oldDelegate.selectedRouteId != selectedRouteId;
}

class _Segment {
  final Offset a;
  final Offset b;
  final bool on;
  final bool faint;
  final String? routeId;

  const _Segment({
    required this.a,
    required this.b,
    required this.on,
    this.faint = false,
    this.routeId,
  });
}

class _Dot {
  final Offset center;
  final TreeNodeState state;
  final bool faint;
  final String? routeId;

  const _Dot({
    required this.center,
    required this.state,
    this.faint = false,
    this.routeId,
  });
}

class _Label {
  final Offset anchor;
  final TextPainter painter;
  final String? routeId;

  const _Label({
    required this.anchor,
    required this.painter,
    this.routeId,
  });
}
