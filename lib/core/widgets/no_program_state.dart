import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'polished.dart';
import 'type_led.dart';

/// The shape every empty tab takes before a program exists: a statement of
/// what will be here, the thing itself sketched but unlit, and the one action
/// that fills it in.
///
/// All three tabs tell the same story and offer the same way out, so they
/// share this shell rather than each inventing an empty screen.
class NoProgramState extends StatelessWidget {
  final String title;
  final String sub;

  /// What sits between the statement and the action — the ghost graph, a
  /// skeleton week, the paths not started yet.
  final List<Widget> children;
  final VoidCallback onCreateProgram;

  const NoProgramState({
    super.key,
    required this.title,
    required this.sub,
    this.children = const [],
    required this.onCreateProgram,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            // Centred in the viewport rather than pinned under the status bar:
            // there is no content above it to anchor to.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TypeTitle(title, sub: sub),
                  ...children,
                  const SizedBox(height: 26),
                  PillButton(
                    label: 'Create my program',
                    radius: 14,
                    onTap: onCreateProgram,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The program's constellation drawn unlit — the same graph the Program tab
/// shows once there is one, so an empty screen still says what the app is
/// for. Every node and link is dashed: nothing here has been earned yet.
class GhostConstellation extends StatelessWidget {
  final double height;

  const GhostConstellation({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _GhostConstellationPainter(height: height)),
    );
  }
}

class _GhostConstellationPainter extends CustomPainter {
  /// The node grid is laid out for a 190-tall box and scaled to fit shorter
  /// ones, so the graph keeps its shape at any height.
  final double height;

  const _GhostConstellationPainter({required this.height});

  static const _nodes = [
    Offset(22, 132),
    Offset(88, 116),
    Offset(154, 104),
    Offset(220, 108),
    Offset(286, 92),
    Offset(350, 74),
    Offset(122, 60),
    Offset(318, 146),
  ];
  static const _links = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5),
    (1, 6),
    (4, 7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 402;
    final scaleY = size.height / 190;
    Offset at(Offset point) =>
        Offset(point.dx * scaleX, point.dy * scaleY);

    // Soft bloom, so the graph sits in something rather than floating.
    canvas.drawCircle(
      at(const Offset(190, 90)),
      130 * scaleX,
      Paint()..color = Colors.white.withValues(alpha: 0.02),
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    for (final (from, to) in _links) {
      _dashedLine(canvas, at(_nodes[from]), at(_nodes[to]), line);
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.14);
    final fill = Paint()..color = AppColors.bg.withValues(alpha: 0.6);
    for (final node in _nodes) {
      final center = at(node);
      final radius = 10.5 * scaleX;
      canvas.drawCircle(center, radius, fill);
      _dashedCircle(canvas, center, radius, ring);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0, gap = 5.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final step = (b - a) / total;
    for (var travelled = 0.0; travelled < total; travelled += dash + gap) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(a + step * travelled, a + step * end, paint);
    }
  }

  void _dashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dash = 2.5, gap = 3.0;
    final circumference = 2 * math.pi * radius;
    final segments = (circumference / (dash + gap)).round().clamp(6, 40);
    final sweep = 2 * math.pi / segments;
    final arc = sweep * dash / (dash + gap);
    final box = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(box, i * sweep, arc, false, paint);
    }
  }

  @override
  bool shouldRepaint(_GhostConstellationPainter oldDelegate) =>
      oldDelegate.height != height;
}

/// A row of the thing that is not there yet: a name stepped back, and a mono
/// note on the right saying so.
class GhostRow extends StatelessWidget {
  final String name;
  final String note;
  final double nameSize;
  final bool last;

  const GhostRow({
    super.key,
    required this.name,
    required this.note,
    this.nameSize = 21,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: nameSize,
                fontWeight:
                    nameSize >= 21 ? FontWeight.w800 : FontWeight.w700,
                color: nameSize >= 21
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                letterSpacing: nameSize * -0.02,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            note,
            style: monoStyle(
              size: note == '—' ? 14 : 12.5,
              letterSpacing: note == '—' ? 0 : 1,
            ),
          ),
        ],
      ),
    );
  }
}
