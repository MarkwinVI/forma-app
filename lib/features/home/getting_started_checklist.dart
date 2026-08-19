import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// Onboarding checklist shown on Home until every step is complete.
/// Steps: build a program, then complete the first workout.
class GettingStartedChecklist extends StatelessWidget {
  final bool programDone;
  final VoidCallback? onSetupProgram;
  final VoidCallback? onStartWorkout;

  const GettingStartedChecklist({
    super.key,
    required this.programDone,
    this.onSetupProgram,
    this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: 'Set up your training program',
        sub: 'Pick goals and a schedule',
        state: programDone ? _StepState.done : _StepState.active,
        onTap: programDone ? null : onSetupProgram,
      ),
      (
        label: 'Complete your first workout',
        sub: 'Log your opening session',
        state: programDone ? _StepState.active : _StepState.locked,
        onTap: programDone ? onStartWorkout : null,
      ),
    ];
    final doneCount = items.where((item) => item.state == _StepState.done).length;

    return SurfaceCard(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 11),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your first steps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$doneCount / ${items.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          for (final item in items)
            _ChecklistRow(
              label: item.label,
              sub: item.sub,
              state: item.state,
              onTap: item.onTap,
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, locked }

class _ChecklistRow extends StatelessWidget {
  final String label;
  final String sub;
  final _StepState state;
  final VoidCallback? onTap;

  const _ChecklistRow({
    required this.label,
    required this.sub,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = state == _StepState.locked;

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Opacity(
        opacity: locked ? 0.5 : 1,
        child: Row(
          children: [
            _StepIndicator(state: state),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (state == _StepState.active)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, child: row);
  }
}

class _StepIndicator extends StatelessWidget {
  final _StepState state;

  const _StepIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _StepState.done:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentPrimary,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Colors.white,
          ),
        );
      case _StepState.active:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(
              width: 2,
              color: AppColors.accentPrimary,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentPrimary,
              shape: BoxShape.circle,
            ),
          ),
        );
      case _StepState.locked:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: AppColors.textMuted,
          ),
        );
    }
  }
}
