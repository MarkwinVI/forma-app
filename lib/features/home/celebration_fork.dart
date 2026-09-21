import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import 'celebration_widgets.dart';

/// The post-workout step for any unlock inside a tree, drawn as the tree:
/// the shared foundation as a trunk, every branch forking off its end, and
/// the mastered step wherever it sits. One screen, five beats — bar fills →
/// the step clears → hold → the title swaps to the new step and its node
/// lights → a helper. At the fork itself the branch the program is on
/// lights up and the helper says where to change it; nothing is asked.

/// One branch growing out of the foundation, as the mini-map draws it.
class ForkBranch {
  final String id;
  final String label;

  /// The branch's steps past the fork. The branch the user is on carries
  /// all of them; the others carry the two the map has room to show.
  final List<String> nodeNames;

  const ForkBranch({
    required this.id,
    required this.label,
    required this.nodeNames,
  });
}

/// An unlock inside a tree, drawn as the tree: the shared foundation as a
/// trunk, every branch forking off its end, and the step just mastered
/// wherever it sits — in the trunk, at the fork, or up a branch.
class ForkUnlockData {
  final Exercise mastered;
  final Exercise newExercise;
  final int masterySets;
  final int masteryValue;
  final int startSets;
  final int startValue;
  final String treeTitle;

  /// The whole shared trunk, first step to the fork.
  final List<String> foundationNames;

  /// Every branch that grows out of the trunk, in catalog order. Empty for
  /// a tree that is one straight path.
  final List<ForkBranch> branches;

  /// The branch the mastered and new steps sit on, when only one does —
  /// null while both are still in the trunk, where no branch is chosen.
  final String? chosenBranchId;

  /// Where the mastered step sits along the route: the trunk, then the
  /// chosen branch's steps.
  final int masteredIndex;

  const ForkUnlockData({
    required this.mastered,
    required this.newExercise,
    required this.masterySets,
    required this.masteryValue,
    required this.startSets,
    required this.startValue,
    required this.treeTitle,
    required this.foundationNames,
    required this.branches,
    required this.chosenBranchId,
    required this.masteredIndex,
  });

  ForkBranch? get chosen {
    for (final branch in branches) {
      if (branch.id == chosenBranchId) return branch;
    }
    return null;
  }

  /// The mastered step ended the trunk and the new one opened a branch,
  /// with others to choose from: the moment the tree actually splits.
  bool get isFork =>
      masteredIndex == foundationNames.length - 1 &&
      chosen != null &&
      branches.length >= 2;

  /// The route the map lights along: the trunk, then the chosen branch.
  List<String> get routeNames => [
        ...foundationNames,
        ...?chosen?.nodeNames,
      ];
}

/// The tree behind an in-tree activation, or null when the new exercise
/// does not follow the mastered one on any path of the mastered one's
/// tree — a hand-off or a manual jump, drawn elsewhere.
ForkUnlockData? resolveForkUnlock({
  required Exercise mastered,
  required Exercise newExercise,
  required int masterySets,
  required int masteryValue,
  required int startSets,
  required int startValue,
}) {
  if (mastered.skillCategoryId.isEmpty ||
      mastered.skillCategoryId != newExercise.skillCategoryId) {
    return null;
  }
  final category = SkillCategoryCatalog.findById(mastered.skillCategoryId);
  if (category == null) return null;

  // The paths the pair sits on, consecutively.
  final onPaths = <String>[];
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    final at = path.indexOf(mastered.id);
    if (at >= 0 && at + 1 < path.length && path[at + 1] == newExercise.id) {
      onPaths.add(entry.key);
    }
  }
  if (onPaths.isEmpty) return null;

  final foundation = category.pathFor(category.foundationBranchId);
  if (foundation.isEmpty) return null;
  String nameOf(String id) => ExerciseCatalog.findById(id)?.name ?? id;

  // One branch per distinct first step past the trunk. Two paths that
  // open with the same exercise are one route on the map; the one the
  // pair sits on keeps the name.
  final chosenId = onPaths.length == 1 ? onPaths.first : null;
  final byFirstStep = <String, ForkBranch>{};
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    if (path.length <= foundation.length ||
        !listEquals(path.sublist(0, foundation.length), foundation)) {
      continue;
    }
    final rest = path.sublist(foundation.length);
    if (byFirstStep.containsKey(rest.first) && entry.key != chosenId) {
      continue;
    }
    final shown = entry.key == chosenId ? rest : rest.take(2).toList();
    byFirstStep[rest.first] = ForkBranch(
      id: entry.key,
      label: _branchLabel(category, entry.key),
      nodeNames: [for (final id in shown) nameOf(id)],
    );
  }
  final branches = byFirstStep.values.toList();

  var masteredIndex = foundation.indexOf(mastered.id);
  if (masteredIndex < 0) {
    if (chosenId == null) return null;
    final path = category.trainingPaths[chosenId]!;
    masteredIndex = path.indexOf(mastered.id);
  }

  return ForkUnlockData(
    mastered: mastered,
    newExercise: newExercise,
    masterySets: masterySets,
    masteryValue: masteryValue,
    startSets: startSets,
    startValue: startValue,
    treeTitle: category.title,
    foundationNames: [for (final id in foundation) nameOf(id)],
    branches: branches,
    chosenBranchId: chosenId,
    masteredIndex: masteredIndex,
  );
}

String _branchLabel(SkillCategory category, String branchId) {
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

/// One screen, five beats: bar fills → foundation cleared (hold) → branch
/// lines draw → title and tag swap to the new exercise, its node lights →
/// helper. The path is changeable on the Program tab, so nothing is asked.
class ForkUnlockContent extends StatefulWidget {
  final ForkUnlockData data;

  const ForkUnlockContent({super.key, required this.data});

  @override
  State<ForkUnlockContent> createState() => _ForkUnlockContentState();
}

class _ForkUnlockContentState extends State<ForkUnlockContent> {
  /// 0 bar filling · 1 foundation cleared, branch firsts open · 2 hold ·
  /// 3 the chosen branch lights, title swaps · 4 helper.
  int _phase = 0;
  bool _fill = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    void at(int ms, VoidCallback fn) {
      _timers.add(Timer(Duration(milliseconds: ms), () {
        if (mounted) setState(fn);
      }));
    }

    at(600, () => _fill = true);
    at(2100, () => _phase = 1);
    at(4300, () => _phase = 2);
    at(5900, () {
      _phase = 3;
      _fill = false;
    });
    at(7100, () => _phase = 4);
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final started = _phase >= 3;
    final done = _phase >= 4;
    final title = started ? data.newExercise.name : data.mastered.name;
    final helper =
        'Mastering ${data.mastered.name} unlocked ${data.newExercise.name}.'
        '${data.isFork ? ' You’re on the ${data.chosen!.label} path. '
            'Change it anytime on the Program tab.' : ''}';
    final target = started
        ? '${data.startSets} × ${data.startValue}'
            '${data.newExercise.isTimed ? 's' : ''}'
        : '${data.masterySets} × ${data.masteryValue}'
            '${data.mastered.isTimed ? 's' : ''}';
    final Widget? tag = started
        ? const CelebrationTag(
            key: ValueKey('started'),
            color: AppColors.accentPrimary,
            label: 'New exercise started',
          )
        : _phase >= 1
            ? const CelebrationTag(
                key: ValueKey('mastered'),
                color: AppColors.green,
                label: 'Exercise mastered',
              )
            : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The tag's slot keeps its height from the first frame so the
            // title never jumps when the tag arrives.
            SizedBox(
              height: 36,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: tag ?? const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                title,
                key: ValueKey(title),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            RiseIn(
              delay: const Duration(milliseconds: 80),
              child: CelebrationTargetBar(
                label: started ? 'STARTING TARGET' : 'PREREQUISITE',
                target: target,
                targetColor:
                    started ? AppColors.textSecondary : AppColors.green,
                fill: _fill,
              ),
            ),
            const SizedBox(height: 12),
            RiseIn(
              delay: const Duration(milliseconds: 140),
              child: ForkMap(data: data, phase: _phase),
            ),
            const SizedBox(height: 14),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: done ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.32, 0.72, 0, 1),
                offset: done ? Offset.zero : const Offset(0, 0.3),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 290),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Text(
                    helper,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini-map ──────────────────────────────────────────────────────────

/// The Progress wheel's radial model, one tree at a time: the trunk runs
/// right from a hub, and the branches fork from the last trunk node at a
/// few degrees each side, keeping the pitch. Both routes are always drawn;
/// the program's is highlighted, never the only one. Beats follow [phase]:
/// the last trunk node pulses → turns green and each branch's first node
/// opens → the chosen branch's first node lights and its route brightens.
class ForkMap extends StatefulWidget {
  final ForkUnlockData data;
  final int phase;

  const ForkMap({super.key, required this.data, required this.phase});

  /// The map runs almost edge to edge, past the column's own padding —
  /// this much stays clear on each side — and the tree fills the width.
  static const double sideMargin = 12;
  static const double height = 178;

  @override
  State<ForkMap> createState() => _ForkMapState();
}

class _ForkMapState extends State<ForkMap> with TickerProviderStateMixin {
  /// Breathing ring on the node about to clear.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  /// One run per beat that changes the picture: the clear burst, then the
  /// light-up ring.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void didUpdateWidget(ForkMap old) {
    super.didUpdateWidget(old);
    // Crossings, not equality: several beats can land in one frame when
    // the app was busy, and each one still has to play.
    if ((old.phase < 1 && widget.phase >= 1) ||
        (old.phase < 3 && widget.phase >= 3)) {
      _beat.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 2 * ForkMap.sideMargin;
    return SizedBox(
      height: ForkMap.height,
      child: OverflowBox(
        maxWidth: double.infinity,
        child: SizedBox(
          width: width,
          height: ForkMap.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _beat]),
            builder: (context, _) => CustomPaint(
              painter: _ForkMapPainter(
                data: widget.data,
                phase: widget.phase,
                pulse: Curves.easeInOut.transform(_pulse.value),
                beat: _beat.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForkMapPainter extends CustomPainter {
  final ForkUnlockData data;
  final int phase;
  final double pulse;
  final double beat;

  _ForkMapPainter({
    required this.data,
    required this.phase,
    required this.pulse,
    required this.beat,
  });

  /// Where the trunk starts — its first exercise sits right here; there is
  /// no hub drawn before it.
  static const _pivotX = 12.0;

  /// The pitch stretches to fill the width; only a long route packs
  /// tighter than the design's 44.
  static const _maxPitch = 96.0;
  static const _minPitch = 24.0;
  static const _lock = Color(0xFF3A3A40);
  static final _dim = Colors.white.withValues(alpha: 0.14);
  static final _trunkOn = AppColors.green.withValues(alpha: 0.5);
  static final _routeOn = AppColors.accentPrimary.withValues(alpha: 0.45);

  bool get _cleared => phase >= 1;
  bool get _lit => phase >= 3;

  /// Where each branch leaves the trunk, in degrees. Two branches sit 16°
  /// apart each side, three across ±20°, more across ±30° so their labels
  /// clear each other.
  static List<double> _offsets(int count) => switch (count) {
        1 => const [0],
        2 => const [-16, 16],
        3 => const [-20, 0, 20],
        _ => [for (var i = 0; i < count; i++) -30 + 60 * i / (count - 1)],
      };

  TextPainter _text(
    String text, {
    required double size,
    required Color color,
    double letterSpacing = 0,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// The most steps the map draws along the route before it starts
  /// dropping trunk steps from the left.
  static const _maxSteps = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final hub = Offset(_pivotX, size.height / 2);
    final branches = data.branches;
    final chosen = data.chosen;
    final trunkAll = data.foundationNames;
    final chosenNodesAll = chosen?.nodeNames ?? const <String>[];
    final beatIn = Curves.easeOut.transform(beat.clamp(0, 1));

    // Window: everything up to the step after the new one, and enough of
    // the trunk to fit — the mastered step is always in view.
    final routeLength = trunkAll.length + chosenNodesAll.length;
    final showUpTo = math.min(
        routeLength, math.max(data.masteredIndex + 2, trunkAll.length));
    final chosenShown = math.max(0, showUpTo - trunkAll.length);
    final otherDepth =
        branches.any((branch) => branch.id != chosen?.id) ? 2 : 0;
    var trunkStart = 0;
    var steps = (trunkAll.length - 1) + math.max(chosenShown, otherDepth);
    while (steps > _maxSteps && trunkStart < trunkAll.length - 1) {
      trunkStart++;
      steps--;
    }
    final trunkNames = trunkAll.sublist(trunkStart);
    final masteredAt = data.masteredIndex - trunkStart;

    final labels = [
      for (final branch in branches)
        _text(branch.label,
            size: 13, color: AppColors.textSecondary, letterSpacing: -0.13),
    ];
    final widestLabel = labels.fold<double>(
      0,
      (widest, label) => math.max(widest, label.width),
    );
    final room = size.width - _pivotX - widestLabel - 11 - 4;
    final pitch = steps <= 0
        ? _maxPitch
        : (room / steps).clamp(_minPitch, _maxPitch).toDouble();

    Offset at(double radius, double degrees) {
      final rad = degrees * math.pi / 180;
      return hub + Offset(radius * math.cos(rad), radius * math.sin(rad));
    }

    final trunk = [
      for (var k = 0; k < trunkNames.length; k++) at(k * pitch, 0),
    ];
    final fork = trunk.last;

    // Branches fan out from the fork node itself, a pitch per step along
    // their own ray, so the spread stays the same whatever the pitch.
    Offset branchAt(int step, double degrees) {
      final rad = degrees * math.pi / 180;
      return fork +
          Offset(step * pitch * math.cos(rad), step * pitch * math.sin(rad));
    }

    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Along the route: done before the mastered step, the step after it
    // is next, everything past that locked.
    Color routeLink(int toIndex) {
      if (toIndex <= masteredAt) return _trunkOn;
      if (toIndex == masteredAt + 1) {
        return Color.lerp(_dim, _routeOn, _lit ? beatIn : 0)!;
      }
      return _dim;
    }

    void routeNode(Offset node, int index, {bool big = false}) {
      if (index < masteredAt) {
        canvas.drawCircle(node, 6, Paint()..color = AppColors.green);
        return;
      }
      if (index == masteredAt) {
        if (!_cleared) {
          canvas.drawCircle(
            node,
            14 * (1 + 0.25 * pulse),
            Paint()
              ..color =
                  AppColors.accentPrimary.withValues(alpha: 0.55 - 0.4 * pulse)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        var radius = 6.0;
        var color = _cleared ? AppColors.green : AppColors.accentPrimary;
        if (_cleared && phase == 1) {
          final t = beat.clamp(0.0, 1.0);
          final burst = Curves.easeOutCubic.transform(t);
          canvas.drawCircle(
            node,
            7 * (1 + 2.4 * burst),
            Paint()
              ..color = AppColors.green.withValues(alpha: 0.9 * (1 - burst))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          final pop = t < 0.45
              ? 1 + 0.9 * Curves.easeOut.transform(t / 0.45)
              : 1.9 - 0.9 * Curves.easeIn.transform((t - 0.45) / 0.55);
          radius *= pop;
          color = Color.lerp(
              AppColors.accentPrimary, AppColors.green, (t / 0.3).clamp(0, 1))!;
        }
        canvas.drawCircle(node, radius, Paint()..color = color);
        return;
      }
      if (index == masteredAt + 1) {
        final openT = _cleared ? (phase == 1 ? beatIn : 1.0) : 0.0;
        final activeT = _lit ? beatIn : 0.0;
        var fill = Color.lerp(_lock, AppColors.textPrimary, openT)!;
        fill = Color.lerp(fill, AppColors.accentPrimary, activeT)!;
        if (activeT > 0) {
          final ringT = (activeT / 0.55).clamp(0.0, 1.0);
          canvas.drawCircle(
            node,
            13 * (0.75 + 0.25 * ringT),
            Paint()
              ..color = AppColors.accentPrimary.withValues(alpha: 0.3 * ringT)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(
            node, 4.6 + 0.9 * openT + 1.0 * activeT, Paint()..color = fill);
        return;
      }
      canvas.drawCircle(node, 4.6, Paint()..color = _lock);
    }

    // A trunk cut on the left starts with a faint stub, so the tree reads
    // as continuing.
    if (trunkStart > 0) {
      canvas.drawLine(
        trunk.first - const Offset(10, 0),
        trunk.first,
        line..color = _trunkOn.withValues(alpha: 0.25),
      );
    }
    for (var k = 1; k < trunk.length; k++) {
      canvas.drawLine(trunk[k - 1], trunk[k], line..color = routeLink(k));
    }

    // Branches: links, nodes, labels. The chosen one is part of the route;
    // the others open their first node only at the fork itself.
    final offsets = _offsets(branches.length);
    for (var j = 0; j < branches.length; j++) {
      final branch = branches[j];
      final on = branch.id == chosen?.id;
      final angle = offsets[j];
      final count = on ? chosenShown : math.min(2, branch.nodeNames.length);
      if (count == 0) continue;
      final nodes = [
        for (var k = 0; k < count; k++) branchAt(k + 1, angle),
      ];
      for (var k = 0; k < nodes.length; k++) {
        final from = k == 0 ? fork : nodes[k - 1];
        final color = on
            ? routeLink(trunkNames.length + k)
            : (k == 0 ? _dim.withValues(alpha: _dim.a * 0.6) : _dim);
        canvas.drawLine(from, nodes[k], line..color = color);
      }
      for (var k = 0; k < nodes.length; k++) {
        if (on) {
          routeNode(nodes[k], trunkNames.length + k);
          continue;
        }
        final openT = k == 0 && data.isFork && _cleared
            ? (phase == 1 ? beatIn : 1.0)
            : 0.0;
        canvas.drawCircle(
          nodes[k],
          4.6 + 0.9 * openT,
          Paint()..color = Color.lerp(_lock, AppColors.textPrimary, openT)!,
        );
      }
      final tip = nodes.last;
      final label = on && _lit
          ? _text(branch.label,
              size: 13,
              color: Color.lerp(
                  AppColors.textSecondary, AppColors.textPrimary, beatIn)!,
              letterSpacing: -0.13)
          : labels[j];
      label.paint(canvas, tip + Offset(11, -label.height / 2));
    }

    // Trunk nodes on top of everything.
    for (var k = 0; k < trunk.length; k++) {
      routeNode(trunk[k], k);
    }

    if (trunkStart == 0) {
      // A tree that never forks has no foundation to speak of: its own
      // name goes over the trunk instead.
      final caption = _text(
        branches.isEmpty ? data.treeTitle.toUpperCase() : 'FOUNDATION',
        size: 10,
        color: masteredAt >= trunk.length - 1 && _cleared
            ? AppColors.green
            : AppColors.textSecondary,
        letterSpacing: 1.4,
      );
      caption.paint(canvas, Offset(trunk.first.dx - 6, hub.dy - 22 - 8));
    }
  }

  @override
  bool shouldRepaint(_ForkMapPainter old) =>
      old.phase != phase ||
      old.pulse != pulse ||
      old.beat != beat ||
      old.data != data;
}
