import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/training_program_model.dart';

/// The workouts-by-type marker language: every workout type is a circled
/// initial, and the week is seven columns each carrying its type's marker.
/// Shared between the Program tab's strip and the schedule sheet so the
/// day ↔ type mapping reads the same everywhere, without a legend.

/// Monday-first day letters, matching [kWeekdayNames].
const List<String> kWeekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Monday-first short day names, matching [kWeekdayNames].
const List<String> kWeekdayShortNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

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

  const ProgramTypeNode({
    super.key,
    required this.sessionType,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final letter = programTypeLetter(sessionType);
    final base = programTypeColor(sessionType);
    // The neutral tone runs dimmer than the accent so white never outshouts
    // the blue it alternates with.
    final dim = base == Colors.white ? 0.62 : 1.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xB3111114),
        border: Border.all(
          color: base.withValues(alpha: 0.55 * dim),
          width: 1.3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.robotoMono(
          fontSize: size * (letter.length > 1 ? 0.36 : 0.48),
          fontWeight: FontWeight.w700,
          color: base.withValues(alpha: 0.95 * dim),
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
    );
  }
}

/// A rest day's marker: a faint dot holding the column's place.
class ProgramRestDot extends StatelessWidget {
  final double size;

  const ProgramRestDot({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: 3.5,
          height: 3.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }
}

/// The week as seven columns, each training day carrying its type's marker.
/// Read left to right it IS the week.
///
/// [onDayTap] makes each column its own target (the schedule sheet's day
/// toggles); [onTap] makes the whole strip one door (the Program tab, where
/// any tap opens the schedule).
class ProgramWeekStrip extends StatelessWidget {
  /// Monday-first, seven entries, rest days included.
  final List<TrainingSessionType> weekCycle;
  final VoidCallback? onTap;
  final ValueChanged<int>? onDayTap;
  final double nodeSize;
  final bool withDivider;

  const ProgramWeekStrip({
    super.key,
    required this.weekCycle,
    this.onTap,
    this.onDayTap,
    this.nodeSize = 22,
    this.withDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final strip = Container(
      padding: const EdgeInsets.only(top: 14, bottom: 20),
      decoration: BoxDecoration(
        border: withDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < weekCycle.length; i++)
            Expanded(child: _column(i)),
        ],
      ),
    );

    return onTap == null ? strip : Pressable(onTap: onTap, child: strip);
  }

  Widget _column(int index) {
    final sessionType = weekCycle[index];
    final trains = sessionType != TrainingSessionType.rest;

    final column = Column(
      children: [
        Text(
          kWeekdayLetters[index],
          style: GoogleFonts.robotoMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: trains ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        trains
            ? ProgramTypeNode(sessionType: sessionType, size: nodeSize)
            : ProgramRestDot(size: nodeSize),
      ],
    );

    if (onDayTap == null) return column;
    return Pressable(
      onTap: () => onDayTap!(index),
      child: Padding(
        // Breathing room so a 22px marker still makes a honest tap target.
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: column,
      ),
    );
  }
}
