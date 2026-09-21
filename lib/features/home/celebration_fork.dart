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

/// The post-workout fork step. Fires when the mastered exercise is the last
/// node of a tree's shared foundation, so the next exercise is not a given:
/// the tree splits here. One screen, five beats — bar fills → foundation
/// cleared → the branch lines draw → the title swaps to the branch the
/// program is on and its first node lights → a helper says where to change
/// it. No decision is asked of a tired user.

/// One branch growing out of the foundation, as the mini-map draws it.
class ForkBranch {
  final String id;
  final String label;

  /// The first steps past the fork — at most two, which is all the map
  /// has room to show.
  final List<String> nodeNames;

  const ForkBranch({
    required this.id,
    required this.label,
    required this.nodeNames,
  });
}

class ForkUnlockData {
  final Exercise mastered;
  final Exercise newExercise;
  final int masterySets;
  final int masteryValue;
  final int startSets;
  final int startValue;
  final String treeTitle;

  /// The shared trunk, first step to the one just mastered.
  final List<String> foundationNames;

  /// Every branch that grows out of that trunk, in catalog order.
  final List<ForkBranch> branches;

  /// The branch the program's track is on — the one that lights up.
  final String chosenBranchId;

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
  });

  ForkBranch get chosen =>
      branches.firstWhere((branch) => branch.id == chosenBranchId);
}

/// The fork behind an activation, or null when the activation is an
/// ordinary next step: the mastered exercise must end its tree's shared
/// foundation, the new one must open a branch, and at least one other
/// branch must grow out of the same trunk. The counts come from the
/// progression events the caller already has.
ForkUnlockData? resolveForkUnlock({
  required Exercise mastered,
  required Exercise newExercise,
  required int masterySets,
  required int masteryValue,
  required int startSets,
  required int startValue,
}) {
  if (!SkillCategory.isFoundationBranchId(mastered.branchId) ||
      SkillCategory.isFoundationBranchId(newExercise.branchId)) {
    return null;
  }
  final category = SkillCategoryCatalog.findById(mastered.skillCategoryId);
  if (category == null) return null;

  String? chosenId;
  List<String>? chosenPath;
  var index = -1;
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    final at = path.indexOf(mastered.id);
    if (at < 0 || at + 1 >= path.length || path[at + 1] != newExercise.id) {
      continue;
    }
    chosenId = entry.key;
    chosenPath = path;
    index = at;
    break;
  }
  if (chosenId == null || chosenPath == null) return null;

  final foundation = chosenPath.sublist(0, index + 1);
  String nameOf(String id) => ExerciseCatalog.findById(id)?.name ?? id;

  // One branch per distinct first step past the fork. Two paths that open
  // with the same exercise are one route on the map; the program's own
  // path is the one that keeps the name.
  final byFirstStep = <String, ForkBranch>{};
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    if (path.length <= index + 1 ||
        !listEquals(path.sublist(0, index + 1), foundation)) {
      continue;
    }
    final next = path.sublist(index + 1, math.min(path.length, index + 3));
    if (byFirstStep.containsKey(next.first) && entry.key != chosenId) {
      continue;
    }
    byFirstStep[next.first] = ForkBranch(
      id: entry.key,
      label: _branchLabel(category, entry.key),
      nodeNames: [for (final id in next) nameOf(id)],
    );
  }
  final branches = byFirstStep.values.toList();
  if (branches.length < 2) return null;

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
    final branch = data.chosen;
    final title = started ? data.newExercise.name : data.mastered.name;
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
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'You’re on the ${branch.label} path. '),
                        const TextSpan(text: 'Change it anytime on the '),
                        const TextSpan(
                          text: 'Program tab',
                          style: TextStyle(
                            color: AppColors.accentPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
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

  static const double width = 342;
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
    if (old.phase != widget.phase && (widget.phase == 1 || widget.phase == 3)) {
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
    return FittedBox(
      child: SizedBox(
        width: ForkMap.width,
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

  static const _hubX = 34.0;
  static const _r0 = 20.0;
  static const _maxPitch = 44.0;
  static const _minPitch = 26.0;
  static const _lock = Color(0xFF3A3A40);
  static final _dim = Colors.white.withValues(alpha: 0.14);
  static final _trunkOn = AppColors.green.withValues(alpha: 0.5);
  static final _routeOn = AppColors.accentPrimary.withValues(alpha: 0.45);

  bool get _cleared => phase >= 1;
  bool get _lit => phase >= 3;

  /// Where each branch leaves the trunk, in degrees. Two branches sit 16°
  /// apart each side; more spread evenly across ±24°.
  static List<double> _offsets(int count) => switch (count) {
        1 => const [0],
        2 => const [-16, 16],
        3 => const [-20, 0, 20],
        _ => [for (var i = 0; i < count; i++) -24 + 48 * i / (count - 1)],
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

  @override
  void paint(Canvas canvas, Size size) {
    final hub = Offset(_hubX, size.height / 2);
    final trunkCount = data.foundationNames.length;
    final branches = data.branches;
    final branchDepth = branches.fold<int>(
      0,
      (depth, branch) => math.max(depth, branch.nodeNames.length),
    );

    // The pitch that fits the trunk, the deepest branch, and the widest
    // label inside the map — the design's 44 when there is room.
    final labels = [
      for (final branch in branches)
        _text(branch.label,
            size: 13, color: AppColors.textSecondary, letterSpacing: -0.13),
    ];
    final widestLabel = labels.fold<double>(
      0,
      (widest, label) => math.max(widest, label.width),
    );
    final steps = (trunkCount - 1) + branchDepth;
    final room = size.width - _hubX - _r0 - widestLabel - 11 - 4;
    final pitch = steps <= 0
        ? _maxPitch
        : (room / steps).clamp(_minPitch, _maxPitch).toDouble();

    Offset at(double radius, double degrees) {
      final rad = degrees * math.pi / 180;
      return hub + Offset(radius * math.cos(rad), radius * math.sin(rad));
    }

    final trunk = [
      for (var k = 0; k < trunkCount; k++) at(_r0 + k * pitch, 0),
    ];
    final fork = trunk.last;
    final forkRadius = _r0 + (trunkCount - 1) * pitch;
    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hub.
    canvas.drawCircle(hub, 11, Paint()..color = AppColors.bg);
    canvas.drawCircle(
      hub,
      11,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(hub, 3.2, Paint()..color = const Color(0xFF4A4B52));

    // Trunk links.
    for (var k = 0; k < trunk.length; k++) {
      final from = k == 0 ? hub + const Offset(11, 0) : trunk[k - 1];
      canvas.drawLine(from, trunk[k], line..color = _trunkOn);
    }

    // Branches: links, nodes, labels.
    final offsets = _offsets(branches.length);
    final beatIn = Curves.easeOut.transform(beat.clamp(0, 1));
    for (var j = 0; j < branches.length; j++) {
      final branch = branches[j];
      final on = branch.id == data.chosenBranchId;
      final angle = offsets[j];
      final nodes = [
        for (var k = 0; k < branch.nodeNames.length; k++)
          at(forkRadius + (k + 1) * pitch, angle),
      ];
      final routeT = on && _lit ? beatIn : 0.0;
      final route = Color.lerp(_dim, _routeOn, routeT)!;
      for (var k = 0; k < nodes.length; k++) {
        final from = k == 0 ? fork : nodes[k - 1];
        canvas.drawLine(
          from,
          nodes[k],
          line..color = k == 0 ? route.withValues(alpha: route.a * 0.6) : route,
        );
      }
      for (var k = 0; k < nodes.length; k++) {
        final first = k == 0;
        final openT = first && _cleared ? (phase == 1 ? beatIn : 1.0) : 0.0;
        final activeT = on && first && _lit ? beatIn : 0.0;
        var fill = Color.lerp(_lock, AppColors.textPrimary, openT)!;
        fill = Color.lerp(fill, AppColors.accentPrimary, activeT)!;
        final radius = 4.6 + 0.9 * openT + 1.0 * activeT;
        if (activeT > 0) {
          final ringT = (activeT / 0.55).clamp(0.0, 1.0);
          canvas.drawCircle(
            nodes[k],
            13 * (0.75 + 0.25 * ringT),
            Paint()
              ..color = AppColors.accentPrimary.withValues(alpha: 0.3 * ringT)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(nodes[k], radius, Paint()..color = fill);
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
      final last = k == trunk.length - 1;
      final node = trunk[k];
      if (last && !_cleared) {
        // Breathing ring on the node about to clear.
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
      var radius = last ? 7.5 : 6.0;
      var color = last && !_cleared ? AppColors.accentPrimary : AppColors.green;
      if (last && _cleared && phase == 1) {
        // The clear: a burst ring flies out and the node pops.
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
    }

    final caption = _text(
      'FOUNDATION',
      size: 10,
      color: _cleared ? AppColors.green : AppColors.textSecondary,
      letterSpacing: 1.4,
    );
    caption.paint(canvas, Offset(trunk.first.dx - 6, hub.dy - 22 - 8));
  }

  @override
  bool shouldRepaint(_ForkMapPainter old) =>
      old.phase != phase ||
      old.pulse != pulse ||
      old.beat != beat ||
      old.data != data;
}
