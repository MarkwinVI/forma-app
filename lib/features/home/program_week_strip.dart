import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/training_program_model.dart';

/// The workouts-by-type marker language: every workout type is a circled
/// initial, so a workout reads the same wherever it is named, without a
/// legend.

/// The type's initial in its marker. Push and Pull collide on P, so they
/// widen to two-character codes — colour helps but never carries the
/// difference alone.
String programTypeLetter(TrainingSessionType sessionType) {
  switch (sessionType) {
    case TrainingSessionType.fullBody:
      return 'F';
    case TrainingSessionType.push:
      return 'PU';
    case TrainingSessionType.pull:
      return 'PL';
    case TrainingSessionType.upper:
      return 'U';
    case TrainingSessionType.lower:
      return 'L';
    case TrainingSessionType.rest:
      return '';
  }
}

/// The marker's base tint: the split's first session takes the accent, the
/// alternating one stays neutral so the pair reads at a glance.
Color programTypeColor(TrainingSessionType sessionType) {
  switch (sessionType) {
    case TrainingSessionType.fullBody:
    case TrainingSessionType.push:
    case TrainingSessionType.upper:
      return AppColors.accentPrimary;
    case TrainingSessionType.pull:
    case TrainingSessionType.lower:
      return Colors.white;
    case TrainingSessionType.rest:
      return AppColors.textMuted;
  }
}

/// Type marker: the type's initial in a circle, always.
class ProgramTypeNode extends StatelessWidget {
  final TrainingSessionType sessionType;
  final double size;

  /// Overrides the type's own tint — the Train ribbon colours a marker by
  /// what happened to its day (green for trained, red for missed).
  final Color? color;

  /// Solid rather than outlined: the Train ribbon marks the booked first
  /// workout this way, the one day on the strip the plan is waiting for.
  final bool filled;

  const ProgramTypeNode({
    super.key,
    required this.sessionType,
    this.size = 20,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final letter = programTypeLetter(sessionType);
    final base = color ?? programTypeColor(sessionType);
    // The neutral tone runs dimmer than the accent so white never outshouts
    // the blue it alternates with.
    final dim = base == Colors.white ? 0.62 : 1.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? base : const Color(0xB3111114),
        border: Border.all(
          color: filled ? base : base.withValues(alpha: 0.55 * dim),
          width: 1.3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: size * (letter.length > 1 ? 0.36 : 0.48),
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : base.withValues(alpha: 0.95 * dim),
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
    );
  }
}
