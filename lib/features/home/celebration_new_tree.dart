import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import 'celebration_widgets.dart';

/// The post-workout step for a hand-off: mastering the last shared step of
/// one tree moved the slot to a *different* tree (dips → handstand push-up).
/// Same one-screen beat structure as the fork step, on the Progress tab's
/// wheel: one tree visible at a time, the next one waiting on the spoke
/// below. Beats: bar fills → the step pops green and the old tree's branch
/// firsts open → the wheel spins to the new tree, which sits locked → the
/// padlock pops off → its first step lights and the title swaps → helper.

class NewTreeUnlockData {
  final Exercise mastered;
  final Exercise newExercise;
  final int masterySets;
  final int masteryValue;
  final int startSets;
  final int startValue;

  /// The tree that handed over: its title, the trunk up to the mastered
  /// step, and the branches it would have forked into.
  final String fromTitle;
  final List<String> fromFoundationNames;
  final List<String> fromBranchLabels;

  /// The tree that took the slot: its title and opening steps, with the
  /// index of the one that starts training.
  final String toTitle;
  final List<String> toNodeNames;
  final int toActiveIndex;

  /// The slot that moved, in the user's words — "vertical push".
  final String slotLabel;

  const NewTreeUnlockData({
    required this.mastered,
    required this.newExercise,
    required this.masterySets,
    required this.masteryValue,
    required this.startSets,
    required this.startValue,
    required this.fromTitle,
    required this.fromFoundationNames,
    required this.fromBranchLabels,
    required this.toTitle,
    required this.toNodeNames,
    required this.toActiveIndex,
    required this.slotLabel,
  });
}

/// The hand-off behind an activation, or null when the new exercise is in
/// the mastered one's own tree — a fork or an ordinary next step.
NewTreeUnlockData? resolveNewTreeUnlock({
  required Exercise mastered,
  required Exercise newExercise,
  required int masterySets,
  required int masteryValue,
  required int startSets,
  required int startValue,
}) {
  if (mastered.skillCategoryId.isEmpty ||
      newExercise.skillCategoryId.isEmpty ||
      mastered.skillCategoryId == newExercise.skillCategoryId) {
    return null;
  }
  final from = SkillCategoryCatalog.findById(mastered.skillCategoryId);
  final to = SkillCategoryCatalog.findById(newExercise.skillCategoryId);
  if (from == null || to == null) return null;

  String nameOf(String id) => ExerciseCatalog.findById(id)?.name ?? id;

  // The trunk: any path through the mastered step, up to it.
  List<String> foundation = const [];
  final branchByNext = <String, String>{};
  for (final entry in from.trainingPaths.entries) {
    final path = entry.value;
    final index = path.indexOf(mastered.id);
    if (index < 0) continue;
    if (foundation.isEmpty) foundation = path.sublist(0, index + 1);
    if (index + 1 < path.length &&
        !SkillCategory.isFoundationBranchId(entry.key)) {
      branchByNext.putIfAbsent(
        path[index + 1],
        () => _branchLabel(from, entry.key),
      );
    }
  }
  if (foundation.isEmpty) return null;

  // The new tree's opening: its first steps, and where the new exercise
  // sits among them — normally the very first.
  List<String> opening = const [];
  var activeIndex = 0;
  for (final path in to.trainingPaths.values) {
    final index = path.indexOf(newExercise.id);
    if (index < 0) continue;
    final start = math.max(0, math.min(index, path.length - 3));
    opening = path.sublist(start, math.min(path.length, start + 3));
    activeIndex = index - start;
    break;
  }
  if (opening.isEmpty) return null;

  return NewTreeUnlockData(
    mastered: mastered,
    newExercise: newExercise,
    masterySets: masterySets,
    masteryValue: masteryValue,
    startSets: startSets,
    startValue: startValue,
    fromTitle: from.title,
    fromFoundationNames: [for (final id in foundation) nameOf(id)],
    fromBranchLabels: branchByNext.values.take(3).toList(),
    toTitle: to.title,
    toNodeNames: [for (final id in opening) nameOf(id)],
    toActiveIndex: activeIndex,
    slotLabel: TrainingTrackX(
      TrainingProgramService.trainingTrackForPattern(to.track),
    ).label.toLowerCase(),
  );
}

String _branchLabel(SkillCategory category, String branchId) {
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

class NewTreeUnlockContent extends StatefulWidget {
  final NewTreeUnlockData data;

  const NewTreeUnlockContent({super.key, required this.data});

  @override
  State<NewTreeUnlockContent> createState() => _NewTreeUnlockContentState();
}

class _NewTreeUnlockContentState extends State<NewTreeUnlockContent> {
  /// 0 bar filling · 1 step cleared, the old tree's branch firsts open ·
  /// 2 the wheel spins to the new tree · 3 padlock off · 4 first step
  /// lights, title swaps · 5 helper.
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
    at(4000, () => _phase = 2);
    at(5200, () => _phase = 3);
    at(6500, () {
      _phase = 4;
      _fill = false;
    });
    at(7700, () => _phase = 5);
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
    final started = _phase >= 4;
    final done = _phase >= 5;
    final title = started
        ? data.newExercise.name
        : _phase >= 2
            ? data.toTitle
            : data.mastered.name;
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
        : _phase >= 3
            ? const CelebrationTag(
                key: ValueKey('tree'),
                color: AppColors.amber,
                label: 'New skill tree unlocked',
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
              // The bar steps back while the wheel turns: it is about the
              // step just cleared, and the screen is about the new tree.
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _phase == 2 || _phase == 3 ? 0.35 : 1,
                child: CelebrationTargetBar(
                  label: started ? 'STARTING TARGET' : 'PREREQUISITE',
                  target: target,
                  targetColor:
                      started ? AppColors.textSecondary : AppColors.green,
                  fill: _fill,
                ),
              ),
            ),
            const SizedBox(height: 12),
            RiseIn(
              delay: const Duration(milliseconds: 140),
              child: NewTreeMap(data: data, phase: _phase),
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
                  constraints: const BoxConstraints(maxWidth: 300),
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
                        TextSpan(
                          text: '${data.toTitle} now takes your '
                              '${data.slotLabel} slot. Prefer to keep '
                              'training ${data.fromTitle.toLowerCase()}? '
                              'Change it on the ',
                        ),
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

// ── Wheel ─────────────────────────────────────────────────────────────

/// The Progress wheel, one spoke at a time. The old tree sits at 0°, the
/// new one waits on the next spoke at +45°, hidden. Once the step clears,
/// the wheel spins −45°: the old tree swings up and out, the new one swings
/// in from below still locked, then plays its unlock.
class NewTreeMap extends StatefulWidget {
  final NewTreeUnlockData data;
  final int phase;

  const NewTreeMap({super.key, required this.data, required this.phase});

  static const double width = 342;
  static const double height = 184;

  @override
  State<NewTreeMap> createState() => _NewTreeMapState();
}

class _NewTreeMapState extends State<NewTreeMap> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  /// One run per beat that changes the picture: the clear, the padlock
  /// coming off, the first step lighting.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );

  @override
  void didUpdateWidget(NewTreeMap old) {
    super.didUpdateWidget(old);
    if (old.phase == widget.phase) return;
    switch (widget.phase) {
      case 2:
        _spin.forward(from: 0);
      case 1 || 3 || 4:
        _beat.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: NewTreeMap.width,
        height: NewTreeMap.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _spin, _beat]),
          builder: (context, _) => CustomPaint(
            painter: _NewTreeMapPainter(
              data: widget.data,
              phase: widget.phase,
              pulse: Curves.easeInOut.transform(_pulse.value),
              spin: const Cubic(0.32, 0.72, 0, 1).transform(_spin.value),
              beat: _beat.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewTreeMapPainter extends CustomPainter {
  final NewTreeUnlockData data;
  final int phase;
  final double pulse;
  final double spin;
  final double beat;

  _NewTreeMapPainter({
    required this.data,
    required this.phase,
    required this.pulse,
    required this.spin,
    required this.beat,
  });

  static const _hubX = 30.0;
  static const _r0 = 20.0;
  static const _step = 45.0;
  static const _maxPitch = 44.0;
  static const _minPitch = 26.0;
  static const _lock = Color(0xFF3A3A40);
  static final _dim = Colors.white.withValues(alpha: 0.14);
  static final _trunkOn = AppColors.green.withValues(alpha: 0.5);
  static final _routeOn = AppColors.accentPrimary.withValues(alpha: 0.45);

  bool get _cleared => phase >= 1;
  bool get _unlocked => phase >= 3;
  bool get _lit => phase >= 4;

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

  static Color _fade(Color color, double alpha) =>
      color.withValues(alpha: color.a * alpha);

  @override
  void paint(Canvas canvas, Size size) {
    final hub = Offset(_hubX, size.height / 2);
    final rotation = -_step * spin;
    final oldAlpha = (1 - spin / 0.55).clamp(0.0, 1.0);
    final newAlpha = ((spin - 0.25) / 0.6).clamp(0.0, 1.0);
    final beatIn = Curves.easeOut.transform(beat.clamp(0, 1));

    final fromLabels = [
      for (final label in data.fromBranchLabels)
        _text(label,
            size: 13, color: AppColors.textSecondary, letterSpacing: -0.13),
    ];
    final toLabel = _text(data.toTitle,
        size: 13,
        color: Color.lerp(
            AppColors.textSecondary, AppColors.textPrimary, _lit ? beatIn : 0)!,
        letterSpacing: -0.13);
    final widestLabel = [
      for (final label in fromLabels) label.width,
      toLabel.width,
    ].fold<double>(0, math.max);
    final trunkCount = data.fromFoundationNames.length;
    final steps = math.max(
      (trunkCount - 1) + (data.fromBranchLabels.isEmpty ? 0 : 2),
      data.toNodeNames.length - 1,
    );
    final room = size.width - _hubX - _r0 - widestLabel - 11 - 4;
    final pitch = steps <= 0
        ? _maxPitch
        : (room / steps).clamp(_minPitch, _maxPitch).toDouble();

    Offset at(double radius, double degrees) {
      final rad = degrees * math.pi / 180;
      return hub + Offset(radius * math.cos(rad), radius * math.sin(rad));
    }

    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Labels stay upright while the wheel turns.
    void upright(Offset anchor, void Function() draw) {
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(-rotation * math.pi / 180);
      canvas.translate(-anchor.dx, -anchor.dy);
      draw();
      canvas.restore();
    }

    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    canvas.rotate(rotation * math.pi / 180);
    canvas.translate(-hub.dx, -hub.dy);

    // ── The old tree, on the 0° spoke ──
    if (oldAlpha > 0) {
      final trunk = [
        for (var k = 0; k < trunkCount; k++) at(_r0 + k * pitch, 0),
      ];
      final fork = trunk.last;
      final forkRadius = _r0 + (trunkCount - 1) * pitch;
      for (var k = 0; k < trunk.length; k++) {
        final from = k == 0 ? hub + const Offset(11, 0) : trunk[k - 1];
        canvas.drawLine(
            from, trunk[k], line..color = _fade(_trunkOn, oldAlpha));
      }
      final offsets = switch (data.fromBranchLabels.length) {
        0 => const <double>[],
        1 => const [0.0],
        2 => const [-16.0, 16.0],
        _ => const [-20.0, 0.0, 20.0],
      };
      for (var j = 0; j < offsets.length; j++) {
        final angle = offsets[j];
        final n1 = at(forkRadius + pitch, angle);
        final n2 = at(forkRadius + 2 * pitch, angle);
        canvas.drawLine(fork, n1, line..color = _fade(_dim, 0.6 * oldAlpha));
        canvas.drawLine(n1, n2, line..color = _fade(_dim, oldAlpha));
        final openT = _cleared ? (phase == 1 ? beatIn : 1.0) : 0.0;
        canvas.drawCircle(
          n1,
          4.6 + 0.9 * openT,
          Paint()
            ..color = _fade(
                Color.lerp(_lock, AppColors.textPrimary, openT)!, oldAlpha),
        );
        canvas.drawCircle(n2, 4.6, Paint()..color = _fade(_lock, oldAlpha));
        upright(n2, () {
          final label = fromLabels[j];
          canvas.saveLayer(
              null, Paint()..color = Colors.white.withValues(alpha: oldAlpha));
          label.paint(canvas, n2 + Offset(11, -label.height / 2));
          canvas.restore();
        });
      }
      for (var k = 0; k < trunk.length; k++) {
        final last = k == trunk.length - 1;
        final node = trunk[k];
        if (last && !_cleared) {
          canvas.drawCircle(
            node,
            14 * (1 + 0.25 * pulse),
            Paint()
              ..color = AppColors.accentPrimary
                  .withValues(alpha: (0.55 - 0.4 * pulse) * oldAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        var radius = last ? 7.5 : 6.0;
        var color =
            last && !_cleared ? AppColors.accentPrimary : AppColors.green;
        if (last && _cleared && phase == 1) {
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
        canvas.drawCircle(
            node, radius, Paint()..color = _fade(color, oldAlpha));
      }
      final caption = _text(
        data.fromTitle.toUpperCase(),
        size: 10,
        color: _fade(
            _cleared ? AppColors.green : AppColors.textSecondary, oldAlpha),
        letterSpacing: 1.4,
      );
      final anchor = Offset(trunk.first.dx - 6, hub.dy - 22);
      upright(anchor, () => caption.paint(canvas, anchor - const Offset(0, 8)));
    }

    // ── The new tree, on the +45° spoke, locked until it swings in ──
    if (newAlpha > 0) {
      final nodes = [
        for (var k = 0; k < data.toNodeNames.length; k++)
          at(_r0 + k * pitch, _step),
      ];
      final active = data.toActiveIndex;
      final litT = _lit ? beatIn : 0.0;
      for (var k = 0; k < nodes.length; k++) {
        final from = k == 0 ? at(11, _step) : nodes[k - 1];
        final on = k == active && _lit;
        canvas.drawLine(
          from,
          nodes[k],
          line
            ..color =
                _fade(Color.lerp(_dim, _routeOn, on ? litT : 0)!, newAlpha),
        );
      }
      for (var k = 0; k < nodes.length; k++) {
        final isActive = k == active;
        final openT = isActive && _unlocked ? (phase == 3 ? beatIn : 1.0) : 0.0;
        final activeT = isActive ? litT : 0.0;
        var fill = Color.lerp(_lock, AppColors.textPrimary, openT)!;
        fill = Color.lerp(fill, AppColors.accentPrimary, activeT)!;
        var radius = 4.6 + 0.9 * openT + 1.0 * activeT;
        if (isActive && _unlocked && phase == 3) {
          final t = beat.clamp(0.0, 1.0);
          final pop = t < 0.45
              ? 1 + 0.6 * Curves.easeOut.transform(t / 0.45)
              : 1.6 - 0.6 * Curves.easeIn.transform((t - 0.45) / 0.55);
          radius *= pop;
        }
        if (activeT > 0) {
          final ringT = (activeT / 0.55).clamp(0.0, 1.0);
          canvas.drawCircle(
            nodes[k],
            13 * (0.75 + 0.25 * ringT),
            Paint()
              ..color = AppColors.accentPrimary
                  .withValues(alpha: 0.3 * ringT * newAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(
            nodes[k], radius, Paint()..color = _fade(fill, newAlpha));
      }
      final tip = nodes.last;
      upright(tip, () {
        canvas.saveLayer(
            null, Paint()..color = Colors.white.withValues(alpha: newAlpha));
        toLabel.paint(canvas, tip + Offset(11, -toLabel.height / 2));
        canvas.restore();
      });

      // The padlock over the first step, popping off on unlock.
      if (!_unlocked || phase == 3) {
        final first = nodes[active];
        final t = _unlocked ? beat.clamp(0.0, 1.0) : 0.0;
        final scale =
            t < 0.4 ? 1 + 0.35 * (t / 0.4) : 1.35 - 0.95 * ((t - 0.4) / 0.6);
        final lift = t < 0.4 ? 0.0 : -22 * ((t - 0.4) / 0.6);
        final tilt = t < 0.4 ? -14 * (t / 0.4) : -14.0;
        final alpha = (t < 0.4 ? 1.0 : 1 - (t - 0.4) / 0.6) * newAlpha;
        upright(first, () {
          canvas.save();
          canvas.translate(first.dx, first.dy + lift);
          canvas.rotate(tilt * math.pi / 180);
          canvas.scale(scale);
          canvas.drawCircle(
            Offset.zero,
            11,
            Paint()..color = AppColors.surface.withValues(alpha: alpha),
          );
          canvas.drawCircle(
            Offset.zero,
            11,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.14 * alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          final lockPaint = Paint()
            ..color = AppColors.textSecondary.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3.4, -0.7, 6.8, 5.1),
              const Radius.circular(1.4),
            ),
            lockPaint,
          );
          canvas.drawPath(
            Path()
              ..moveTo(-1.9, -0.7)
              ..lineTo(-1.9, -2.4)
              ..arcToPoint(const Offset(1.9, -2.4),
                  radius: const Radius.circular(1.9))
              ..lineTo(1.9, -0.7),
            lockPaint,
          );
          canvas.restore();
        });
      }
    }

    canvas.restore();

    // Hub, unrotated.
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
  }

  @override
  bool shouldRepaint(_NewTreeMapPainter old) =>
      old.phase != phase ||
      old.pulse != pulse ||
      old.spin != spin ||
      old.beat != beat ||
      old.data != data;
}
