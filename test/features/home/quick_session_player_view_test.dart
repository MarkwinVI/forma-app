import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/quick_session_player_view.dart';
import 'package:forma_app/features/home/quick_sessions.dart';

void main() {
  const session = QuickSession(
    id: 'test',
    name: 'Test session',
    minutes: 1,
    summary: '',
    group: QuickSessionGroup.shortOnTime,
    image: 'assets/quick_sessions/bar.jpg',
    description: '',
    equipment: 'None',
    moves: [
      QuickSessionMove.timed('Side Plank', 10, perSide: true),
      QuickSessionMove.reps('Push-Up', 8),
    ],
  );

  Future<List<bool?>> pumpPlayer(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = (size ?? const Size(393, 852)) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await showQuickSessionPlayer(context, session: session),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return results;
  }

  const second = Duration(seconds: 1);

  testWidgets('leads through a timed move, its other side, and a counted one',
      (tester) async {
    final results = await pumpPlayer(tester);

    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('Side Plank'), findsOneWidget);
    expect(find.text('10 S / SIDE'), findsOneWidget);

    // Through the pause, into the left side.
    await tester.pump(second * 5);
    expect(find.text('MOVE 1 OF 2'), findsOneWidget);
    expect(find.text('LEFT SIDE'), findsOneWidget);
    expect(find.text('Side Plank, right side'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.pump(second * 10);
    expect(find.text('SWITCH SIDES'), findsOneWidget);

    // The right side, then the pause before the push-ups.
    await tester.pump(second * 5);
    expect(find.text('RIGHT SIDE'), findsOneWidget);
    expect(find.text('Push-Up'), findsOneWidget);
    await tester.pump(second * 10);
    await tester.pump(second * 5);

    // A counted move: the reps where the clock was, and Done to go on.
    expect(find.text('8×'), findsOneWidget);
    expect(find.text('LAST MOVE'), findsOneWidget);
    await tester.pump(second * 40);
    expect(find.text('8×'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Session done'), findsOneWidget);
    expect(find.textContaining('Test session · '), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('Pause holds the clock until Resume', (tester) async {
    await pumpPlayer(tester);
    await tester.pump(second * 5);
    await tester.pump(second * 2);
    expect(find.text('0:08'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump(second * 30);
    expect(find.text('0:08'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump(second * 2);
    expect(find.text('0:06'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing asks first, and holds the session while it asks',
      (tester) async {
    final results = await pumpPlayer(tester);
    await tester.pump(second * 6);
    expect(find.text('0:09'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('End session'));
    await tester.pumpAndSettle();
    expect(find.text('End this session?'), findsOneWidget);

    // Kept: the session picks up where it was.
    await tester.tap(find.text('Cancel'));
    await tester.pump(second);
    await tester.pump(second);
    expect(find.text('0:09'), findsNothing);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('End session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('fits a small phone', (tester) async {
    await pumpPlayer(tester, size: const Size(320, 568));
    await tester.pump(second * 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
