import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../progress/widgets/skill_wheel.dart';

/// The Program tab's skill-tree door: a static miniature of the radial
/// wheel — blue rim arcs over the trees with a progression running — next
/// to the running count and the way into the full map.
class ProgramSkillTreesCard extends StatelessWidget {
  final List<WheelFamily> families;
  final Set<String> activeCategoryIds;

  /// Trees behind an unmet prerequisite — dashed gray arcs on the
  /// miniature, where running trees get blue ones.
  final Set<String> lockedCategoryIds;
  final VoidCallback onOpen;

  const ProgramSkillTreesCard({
    super.key,
    required this.families,
    required this.activeCategoryIds,
    this.lockedCategoryIds = const {},
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(
                painter: _MiniWheelPainter(
                  families: families,
                  activeCategoryIds: activeCategoryIds,
                  lockedCategoryIds: lockedCategoryIds,
                ),
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Text(
                'Edit Progression',
                style: TextStyle(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// A static, non-interactive render of the index wheel: node statuses, the
/// rim ring, and a blue arc over every active tree. Same layout rules as
/// the full wheel (r0 20 → reach 209, rim 250, clamped branch fans), just
/// without cameras, labels, or gestures.
class _MiniWheelPainter extends CustomPainter {
  final List<WheelFamily> families;
  final Set<String> activeCategoryIds;
  final Set<String> lockedCategoryIds;

  _MiniWheelPainter({
    required this.families,
    required this.activeCategoryIds,
    required this.lockedCategoryIds,
  });

  static const double _r0 = 20, _reach = 209, _rim = 250;

  @override
  void paint(Canvas canvas, Size size) {
    if (families.length < 2) return;
    final n = families.length;
    final stepDeg = 360 / n;

    // User space: hub at the origin, everything inside rim + margin.
    final scale = size.shortestSide / (2 * (_rim + 16));
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    canvas.drawCircle(
      Offset.zero,
      _rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    for (var i = 0; i < n; i++) {
      final family = families[i];
      final active = activeCategoryIds.contains(family.categoryId);
      final angle = (-90 + stepDeg * i) * math.pi / 180;

      const arcR = _rim + 12;
      final halfSweep = math.min(19.0, stepDeg / 2 - 3) * math.pi / 180;
      if (active) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: arcR),
          angle - halfSweep,
          2 * halfSweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..color = AppColors.accentBright.withValues(alpha: 0.85),
        );
      } else if (lockedCategoryIds.contains(family.categoryId)) {
        // Locked behind a prerequisite: the same arc, dashed and gray.
        final dashPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF66676E);
        const dashLen = 7.0, gapLen = 12.0;
        const dashSweep = dashLen / arcR, gapSweep = gapLen / arcR;
        for (var a = angle - halfSweep;
            a < angle + halfSweep;
            a += dashSweep + gapSweep) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: arcR),
            a,
            math.min(dashSweep, angle + halfSweep - a),
            false,
            dashPaint,
          );
        }
      }

      _paintFamily(
        canvas,
        family,
        angle,
        stepDeg,
        opacity: active ? 1.0 : 0.45,
      );
    }

    // Hub disc.
    canvas.drawCircle(
      Offset.zero,
      16,
      Paint()..color = AppColors.bg,
    );
    canvas.drawCircle(
      Offset.zero,
      16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    canvas.restore();
  }

  void _paintFamily(
    Canvas canvas,
    WheelFamily family,
    double angle,
    double stepDeg, {
    required double opacity,
  }) {
    final branchMax = family.branches.isEmpty
        ? 0
        : family.branches.map((b) => b.steps.length).reduce(math.max);
    final depth = math
        .max(1, math.max(family.trunk.length, 1) - 1 + branchMax)
        .toDouble();
    final pitch = (_reach - _r0) / depth;

    final linkPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.09 * opacity);

    Offset at(double r, double bearing) =>
        Offset(r * math.cos(bearing), r * math.sin(bearing));

    void node(Offset p, WheelNodeState state) {
      final color = switch (state) {
        WheelNodeState.mastered => AppColors.green,
        WheelNodeState.skipped => AppColors.green.withValues(alpha: 0.4),
        WheelNodeState.active => AppColors.textPrimary,
        WheelNodeState.locked => const Color(0xFF4A4B52),
      };
      canvas.drawCircle(
        p,
        state == WheelNodeState.active ? 8 : 6,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }

    final trunkPoints = <Offset>[];
    for (var k = 0; k < family.trunk.length; k++) {
      trunkPoints.add(at(_r0 + k * pitch, angle));
      if (k > 0) {
        canvas.drawLine(trunkPoints[k - 1], trunkPoints[k], linkPaint);
      }
    }
    final forkR =
        family.trunk.isEmpty ? _r0 : _r0 + (family.trunk.length - 1) * pitch;
    final fork = trunkPoints.isEmpty ? at(_r0, angle) : trunkPoints.last;

    final count = family.branches.length;
    final tight = family.trunk.isEmpty;
    final spread =
        tight ? 10.0 : (count == 2 ? 10.0 : (count == 3 ? 12.0 : 16.0));
    List<double> offsets;
    if (count <= 1) {
      offsets = const [0];
    } else if (count == 2) {
      offsets = [-spread, spread];
    } else if (count == 3) {
      offsets = [-spread, 0, spread];
    } else {
      offsets = [
        for (var i = 0; i < count; i++)
          -spread + 2 * spread * i / (count - 1),
      ];
    }

    final maxRad = (stepDeg / 2 - 2.5) * math.pi / 180;
    for (var j = 0; j < count; j++) {
      final branch = family.branches[j];
      final raw = angle + offsets[j] * math.pi / 180;
      final bearing = angle + (raw - angle).clamp(-maxRad, maxRad);
      final branchPitch = (_reach - forkR) / branch.steps.length;
      var prev = fork;
      for (var k = 0; k < branch.steps.length; k++) {
        final p = at(forkR + (k + 1) * branchPitch, bearing);
        canvas.drawLine(prev, p, linkPaint);
        node(p, branch.steps[k].state);
        prev = p;
      }
    }
    for (var k = 0; k < family.trunk.length; k++) {
      node(trunkPoints[k], family.trunk[k].state);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWheelPainter oldDelegate) =>
      oldDelegate.families != families ||
      oldDelegate.activeCategoryIds != activeCategoryIds;
}
