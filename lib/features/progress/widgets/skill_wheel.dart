import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// How one step of a tree reads on the wheel. Skipped counts as cleared
/// everywhere (same rule as the rest of the app); the wheel only tells the
/// two apart in the focused card's status line.
/// [available] is a step whose prerequisite is cleared but which is not the
/// step being trained — reachable right now, drawn as a white node.
enum WheelNodeState { mastered, skipped, active, available, locked }

extension WheelNodeStateX on WheelNodeState {
  bool get isCleared =>
      this == WheelNodeState.mastered || this == WheelNodeState.skipped;
}

class WheelNode {
  final String exerciseId;
  final String name;
  final WheelNodeState state;

  const WheelNode({
    required this.exerciseId,
    required this.name,
    required this.state,
  });
}

class WheelBranch {
  final String id;
  final String label;
  final List<WheelNode> steps;

  const WheelBranch({
    required this.id,
    required this.label,
    required this.steps,
  });
}

/// One family (skill category) on the wheel: the foundation trunk every
/// branch grows out of, plus the named branch tails.
class WheelFamily {
  final String categoryId;
  final String title;
  final List<WheelNode> trunk;
  final List<WheelBranch> branches;

  /// Trunk then every branch's steps in branch order — the order the
  /// left/right selector walks.
  late final List<WheelNode> flat = [
    ...trunk,
    for (final branch in branches) ...branch.steps,
  ];

  /// Section name for every entry of [flat] — FOUNDATION for the trunk, the
  /// branch's label for its steps. Drives the grouped step list.
  late final List<String> flatSections = [
    for (final _ in trunk) 'FOUNDATION',
    for (final branch in branches)
      for (final _ in branch.steps) branch.label.toUpperCase(),
  ];

  WheelFamily({
    required this.categoryId,
    required this.title,
    required this.trunk,
    required this.branches,
  });

  /// Where the selector lands on fly-in: the step being trained, or on an
  /// idle tree the first step a start would land on.
  int get activeFlatIndex {
    final active = flat.indexWhere((n) => n.state == WheelNodeState.active);
    if (active >= 0) return active;
    final available =
        flat.indexWhere((n) => n.state == WheelNodeState.available);
    return available < 0 ? 0 : available;
  }
}

/// Why a tree is locked: the prerequisite step in another tree that has to
/// be mastered first. Only unmet locks are represented — a passed
/// prerequisite means no lock at all.
class WheelTreeLock {
  final String prereqExerciseName;
  final String prereqTreeTitle;

  const WheelTreeLock({
    required this.prereqExerciseName,
    required this.prereqTreeTitle,
  });
}

/// Lets the screen around the wheel drive it (back arrow, queue rows).
class SkillWheelController {
  _SkillWheelState? _state;

  void back() => _state?._go(null, 0);

  void goTo(int familyIndex, int flatIndex) =>
      _state?._go(familyIndex, flatIndex);
}

/// The radial skill-tree wheel: every family radiating from a hub. Tap a
/// family to fly in (640ms — ease-out-cubic camera, ease-out-back spin),
/// swipe up/down to spin to the next family (720ms, camera holds), swipe
/// left/right to walk the steps, tap the background to pull back out.
class SkillWheel extends StatefulWidget {
  /// Height of the wheel band on the overview, in design px (the wheel's
  /// 400-unit-wide reference space). The screen around the wheel uses it to
  /// place the performance sheet's resting edge.
  static const double overviewBandHeight = 408;

  final List<WheelFamily> families;
  final SkillWheelController? controller;
  final void Function(int? selected, int focus)? onChanged;

  /// Goal keys (`<categoryId>:<branchId>`, or `<categoryId>:*` for a family
  /// with no branches) currently chosen as destinations. Each lights an
  /// amber route from the start of its tree and an amber marker on its tip.
  final Set<String> pickedGoals;

  /// Goal keys that can be chosen. A tip outside this set is drawn plain —
  /// its branch is not something a program can be built toward.
  final Set<String> pickableGoals;

  /// Called with a tip's goal key when its marker is tapped. Supplying it
  /// turns the wheel into a goal picker: tips become tappable markers, and
  /// the per-step selector — which a picker has no use for — goes away
  /// along with the left/right swipe that drives it.
  final void Function(String goalKey)? onToggleGoal;

  /// Categories with a progression running in the program. Each gets a blue
  /// rim arc over its sector on the overview, and its curved name brightens
  /// to match.
  final Set<String> activeCategoryIds;

  /// Categories still behind an unmet prerequisite in another tree. Each
  /// gets a dashed gray rim arc and a padlock badge on its spoke, and its
  /// curved name dims. A tree that is actively training draws as active —
  /// the user started it anyway, so it is running.
  final Set<String> lockedCategoryIds;

  const SkillWheel({
    super.key,
    required this.families,
    this.controller,
    this.onChanged,
    this.pickedGoals = const {},
    this.pickableGoals = const {},
    this.onToggleGoal,
    this.activeCategoryIds = const {},
    this.lockedCategoryIds = const {},
  });

  bool get isPicker => onToggleGoal != null;

  @override
  State<SkillWheel> createState() => _SkillWheelState();
}

class _SkillWheelState extends State<SkillWheel>
    with TickerProviderStateMixin {
  // Geometry, verbatim from the reference design: the radial lives in a
  // 400-unit-wide user space with the hub at (240, 240). Every family is cut
  // to the same length — a short family spaces its nodes further apart.
  static const double _hx = 240, _hy = 240;
  static const double _r0 = 20, _reach = 209;
  static const double _rim = 250; // pie-sector rim ring radius
  static const double _w = 400;
  static const double _openH = SkillWheel.overviewBandHeight;
  static const double _floorH = 180, _bandMax = 218, _minBox = 240;
  static const int _moveMs = 640; // camera moves (enter/leave a tree)
  static const int _spinMs = 720; // camera holds (family change)
  static const double _bounce = 1.45;

  static const Color _accent = AppColors.accentBright;
  static const Color _green = AppColors.green;
  static const Color _lock = AppColors.surface3;
  // Dimmed neighbours sit well back: legible as faint structure, no
  // competition with the focused tree.
  static const Color _mutedNode = Color(0xFF222226);
  static const Color _mutedLink = Color(0x08FFFFFF); // white 3%
  static const Color _linkDim = Color(0x16FFFFFF); // white 8.5%
  static const Color _linkOn = Color(0x803FD07E); // green 50%
  static const Color _linkFaint = Color(0x13FFFFFF); // white 7.5%
  static const Color _cardBg = AppColors.bg;

  int? _sel;
  int _focus = 0;

  // Camera + rotation, animated outside setState: the tween owns these and a
  // rebuild mid-animation must not clobber an interpolated frame.
  late List<double> _fromVB, _toVB;
  double _fromRot = 0, _toRot = 0;
  late List<double> _fromLit, _toLit;
  late final AnimationController _move;
  late final AnimationController _labels;
  late final AnimationController _halo;

  /// Sector geometry (spokes, rim ring, curved names) shows on the wheel and
  /// fades away while a tree is focused.
  late final AnimationController _sector;
  Timer? _labelTimer;

  Offset? _dragStart;
  Offset? _dragLast;

  final Map<int, _TreeGeo> _geoCache = {};

  int get _n => widget.families.length;
  double get _stepDeg => 360 / _n;
  double get _clampDeg => _stepDeg / 2 - 0.5;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _fromVB = _toVB = _target(null);
    _fromLit = _toLit = List.filled(_n, 1);
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _moveMs),
      value: 1,
    );
    _labels = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _sector = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant SkillWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
    if (widget.families.length != oldWidget.families.length) {
      _geoCache.clear();
      _sel = null;
      _focus = 0;
      _fromVB = _toVB = _target(null);
      _fromLit = _toLit = List.filled(_n, 1);
      _fromRot = _toRot = 0;
    } else {
      // Statuses may have changed under the same shape.
      _geoCache.clear();
    }
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _move.dispose();
    _labels.dispose();
    _halo.dispose();
    _sector.dispose();
    widget.controller?._state = null;
    super.dispose();
  }

  // ── Angles and easing ──────────────────────────────────────────────

  double _angDeg(int i) => -90 + _stepDeg * i;
  double _angRad(int i) => _angDeg(i) * math.pi / 180;

  static double _cubicOut(double p) => 1 - math.pow(1 - p, 3).toDouble();

  static double _backOut(double p) {
    const k1 = _bounce, k3 = k1 + 1;
    return 1 +
        k3 * math.pow(p - 1, 3).toDouble() +
        k1 * math.pow(p - 1, 2).toDouble();
  }

  // ── Family tree geometry (static bearings; rotation is a canvas op) ─

  double _depth(WheelFamily f) {
    final branchMax = f.branches.isEmpty
        ? 0
        : f.branches.map((b) => b.steps.length).reduce(math.max);
    // A family whose branches fork straight from the start (no shared trunk)
    // counts its fork as sitting at r0, like a one-step trunk.
    return math.max(1, math.max(f.trunk.length, 1) - 1 + branchMax)
        .toDouble();
  }

  double _pitch(WheelFamily f) => (_reach - _r0) / _depth(f);

  /// Branch bearings leave the fork at an angle rather than a parallel lane,
  /// clamped so a family never crosses into its neighbour's sector.
  ///
  /// A trunkless family (Core) forks straight from the hub, so its branches
  /// run near-parallel for their whole length — the sub-fork spread keeps
  /// them reading as one family instead of three spokes. Trunked fans stay
  /// nearly as tight: two- and three-branch forks open just enough to tell
  /// the routes apart, and only the four-branch fan uses the full spread.
  List<double> _offsets(int count, {bool tight = false}) {
    if (count <= 1) return const [0];
    // Wide fans stop short of the sector dividers, so outer-branch nodes
    // never sit on the hairlines.
    final s = tight ? 10.0 : (count == 2 ? 10.0 : (count == 3 ? 12.0 : 16.0));
    if (count == 2) return [-s, s];
    if (count == 3) return [-s, 0, s];
    return [for (var i = 0; i < count; i++) -s + 2 * s * i / (count - 1)];
  }

  double _clampAng(double baseRad, double angRad) {
    final maxRad = (_stepDeg / 2 - 2.5) * math.pi / 180;
    final d = angRad - baseRad;
    return baseRad + d.clamp(-maxRad, maxRad);
  }

  _TreeGeo _tree(int i) {
    final cached = _geoCache[i];
    if (cached != null) return cached;

    final f = widget.families[i];
    final a = _angRad(i);
    final p = _pitch(f);
    final nodes = <_GeoNode>[];
    final links = <_GeoLink>[];
    final tips = <_GeoTip>[];
    var flat = 0;

    final trunk = <_GeoNode>[];
    for (var k = 0; k < f.trunk.length; k++) {
      final r = _r0 + k * p;
      final n = _GeoNode(
        x: _hx + r * math.cos(a),
        y: _hy + r * math.sin(a),
        r: r,
        state: f.trunk[k].state,
        flat: flat++,
      );
      nodes.add(n);
      trunk.add(n);
      if (k > 0) links.add(_GeoLink(p: trunk[k - 1], q: n, faint: false));
    }
    // A trunkless family (parallel branches from step one) forks from a
    // virtual node at r0, so its branches read like every other family's.
    final fork = trunk.isNotEmpty
        ? trunk.last
        : _GeoNode(
            x: _hx + _r0 * math.cos(a),
            y: _hy + _r0 * math.sin(a),
            r: _r0,
            state: WheelNodeState.locked,
            flat: -1,
          );

    final offs = _offsets(f.branches.length, tight: f.trunk.isEmpty);
    for (var j = 0; j < f.branches.length; j++) {
      final b = f.branches[j];
      final bearing = _clampAng(a, a + offs[j] * math.pi / 180);
      // Every branch runs the full distance from the fork to the reach — a
      // branch with fewer steps spaces its nodes further apart instead of
      // stopping short.
      final branchPitch = (_reach - fork.r) / b.steps.length;
      var prev = fork;
      final chain = <_GeoNode>[];
      for (var k = 0; k < b.steps.length; k++) {
        // A branch node sits on its own bearing from the hub, so the branch
        // reads as its own ray out of the fork.
        final r = fork.r + (k + 1) * branchPitch;
        final n = _GeoNode(
          x: _hx + r * math.cos(bearing),
          y: _hy + r * math.sin(bearing),
          r: r,
          state: b.steps[k].state,
          flat: flat++,
        );
        nodes.add(n);
        chain.add(n);
        // The one link that leaves the fork is a hairline.
        links.add(_GeoLink(p: prev, q: n, faint: k == 0));
        prev = n;
      }
      tips.add(_GeoTip(
        name: b.label,
        x: prev.x,
        y: prev.y,
        ang: bearing,
        id: '${f.categoryId}:${b.id}',
        chain: chain,
      ));
    }
    if (f.branches.isEmpty) {
      tips.add(_GeoTip(
        name: f.title,
        x: fork.x,
        y: fork.y,
        ang: a,
        id: '${f.categoryId}:*',
        chain: const [],
      ));
    }

    final geo = _TreeGeo(
      nodes: nodes,
      links: links,
      tips: tips,
      fork: fork,
      trunk: trunk,
    );
    _geoCache[i] = geo;
    return geo;
  }

  // ── Camera ─────────────────────────────────────────────────────────

  /// One framing for every family: switching family needs no camera move at
  /// all — a pure spin about the hub.
  List<double> _target(int? sel) {
    if (sel == null) {
      // Frame the pie: the rim ring plus a small margin.
      const half = _rim + 10;
      const w = 2 * half * _w / _openH;
      return const [_hx - w / 2, _hy - half, w, _openH];
    }
    // Left edge pinned just behind the hub, right edge at the deepest reach
    // plus a label allowance, vertical span centred on the hub. The slack
    // above and below the tree is where the dimmed neighbours read.
    const x0 = _hx - 16.0, x1 = _hx + _reach + 62.0;
    final yHalf = _reach * math.sin(_clampDeg * math.pi / 180) + 14;
    final y0 = _hy - yHalf, y1 = _hy + yHalf;
    final bandH = (_w * (y1 - y0) / (x1 - x0))
        .roundToDouble()
        .clamp(_floorH, _bandMax)
        .toDouble();
    final w = [_minBox, x1 - x0, (y1 - y0) * _w / bandH].reduce(math.max);
    return [
      (x0 + x1) / 2 - w / 2,
      (y0 + y1) / 2 - w * bandH / _w / 2,
      w,
      bandH,
    ];
  }

  /// The selected family locks to the horizontal — the orientation that fits
  /// the wide, short band.
  double _rotFor(int? sel) => sel == null ? 0 : 90 - _stepDeg * sel;

  List<double> _liveVB() {
    final p = _cubicOut(_move.value);
    return [
      for (var i = 0; i < 4; i++) _fromVB[i] + (_toVB[i] - _fromVB[i]) * p,
    ];
  }

  double _liveRot() => _fromRot + (_toRot - _fromRot) * _backOut(_move.value);

  List<double> _liveLit() {
    // Colour is locked to the motion curve — the same ease-out-back the
    // rotation uses, clamped through the overshoot.
    final q = _backOut(_move.value).clamp(0.0, 1.0);
    return [
      for (var i = 0; i < _n; i++)
        _fromLit[i] + (_toLit[i] - _fromLit[i]) * q,
    ];
  }

  // ── Transitions ────────────────────────────────────────────────────

  void _go(int? sel, int focus) {
    final fromVB = _liveVB();
    var fromRot = _liveRot();
    var toRot = _rotFor(sel);
    // Shortest way round the wheel, then fold both ends back toward zero by
    // whole turns so repeated swipes can't drift the rotation.
    while (toRot - fromRot > 180) {
      toRot -= 360;
    }
    while (toRot - fromRot < -180) {
      toRot += 360;
    }
    final turns = (fromRot / 360).round();
    if (turns != 0) {
      fromRot -= turns * 360;
      toRot -= turns * 360;
    }

    final toVB = _target(sel);
    final moves =
        List.generate(4, (i) => (fromVB[i] - toVB[i]).abs()).any((d) => d > 0.5);
    final spins = (toRot - fromRot).abs() > 0.5;

    _fromLit = _liveLit();
    // In the wheel every family is lit; focused, only the one in focus is.
    _toLit = [
      for (var i = 0; i < _n; i++) (sel == null || sel == i) ? 1.0 : 0.0,
    ];
    _fromVB = fromVB;
    _toVB = toVB;
    _fromRot = fromRot;
    _toRot = toRot;

    final durationMs = moves ? _moveMs : _spinMs;
    _move.duration = Duration(milliseconds: durationMs);
    _move.forward(from: 0);

    // Labels come in on the bounce-back: the overshoot peaks around 62% of
    // the duration, so names materialise while the wheel settles into its
    // detent — not mid-flight, not a beat after everything stopped. Only
    // when the view itself changes, though: refocusing another node of the
    // focused tree moves no camera, and the branch names must hold steady
    // rather than blink out and back.
    if (moves || spins || sel != _sel) {
      final delayMs = (moves || spins) ? (durationMs * 0.62).round() : 200;
      _labelTimer?.cancel();
      _labels.value = 0;
      _labelTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) _labels.forward(from: 0);
      });
    }

    if (sel == null) {
      _halo.stop();
      _halo.value = 0;
      _sector.forward();
    } else {
      _halo.repeat();
      _sector.reverse();
    }

    setState(() {
      _sel = sel;
      _focus = focus;
    });
    widget.onChanged?.call(sel, focus);
  }

  // ── Gestures ───────────────────────────────────────────────────────
  // One scale recognizer covers both: single-finger drags are the swipes,
  // and a two-finger pinch-out of the focused tree pulls back to the wheel.

  bool _pinchHandled = false;

  void _onScaleStart(ScaleStartDetails d) {
    _dragStart = d.localFocalPoint;
    _dragLast = d.localFocalPoint;
    _pinchHandled = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    _dragLast = d.localFocalPoint;
    if (!_pinchHandled && d.pointerCount >= 2 && d.scale < 0.8 && _sel != null) {
      _pinchHandled = true;
      _go(null, 0);
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final start = _dragStart, end = _dragLast;
    _dragStart = null;
    _dragLast = null;
    if (_pinchHandled || start == null || end == null) return;
    final delta = end - start;
    if (delta.distance < 8) return;
    final sel = _sel;
    if (sel == null) return;
    // The system-style back swipe: a rightward drag from the left edge
    // pulls out of the tree instead of walking the selector.
    if (start.dx < 30 && delta.dx > 50 && delta.dx.abs() > delta.dy.abs()) {
      _go(null, 0);
      return;
    }
    if (delta.dy.abs() >= delta.dx.abs()) {
      // Across the tree: the next family comes up from below as you drag up.
      final i = (sel + (delta.dy > 0 ? -1 : 1) + _n) % _n;
      _go(i, widget.families[i].activeFlatIndex);
    } else if (widget.isPicker) {
      // Nothing to walk: a picker chooses destinations, not steps.
    } else {
      final count = widget.families[sel].flat.length;
      final next =
          (_focus + (delta.dx > 0 ? -1 : 1)).clamp(0, count - 1);
      if (next != _focus) _go(sel, next);
    }
  }

  void _onTapUp(TapUpDetails details, double width) {
    final vb = _liveVB();
    final scale = width / vb[2];
    final ux = vb[0] + details.localPosition.dx / scale;
    final uy = vb[1] + details.localPosition.dy / scale;

    final dx = ux - _hx, dy = uy - _hy;
    final radius = math.sqrt(dx * dx + dy * dy);
    if (radius > _rim) {
      // Background: pull back out to the wheel.
      if (_sel != null) _go(null, 0);
      return;
    }

    // Which wedge, in the wheel's unrotated space.
    final thetaDeg =
        math.atan2(dy, dx) * 180 / math.pi - _liveRot();
    var idx = ((thetaDeg + 90) / _stepDeg).round() % _n;
    if (idx < 0) idx += _n;

    final sel = _sel;
    final rot = _rotFor(sel ?? idx) * math.pi / 180;

    // Picking a goal comes first: a tap on a tip's marker toggles it rather
    // than doing anything to the camera.
    if (widget.isPicker && sel != null) {
      for (final tip in _tree(sel).tips) {
        if (!widget.pickableGoals.contains(tip.id)) continue;
        final p = _rotate(tip.x, tip.y, rot);
        if ((p - Offset(ux, uy)).distance < 16) {
          widget.onToggleGoal!(tip.id);
          return;
        }
      }
    }

    if (idx != sel) {
      _go(idx, widget.families[idx].activeFlatIndex);
      return;
    }
    if (sel == null) return;
    if (widget.isPicker) return;

    // A tap on the focused tree moves the selector to the nearest node — the
    // tree stays put and the card below follows.
    _GeoNode? best;
    var bestDistance = double.infinity;
    for (final node in _tree(sel).nodes) {
      final p = _rotate(node.x, node.y, rot);
      final d = (p - Offset(ux, uy)).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = node;
      }
    }
    if (best != null && bestDistance < 42 && best.flat != _focus) {
      _go(sel, best.flat);
    }
  }

  static Offset _rotate(double x, double y, double rad) {
    final dx = x - _hx, dy = y - _hy;
    final c = math.cos(rad), s = math.sin(rad);
    return Offset(_hx + dx * c - dy * s, _hy + dx * s + dy * c);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.families.length < 2) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        // The band is as wide as it is given, and its height follows the
        // camera. Where that would not fit — a short screen, a landscape
        // window — the wheel narrows until the OPENING framing does, so the
        // width stays put while the camera animates.
        var width = constraints.maxWidth;
        if (constraints.hasBoundedHeight) {
          final capped =
              constraints.maxHeight * _w / SkillWheel.overviewBandHeight;
          if (capped < width) width = capped;
        }
        return AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final vb = _liveVB();
            final height = vb[3] * width / _w;
            // heightFactor 1, not a plain Center: the band takes exactly the
            // height it paints, so the camera's own framing sets the gap
            // below the header — a Center would hold the full height it was
            // allowed and pad the short focused band top and bottom.
            //
            // The detector sits inside the alignment, not around it: taps are
            // read in the painted box's own coordinates, so a wheel narrower
            // than the space it was given still maps a tap to the right node.
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _onTapUp(d, width),
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: ClipRect(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: CustomPaint(
                      painter: _WheelPainter(
                        state: this,
                        repaint:
                            Listenable.merge([_move, _labels, _halo, _sector]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GeoNode {
  final double x, y, r;
  final WheelNodeState state;
  final int flat;

  const _GeoNode({
    required this.x,
    required this.y,
    required this.r,
    required this.state,
    required this.flat,
  });
}

class _GeoLink {
  final _GeoNode p, q;
  final bool faint;

  const _GeoLink({required this.p, required this.q, required this.faint});
}

class _GeoTip {
  final String name;
  final double x, y, ang;

  /// Stable id for the branch this tip ends — `<categoryId>:<branchId>`, or
  /// `<categoryId>:*` for a family with no branches. Goal picking keys on it.
  final String id;

  /// The tip's own steps, fork excluded. Prefixed by the trunk it gives the
  /// whole route from the start of the tree to this goal.
  final List<_GeoNode> chain;

  const _GeoTip({
    required this.name,
    required this.x,
    required this.y,
    required this.ang,
    required this.id,
    required this.chain,
  });
}

class _TreeGeo {
  final List<_GeoNode> nodes;
  final List<_GeoLink> links;
  final List<_GeoTip> tips;
  final _GeoNode fork;
  final List<_GeoNode> trunk;

  const _TreeGeo({
    required this.nodes,
    required this.links,
    required this.tips,
    required this.fork,
    required this.trunk,
  });
}

class _WheelPainter extends CustomPainter {
  final _SkillWheelState state;

  _WheelPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  static const _hx = _SkillWheelState._hx;
  static const _hy = _SkillWheelState._hy;

  // Locked steps keep the default node size — only the active one is larger.
  // A picker marks destinations, not the step being trained, so there it
  // draws like any other step still to clear.
  double _radiusOf(WheelNodeState st) =>
      st == WheelNodeState.active && !state.widget.isPicker ? 4.9 : 3.5;

  Color _fillOf(WheelNodeState st) {
    if (state.widget.isPicker) {
      // A picker marks destinations, not progress — only cleared steps read
      // green, everything still ahead is neutral.
      return st.isCleared ? _SkillWheelState._green : _SkillWheelState._lock;
    }
    return switch (st) {
      WheelNodeState.active => _SkillWheelState._accent,
      WheelNodeState.mastered || WheelNodeState.skipped =>
        _SkillWheelState._green,
      WheelNodeState.available => AppColors.textPrimary,
      WheelNodeState.locked => _SkillWheelState._lock,
    };
  }

  /// Whether a link reads as travelled. A picker draws no working step, so
  /// the lit path stops at the last step actually cleared. An available step
  /// is reachable but not travelled — links into it stay unlit.
  bool _lit(_GeoLink l) {
    bool travelled(WheelNodeState st) => state.widget.isPicker
        ? st.isCleared
        : st.isCleared || st == WheelNodeState.active;
    return travelled(l.p.state) && travelled(l.q.state);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final vb = state._liveVB();
    final rot = state._liveRot() * math.pi / 180;
    final lit = state._liveLit();
    final labelFade = Curves.easeOut.transform(state._labels.value);

    final scale = size.width / vb[2];
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-vb[0], -vb[1]);

    // ── Pie sectors: hairline spokes, rim ring, names curved on the arc.
    // Static (the trees rotate underneath) and faded out while focused.
    final sectorFade = Curves.ease.transform(state._sector.value);
    if (sectorFade > 0.01) {
      _paintSectors(canvas, sectorFade);
    }

    // ── Trees, rotated about the hub ──
    canvas.save();
    canvas.translate(_hx, _hy);
    canvas.rotate(rot);
    canvas.translate(-_hx, -_hy);

    for (var i = 0; i < state._n; i++) {
      final geo = state._tree(i);
      final v = lit[i];

      for (final link in geo.links) {
        final Color litColor;
        final double litWidth;
        if (link.faint) {
          litColor = _SkillWheelState._linkFaint;
          litWidth = 1;
        } else if (_lit(link)) {
          litColor = _SkillWheelState._linkOn;
          litWidth = 2;
        } else {
          litColor = _SkillWheelState._linkDim;
          litWidth = 1.2;
        }
        canvas.drawLine(
          Offset(link.p.x, link.p.y),
          Offset(link.q.x, link.q.y),
          Paint()
            ..color = Color.lerp(_SkillWheelState._mutedLink, litColor, v)!
            ..strokeWidth = 1.4 + (litWidth - 1.4) * v
            ..strokeCap = StrokeCap.round,
        );
      }

      for (final node in geo.nodes) {
        canvas.drawCircle(
          Offset(node.x, node.y),
          _radiusOf(node.state),
          Paint()
            ..color = Color.lerp(
              _SkillWheelState._mutedNode,
              _fillOf(node.state),
              v,
            )!,
        );
      }
    }
    canvas.restore();

    // ── Overlay, unrotated user space, laid out for the destination camera ──
    final camTarget = state._target(state._sel);
    final k = camTarget[2] / _SkillWheelState._w;
    final destRot = state._rotFor(state._sel) * math.pi / 180;

    if (state._sel == null) {
      _paintWheelOverlay(canvas, camTarget, k, destRot, labelFade);
    } else {
      _paintFocusedOverlay(canvas, k, destRot, labelFade);
    }

    canvas.restore();
  }

  /// The pie-sector layer: hairline spokes between sectors, the rim ring,
  /// and each family's name curved along the arc just inside the rim.
  /// Bottom sectors get a reversed arc at a slightly larger radius so the
  /// glyphs stay upright at the same optical line.
  void _paintSectors(Canvas canvas, double opacity) {
    const rim = _SkillWheelState._rim;
    final stepDeg = state._stepDeg;
    // Sector text is sized for the overview camera, where it lives.
    const k = 2 * (rim + 10) / _SkillWheelState._openH;

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055 * opacity)
      ..strokeWidth = 1;
    for (var i = 0; i < state._n; i++) {
      final edge = (state._angDeg(i) - stepDeg / 2) * math.pi / 180;
      canvas.drawLine(
        Offset(_hx + 26 * math.cos(edge), _hy + 26 * math.sin(edge)),
        Offset(_hx + rim * math.cos(edge), _hy + rim * math.sin(edge)),
        spokePaint,
      );
    }
    canvas.drawCircle(
      const Offset(_hx, _hy),
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.055 * opacity),
    );
    // The "training now" hint lives in the curved names: active trees read
    // in blue, locked trees dim behind their padlock. (Rim arcs were tried
    // and clipped at the screen edge — the labels carry it instead.)
    for (var i = 0; i < state._n; i++) {
      final categoryId = state.widget.families[i].categoryId;
      final active = state.widget.activeCategoryIds.contains(categoryId);
      final locked = !active &&
          state.widget.lockedCategoryIds.contains(categoryId);
      if (locked) {
        _paintPadlock(canvas, state._angRad(i), opacity);
      }
      _paintArcLabel(
        canvas,
        state.widget.families[i].title.toUpperCase(),
        state._angDeg(i),
        k,
        opacity,
        color: active
            ? const Color(0xFF8FB4F5)
            : locked
                ? const Color(0xFF4A4B52)
                : const Color(0xFF66676E),
      );
    }
  }

  /// The padlock badge on a locked tree's spoke, inside the rim and clear
  /// of the curved names: the tree waits on a prerequisite in another tree.
  void _paintPadlock(Canvas canvas, double angleRad, double opacity) {
    const r = _SkillWheelState._rim - 34;
    final lx = _hx + r * math.cos(angleRad);
    final ly = _hy + r * math.sin(angleRad);

    canvas.drawCircle(
      Offset(lx, ly),
      10.5,
      Paint()..color = _SkillWheelState._cardBg.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      Offset(lx, ly),
      10.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22 * opacity),
    );
    final metal = const Color(0xFF8A8B93).withValues(alpha: opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lx - 4, ly - 1, 8, 6.6),
        const Radius.circular(1.8),
      ),
      Paint()..color = metal,
    );
    final shackle = Path()
      ..moveTo(lx - 2.5, ly - 1)
      ..lineTo(lx - 2.5, ly - 2.8)
      ..arcToPoint(
        Offset(lx + 2.5, ly - 2.8),
        radius: const Radius.circular(2.5),
      )
      ..lineTo(lx + 2.5, ly - 1);
    canvas.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = metal,
    );
  }

  /// A goal marker on a branch tip: dashed and hollow while the goal is
  /// still on offer, solid amber under a breathing halo once it is chosen.
  void _paintGoalMarker(
    Canvas canvas,
    Offset at, {
    required bool picked,
    required double fade,
    required double haloT,
  }) {
    if (!picked) {
      canvas.drawCircle(
        at,
        6.5,
        Paint()..color = _SkillWheelState._cardBg.withValues(alpha: fade),
      );
      // Dashes, drawn as short arcs: 12 marks around the ring reads as the
      // design's 2.4/2.2 dash pattern at this radius.
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = AppColors.amber.withValues(alpha: 0.55 * fade);
      const marks = 12;
      const sweep = math.pi * 2 / marks;
      for (var i = 0; i < marks; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: at, radius: 6.5),
          i * sweep,
          sweep * 0.5,
          false,
          paint,
        );
      }
      return;
    }

    canvas.drawCircle(
      at,
      5.5,
      Paint()..color = AppColors.amber.withValues(alpha: fade),
    );
    final pulse =
        0.45 + (0.08 - 0.45) * (0.5 - 0.5 * math.cos(2 * math.pi * haloT));
    canvas.drawCircle(
      at,
      10.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = AppColors.amber.withValues(alpha: (fade * pulse).clamp(0, 1)),
    );
  }

  /// One name on an arc: glyphs placed one by one along the circle, each
  /// rotated to its local tangent.
  void _paintArcLabel(
    Canvas canvas,
    String text,
    double midDeg,
    double k,
    double opacity, {
    Color color = const Color(0xFF66676E),
  }) {
    final reversed = math.sin(midDeg * math.pi / 180) > 0.3;
    final r = reversed ? 245.0 : 235.0;

    TextStyle style(double fontSize) => GoogleFonts.robotoMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: fontSize * 0.13,
          color: color.withValues(alpha: opacity),
        );

    List<TextPainter> layout(double fontSize) => [
          for (final ch in text.characters)
            TextPainter(
              text: TextSpan(text: ch, style: style(fontSize)),
              textDirection: TextDirection.ltr,
            )..layout(),
        ];

    var fontSize = 10.5 * k;
    var glyphs = layout(fontSize);
    var total = glyphs.fold(0.0, (t, g) => t + g.width);
    // A long name (Handstand Pushups) must stay inside its sector's arc.
    final maxArc = r * (state._stepDeg - 5) * math.pi / 180;
    if (total > maxArc) {
      fontSize *= maxArc / total;
      glyphs = layout(fontSize);
      total = glyphs.fold(0.0, (t, g) => t + g.width);
    }

    final mid = midDeg * math.pi / 180;
    var along = -total / 2;
    for (final glyph in glyphs) {
      final center = along + glyph.width / 2;
      along += glyph.width;
      final theta = mid + (reversed ? -center / r : center / r);
      final phi = theta + (reversed ? -math.pi / 2 : math.pi / 2);
      final baseline =
          glyph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      canvas.save();
      canvas.translate(
        _hx + r * math.cos(theta),
        _hy + r * math.sin(theta),
      );
      canvas.rotate(phi);
      glyph.paint(canvas, Offset(-glyph.width / 2, -baseline));
      canvas.restore();
    }
  }

  /// The small hub disc, fading in with the wheel.
  void _paintWheelOverlay(
    Canvas canvas,
    List<double> vb,
    double k,
    double rot,
    double fade,
  ) {
    if (fade <= 0) return;

    // Goals chosen inside a tree stay visible from the wheel: an amber
    // marker sits on each chosen tip.
    if (state.widget.isPicker) {
      for (var i = 0; i < state._n; i++) {
        for (final tip in state._tree(i).tips) {
          if (!state.widget.pickedGoals.contains(tip.id)) continue;
          canvas.drawCircle(
            Offset(tip.x, tip.y),
            5,
            Paint()..color = AppColors.amber.withValues(alpha: fade),
          );
          canvas.drawCircle(
            Offset(tip.x, tip.y),
            9.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = AppColors.amber.withValues(alpha: 0.5 * fade),
          );
        }
      }
    }

    canvas.drawCircle(
      const Offset(_hx, _hy),
      11,
      Paint()..color = _SkillWheelState._cardBg.withValues(alpha: fade),
    );
    canvas.drawCircle(
      const Offset(_hx, _hy),
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.16 * fade),
    );
    canvas.drawCircle(
      const Offset(_hx, _hy),
      3.2,
      Paint()..color = const Color(0xFF4A4B52).withValues(alpha: fade),
    );
  }

  /// Branch names in one left-aligned column with leader lines back to each
  /// tip, and the pulsing selector ring on the focused node.
  void _paintFocusedOverlay(
    Canvas canvas,
    double k,
    double rot,
    double fade,
  ) {
    final sel = state._sel!;
    final geo = state._tree(sel);
    final picker = state.widget.isPicker;

    // Under everything else: the amber route from the start of the tree to
    // each goal chosen in it.
    if (picker && fade > 0) {
      for (final tip in geo.tips) {
        if (!state.widget.pickedGoals.contains(tip.id)) continue;
        final route = [...geo.trunk, ...tip.chain];
        if (route.length < 2) continue;
        final path = Path();
        for (var i = 0; i < route.length; i++) {
          final p = _SkillWheelState._rotate(route[i].x, route[i].y, rot);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = AppColors.amber.withValues(alpha: 0.55 * fade),
        );
      }
    }

    if (fade > 0) {
      // Tips rotated into the focused (horizontal) orientation.
      final items = [
        for (final tip in geo.tips)
          _TipItem(
            name: tip.name,
            tip: _SkillWheelState._rotate(tip.x, tip.y, rot),
            ang: tip.ang + rot,
            id: tip.id,
          ),
      ];
      for (final item in items) {
        item.labelX = item.tip.dx + 20 * math.cos(item.ang);
        item.labelY = item.tip.dy + 20 * math.sin(item.ang);
        item.labelY0 = item.labelY;
      }
      // One column, to the RIGHT of every tip — a sub-fan's tips sit far too
      // close together to label in place, and a column that backed up to fit
      // a long name would run over the tree. The column is pinned clear of
      // the deepest node instead, and the names wrap into the space that
      // leaves before the camera's right edge.
      final rightmostTip = items.map((o) => o.tip.dx).reduce(math.max);
      final colX = math.max(
        items.map((o) => o.labelX).reduce(math.max),
        rightmostTip + 12 * k,
      );
      final camTarget = state._target(state._sel);
      final rightEdge = camTarget[0] + camTarget[2] - 6 * k;
      final avail = math.max(rightEdge - colX, 40 * k);

      for (final item in items) {
        item.labelX = colX;
        // A chosen goal says so in its name as well as its route.
        final picked = state.widget.pickedGoals.contains(item.id);
        TextStyle style(double fontSize) => TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.12 * k,
              height: 1.15,
              color: (picked ? AppColors.amber : const Color(0xFF8A8B93))
                  .withValues(alpha: fade),
            );
        var fontSize = 12.5 * k;
        // Flutter breaks a word that cannot fit rather than overflowing, so
        // fitting is measured on the longest WORD: a name whose widest word
        // overruns the column shrinks slightly instead of snapping in half
        // ("Handstan / d Pushups").
        var longestWord = 0.0;
        for (final word in item.name.split(' ')) {
          final wp = TextPainter(
            text: TextSpan(text: word, style: style(fontSize)),
            textDirection: TextDirection.ltr,
          )..layout();
          longestWord = math.max(longestWord, wp.width);
        }
        if (longestWord > avail) {
          fontSize *= math.max(avail / longestWord, 0.7);
        }
        item.painter = TextPainter(
          text: TextSpan(text: item.name, style: style(fontSize)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: avail);
      }

      items.sort((a, b) => a.labelY.compareTo(b.labelY));
      for (var i = 1; i < items.length; i++) {
        // Labels are centred on their line, so two neighbours need half of
        // each height between them — a wrapped name takes more room.
        final gap = math.max(
          17 * k,
          (items[i - 1].painter!.height + items[i].painter!.height) / 2 +
              4 * k,
        );
        if (items[i].labelY - items[i - 1].labelY < gap) {
          items[i].labelY = items[i - 1].labelY + gap;
        }
      }
      final mean0 =
          items.fold(0.0, (t, o) => t + o.labelY0) / items.length;
      final mean1 =
          items.fold(0.0, (t, o) => t + o.labelY) / items.length;
      for (final item in items) {
        item.labelY += mean0 - mean1;
      }

      for (final item in items) {
        // Every pickable tip carries its marker: a dashed ring waiting to be
        // chosen, a filled dot with a breathing halo once it is.
        if (picker && state.widget.pickableGoals.contains(item.id)) {
          _paintGoalMarker(
            canvas,
            item.tip,
            picked: state.widget.pickedGoals.contains(item.id),
            fade: fade,
            haloT: state._halo.value,
          );
        }
        final painter = item.painter!;
        painter.paint(
          canvas,
          Offset(item.labelX, item.labelY + 2 * k - painter.height / 2),
        );
      }
    }

    // A picker has no working step to point at, so it draws no selector.
    if (picker) return;

    // Selector ring, fading in on the same beat as the labels, then pulsing.
    final here = geo.nodes.firstWhere(
      (n) => n.flat == state._focus,
      orElse: () => geo.nodes.first,
    );
    final p = _SkillWheelState._rotate(here.x, here.y, rot);
    // Halo: opacity breathes 0.45 → 0.08 → 0.45 over the 2.6s cycle.
    final haloT = state._halo.value;
    final pulse =
        0.45 + (0.08 - 0.45) * (0.5 - 0.5 * math.cos(2 * math.pi * haloT));
    canvas.drawCircle(
      p,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _SkillWheelState._accent
            .withValues(alpha: (fade * pulse).clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => true;
}

class _TipItem {
  final String name;
  final Offset tip;
  final double ang;
  final String id;
  double labelX = 0, labelY = 0, labelY0 = 0;
  TextPainter? painter;

  _TipItem({
    required this.name,
    required this.tip,
    required this.ang,
    required this.id,
  });
}
