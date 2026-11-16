import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/quick_session_player.dart';
import 'package:forma_app/features/home/quick_sessions.dart';

QuickSession session({
  required List<QuickSessionMove> moves,
  int restSeconds = 0,
  int rounds = 1,
}) =>
    QuickSession(
      id: 'test',
      name: 'Test',
      minutes: 5,
      summary: '',
      group: QuickSessionGroup.shortOnTime,
      image: 'assets/quick_sessions/bar.jpg',
      description: '',
      equipment: 'None',
      moves: moves,
      restSeconds: restSeconds,
      rounds: rounds,
    );

const second = Duration(seconds: 1);

void main() {
  const plank = QuickSessionMove.timed('Plank', 30);
  const sidePlank = QuickSessionMove.timed('Side Plank', 20, perSide: true);
  const pushUp = QuickSessionMove.reps('Push-Up', 10);

  group('a move', () {
    test('prints its time, its sides, or its reps', () {
      expect(plank.amount, '30 S');
      expect(sidePlank.amount, '20 S / SIDE');
      expect(pushUp.amount, '10×');
    });

    test('a session says how its moves run on', () {
      expect(session(moves: [plank]).pacing, 'NO REST');
      expect(session(moves: [plank], restSeconds: 20).pacing, '20 S REST');
    });
  });

  group('the steps', () {
    test('a sided move is two steps, with a short switch between', () {
      final steps = quickSessionSteps(
        session(moves: [plank, sidePlank], restSeconds: 15),
      );
      expect(steps.map((s) => s.side), [null, 'LEFT SIDE', 'RIGHT SIDE']);
      expect(steps.map((s) => s.leadInSeconds), [5, 15, 5]);
    });

    test('moves that run on still leave time to change position', () {
      final steps = quickSessionSteps(session(moves: [plank, pushUp]));
      expect(steps.map((s) => s.leadInSeconds), [5, 5]);
    });

    test('every round repeats the moves', () {
      final steps =
          quickSessionSteps(session(moves: [plank, pushUp], rounds: 2));
      expect(steps.map((s) => s.name), ['Plank', 'Push-Up', 'Plank', 'Push-Up']);
      expect(steps.map((s) => s.round), [1, 1, 2, 2]);
    });

    test('every session in the catalogue lays out', () {
      for (final s in QuickSessions.all) {
        expect(quickSessionSteps(s), isNotEmpty, reason: s.id);
      }
    });
  });

  group('the player', () {
    test('opens on a pause, then runs a timed move down and moves on', () {
      final cues = <QuickSessionCue>[];
      final player =
          QuickSessionPlayer(session(moves: [plank, pushUp]), onCue: cues.add);

      expect(player.phase, QuickSessionPhase.leadIn);
      expect(player.secondsLeft, 5);

      player.advance(second * 5);
      expect(player.phase, QuickSessionPhase.work);
      expect(player.secondsLeft, 30);
      expect(cues.last, QuickSessionCue.go);

      player.advance(second * 15);
      expect(player.secondsLeft, 15);
      expect(player.progress, closeTo(0.5, 0.001));

      player.advance(second * 15);
      expect(player.index, 1);
      expect(player.phase, QuickSessionPhase.leadIn);
      expect(cues.last, QuickSessionCue.rest);
    });

    test('ticks through the last three seconds of a countdown', () {
      final cues = <QuickSessionCue>[];
      final player = QuickSessionPlayer(session(moves: [plank]), onCue: cues.add);
      for (var i = 0; i < 4; i++) {
        player.advance(second);
      }
      // 5 → 4 says nothing; 3, 2 and 1 each tick.
      expect(cues, List.filled(3, QuickSessionCue.tick));
    });

    test('a counted move waits for Done, however long that takes', () {
      final player = QuickSessionPlayer(session(moves: [pushUp, plank]));
      player.advance(second * 5);
      expect(player.isCountingDown, isFalse);

      player.advance(second * 90);
      expect(player.index, 0);
      expect(player.phase, QuickSessionPhase.work);

      player.done();
      expect(player.index, 1);
      expect(player.phase, QuickSessionPhase.leadIn);
    });

    test('Done does nothing on a timed move or in a pause', () {
      final player = QuickSessionPlayer(session(moves: [plank]));
      player.done();
      expect(player.phase, QuickSessionPhase.leadIn);
      player.advance(second * 5);
      player.done();
      expect(player.phase, QuickSessionPhase.work);
    });

    test('a pause holds the clock and the time spent', () {
      final player = QuickSessionPlayer(session(moves: [plank]));
      player.advance(second * 5);
      player.togglePause();
      player.advance(second * 60);
      expect(player.secondsLeft, 30);
      expect(player.active, second * 5);

      player.togglePause();
      player.advance(second * 10);
      expect(player.secondsLeft, 20);
    });

    test('skip leaves a pause for its move, and a move for the next pause',
        () {
      final player = QuickSessionPlayer(session(moves: [plank, pushUp]));
      player.skip();
      expect(player.phase, QuickSessionPhase.work);
      expect(player.index, 0);
      player.skip();
      expect(player.phase, QuickSessionPhase.leadIn);
      expect(player.index, 1);
    });

    test('back restarts the move, or from a pause goes to the one before',
        () {
      final player = QuickSessionPlayer(session(moves: [plank, pushUp]));
      player.advance(second * 20); // 15 s into the plank
      player.previous();
      expect(player.index, 0);
      expect(player.secondsLeft, 30);

      player.skip(); // into the pause before the push-ups
      player.previous();
      expect(player.index, 0);
      expect(player.phase, QuickSessionPhase.work);
    });

    test('finishes after the last step and then stands still', () {
      final cues = <QuickSessionCue>[];
      final player = QuickSessionPlayer(session(moves: [plank]), onCue: cues.add);
      player.advance(second * 5);
      player.advance(second * 30);
      expect(player.isFinished, isTrue);
      expect(cues.last, QuickSessionCue.finished);
      expect(player.active, second * 35);

      player.advance(second * 30);
      player.skip();
      player.togglePause();
      expect(player.isFinished, isTrue);
      expect(player.paused, isFalse);
      expect(player.active, second * 35);
    });

    test('a late tick does not eat into the next step', () {
      final player = QuickSessionPlayer(session(moves: [plank]));
      player.advance(second * 12);
      expect(player.phase, QuickSessionPhase.work);
      expect(player.secondsLeft, 30);
    });
  });
}
