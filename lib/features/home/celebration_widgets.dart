import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pieces the post-workout celebration steps share, in [FinishedWorkoutView]
/// and the fork and new-tree steps that live in files of their own.

class CelebrationTag extends StatelessWidget {
  final Color color;
  final String label;

  const CelebrationTag({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide-up + fade-in entrance, staggered by [delay].
class RiseIn extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const RiseIn({
    super.key,
    required this.delay,
    required this.child,
  });

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.32, 0.72, 0, 1),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// How wide the target bar and the tree map under it are — one width, so
/// the two always line up.
const double celebrationContentWidth = 320;

/// Label, target and a bar that fills to it — green, since what fills is
/// the mastered prerequisite.
class CelebrationTargetBar extends StatelessWidget {
  final String label;
  final String target;
  final Color targetColor;
  final bool fill;

  const CelebrationTargetBar({
    super.key,
    required this.label,
    required this.target,
    required this.targetColor,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: celebrationContentWidth),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                target,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: targetColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: AppColors.surface2),
                  AnimatedFractionallySizedBox(
                    duration: fill
                        ? const Duration(milliseconds: 1250)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    widthFactor: fill ? 1 : 0,
                    alignment: Alignment.centerLeft,
                    child: Container(color: AppColors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
