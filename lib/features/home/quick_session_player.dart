import 'package:flutter/foundation.dart';

import 'quick_sessions.dart';

/// One stretch of work in a running quick session: a move, or one side of
/// it, in one round.
class QuickSessionStep {
  final QuickSessionMove move;

  /// "LEFT SIDE" / "RIGHT SIDE" for a move done on each side; else null.
  final String? side;

  /// 1-based, and how many there are; [rounds] is 1 for most sessions.
  final int round;
  final int rounds;

  /// Seconds between the step before and this one: time to rest, change
  /// position, or get ready before the first.
  final int leadInSeconds;

  const QuickSessionStep({
    required this.move,
    required this.round,
    required this.rounds,
    required this.leadInSeconds,
    this.side,
  });

  bool get isTimed => move.isTimed;

  /// "Side Plank" either way: the side is said beside it, not in it.
  String get name => move.name;
}

/// The least time between two steps, however a session is paced: long
/// enough to read what is next and get into position for it.
const quickSessionMinLeadIn = 5;

/// A session's moves laid out as the player runs them: every round, both
/// sides of a sided move, each with the pause that comes before it.
List<QuickSessionStep> quickSessionSteps(QuickSession session) {
  final steps = <QuickSessionStep>[];
  final between = session.restSeconds > quickSessionMinLeadIn
      ? session.restSeconds
      : quickSessionMinLeadIn;
  for (var round = 1; round <= session.rounds; round++) {
    for (final move in session.moves) {
      final sides = move.perSide ? const ['LEFT SIDE', 'RIGHT SIDE'] : [null];
      for (final side in sides) {
        steps.add(QuickSessionStep(
          move: move,
          side: side,
          round: round,
          rounds: session.rounds,
          // Switching sides is a change of position, not a rest.
          leadInSeconds: steps.isEmpty || side == 'RIGHT SIDE'
              ? quickSessionMinLeadIn
              : between,
        ));
      }
    }
  }
  return steps;
}

/// Where the player is inside a step.
enum QuickSessionPhase {
  /// The pause before the step: rest, switch sides, or get ready.
  leadIn,

  /// The step itself: a countdown, or reps until "Done".
  work,

  /// Every step is behind.
  finished,
}

/// What the player says without the screen — the phone is on the floor.
enum QuickSessionCue {
  /// One of the last three seconds of a countdown.
  tick,

  /// A step starts.
  go,

  /// A step ends and a pause starts.
  rest,

  /// The session is over.
  finished,
}

/// Runs a quick session: which step, which phase, how long is left.
///
/// It keeps no clock of its own. Whoever owns it calls [advance] with the
/// time that has passed, which is what lets a test walk a ten-minute
/// session in a line.
class QuickSessionPlayer extends ChangeNotifier {
  final List<QuickSessionStep> steps;
  final void Function(QuickSessionCue cue)? onCue;

  QuickSessionPlayer(QuickSession session, {this.onCue})
      : steps = quickSessionSteps(session) {
    _remaining = Duration(seconds: steps.first.leadInSeconds);
  }

  int _index = 0;
  QuickSessionPhase _phase = QuickSessionPhase.leadIn;
  Duration _remaining = Duration.zero;
  Duration _active = Duration.zero;
  bool _paused = false;

  int get index => _index;
  QuickSessionPhase get phase => _phase;
  bool get paused => _paused;
  bool get isFinished => _phase == QuickSessionPhase.finished;
  QuickSessionStep get step => steps[_index];

  /// The step after this one, or null on the last.
  QuickSessionStep? get next =>
      _index + 1 < steps.length ? steps[_index + 1] : null;

  /// Time spent in the session, pauses left out.
  Duration get active => _active;

  /// Whether a clock is running down: every pause, and a timed step. A
  /// counted step waits for [done] instead.
  bool get isCountingDown =>
      _phase == QuickSessionPhase.leadIn ||
      (_phase == QuickSessionPhase.work && step.isTimed);

  /// What the countdown shows: whole seconds, rounded up, so it reads
  /// "0:45" as the step starts and never sits on "0:00".
  int get secondsLeft =>
      (_remaining.inMilliseconds / Duration.millisecondsPerSecond).ceil();

  /// 0 → 1 through the phase's countdown; 0 on a counted step.
  double get progress {
    if (!isCountingDown) return 0;
    final total = _phase == QuickSessionPhase.leadIn
        ? step.leadInSeconds
        : step.move.seconds!;
    if (total <= 0) return 1;
    final left = _remaining.inMilliseconds / (total * 1000);
    return (1 - left).clamp(0.0, 1.0);
  }

  /// Moves the session on by [elapsed]. Nothing happens while paused.
  void advance(Duration elapsed) {
    if (_paused || isFinished || elapsed <= Duration.zero) return;
    _active += elapsed;
    if (!isCountingDown) return;

    final before = secondsLeft;
    _remaining -= elapsed;
    if (_remaining <= Duration.zero) {
      // What is left over is dropped, not carried: a late tick should not
      // shorten the next step.
      if (_phase == QuickSessionPhase.leadIn) {
        _startWork();
      } else {
        _completeStep();
      }
    } else {
      final now = secondsLeft;
      if (now != before && now <= 3) onCue?.call(QuickSessionCue.tick);
    }
    notifyListeners();
  }

  void togglePause() {
    if (isFinished) return;
    _paused = !_paused;
    notifyListeners();
  }

  /// "Done" on a counted step.
  void done() {
    if (_phase != QuickSessionPhase.work || step.isTimed) return;
    _completeStep();
    notifyListeners();
  }

  /// Forward: out of a pause into its step, or past the step.
  void skip() {
    if (isFinished) return;
    if (_phase == QuickSessionPhase.leadIn) {
      _startWork();
    } else {
      _completeStep();
    }
    notifyListeners();
  }

  /// Back: to the start of this step, or from its pause to the step
  /// before. Either way the step starts over at once, with no pause — the
  /// person asked for it.
  void previous() {
    if (isFinished) return;
    if (_phase == QuickSessionPhase.leadIn && _index > 0) _index--;
    _startWork();
    notifyListeners();
  }

  void _startWork() {
    _phase = QuickSessionPhase.work;
    _remaining =
        step.isTimed ? Duration(seconds: step.move.seconds!) : Duration.zero;
    onCue?.call(QuickSessionCue.go);
  }

  void _completeStep() {
    if (_index + 1 >= steps.length) {
      _phase = QuickSessionPhase.finished;
      _remaining = Duration.zero;
      onCue?.call(QuickSessionCue.finished);
      return;
    }
    _index++;
    _phase = QuickSessionPhase.leadIn;
    _remaining = Duration(seconds: step.leadInSeconds);
    onCue?.call(QuickSessionCue.rest);
  }
}
