import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';

/// The result of adding, removing or re-aiming a track: the refreshed set,
/// and what to tell the user about it.
class SkillTrackChange {
  final List<SkillTrack> tracks;
  final String? message;

  const SkillTrackChange({required this.tracks, this.message});
}

/// What adding or removing a tree does to the week, spelled out before the
/// user commits to it.
class SkillTrackImpact {
  /// The step that joins or leaves the sessions.
  final String exerciseName;

  /// Weekday names the change lands on.
  final List<String> dayNames;

  /// The kind of workout those days are, when they are all the same kind —
  /// null when the tree spans more than one (a core tree lands on both push
  /// and pull days).
  final TrainingSessionType? sessionType;

  /// Whether those are every workout of that kind in the week, which is what
  /// lets the copy say "all four full-body workouts" rather than listing days.
  final bool coversEverySession;

  /// The weekly-balance line this tree feeds, and where it moves. Stated as a
  /// before and after rather than against the target, so no benchmark to
  /// carry here.
  final String balanceLabel;
  final int before;
  final int after;

  const SkillTrackImpact({
    required this.exerciseName,
    required this.dayNames,
    required this.balanceLabel,
    required this.before,
    required this.after,
    this.sessionType,
    this.coversEverySession = false,
  });

  String get days {
    if (dayNames.length < 2) return dayNames.join();
    return '${dayNames.take(dayNames.length - 1).join(', ')} '
        'and ${dayNames.last}';
  }
}

/// Works out that impact without committing to it.
typedef SkillTrackImpactProbe = SkillTrackImpact? Function(
  String skillCategoryId,
  bool include,
);

/// Persists one change to a track and reports the new state back.
typedef SkillTrackUpdate = Future<SkillTrackChange?> Function({
  required String skillCategoryId,
  String? branchId,
  bool? included,
});

/// The two sentences the confirmation sheet shows: what the change does to
/// the week, and what it does to the weekly balance.
class SkillTrackImpactCopy {
  final String change;
  final String balance;

  const SkillTrackImpactCopy({required this.change, required this.balance});
}

/// Spells the impact out in plain sentences — counts as words, workouts named
/// by the kind of session they are, and the balance movement stated as a
/// before and after rather than against a target.
SkillTrackImpactCopy skillTrackImpactCopy({
  required SkillTrackImpact impact,
  required String treeName,
  required bool removing,
}) {
  final where = _workoutsPhrase(impact);
  final change = removing
      ? 'The $treeName progression will be removed from $where.'
      : 'The $treeName progression, starting with ${impact.exerciseName}, '
          'will be added to $where.';

  return SkillTrackImpactCopy(
    change: change,
    balance: removing ? _removedBalance(impact) : _addedBalance(impact),
  );
}

/// "all four full-body workouts" when the tree lands on every workout of one
/// kind, and the days themselves when it does not — never a count that reads
/// as more than the change actually touches.
String _workoutsPhrase(SkillTrackImpact impact) {
  final count = impact.dayNames.length;
  if (count == 0) return 'your workouts';

  final kind = impact.sessionType;
  if (kind == null || !impact.coversEverySession) {
    return count == 1
        ? 'your ${impact.dayNames.single} workout'
        : 'your ${impact.days} workouts';
  }

  final label = _sessionLabel(kind);
  if (count == 1) return 'your $label workout';
  if (count == 2) return 'both $label workouts';
  return 'all ${_word(count)} $label workouts';
}

String _addedBalance(SkillTrackImpact impact) {
  final movement = _movement(impact.balanceLabel);
  if (impact.after <= impact.before) {
    return 'This leaves $movement training at ${_amount(impact.after)} '
        'per week.';
  }
  return 'This increases $movement training from ${_from(impact.before)} '
      'to ${_amount(impact.after)} per week.';
}

String _removedBalance(SkillTrackImpact impact) {
  final movement = _movement(impact.balanceLabel);
  const kept = 'Your progress will stay saved.';

  if (impact.after == 0) {
    return 'This leaves no $movement training in your program. $kept';
  }
  if (impact.after >= impact.before) {
    return 'This leaves $movement training at ${_amount(impact.after)} '
        'per week. $kept';
  }
  return 'This reduces $movement training from ${_from(impact.before)} '
      'to ${_amount(impact.after)} per week. $kept';
}

/// "Horizontal pull" reads as a compound adjective in front of "training", so
/// it is hyphenated: horizontal-pull training. A label that is already two
/// things — glutes & hamstrings — is a list, not a compound, and stays as it is.
String _movement(String balanceLabel) {
  final lower = balanceLabel.toLowerCase();
  if (lower.contains('&')) return lower;
  return lower.replaceAll(' ', '-');
}

/// "none", "one time", "four times" — an absence is worth saying as one.
String _amount(int value) {
  if (value <= 0) return 'none';
  return '${_word(value)} ${value == 1 ? 'time' : 'times'}';
}

/// The left-hand side of "from X to Y times per week": bare, because the unit
/// on the right covers both. "none" is the exception — it carries no unit to
/// share.
String _from(int value) => value <= 0 ? 'none' : _word(value);

String _sessionLabel(TrainingSessionType sessionType) {
  switch (sessionType) {
    case TrainingSessionType.fullBody:
      return 'full-body';
    case TrainingSessionType.push:
      return 'push';
    case TrainingSessionType.pull:
      return 'pull';
    case TrainingSessionType.upper:
      return 'upper-body';
    case TrainingSessionType.lower:
      return 'lower-body';
    case TrainingSessionType.rest:
      return 'training';
  }
}

const List<String> _words = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
];

String _word(int value) =>
    value >= 0 && value < _words.length ? _words[value] : '$value';
