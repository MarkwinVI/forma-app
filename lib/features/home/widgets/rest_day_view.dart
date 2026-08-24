import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';

/// Recovery (rest) day state of the Train tab — a calm breathing illustration
/// with recovery copy, the next session and how far off it is, and a quiet
/// "train something else" escape hatch. No workout list, no insight block.
class RestDayView extends StatefulWidget {
  /// What the day is called. Today is resting; a day ahead has one planned.
  final String title;

  /// Title of the next training session (e.g. "Lower Day") and how far away it
  /// is (e.g. "tomorrow", "in 2 days"). Both null hides the "next up" row.
  final String? nextTitle;
  final String? nextWhen;
  final VoidCallback? onTrainSomethingElse;

  const RestDayView({
    super.key,
    this.title = 'Nothing to do today',
    this.nextTitle,
    this.nextWhen,
    this.onTrainSomethingElse,
  });

  @override
  State<RestDayView> createState() => _RestDayViewState();
}

class _RestDayViewState extends State<RestDayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduce Motion: the rings rest at mid-breath instead of breathing.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.5;
      return;
    }
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        // The rings take whatever the copy and footer leave, capped at
        // their drawn size. Sizing them by a fraction of the viewport
        // instead let a short screen overflow by a pixel or two, since
        // everything under them is fixed height and cannot give.
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_controller.value);
                  return FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: _BreathingRings(progress: t),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'RECOVERY',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'RobotoMono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.accentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.54,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.nextTitle != null)
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
            child: Row(
              children: [
                const Text(
                  'NEXT UP',
                  style: TextStyle(fontFamily: 'RobotoMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: widget.nextTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        if (widget.nextWhen != null)
                          TextSpan(
                            text: ' · ${widget.nextWhen}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.onTrainSomethingElse != null) ...[
          const SizedBox(height: 4),
          TextAction(
            label: 'Feeling fresh? Train something else',
            icon: Icons.swap_horiz_rounded,
            onTap: widget.onTrainSomethingElse,
          ),
        ],
      ],
    );
  }
}

/// Concentric breathing rings around a moon glyph — the calm centerpiece of
/// the recovery state. [progress] (0→1) drives a gentle expand/contract.
class _BreathingRings extends StatelessWidget {
  static const _ringSizes = [312.0, 240.0, 172.0, 108.0];

  final double progress;

  const _BreathingRings({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scale = 1 + 0.05 * progress;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accentPrimary.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
        for (var i = 0; i < _ringSizes.length; i++)
          Transform.scale(
            scale: scale,
            child: Container(
              width: _ringSizes[i],
              height: _ringSizes[i],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPrimary
                      .withValues(alpha: 0.12 + i * 0.06),
                ),
              ),
            ),
          ),
        Transform.scale(
          scale: scale,
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
            ),
            alignment: Alignment.center,
            child: const ExcludeSemantics(
              child: Icon(
                Icons.bedtime_rounded,
                size: 28,
                color: AppColors.accentBright,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
